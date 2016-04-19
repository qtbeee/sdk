// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
/*
DON'T EDIT. GENERATED. DON'T EDIT.
This file has been generated by 'publish.dart' in the dart_messages package.

Messages are maintained in `lib/shared_messages.dart` of that same package.
After any change to that file, run `bin/publish.dart` to generate a new version
of the json, dart2js and analyzer representations.
*/
import '../messages.dart' show MessageKind, MessageTemplate;

const Map<MessageKind, MessageTemplate> TEMPLATES = const <MessageKind, MessageTemplate>{ 
  MessageKind.CONST_CONSTRUCTOR_WITH_BODY: const MessageTemplate(
    MessageKind.CONST_CONSTRUCTOR_WITH_BODY,
    "Const constructor can't have a body.",
    howToFix: "Try removing the 'const' keyword or the body.",
    examples: const [
      r"""
         class C {
           const C() {}
         }

         main() => new C();""",
    ]
  ),  // Generated. Don't edit.
  MessageKind.CONST_FACTORY: const MessageTemplate(
    MessageKind.CONST_FACTORY,
    "Only redirecting factory constructors can be declared to be 'const'.",
    howToFix: "Try removing the 'const' keyword or replacing the body with '=' followed by a valid target.",
    examples: const [
      r"""
         class C {
           const factory C() {}
         }

         main() => new C();""",
    ]
  ),  // Generated. Don't edit.
  MessageKind.EXTRANEOUS_MODIFIER: const MessageTemplate(
    MessageKind.EXTRANEOUS_MODIFIER,
    "Can't have modifier '#{modifier}' here.",
    howToFix: "Try removing '#{modifier}'.",
    examples: const [
      "var String foo; main(){}",
      "var set foo; main(){}",
      "var final foo; main(){}",
      "var var foo; main(){}",
      "var const foo; main(){}",
      "var abstract foo; main(){}",
      "var static foo; main(){}",
      "var external foo; main(){}",
      "get var foo; main(){}",
      "set var foo; main(){}",
      "final var foo; main(){}",
      "var var foo; main(){}",
      "const var foo; main(){}",
      "abstract var foo; main(){}",
      "static var foo; main(){}",
      "external var foo; main(){}",
    ]
  ),  // Generated. Don't edit.
  MessageKind.EXTRANEOUS_MODIFIER_REPLACE: const MessageTemplate(
    MessageKind.EXTRANEOUS_MODIFIER_REPLACE,
    "Can't have modifier '#{modifier}' here.",
    howToFix: "Try replacing modifier '#{modifier}' with 'var', 'final', or a type.",
    examples: const [
      "set foo; main(){}",
      "abstract foo; main(){}",
      "static foo; main(){}",
      "external foo; main(){}",
    ]
  ),  // Generated. Don't edit.
  MessageKind.CONSTRUCTOR_WITH_RETURN_TYPE: const MessageTemplate(
    MessageKind.CONSTRUCTOR_WITH_RETURN_TYPE,
    "Constructors can't have a return type.",
    howToFix: "Try removing the return type.",
    examples: const [
      "class A { int A() {} } main() { new A(); }",
    ]
  ),  // Generated. Don't edit.
  MessageKind.MISSING_EXPRESSION_IN_THROW: const MessageTemplate(
    MessageKind.MISSING_EXPRESSION_IN_THROW,
    "Missing expression after 'throw'.",
    howToFix: "Did you mean 'rethrow'?",
    examples: const [
      "main() { throw; }",
      "main() { try { throw 0; } catch(e) { throw; } }",
    ]
  ),  // Generated. Don't edit.
  MessageKind.RETHROW_OUTSIDE_CATCH: const MessageTemplate(
    MessageKind.RETHROW_OUTSIDE_CATCH,
    "Rethrow must be inside of catch clause.",
    howToFix: "Try moving the expression into a catch clause, or using a 'throw' expression.",
    examples: const [
      "main() { rethrow; }",
    ]
  ),  // Generated. Don't edit.
  MessageKind.RETURN_IN_GENERATIVE_CONSTRUCTOR: const MessageTemplate(
    MessageKind.RETURN_IN_GENERATIVE_CONSTRUCTOR,
    "Constructors can't return values.",
    howToFix: "Try removing the return statement or using a factory constructor.",
    examples: const [
      r"""
        class C {
          C() {
            return 1;
          }
        }

        main() => new C();""",
    ]
  ),  // Generated. Don't edit.
  MessageKind.RETURN_IN_GENERATOR: const MessageTemplate(
    MessageKind.RETURN_IN_GENERATOR,
    "Can't return a value from a generator function (using the '#{modifier}' modifier).",
    howToFix: "Try removing the value, replacing 'return' with 'yield' or changing the method body modifier.",
    examples: const [
      r"""
        foo() async* { return 0; }
        main() => foo();
        """,
      r"""
        foo() sync* { return 0; }
        main() => foo();
        """,
    ]
  ),  // Generated. Don't edit.
  MessageKind.NOT_ASSIGNABLE: const MessageTemplate(
    MessageKind.NOT_ASSIGNABLE,
    "'#{fromType}' is not assignable to '#{toType}'."  ),  // Generated. Don't edit.
  MessageKind.FORIN_NOT_ASSIGNABLE: const MessageTemplate(
    MessageKind.FORIN_NOT_ASSIGNABLE,
    "The element type '#{currentType}' of '#{expressionType}' is not assignable to '#{elementType}'.",
    examples: const [
      r"""
        main() {
          List<int> list = <int>[1, 2];
          for (String x in list) x;
        }
        """,
    ]
  ),  // Generated. Don't edit.
  MessageKind.CANNOT_RESOLVE: const MessageTemplate(
    MessageKind.CANNOT_RESOLVE,
    "Can't resolve '#{name}'."  ),  // Generated. Don't edit.
  MessageKind.UNDEFINED_METHOD: const MessageTemplate(
    MessageKind.UNDEFINED_METHOD,
    "The method '#{memberName}' is not defined for the class '#{className}'.",
    examples: const [
      r"""
        class A {
          foo() { bar(); }
        }
        main() { new A().foo(); }
        """,
    ]
  ),  // Generated. Don't edit.
  MessageKind.UNDEFINED_GETTER: const MessageTemplate(
    MessageKind.UNDEFINED_GETTER,
    "The getter '#{memberName}' is not defined for the class '#{className}'.",
    examples: const [
      "class A {} main() { new A().x; }",
      "class A {} main() { A.x; }",
    ]
  ),  // Generated. Don't edit.
  MessageKind.UNDEFINED_INSTANCE_GETTER_BUT_SETTER: const MessageTemplate(
    MessageKind.UNDEFINED_INSTANCE_GETTER_BUT_SETTER,
    "The setter '#{memberName}' in class '#{className}' can not be used as a getter.",
    examples: const [
      "class A { set x(y) {} } main() { new A().x; }",
    ]
  ),  // Generated. Don't edit.
  MessageKind.UNDEFINED_OPERATOR: const MessageTemplate(
    MessageKind.UNDEFINED_OPERATOR,
    "The operator '#{memberName}' is not defined for the class '#{className}'.",
    examples: const [
      "class A {} main() { new A() + 3; }",
    ]
  ),  // Generated. Don't edit.
  MessageKind.UNDEFINED_SETTER: const MessageTemplate(
    MessageKind.UNDEFINED_SETTER,
    "The setter '#{memberName}' is not defined for the class '#{className}'.",
    examples: const [
      "class A {} main() { new A().x = 499; }",
    ]
  ),  // Generated. Don't edit.
  MessageKind.NO_SUCH_SUPER_MEMBER: const MessageTemplate(
    MessageKind.NO_SUCH_SUPER_MEMBER,
    "Can't resolve '#{memberName}' in a superclass of '#{className}'."  ),  // Generated. Don't edit.
  MessageKind.UNDEFINED_SUPER_SETTER: const MessageTemplate(
    MessageKind.UNDEFINED_SUPER_SETTER,
    "The setter '#{memberName}' is not defined in a superclass of '#{className}'.",
    examples: const [
      r"""
        class A {}
        class B extends A {
          foo() { super.x = 499; }
        }
        main() { new B().foo(); }
        """,
    ]
  ),  // Generated. Don't edit.
  MessageKind.UNDEFINED_STATIC_GETTER_BUT_SETTER: const MessageTemplate(
    MessageKind.UNDEFINED_STATIC_GETTER_BUT_SETTER,
    "Cannot resolve getter '#{name}'.",
    examples: const [
      "set foo(x) {}  main() { foo; }",
    ]
  ),  // Generated. Don't edit.
  MessageKind.UNDEFINED_STATIC_SETTER_BUT_GETTER: const MessageTemplate(
    MessageKind.UNDEFINED_STATIC_SETTER_BUT_GETTER,
    "Cannot resolve setter '#{name}'.",
    examples: const [
      r"""
        main() {
          final x = 1;
          x = 2;
        }""",
      r"""
        main() {
          const x = 1;
          x = 2;
        }
        """,
      r"""
        final x = 1;
        main() { x = 3; }
        """,
      r"""
        const x = 1;
        main() { x = 3; }
        """,
      "get foo => null  main() { foo = 5; }",
      "const foo = 0  main() { foo = 5; }",
    ]
  ),  // Generated. Don't edit.
};
