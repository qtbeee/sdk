// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.bytecode.assembler;

import 'dart:typed_data';

import 'dbc.dart';
import 'exceptions.dart' show ExceptionsTable;

class Label {
  List<int> _jumps = <int>[];
  int offset = -1;

  Label();

  bool get isBound => offset >= 0;

  int jumpOperand(int jumpOffset) {
    if (isBound) {
      // Jump instruction takes an offset in DBC words.
      return (offset - jumpOffset) >> BytecodeAssembler.kLog2BytesPerBytecode;
    }
    _jumps.add(jumpOffset);
    return 0;
  }

  List<int> bind(int offset) {
    assert(!isBound);
    this.offset = offset;
    final jumps = _jumps;
    _jumps = null;
    return jumps;
  }
}

class BytecodeAssembler {
  static const int kBitsPerInt = 64;
  static const int kLog2BytesPerBytecode = 2;

  // TODO(alexmarkov): figure out more efficient storage for generated bytecode.
  final List<int> bytecode = new List<int>();
  final Uint32List _encodeBufferIn;
  final Uint8List _encodeBufferOut;
  final ExceptionsTable exceptionsTable = new ExceptionsTable();

  BytecodeAssembler._(this._encodeBufferIn, this._encodeBufferOut);

  factory BytecodeAssembler() {
    final buf = new Uint32List(1);
    return new BytecodeAssembler._(buf, new Uint8List.view(buf.buffer));
  }

  int get offset => bytecode.length;
  int get offsetInWords => bytecode.length >> kLog2BytesPerBytecode;

  void bind(Label label) {
    final List<int> jumps = label.bind(offset);
    for (int jumpOffset in jumps) {
      patchJump(jumpOffset, label.jumpOperand(jumpOffset));
    }
  }

  void emitWord(int word) {
    _encodeBufferIn[0] = word; // TODO(alexmarkov): Which endianness to use?
    bytecode.addAll(_encodeBufferOut);
  }

  int _getOpcodeAt(int pos) {
    return bytecode[pos]; // TODO(alexmarkov): Take endianness into account.
  }

  void _setWord(int pos, int word) {
    _encodeBufferIn[0] = word; // TODO(alexmarkov): Which endianness to use?
    bytecode.setRange(pos, pos + _encodeBufferOut.length, _encodeBufferOut);
  }

  int _unsigned(int v, int bits) {
    assert(bits < kBitsPerInt);
    final int mask = (1 << bits) - 1;
    if ((v & mask) != v) {
      throw 'Value $v is out of unsigned $bits-bit range';
    }
    return v;
  }

  int _signed(int v, int bits) {
    assert(bits < kBitsPerInt);
    final int shift = kBitsPerInt - bits;
    if (((v << shift) >> shift) != v) {
      throw 'Value $v is out of signed $bits-bit range';
    }
    final int mask = (1 << bits) - 1;
    return v & mask;
  }

  int _uint8(int v) => _unsigned(v, 8);
  int _uint16(int v) => _unsigned(v, 16);

//  int _int8(int v) => _signed(v, 8);
  int _int16(int v) => _signed(v, 16);
  int _int24(int v) => _signed(v, 24);

  int _encode0(Opcode opcode) => _uint8(opcode.index);

  int _encodeA(Opcode opcode, int ra) =>
      _uint8(opcode.index) | (_uint8(ra) << 8);

  int _encodeAD(Opcode opcode, int ra, int rd) =>
      _uint8(opcode.index) | (_uint8(ra) << 8) | (_uint16(rd) << 16);

// TODO(alexmarkov) This format is currently unused. Restore it if needed, or
// remove it once bytecode instruction set is finalized.
//
//  int _encodeAX(Opcode opcode, int ra, int rx) =>
//      _uint8(opcode.index) | (_uint8(ra) << 8) | (_int16(rx) << 16);

  int _encodeD(Opcode opcode, int rd) =>
      _uint8(opcode.index) | (_uint16(rd) << 16);

  int _encodeX(Opcode opcode, int rx) =>
      _uint8(opcode.index) | (_int16(rx) << 16);

  int _encodeABC(Opcode opcode, int ra, int rb, int rc) =>
      _uint8(opcode.index) |
      (_uint8(ra) << 8) |
      (_uint8(rb) << 16) |
      (_uint8(rc) << 24);

// TODO(alexmarkov) This format is currently unused. Restore it if needed, or
// remove it once bytecode instruction set is finalized.
//
//  int _encodeABY(Opcode opcode, int ra, int rb, int ry) =>
//      _uint8(opcode.index) |
//      (_uint8(ra) << 8) |
//      (_uint8(rb) << 16) |
//      (_int8(ry) << 24);

  int _encodeT(Opcode opcode, int rt) =>
      _uint8(opcode.index) | (_int24(rt) << 8);

  void emitTrap() {
    emitWord(_encode0(Opcode.kTrap));
  }

  void emitDrop1() {
    emitWord(_encode0(Opcode.kDrop1));
  }

  void emitJump(Label label) {
    emitWord(_encodeT(Opcode.kJump, label.jumpOperand(offset)));
  }

  void emitJumpIfNoAsserts(Label label) {
    emitWord(_encodeT(Opcode.kJumpIfNoAsserts, label.jumpOperand(offset)));
  }

  void emitJumpIfNotZeroTypeArgs(Label label) {
    emitWord(
        _encodeT(Opcode.kJumpIfNotZeroTypeArgs, label.jumpOperand(offset)));
  }

  void emitJumpIfEqStrict(Label label) {
    emitWord(_encodeT(Opcode.kJumpIfEqStrict, label.jumpOperand(offset)));
  }

  void emitJumpIfNeStrict(Label label) {
    emitWord(_encodeT(Opcode.kJumpIfNeStrict, label.jumpOperand(offset)));
  }

  void emitJumpIfTrue(Label label) {
    emitWord(_encodeT(Opcode.kJumpIfTrue, label.jumpOperand(offset)));
  }

  void emitJumpIfFalse(Label label) {
    emitWord(_encodeT(Opcode.kJumpIfFalse, label.jumpOperand(offset)));
  }

  void emitJumpIfNull(Label label) {
    emitWord(_encodeT(Opcode.kJumpIfNull, label.jumpOperand(offset)));
  }

  void emitJumpIfNotNull(Label label) {
    emitWord(_encodeT(Opcode.kJumpIfNotNull, label.jumpOperand(offset)));
  }

  void patchJump(int pos, int rt) {
    final Opcode opcode = Opcode.values[_getOpcodeAt(pos)];
    assert(isJump(opcode));
    _setWord(pos, _encodeT(opcode, rt));
  }

  void emitReturnTOS() {
    emitWord(_encode0(Opcode.kReturnTOS));
  }

  void emitPush(int rx) {
    emitWord(_encodeX(Opcode.kPush, rx));
  }

  void emitLoadConstant(int ra, int rd) {
    emitWord(_encodeAD(Opcode.kLoadConstant, ra, rd));
  }

  void emitPushConstant(int rd) {
    emitWord(_encodeD(Opcode.kPushConstant, rd));
  }

  void emitPushNull() {
    emitWord(_encode0(Opcode.kPushNull));
  }

  void emitPushTrue() {
    emitWord(_encode0(Opcode.kPushTrue));
  }

  void emitPushFalse() {
    emitWord(_encode0(Opcode.kPushFalse));
  }

  void emitPushInt(int rx) {
    emitWord(_encodeX(Opcode.kPushInt, rx));
  }

  void emitStoreLocal(int rx) {
    emitWord(_encodeX(Opcode.kStoreLocal, rx));
  }

  void emitPopLocal(int rx) {
    emitWord(_encodeX(Opcode.kPopLocal, rx));
  }

  void emitIndirectStaticCall(int ra, int rd) {
    emitWord(_encodeAD(Opcode.kIndirectStaticCall, ra, rd));
  }

  void emitInstanceCall(int ra, int rd) {
    emitWord(_encodeAD(Opcode.kInstanceCall, ra, rd));
  }

  void emitNativeCall(int rd) {
    emitWord(_encodeD(Opcode.kNativeCall, rd));
  }

  void emitStoreStaticTOS(int rd) {
    emitWord(_encodeD(Opcode.kStoreStaticTOS, rd));
  }

  void emitPushStatic(int rd) {
    emitWord(_encodeD(Opcode.kPushStatic, rd));
  }

  void emitCreateArrayTOS() {
    emitWord(_encode0(Opcode.kCreateArrayTOS));
  }

  void emitAllocate(int rd) {
    emitWord(_encodeD(Opcode.kAllocate, rd));
  }

  void emitAllocateT() {
    emitWord(_encode0(Opcode.kAllocateT));
  }

  void emitStoreIndexedTOS() {
    emitWord(_encode0(Opcode.kStoreIndexedTOS));
  }

  void emitStoreFieldTOS(int rd) {
    emitWord(_encodeD(Opcode.kStoreFieldTOS, rd));
  }

  void emitStoreContextParent() {
    emitWord(_encode0(Opcode.kStoreContextParent));
  }

  void emitStoreContextVar(int rd) {
    emitWord(_encodeD(Opcode.kStoreContextVar, rd));
  }

  void emitLoadFieldTOS(int rd) {
    emitWord(_encodeD(Opcode.kLoadFieldTOS, rd));
  }

  void emitLoadTypeArgumentsField(int rd) {
    emitWord(_encodeD(Opcode.kLoadTypeArgumentsField, rd));
  }

  void emitLoadContextParent() {
    emitWord(_encode0(Opcode.kLoadContextParent));
  }

  void emitLoadContextVar(int rd) {
    emitWord(_encodeD(Opcode.kLoadContextVar, rd));
  }

  void emitBooleanNegateTOS() {
    emitWord(_encode0(Opcode.kBooleanNegateTOS));
  }

  void emitThrow(int ra) {
    emitWord(_encodeA(Opcode.kThrow, ra));
  }

  void emitEntry(int rd) {
    emitWord(_encodeD(Opcode.kEntry, rd));
  }

  void emitFrame(int rd) {
    emitWord(_encodeD(Opcode.kFrame, rd));
  }

  void emitSetFrame(int ra) {
    emitWord(_encodeA(Opcode.kSetFrame, ra));
  }

  void emitAllocateContext(int rd) {
    emitWord(_encodeD(Opcode.kAllocateContext, rd));
  }

  void emitCloneContext() {
    emitWord(_encode0(Opcode.kCloneContext));
  }

  void emitMoveSpecial(int ra, SpecialIndex rd) {
    emitWord(_encodeAD(Opcode.kMoveSpecial, ra, rd.index));
  }

  void emitInstantiateType(int rd) {
    emitWord(_encodeD(Opcode.kInstantiateType, rd));
  }

  void emitInstantiateTypeArgumentsTOS(int ra, int rd) {
    emitWord(_encodeAD(Opcode.kInstantiateTypeArgumentsTOS, ra, rd));
  }

  void emitAssertAssignable(int ra, int rd) {
    emitWord(_encodeAD(Opcode.kAssertAssignable, ra, rd));
  }

  void emitAssertSubtype() {
    emitWord(_encode0(Opcode.kAssertSubtype));
  }

  void emitAssertBoolean(int ra) {
    emitWord(_encodeA(Opcode.kAssertBoolean, ra));
  }

  void emitCheckStack() {
    emitWord(_encode0(Opcode.kCheckStack));
  }

  void emitCheckFunctionTypeArgs(int ra, int rd) {
    emitWord(_encodeAD(Opcode.kCheckFunctionTypeArgs, ra, rd));
  }

  void emitEntryFixed(int ra, int rd) {
    emitWord(_encodeAD(Opcode.kEntryFixed, ra, rd));
  }

  void emitEntryOptional(int ra, int rb, int rc) {
    emitWord(_encodeABC(Opcode.kEntryOptional, ra, rb, rc));
  }
}
