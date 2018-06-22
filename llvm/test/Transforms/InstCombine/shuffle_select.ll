; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; RUN: opt < %s -instcombine -S | FileCheck %s

; Try to eliminate binops and shuffles when the shuffle is a select in disguise:
; PR37806 - https://bugs.llvm.org/show_bug.cgi?id=37806

define <4 x i32> @add(<4 x i32> %v0) {
; CHECK-LABEL: @add(
; CHECK-NEXT:    [[T3:%.*]] = add <4 x i32> [[V0:%.*]], <i32 1, i32 6, i32 3, i32 8>
; CHECK-NEXT:    ret <4 x i32> [[T3]]
;
  %t1 = add <4 x i32> %v0, <i32 1, i32 2, i32 3, i32 4>
  %t2 = add <4 x i32> %v0, <i32 5, i32 6, i32 7, i32 8>
  %t3 = shufflevector <4 x i32> %t1, <4 x i32> %t2, <4 x i32> <i32 0, i32 5, i32 2, i32 7>
  ret <4 x i32> %t3
}

; Constant operand 0 (LHS) also works.

define <4 x i32> @sub(<4 x i32> %v0) {
; CHECK-LABEL: @sub(
; CHECK-NEXT:    [[T3:%.*]] = sub <4 x i32> <i32 1, i32 2, i32 3, i32 8>, [[V0:%.*]]
; CHECK-NEXT:    ret <4 x i32> [[T3]]
;
  %t1 = sub <4 x i32> <i32 1, i32 2, i32 3, i32 4>, %v0
  %t2 = sub <4 x i32> <i32 5, i32 6, i32 7, i32 8>, %v0
  %t3 = shufflevector <4 x i32> %t1, <4 x i32> %t2, <4 x i32> <i32 0, i32 1, i32 2, i32 7>
  ret <4 x i32> %t3
}

; If any element of the shuffle mask operand is undef, that element of the result is undef.
; The shuffle is eliminated in this transform, but we can replace a constant element with undef.

define <4 x i32> @mul(<4 x i32> %v0) {
; CHECK-LABEL: @mul(
; CHECK-NEXT:    [[T3:%.*]] = mul <4 x i32> [[V0:%.*]], <i32 undef, i32 6, i32 3, i32 8>
; CHECK-NEXT:    ret <4 x i32> [[T3]]
;
  %t1 = mul <4 x i32> %v0, <i32 1, i32 2, i32 3, i32 4>
  %t2 = mul <4 x i32> %v0, <i32 5, i32 6, i32 7, i32 8>
  %t3 = shufflevector <4 x i32> %t1, <4 x i32> %t2, <4 x i32> <i32 undef, i32 5, i32 2, i32 7>
  ret <4 x i32> %t3
}

; Preserve flags when possible.

define <4 x i32> @shl(<4 x i32> %v0) {
; CHECK-LABEL: @shl(
; CHECK-NEXT:    [[T3:%.*]] = shl nuw <4 x i32> [[V0:%.*]], <i32 undef, i32 6, i32 3, i32 undef>
; CHECK-NEXT:    ret <4 x i32> [[T3]]
;
  %t1 = shl nuw <4 x i32> %v0, <i32 1, i32 2, i32 3, i32 4>
  %t2 = shl nuw <4 x i32> %v0, <i32 5, i32 6, i32 7, i32 8>
  %t3 = shufflevector <4 x i32> %t1, <4 x i32> %t2, <4 x i32> <i32 undef, i32 5, i32 2, i32 undef>
  ret <4 x i32> %t3
}

; Can't propagate the flag here.

define <4 x i32> @lshr(<4 x i32> %v0) {
; CHECK-LABEL: @lshr(
; CHECK-NEXT:    [[T3:%.*]] = lshr <4 x i32> <i32 5, i32 6, i32 3, i32 8>, [[V0:%.*]]
; CHECK-NEXT:    ret <4 x i32> [[T3]]
;
  %t1 = lshr exact <4 x i32> <i32 1, i32 2, i32 3, i32 4>, %v0
  %t2 = lshr <4 x i32> <i32 5, i32 6, i32 7, i32 8>, %v0
  %t3 = shufflevector <4 x i32> %t1, <4 x i32> %t2, <4 x i32> <i32 4, i32 5, i32 2, i32 7>
  ret <4 x i32> %t3
}

; Try weird types.

define <3 x i32> @ashr(<3 x i32> %v0) {
; CHECK-LABEL: @ashr(
; CHECK-NEXT:    [[T3:%.*]] = ashr <3 x i32> [[V0:%.*]], <i32 4, i32 2, i32 3>
; CHECK-NEXT:    ret <3 x i32> [[T3]]
;
  %t1 = ashr <3 x i32> %v0, <i32 1, i32 2, i32 3>
  %t2 = ashr <3 x i32> %v0, <i32 4, i32 5, i32 6>
  %t3 = shufflevector <3 x i32> %t1, <3 x i32> %t2, <3 x i32> <i32 3, i32 1, i32 2>
  ret <3 x i32> %t3
}

define <3 x i42> @and(<3 x i42> %v0) {
; CHECK-LABEL: @and(
; CHECK-NEXT:    [[T3:%.*]] = and <3 x i42> [[V0:%.*]], <i42 1, i42 5, i42 undef>
; CHECK-NEXT:    ret <3 x i42> [[T3]]
;
  %t1 = and <3 x i42> %v0, <i42 1, i42 2, i42 3>
  %t2 = and <3 x i42> %v0, <i42 4, i42 5, i42 6>
  %t3 = shufflevector <3 x i42> %t1, <3 x i42> %t2, <3 x i32> <i32 0, i32 4, i32 undef>
  ret <3 x i42> %t3
}

; It doesn't matter if the intermediate ops have extra uses.

declare void @use_v4i32(<4 x i32>)

define <4 x i32> @or(<4 x i32> %v0) {
; CHECK-LABEL: @or(
; CHECK-NEXT:    [[T1:%.*]] = or <4 x i32> [[V0:%.*]], <i32 1, i32 2, i32 3, i32 4>
; CHECK-NEXT:    [[T3:%.*]] = or <4 x i32> [[V0]], <i32 5, i32 6, i32 3, i32 4>
; CHECK-NEXT:    call void @use_v4i32(<4 x i32> [[T1]])
; CHECK-NEXT:    ret <4 x i32> [[T3]]
;
  %t1 = or <4 x i32> %v0, <i32 1, i32 2, i32 3, i32 4>
  %t2 = or <4 x i32> %v0, <i32 5, i32 6, i32 7, i32 8>
  %t3 = shufflevector <4 x i32> %t1, <4 x i32> %t2, <4 x i32> <i32 4, i32 5, i32 2, i32 3>
  call void @use_v4i32(<4 x i32> %t1)
  ret <4 x i32> %t3
}

define <4 x i32> @xor(<4 x i32> %v0) {
; CHECK-LABEL: @xor(
; CHECK-NEXT:    [[T2:%.*]] = xor <4 x i32> [[V0:%.*]], <i32 5, i32 6, i32 7, i32 8>
; CHECK-NEXT:    [[T3:%.*]] = xor <4 x i32> [[V0]], <i32 1, i32 6, i32 3, i32 4>
; CHECK-NEXT:    call void @use_v4i32(<4 x i32> [[T2]])
; CHECK-NEXT:    ret <4 x i32> [[T3]]
;
  %t1 = xor <4 x i32> %v0, <i32 1, i32 2, i32 3, i32 4>
  %t2 = xor <4 x i32> %v0, <i32 5, i32 6, i32 7, i32 8>
  %t3 = shufflevector <4 x i32> %t1, <4 x i32> %t2, <4 x i32> <i32 0, i32 5, i32 2, i32 3>
  call void @use_v4i32(<4 x i32> %t2)
  ret <4 x i32> %t3
}

define <4 x i32> @udiv(<4 x i32> %v0) {
; CHECK-LABEL: @udiv(
; CHECK-NEXT:    [[T1:%.*]] = udiv <4 x i32> <i32 1, i32 2, i32 3, i32 4>, [[V0:%.*]]
; CHECK-NEXT:    [[T2:%.*]] = udiv <4 x i32> <i32 5, i32 6, i32 7, i32 8>, [[V0]]
; CHECK-NEXT:    [[T3:%.*]] = udiv <4 x i32> <i32 1, i32 2, i32 3, i32 8>, [[V0]]
; CHECK-NEXT:    call void @use_v4i32(<4 x i32> [[T1]])
; CHECK-NEXT:    call void @use_v4i32(<4 x i32> [[T2]])
; CHECK-NEXT:    ret <4 x i32> [[T3]]
;
  %t1 = udiv <4 x i32> <i32 1, i32 2, i32 3, i32 4>, %v0
  %t2 = udiv <4 x i32> <i32 5, i32 6, i32 7, i32 8>, %v0
  %t3 = shufflevector <4 x i32> %t1, <4 x i32> %t2, <4 x i32> <i32 0, i32 1, i32 2, i32 7>
  call void @use_v4i32(<4 x i32> %t1)
  call void @use_v4i32(<4 x i32> %t2)
  ret <4 x i32> %t3
}

; Div/rem need special handling if the shuffle has undef elements.

define <4 x i32> @sdiv(<4 x i32> %v0) {
; CHECK-LABEL: @sdiv(
; CHECK-NEXT:    [[T3:%.*]] = sdiv <4 x i32> [[V0:%.*]], <i32 1, i32 2, i32 7, i32 1>
; CHECK-NEXT:    ret <4 x i32> [[T3]]
;
  %t1 = sdiv <4 x i32> %v0, <i32 1, i32 2, i32 3, i32 4>
  %t2 = sdiv <4 x i32> %v0, <i32 5, i32 6, i32 7, i32 8>
  %t3 = shufflevector <4 x i32> %t1, <4 x i32> %t2, <4 x i32> <i32 undef, i32 1, i32 6, i32 undef>
  ret <4 x i32> %t3
}

define <4 x i32> @urem(<4 x i32> %v0) {
; CHECK-LABEL: @urem(
; CHECK-NEXT:    [[T3:%.*]] = urem <4 x i32> <i32 1, i32 2, i32 7, i32 1>, [[V0:%.*]]
; CHECK-NEXT:    ret <4 x i32> [[T3]]
;
  %t1 = urem <4 x i32> <i32 1, i32 2, i32 3, i32 4>, %v0
  %t2 = urem <4 x i32> <i32 5, i32 6, i32 7, i32 8>, %v0
  %t3 = shufflevector <4 x i32> %t1, <4 x i32> %t2, <4 x i32> <i32 0, i32 1, i32 6, i32 undef>
  ret <4 x i32> %t3
}

define <4 x i32> @srem(<4 x i32> %v0) {
; CHECK-LABEL: @srem(
; CHECK-NEXT:    [[T3:%.*]] = srem <4 x i32> <i32 1, i32 2, i32 7, i32 4>, [[V0:%.*]]
; CHECK-NEXT:    ret <4 x i32> [[T3]]
;
  %t1 = srem <4 x i32> <i32 1, i32 2, i32 3, i32 4>, %v0
  %t2 = srem <4 x i32> <i32 5, i32 6, i32 7, i32 8>, %v0
  %t3 = shufflevector <4 x i32> %t1, <4 x i32> %t2, <4 x i32> <i32 0, i32 1, i32 6, i32 3>
  ret <4 x i32> %t3
}

; Try FP ops/types.

define <4 x float> @fadd(<4 x float> %v0) {
; CHECK-LABEL: @fadd(
; CHECK-NEXT:    [[T3:%.*]] = fadd <4 x float> [[V0:%.*]], <float 1.000000e+00, float 2.000000e+00, float 7.000000e+00, float 8.000000e+00>
; CHECK-NEXT:    ret <4 x float> [[T3]]
;
  %t1 = fadd <4 x float> %v0, <float 1.0, float 2.0, float 3.0, float 4.0>
  %t2 = fadd <4 x float> %v0, <float 5.0, float 6.0, float 7.0, float 8.0>
  %t3 = shufflevector <4 x float> %t1, <4 x float> %t2, <4 x i32> <i32 0, i32 1, i32 6, i32 7>
  ret <4 x float> %t3
}

define <4 x double> @fsub(<4 x double> %v0) {
; CHECK-LABEL: @fsub(
; CHECK-NEXT:    [[T3:%.*]] = fsub <4 x double> <double undef, double 2.000000e+00, double 7.000000e+00, double 8.000000e+00>, [[V0:%.*]]
; CHECK-NEXT:    ret <4 x double> [[T3]]
;
  %t1 = fsub <4 x double> <double 1.0, double 2.0, double 3.0, double 4.0>, %v0
  %t2 = fsub <4 x double> <double 5.0, double 6.0, double 7.0, double 8.0>, %v0
  %t3 = shufflevector <4 x double> %t1, <4 x double> %t2, <4 x i32> <i32 undef, i32 1, i32 6, i32 7>
  ret <4 x double> %t3
}

; Intersect any FMF.

define <4 x float> @fmul(<4 x float> %v0) {
; CHECK-LABEL: @fmul(
; CHECK-NEXT:    [[T3:%.*]] = fmul nnan ninf <4 x float> [[V0:%.*]], <float 1.000000e+00, float 6.000000e+00, float 7.000000e+00, float 8.000000e+00>
; CHECK-NEXT:    ret <4 x float> [[T3]]
;
  %t1 = fmul nnan ninf <4 x float> %v0, <float 1.0, float 2.0, float 3.0, float 4.0>
  %t2 = fmul nnan ninf <4 x float> %v0, <float 5.0, float 6.0, float 7.0, float 8.0>
  %t3 = shufflevector <4 x float> %t1, <4 x float> %t2, <4 x i32> <i32 0, i32 5, i32 6, i32 7>
  ret <4 x float> %t3
}

define <4 x double> @fdiv(<4 x double> %v0) {
; CHECK-LABEL: @fdiv(
; CHECK-NEXT:    [[T3:%.*]] = fdiv nnan arcp <4 x double> <double undef, double 2.000000e+00, double 7.000000e+00, double 8.000000e+00>, [[V0:%.*]]
; CHECK-NEXT:    ret <4 x double> [[T3]]
;
  %t1 = fdiv fast <4 x double> <double 1.0, double 2.0, double 3.0, double 4.0>, %v0
  %t2 = fdiv nnan arcp <4 x double> <double 5.0, double 6.0, double 7.0, double 8.0>, %v0
  %t3 = shufflevector <4 x double> %t1, <4 x double> %t2, <4 x i32> <i32 undef, i32 1, i32 6, i32 7>
  ret <4 x double> %t3
}

; The variable operand must be either the first operand or second operand in both binops.

define <4 x double> @frem(<4 x double> %v0) {
; CHECK-LABEL: @frem(
; CHECK-NEXT:    [[T1:%.*]] = frem <4 x double> <double 1.000000e+00, double 2.000000e+00, double 3.000000e+00, double 4.000000e+00>, [[V0:%.*]]
; CHECK-NEXT:    [[T2:%.*]] = frem <4 x double> [[V0]], <double 5.000000e+00, double 6.000000e+00, double 7.000000e+00, double 8.000000e+00>
; CHECK-NEXT:    [[T3:%.*]] = shufflevector <4 x double> [[T1]], <4 x double> [[T2]], <4 x i32> <i32 0, i32 1, i32 6, i32 7>
; CHECK-NEXT:    ret <4 x double> [[T3]]
;
  %t1 = frem <4 x double> <double 1.0, double 2.0, double 3.0, double 4.0>, %v0
  %t2 = frem <4 x double> %v0, <double 5.0, double 6.0, double 7.0, double 8.0>
  %t3 = shufflevector <4 x double> %t1, <4 x double> %t2, <4 x i32> <i32 0, i32 1, i32 6, i32 7>
  ret <4 x double> %t3
}

; FIXME:
; Shift-left with constant shift amount can be converted to mul to enable the fold.

define <4 x i32> @mul_shl(<4 x i32> %v0) {
; CHECK-LABEL: @mul_shl(
; CHECK-NEXT:    [[T1:%.*]] = mul nuw <4 x i32> [[V0:%.*]], <i32 undef, i32 undef, i32 3, i32 4>
; CHECK-NEXT:    [[T2:%.*]] = shl nuw <4 x i32> [[V0]], <i32 5, i32 6, i32 7, i32 8>
; CHECK-NEXT:    [[T3:%.*]] = shufflevector <4 x i32> [[T1]], <4 x i32> [[T2]], <4 x i32> <i32 4, i32 5, i32 2, i32 3>
; CHECK-NEXT:    ret <4 x i32> [[T3]]
;
  %t1 = mul nuw <4 x i32> %v0, <i32 1, i32 2, i32 3, i32 4>
  %t2 = shl nuw <4 x i32> %v0, <i32 5, i32 6, i32 7, i32 8>
  %t3 = shufflevector <4 x i32> %t1, <4 x i32> %t2, <4 x i32> <i32 4, i32 5, i32 2, i32 3>
  ret <4 x i32> %t3
}

define <4 x i32> @shl_mul(<4 x i32> %v0) {
; CHECK-LABEL: @shl_mul(
; CHECK-NEXT:    [[T1:%.*]] = shl nsw <4 x i32> [[V0:%.*]], <i32 1, i32 2, i32 3, i32 4>
; CHECK-NEXT:    [[T2:%.*]] = mul nsw <4 x i32> [[V0]], <i32 5, i32 undef, i32 undef, i32 undef>
; CHECK-NEXT:    [[T3:%.*]] = shufflevector <4 x i32> [[T1]], <4 x i32> [[T2]], <4 x i32> <i32 4, i32 undef, i32 2, i32 3>
; CHECK-NEXT:    ret <4 x i32> [[T3]]
;
  %t1 = shl nsw <4 x i32> %v0, <i32 1, i32 2, i32 3, i32 4>
  %t2 = mul nsw <4 x i32> %v0, <i32 5, i32 6, i32 7, i32 8>
  %t3 = shufflevector <4 x i32> %t1, <4 x i32> %t2, <4 x i32> <i32 4, i32 undef, i32 2, i32 3>
  ret <4 x i32> %t3
}

; PR37806 - https://bugs.llvm.org/show_bug.cgi?id=37806
; Demanded elements + simplification can remove the mul alone, but that's not the best case.

define <4 x i32> @mul_is_nop_shl(<4 x i32> %v0) {
; CHECK-LABEL: @mul_is_nop_shl(
; CHECK-NEXT:    [[T2:%.*]] = shl <4 x i32> [[V0:%.*]], <i32 5, i32 6, i32 7, i32 8>
; CHECK-NEXT:    [[T3:%.*]] = shufflevector <4 x i32> [[V0]], <4 x i32> [[T2]], <4 x i32> <i32 0, i32 5, i32 6, i32 7>
; CHECK-NEXT:    ret <4 x i32> [[T3]]
;
  %t1 = mul <4 x i32> %v0, <i32 1, i32 2, i32 3, i32 4>
  %t2 = shl <4 x i32> %v0, <i32 5, i32 6, i32 7, i32 8>
  %t3 = shufflevector <4 x i32> %t1, <4 x i32> %t2, <4 x i32> <i32 0, i32 5, i32 6, i32 7>
  ret <4 x i32> %t3
}

define <4 x i32> @shl_mul_not_constant_shift_amount(<4 x i32> %v0) {
; CHECK-LABEL: @shl_mul_not_constant_shift_amount(
; CHECK-NEXT:    [[T1:%.*]] = shl <4 x i32> <i32 1, i32 2, i32 3, i32 4>, [[V0:%.*]]
; CHECK-NEXT:    [[T2:%.*]] = mul <4 x i32> [[V0]], <i32 5, i32 6, i32 undef, i32 undef>
; CHECK-NEXT:    [[T3:%.*]] = shufflevector <4 x i32> [[T1]], <4 x i32> [[T2]], <4 x i32> <i32 4, i32 5, i32 2, i32 3>
; CHECK-NEXT:    ret <4 x i32> [[T3]]
;
  %t1 = shl <4 x i32> <i32 1, i32 2, i32 3, i32 4>, %v0
  %t2 = mul <4 x i32> %v0, <i32 5, i32 6, i32 7, i32 8>
  %t3 = shufflevector <4 x i32> %t1, <4 x i32> %t2, <4 x i32> <i32 4, i32 5, i32 2, i32 3>
  ret <4 x i32> %t3
}

