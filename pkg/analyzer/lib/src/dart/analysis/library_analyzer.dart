// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/context/context.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/constant/constant_verifier.dart';
import 'package:analyzer/src/dart/constant/evaluation.dart';
import 'package:analyzer/src/dart/constant/utilities.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/handle.dart';
import 'package:analyzer/src/dart/element/inheritance_manager2.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/error/inheritance_override.dart';
import 'package:analyzer/src/error/pending_error.dart';
import 'package:analyzer/src/generated/declaration_resolver.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error_verifier.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/lint/linter_visitor.dart';
import 'package:analyzer/src/services/lint.dart';
import 'package:analyzer/src/summary/link.dart';
import 'package:analyzer/src/task/dart.dart';
import 'package:analyzer/src/task/strong/checker.dart';

/**
 * Analyzer of a single library.
 */
class LibraryAnalyzer {
  final AnalysisOptionsImpl _analysisOptions;
  final DeclaredVariables _declaredVariables;
  final SourceFactory _sourceFactory;
  final FileState _library;
  final InheritanceManager2 _inheritance;

  final bool Function(Uri) _isLibraryUri;
  final AnalysisContextImpl _context;
  final ElementResynthesizer _resynthesizer;
  final TypeProvider _typeProvider;

  LibraryElement _libraryElement;
  LibraryScope _libraryScope;

  final Map<FileState, LineInfo> _fileToLineInfo = {};
  final Map<FileState, IgnoreInfo> _fileToIgnoreInfo = {};

  final Map<FileState, RecordingErrorListener> _errorListeners = {};
  final Map<FileState, ErrorReporter> _errorReporters = {};
  final List<UsedImportedElements> _usedImportedElementsList = [];
  final List<UsedLocalElements> _usedLocalElementsList = [];
  final Map<FileState, List<PendingError>> _fileToPendingErrors = {};
  final Set<ConstantEvaluationTarget> _constants = new Set();

  LibraryAnalyzer(
      this._analysisOptions,
      this._declaredVariables,
      this._sourceFactory,
      this._isLibraryUri,
      this._context,
      this._resynthesizer,
      this._library)
      : _inheritance = new InheritanceManager2(_context.typeSystem),
        _typeProvider = _context.typeProvider;

  /**
   * Compute analysis results for all units of the library.
   */
  Future<Map<FileState, UnitAnalysisResult>> analyze() async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    return PerformanceStatistics.analysis.makeCurrentWhileAsync(() async {
      return _analyze();
    });
  }

  Map<FileState, UnitAnalysisResult> _analyze() {
    Map<FileState, CompilationUnit> units = {};

    // Parse all files.
    for (FileState file in _library.libraryFiles) {
      units[file] = _parse(file);
    }

    // Resolve URIs in directives to corresponding sources.
    units.forEach((file, unit) {
      _resolveUriBasedDirectives(file, unit);
    });

    try {
      _libraryElement = _resynthesizer
          .getElement(new ElementLocationImpl.con3([_library.uriStr]));
      _libraryScope = new LibraryScope(_libraryElement);

      _resolveDirectives(units);

      units.forEach((file, unit) {
        _resolveFile(file, unit);
        _computePendingMissingRequiredParameters(file, unit);
      });

      units.values.forEach(_findConstants);
      _computeConstants();

      PerformanceStatistics.errors.makeCurrentWhile(() {
        units.forEach((file, unit) {
          _computeVerifyErrors(file, unit);
        });
      });

      if (_analysisOptions.hint) {
        PerformanceStatistics.hints.makeCurrentWhile(() {
          units.forEach((file, unit) {
            {
              var visitor = new GatherUsedLocalElementsVisitor(_libraryElement);
              unit.accept(visitor);
              _usedLocalElementsList.add(visitor.usedElements);
            }
            {
              var visitor =
                  new GatherUsedImportedElementsVisitor(_libraryElement);
              unit.accept(visitor);
              _usedImportedElementsList.add(visitor.usedElements);
            }
          });
          units.forEach((file, unit) {
            _computeHints(file, unit);
          });
        });
      }

      if (_analysisOptions.lint) {
        PerformanceStatistics.lints.makeCurrentWhile(() {
          units.forEach((file, unit) {
            _computeLints(file, unit);
          });
        });
      }
    } finally {
      _context.dispose();
    }

    // Return full results.
    Map<FileState, UnitAnalysisResult> results = {};
    units.forEach((file, unit) {
      List<AnalysisError> errors = _getErrorListener(file).errors;
      errors = _filterIgnoredErrors(file, errors);
      results[file] = new UnitAnalysisResult(file, unit, errors);
    });
    return results;
  }

  void _computeConstantErrors(
      ErrorReporter errorReporter, CompilationUnit unit) {
    ConstantVerifier constantVerifier = new ConstantVerifier(
        errorReporter, _libraryElement, _typeProvider, _declaredVariables,
        forAnalysisDriver: true);
    unit.accept(constantVerifier);
  }

  /**
   * Compute [_constants] in all units.
   */
  void _computeConstants() {
    ConstantEvaluationEngine evaluationEngine = new ConstantEvaluationEngine(
        _typeProvider, _declaredVariables,
        forAnalysisDriver: true, typeSystem: _context.typeSystem);

    List<_ConstantNode> nodes = [];
    Map<ConstantEvaluationTarget, _ConstantNode> nodeMap = {};
    for (ConstantEvaluationTarget constant in _constants) {
      var node = new _ConstantNode(evaluationEngine, nodeMap, constant);
      nodes.add(node);
      nodeMap[constant] = node;
    }

    for (_ConstantNode node in nodes) {
      if (!node.isEvaluated) {
        new _ConstantWalker(evaluationEngine).walk(node);
      }
    }
  }

  void _computeHints(FileState file, CompilationUnit unit) {
    if (file.source == null) {
      return;
    }

    AnalysisErrorListener errorListener = _getErrorListener(file);
    ErrorReporter errorReporter = _getErrorReporter(file);

    //
    // Convert the pending errors into actual errors.
    //
    for (PendingError pendingError in _fileToPendingErrors[file]) {
      errorListener.onError(pendingError.toAnalysisError());
    }

    unit.accept(
        new DeadCodeVerifier(errorReporter, typeSystem: _context.typeSystem));

    // Dart2js analysis.
    if (_analysisOptions.dart2jsHint) {
      unit.accept(new Dart2JSVerifier(errorReporter));
    }

    unit.accept(new BestPracticesVerifier(
        errorReporter, _typeProvider, _libraryElement,
        typeSystem: _context.typeSystem));

    unit.accept(new OverrideVerifier(
      _inheritance,
      _libraryElement,
      errorReporter,
    ));

    new ToDoFinder(errorReporter).findIn(unit);

    // Verify imports.
    {
      ImportsVerifier verifier = new ImportsVerifier();
      verifier.addImports(unit);
      _usedImportedElementsList.forEach(verifier.removeUsedElements);
      verifier.generateDuplicateImportHints(errorReporter);
      verifier.generateDuplicateShownHiddenNameHints(errorReporter);
      verifier.generateUnusedImportHints(errorReporter);
      verifier.generateUnusedShownNameHints(errorReporter);
    }

    // Unused local elements.
    {
      UsedLocalElements usedElements =
          new UsedLocalElements.merge(_usedLocalElementsList);
      UnusedLocalElementsVerifier visitor =
          new UnusedLocalElementsVerifier(errorListener, usedElements);
      unit.accept(visitor);
    }
  }

  void _computeLints(FileState file, CompilationUnit unit) {
    if (file.source == null) {
      return;
    }

    ErrorReporter errorReporter = _getErrorReporter(file);

    var nodeRegistry = new NodeLintRegistry(_analysisOptions.enableTiming);
    var visitors = <AstVisitor>[];
    for (Linter linter in _analysisOptions.lintRules) {
      linter.reporter = errorReporter;
      if (linter is NodeLintRule) {
        (linter as NodeLintRule).registerNodeProcessors(nodeRegistry);
      } else {
        AstVisitor visitor = linter.getVisitor();
        if (visitor != null) {
          if (_analysisOptions.enableTiming) {
            var timer = lintRegistry.getTimer(linter);
            visitor = new TimedAstVisitor(visitor, timer);
          }
          visitors.add(visitor);
        }
      }
    }

    // Run lints that handle specific node types.
    unit.accept(new LinterVisitor(
        nodeRegistry, ExceptionHandlingDelegatingAstVisitor.logException));

    // Run visitor based lints.
    if (visitors.isNotEmpty) {
      AstVisitor visitor = new ExceptionHandlingDelegatingAstVisitor(
          visitors, ExceptionHandlingDelegatingAstVisitor.logException);
      unit.accept(visitor);
    }
  }

  void _computePendingMissingRequiredParameters(
      FileState file, CompilationUnit unit) {
    // TODO(scheglov) This can be done without "pending" if we resynthesize.
    var computer = new RequiredConstantsComputer(file.source);
    unit.accept(computer);
    _constants.addAll(computer.requiredConstants);
    _fileToPendingErrors[file] = computer.pendingErrors;
  }

  void _computeVerifyErrors(FileState file, CompilationUnit unit) {
    if (file.source == null) {
      return;
    }

    RecordingErrorListener errorListener = _getErrorListener(file);

    CodeChecker checker = new CodeChecker(
      _typeProvider,
      _context.typeSystem,
      errorListener,
      _analysisOptions,
    );
    checker.visitCompilationUnit(unit);

    ErrorReporter errorReporter = _getErrorReporter(file);

    //
    // Validate the directives.
    //
    _validateUriBasedDirectives(file, unit);

    //
    // Use the ConstantVerifier to compute errors.
    //
    _computeConstantErrors(errorReporter, unit);

    //
    // Compute inheritance and override errors.
    //
    var inheritanceOverrideVerifier = new InheritanceOverrideVerifier(
        _context.typeSystem, _inheritance, errorReporter);
    inheritanceOverrideVerifier.verifyUnit(unit);

    //
    // Use the ErrorVerifier to compute errors.
    //
    ErrorVerifier errorVerifier = new ErrorVerifier(
        errorReporter, _libraryElement, _typeProvider, _inheritance, false);
    unit.accept(errorVerifier);
  }

  /**
   * Return a subset of the given [errors] that are not marked as ignored in
   * the [file].
   */
  List<AnalysisError> _filterIgnoredErrors(
      FileState file, List<AnalysisError> errors) {
    if (errors.isEmpty) {
      return errors;
    }

    IgnoreInfo ignoreInfo = _fileToIgnoreInfo[file];
    if (!ignoreInfo.hasIgnores) {
      return errors;
    }

    LineInfo lineInfo = _fileToLineInfo[file];

    bool isIgnored(AnalysisError error) {
      int errorLine = lineInfo.getLocation(error.offset).lineNumber;
      String errorCode = error.errorCode.name.toLowerCase();
      return ignoreInfo.ignoredAt(errorCode, errorLine);
    }

    return errors.where((AnalysisError e) => !isIgnored(e)).toList();
  }

  /// Find constants to compute.
  void _findConstants(CompilationUnit unit) {
    ConstantFinder constantFinder = new ConstantFinder();
    unit.accept(constantFinder);
    _constants.addAll(constantFinder.constantsToCompute);

    var dependenciesFinder = new ConstantExpressionsDependenciesFinder();
    unit.accept(dependenciesFinder);
    _constants.addAll(dependenciesFinder.dependencies);
  }

  RecordingErrorListener _getErrorListener(FileState file) =>
      _errorListeners.putIfAbsent(file, () => new RecordingErrorListener());

  ErrorReporter _getErrorReporter(FileState file) {
    return _errorReporters.putIfAbsent(file, () {
      RecordingErrorListener listener = _getErrorListener(file);
      return new ErrorReporter(listener, file.source);
    });
  }

  /**
   * Return the name of the library that the given part is declared to be a
   * part of, or `null` if the part does not contain a part-of directive.
   */
  _NameOrSource _getPartLibraryNameOrUri(Source partSource,
      CompilationUnit partUnit, List<Directive> directivesToResolve) {
    for (Directive directive in partUnit.directives) {
      if (directive is PartOfDirective) {
        directivesToResolve.add(directive);
        LibraryIdentifier libraryName = directive.libraryName;
        if (libraryName != null) {
          return new _NameOrSource(libraryName.name, null);
        }
        String uri = directive.uri?.stringValue;
        if (uri != null) {
          Source librarySource = _sourceFactory.resolveUri(partSource, uri);
          if (librarySource != null) {
            return new _NameOrSource(null, librarySource);
          }
        }
      }
    }
    return null;
  }

  /**
   * Return `true` if the given [source] is a library.
   */
  bool _isLibrarySource(Source source) {
    return _isLibraryUri(source.uri);
  }

  /**
   * Return a new parsed unresolved [CompilationUnit].
   */
  CompilationUnit _parse(FileState file) {
    AnalysisErrorListener errorListener = _getErrorListener(file);
    String content = file.content;
    CompilationUnit unit = file.parse(errorListener);

    LineInfo lineInfo = unit.lineInfo;
    _fileToLineInfo[file] = lineInfo;
    _fileToIgnoreInfo[file] = IgnoreInfo.calculateIgnores(content, lineInfo);

    return unit;
  }

  void _resolveDirectives(Map<FileState, CompilationUnit> units) {
    CompilationUnit definingCompilationUnit = units[_library];
    definingCompilationUnit.element = _libraryElement.definingCompilationUnit;

    bool matchNodeElement(Directive node, Element element) {
      return node.offset == element.nameOffset;
    }

    ErrorReporter libraryErrorReporter = _getErrorReporter(_library);

    LibraryIdentifier libraryNameNode = null;
    var seenPartSources = new Set<Source>();
    var directivesToResolve = <Directive>[];
    int partIndex = 0;
    for (Directive directive in definingCompilationUnit.directives) {
      if (directive is LibraryDirective) {
        libraryNameNode = directive.name;
        directivesToResolve.add(directive);
      } else if (directive is ImportDirective) {
        for (ImportElement importElement in _libraryElement.imports) {
          if (matchNodeElement(directive, importElement)) {
            directive.element = importElement;
            directive.prefix?.staticElement = importElement.prefix;
            Source source = importElement.importedLibrary?.source;
            if (source != null && !_isLibrarySource(source)) {
              ErrorCode errorCode = importElement.isDeferred
                  ? StaticWarningCode.IMPORT_OF_NON_LIBRARY
                  : CompileTimeErrorCode.IMPORT_OF_NON_LIBRARY;
              libraryErrorReporter.reportErrorForNode(
                  errorCode, directive.uri, [directive.uri]);
            }
          }
        }
      } else if (directive is ExportDirective) {
        for (ExportElement exportElement in _libraryElement.exports) {
          if (matchNodeElement(directive, exportElement)) {
            directive.element = exportElement;
            Source source = exportElement.exportedLibrary?.source;
            if (source != null && !_isLibrarySource(source)) {
              libraryErrorReporter.reportErrorForNode(
                  CompileTimeErrorCode.EXPORT_OF_NON_LIBRARY,
                  directive.uri,
                  [directive.uri]);
            }
          }
        }
      } else if (directive is PartDirective) {
        StringLiteral partUri = directive.uri;

        FileState partFile = _library.partedFiles[partIndex];
        CompilationUnit partUnit = units[partFile];
        CompilationUnitElement partElement = _libraryElement.parts[partIndex];
        partUnit.element = partElement;
        directive.element = partElement;
        partIndex++;

        Source partSource = directive.uriSource;
        if (partSource == null) {
          continue;
        }

        //
        // Validate that the part source is unique in the library.
        //
        if (!seenPartSources.add(partSource)) {
          libraryErrorReporter.reportErrorForNode(
              CompileTimeErrorCode.DUPLICATE_PART, partUri, [partSource.uri]);
        }

        //
        // Validate that the part contains a part-of directive with the same
        // name or uri as the library.
        //
        if (_context.exists(partSource)) {
          _NameOrSource nameOrSource = _getPartLibraryNameOrUri(
              partSource, partUnit, directivesToResolve);
          if (nameOrSource == null) {
            libraryErrorReporter.reportErrorForNode(
                CompileTimeErrorCode.PART_OF_NON_PART,
                partUri,
                [partUri.toSource()]);
          } else {
            String name = nameOrSource.name;
            if (name != null) {
              if (libraryNameNode == null) {
                libraryErrorReporter.reportErrorForNode(
                    ResolverErrorCode.PART_OF_UNNAMED_LIBRARY, partUri, [name]);
              } else if (libraryNameNode.name != name) {
                libraryErrorReporter.reportErrorForNode(
                    StaticWarningCode.PART_OF_DIFFERENT_LIBRARY,
                    partUri,
                    [libraryNameNode.name, name]);
              }
            } else {
              Source source = nameOrSource.source;
              if (source != _library.source) {
                libraryErrorReporter.reportErrorForNode(
                    StaticWarningCode.PART_OF_DIFFERENT_LIBRARY,
                    partUri,
                    [_library.uriStr, source.uri]);
              }
            }
          }
        }
      }
    }

    // TODO(brianwilkerson) Report the error
    // ResolverErrorCode.MISSING_LIBRARY_DIRECTIVE_WITH_PART

    //
    // Resolve the relevant directives to the library element.
    //
    for (Directive directive in directivesToResolve) {
      directive.element = _libraryElement;
    }

    // TODO(scheglov) remove DirectiveResolver class
  }

  void _resolveFile(FileState file, CompilationUnit unit) {
    Source source = file.source;
    if (source == null) {
      return;
    }

    RecordingErrorListener errorListener = _getErrorListener(file);

    CompilationUnitElement unitElement = unit.declaredElement;

    // TODO(scheglov) Hack: set types for top-level variables
    // Otherwise TypeResolverVisitor will set declared types, and because we
    // don't run InferStaticVariableTypeTask, we will stuck with these declared
    // types. And we don't need to run this task - resynthesized elements have
    // inferred types.
    for (var e in unitElement.topLevelVariables) {
      if (!e.isSynthetic) {
        e.type;
      }
    }

    new DeclarationResolver().resolve(unit, unitElement);

    unit.accept(new AstRewriteVisitor(_context.typeSystem, _libraryElement,
        source, _typeProvider, errorListener,
        nameScope: _libraryScope));

    // TODO(scheglov) remove EnumMemberBuilder class

    new TypeParameterBoundsResolver(
            _context.typeSystem, _libraryElement, source, errorListener)
        .resolveTypeBounds(unit);

    unit.accept(new TypeResolverVisitor(
        _libraryElement, source, _typeProvider, errorListener));

    unit.accept(new VariableResolverVisitor(
        _libraryElement, source, _typeProvider, errorListener,
        nameScope: _libraryScope));

    unit.accept(new PartialResolverVisitor(_inheritance, _libraryElement,
        source, _typeProvider, AnalysisErrorListener.NULL_LISTENER));

    // Nothing for RESOLVED_UNIT8?
    // Nothing for RESOLVED_UNIT9?
    // Nothing for RESOLVED_UNIT10?

    unit.accept(new ResolverVisitor(
        _inheritance, _libraryElement, source, _typeProvider, errorListener));
  }

  /**
   * Return the result of resolve the given [uriContent], reporting errors
   * against the [uriLiteral].
   */
  Source _resolveUri(FileState file, bool isImport, StringLiteral uriLiteral,
      String uriContent) {
    UriValidationCode code =
        UriBasedDirectiveImpl.validateUri(isImport, uriLiteral, uriContent);
    if (code == null) {
      try {
        Uri.parse(uriContent);
      } on FormatException {
        return null;
      }
      return _sourceFactory.resolveUri(file.source, uriContent);
    } else if (code == UriValidationCode.URI_WITH_DART_EXT_SCHEME) {
      return null;
    } else if (code == UriValidationCode.URI_WITH_INTERPOLATION) {
      _getErrorReporter(file).reportErrorForNode(
          CompileTimeErrorCode.URI_WITH_INTERPOLATION, uriLiteral);
      return null;
    } else if (code == UriValidationCode.INVALID_URI) {
      _getErrorReporter(file).reportErrorForNode(
          CompileTimeErrorCode.INVALID_URI, uriLiteral, [uriContent]);
      return null;
    }
    return null;
  }

  void _resolveUriBasedDirectives(FileState file, CompilationUnit unit) {
    for (Directive directive in unit.directives) {
      if (directive is UriBasedDirective) {
        StringLiteral uriLiteral = directive.uri;
        String uriContent = uriLiteral.stringValue?.trim();
        directive.uriContent = uriContent;
        Source defaultSource = _resolveUri(
            file, directive is ImportDirective, uriLiteral, uriContent);
        directive.uriSource = defaultSource;
      }
    }
  }

  /**
   * Check the given [directive] to see if the referenced source exists and
   * report an error if it does not.
   */
  void _validateUriBasedDirective(
      FileState file, UriBasedDirectiveImpl directive) {
    Source source = directive.uriSource;
    if (source != null) {
      if (_context.exists(source)) {
        return;
      }
    } else {
      // Don't report errors already reported by ParseDartTask.resolveDirective
      // TODO(scheglov) we don't use this task here
      if (directive.validate() != null) {
        return;
      }
    }
    StringLiteral uriLiteral = directive.uri;
    CompileTimeErrorCode errorCode = CompileTimeErrorCode.URI_DOES_NOT_EXIST;
    if (_isGenerated(source)) {
      errorCode = CompileTimeErrorCode.URI_HAS_NOT_BEEN_GENERATED;
    }
    _getErrorReporter(file)
        .reportErrorForNode(errorCode, uriLiteral, [directive.uriContent]);
  }

  /**
   * Check each directive in the given [unit] to see if the referenced source
   * exists and report an error if it does not.
   */
  void _validateUriBasedDirectives(FileState file, CompilationUnit unit) {
    for (Directive directive in unit.directives) {
      if (directive is UriBasedDirective) {
        _validateUriBasedDirective(file, directive);
      }
    }
  }

  /**
   * Return `true` if the given [source] refers to a file that is assumed to be
   * generated.
   */
  static bool _isGenerated(Source source) {
    if (source == null) {
      return false;
    }
    // TODO(brianwilkerson) Generalize this mechanism.
    const List<String> suffixes = const <String>[
      '.g.dart',
      '.pb.dart',
      '.pbenum.dart',
      '.pbserver.dart',
      '.pbjson.dart',
      '.template.dart'
    ];
    String fullName = source.fullName;
    for (String suffix in suffixes) {
      if (fullName.endsWith(suffix)) {
        return true;
      }
    }
    return false;
  }
}

/**
 * Analysis result for single file.
 */
class UnitAnalysisResult {
  final FileState file;
  final CompilationUnit unit;
  final List<AnalysisError> errors;

  UnitAnalysisResult(this.file, this.unit, this.errors);
}

/**
 * [Node] that is used to compute constants in dependency order.
 */
class _ConstantNode extends Node<_ConstantNode> {
  final ConstantEvaluationEngine evaluationEngine;
  final Map<ConstantEvaluationTarget, _ConstantNode> nodeMap;
  final ConstantEvaluationTarget constant;

  bool isEvaluated = false;

  _ConstantNode(this.evaluationEngine, this.nodeMap, this.constant);

  @override
  List<_ConstantNode> computeDependencies() {
    List<ConstantEvaluationTarget> targets = [];
    evaluationEngine.computeDependencies(constant, targets.add);
    return targets.map(_getNode).toList();
  }

  _ConstantNode _getNode(ConstantEvaluationTarget constant) {
    return nodeMap.putIfAbsent(
        constant, () => new _ConstantNode(evaluationEngine, nodeMap, constant));
  }
}

/**
 * [DependencyWalker] for computing constants and detecting cycles.
 */
class _ConstantWalker extends DependencyWalker<_ConstantNode> {
  final ConstantEvaluationEngine evaluationEngine;

  _ConstantWalker(this.evaluationEngine);

  @override
  void evaluate(_ConstantNode node) {
    evaluationEngine.computeConstantValue(node.constant);
    node.isEvaluated = true;
  }

  @override
  void evaluateScc(List<_ConstantNode> scc) {
    var constantsInCycle = scc.map((node) => node.constant);
    for (_ConstantNode node in scc) {
      if (node.constant is ConstructorElementImpl) {
        (node.constant as ConstructorElementImpl).isCycleFree = false;
      }
      evaluationEngine.generateCycleError(constantsInCycle, node.constant);
      node.isEvaluated = true;
    }
  }
}

/**
 * Either the name or the source associated with a part-of directive.
 */
class _NameOrSource {
  final String name;
  final Source source;

  _NameOrSource(this.name, this.source);
}
