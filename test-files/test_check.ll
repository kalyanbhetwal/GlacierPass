; ModuleID = 'test_prologue_boundary.c'
source_filename = "test_prologue_boundary.c"
target datalayout = "e-m:e-p:16:16-i32:16-i64:16-f32:16-f64:16-a:8-n8:16-S16"
target triple = "msp430"

@.str = private unnamed_addr constant [8 x i8] c"discard\00", section "llvm.metadata"
@.str.1 = private unnamed_addr constant [25 x i8] c"test_prologue_boundary.c\00", section "llvm.metadata"
@.str.2 = private unnamed_addr constant [10 x i8] c"immediate\00", section "llvm.metadata"
@llvm.global.annotations = appending global [9 x { ptr, ptr, ptr, i32, ptr }] [{ ptr, ptr, ptr, i32, ptr } { ptr @discard_no_locals, ptr @.str, ptr @.str.1, i32 71, ptr null }, { ptr, ptr, ptr, i32, ptr } { ptr @discard_with_locals, ptr @.str, ptr @.str.1, i32 80, ptr null }, { ptr, ptr, ptr, i32, ptr } { ptr @discard_with_array, ptr @.str, ptr @.str.1, i32 92, ptr null }, { ptr, ptr, ptr, i32, ptr } { ptr @immediate_no_locals, ptr @.str.2, ptr @.str.1, i32 109, ptr null }, { ptr, ptr, ptr, i32, ptr } { ptr @immediate_with_locals, ptr @.str.2, ptr @.str.1, i32 118, ptr null }, { ptr, ptr, ptr, i32, ptr } { ptr @immediate_with_array, ptr @.str.2, ptr @.str.1, i32 129, ptr null }, { ptr, ptr, ptr, i32, ptr } { ptr @immediate_multiple_returns, ptr @.str.2, ptr @.str.1, i32 143, ptr null }, { ptr, ptr, ptr, i32, ptr } { ptr @discard_calls_immediate, ptr @.str, ptr @.str.1, i32 170, ptr null }, { ptr, ptr, ptr, i32, ptr } { ptr @immediate_calls_normal, ptr @.str.2, ptr @.str.1, i32 179, ptr null }], section "llvm.metadata"

; Function Attrs: noinline nounwind optnone
define dso_local i16 @normal_no_locals(i16 noundef %a, i16 noundef %b) #0 {
entry:
  %a.addr = alloca i16, align 2
  %b.addr = alloca i16, align 2
  store i16 %a, ptr %a.addr, align 2
  store i16 %b, ptr %b.addr, align 2
  %0 = load i16, ptr %a.addr, align 2
  %1 = load i16, ptr %b.addr, align 2
  %add = add nsw i16 %0, %1
  ret i16 %add
}

; Function Attrs: noinline nounwind optnone
define dso_local i16 @normal_with_small_locals(i16 noundef %a, i16 noundef %b) #0 {
entry:
  %a.addr = alloca i16, align 2
  %b.addr = alloca i16, align 2
  %x = alloca i16, align 2
  %y = alloca i16, align 2
  store i16 %a, ptr %a.addr, align 2
  store i16 %b, ptr %b.addr, align 2
  %0 = load i16, ptr %a.addr, align 2
  %mul = mul nsw i16 %0, 2
  store i16 %mul, ptr %x, align 2
  %1 = load i16, ptr %b.addr, align 2
  %mul1 = mul nsw i16 %1, 3
  store i16 %mul1, ptr %y, align 2
  %2 = load i16, ptr %x, align 2
  %3 = load i16, ptr %y, align 2
  %add = add nsw i16 %2, %3
  ret i16 %add
}

; Function Attrs: noinline nounwind optnone
define dso_local i16 @normal_with_large_locals(i16 noundef %a, i16 noundef %b) #0 {
entry:
  %a.addr = alloca i16, align 2
  %b.addr = alloca i16, align 2
  %arr = alloca [10 x i16], align 2
  %i = alloca i16, align 2
  store i16 %a, ptr %a.addr, align 2
  store i16 %b, ptr %b.addr, align 2
  store i16 0, ptr %i, align 2
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %0 = load i16, ptr %i, align 2
  %cmp = icmp slt i16 %0, 10
  br i1 %cmp, label %for.body, label %for.end

for.body:                                         ; preds = %for.cond
  %1 = load i16, ptr %a.addr, align 2
  %2 = load i16, ptr %b.addr, align 2
  %add = add nsw i16 %1, %2
  %3 = load i16, ptr %i, align 2
  %add1 = add nsw i16 %add, %3
  %4 = load i16, ptr %i, align 2
  %arrayidx = getelementptr inbounds [10 x i16], ptr %arr, i16 0, i16 %4
  store i16 %add1, ptr %arrayidx, align 2
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %5 = load i16, ptr %i, align 2
  %inc = add nsw i16 %5, 1
  store i16 %inc, ptr %i, align 2
  br label %for.cond, !llvm.loop !2

for.end:                                          ; preds = %for.cond
  %arrayidx2 = getelementptr inbounds [10 x i16], ptr %arr, i16 0, i16 5
  %6 = load i16, ptr %arrayidx2, align 2
  ret i16 %6
}

; Function Attrs: noinline nounwind optnone
define dso_local i16 @normal_with_call(i16 noundef %a, i16 noundef %b) #0 {
entry:
  %a.addr = alloca i16, align 2
  %b.addr = alloca i16, align 2
  store i16 %a, ptr %a.addr, align 2
  store i16 %b, ptr %b.addr, align 2
  %0 = load i16, ptr %a.addr, align 2
  %1 = load i16, ptr %b.addr, align 2
  %call = call i16 @normal_no_locals(i16 noundef %0, i16 noundef %1)
  %add = add nsw i16 %call, 10
  ret i16 %add
}

; Function Attrs: noinline nounwind optnone
define dso_local i16 @discard_no_locals(i16 noundef %a, i16 noundef %b) #0 {
entry:
  %a.addr = alloca i16, align 2
  %b.addr = alloca i16, align 2
  store i16 %a, ptr %a.addr, align 2
  store i16 %b, ptr %b.addr, align 2
  %0 = load i16, ptr %a.addr, align 2
  %1 = load i16, ptr %b.addr, align 2
  %add = add nsw i16 %0, %1
  ret i16 %add
}

; Function Attrs: noinline nounwind optnone
define dso_local i16 @discard_with_locals(i16 noundef %a, i16 noundef %b) #0 {
entry:
  %a.addr = alloca i16, align 2
  %b.addr = alloca i16, align 2
  %x = alloca i16, align 2
  %y = alloca i16, align 2
  %z = alloca i16, align 2
  store i16 %a, ptr %a.addr, align 2
  store i16 %b, ptr %b.addr, align 2
  %0 = load i16, ptr %a.addr, align 2
  %mul = mul nsw i16 %0, 2
  store i16 %mul, ptr %x, align 2
  %1 = load i16, ptr %b.addr, align 2
  %mul1 = mul nsw i16 %1, 3
  store i16 %mul1, ptr %y, align 2
  %2 = load i16, ptr %x, align 2
  %3 = load i16, ptr %y, align 2
  %add = add nsw i16 %2, %3
  store i16 %add, ptr %z, align 2
  %4 = load i16, ptr %z, align 2
  ret i16 %4
}

; Function Attrs: noinline nounwind optnone
define dso_local i16 @discard_with_array(i16 noundef %a) #0 {
entry:
  %a.addr = alloca i16, align 2
  %arr = alloca [5 x i16], align 2
  %i = alloca i16, align 2
  store i16 %a, ptr %a.addr, align 2
  store i16 0, ptr %i, align 2
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %0 = load i16, ptr %i, align 2
  %cmp = icmp slt i16 %0, 5
  br i1 %cmp, label %for.body, label %for.end

for.body:                                         ; preds = %for.cond
  %1 = load i16, ptr %a.addr, align 2
  %2 = load i16, ptr %i, align 2
  %add = add nsw i16 %1, %2
  %3 = load i16, ptr %i, align 2
  %arrayidx = getelementptr inbounds [5 x i16], ptr %arr, i16 0, i16 %3
  store i16 %add, ptr %arrayidx, align 2
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %4 = load i16, ptr %i, align 2
  %inc = add nsw i16 %4, 1
  store i16 %inc, ptr %i, align 2
  br label %for.cond, !llvm.loop !4

for.end:                                          ; preds = %for.cond
  %arrayidx1 = getelementptr inbounds [5 x i16], ptr %arr, i16 0, i16 2
  %5 = load i16, ptr %arrayidx1, align 2
  ret i16 %5
}

; Function Attrs: noinline nounwind optnone
define dso_local i16 @immediate_no_locals(i16 noundef %a, i16 noundef %b) #0 {
entry:
  %a.addr = alloca i16, align 2
  %b.addr = alloca i16, align 2
  store i16 %a, ptr %a.addr, align 2
  store i16 %b, ptr %b.addr, align 2
  %0 = load i16, ptr %a.addr, align 2
  %1 = load i16, ptr %b.addr, align 2
  %sub = sub nsw i16 %0, %1
  ret i16 %sub
}

; Function Attrs: noinline nounwind optnone
define dso_local i16 @immediate_with_locals(i16 noundef %a, i16 noundef %b) #0 {
entry:
  %a.addr = alloca i16, align 2
  %b.addr = alloca i16, align 2
  %temp1 = alloca i16, align 2
  %temp2 = alloca i16, align 2
  store i16 %a, ptr %a.addr, align 2
  store i16 %b, ptr %b.addr, align 2
  %0 = load i16, ptr %a.addr, align 2
  %shl = shl i16 %0, 1
  store i16 %shl, ptr %temp1, align 2
  %1 = load i16, ptr %b.addr, align 2
  %shr = ashr i16 %1, 1
  store i16 %shr, ptr %temp2, align 2
  %2 = load i16, ptr %temp1, align 2
  %3 = load i16, ptr %temp2, align 2
  %add = add nsw i16 %2, %3
  ret i16 %add
}

; Function Attrs: noinline nounwind optnone
define dso_local i16 @immediate_with_array(i16 noundef %x) #0 {
entry:
  %x.addr = alloca i16, align 2
  %data = alloca [8 x i16], align 2
  %i = alloca i16, align 2
  store i16 %x, ptr %x.addr, align 2
  store i16 0, ptr %i, align 2
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %0 = load i16, ptr %i, align 2
  %cmp = icmp slt i16 %0, 8
  br i1 %cmp, label %for.body, label %for.end

for.body:                                         ; preds = %for.cond
  %1 = load i16, ptr %x.addr, align 2
  %2 = load i16, ptr %i, align 2
  %mul = mul nsw i16 %1, %2
  %3 = load i16, ptr %i, align 2
  %arrayidx = getelementptr inbounds [8 x i16], ptr %data, i16 0, i16 %3
  store i16 %mul, ptr %arrayidx, align 2
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %4 = load i16, ptr %i, align 2
  %inc = add nsw i16 %4, 1
  store i16 %inc, ptr %i, align 2
  br label %for.cond, !llvm.loop !5

for.end:                                          ; preds = %for.cond
  %arrayidx1 = getelementptr inbounds [8 x i16], ptr %data, i16 0, i16 7
  %5 = load i16, ptr %arrayidx1, align 2
  ret i16 %5
}

; Function Attrs: noinline nounwind optnone
define dso_local i16 @immediate_multiple_returns(i16 noundef %a, i16 noundef %b) #0 {
entry:
  %retval = alloca i16, align 2
  %a.addr = alloca i16, align 2
  %b.addr = alloca i16, align 2
  store i16 %a, ptr %a.addr, align 2
  store i16 %b, ptr %b.addr, align 2
  %0 = load i16, ptr %a.addr, align 2
  %1 = load i16, ptr %b.addr, align 2
  %cmp = icmp sgt i16 %0, %1
  br i1 %cmp, label %if.then, label %if.else

if.then:                                          ; preds = %entry
  %2 = load i16, ptr %a.addr, align 2
  store i16 %2, ptr %retval, align 2
  br label %return

if.else:                                          ; preds = %entry
  %3 = load i16, ptr %a.addr, align 2
  %4 = load i16, ptr %b.addr, align 2
  %cmp1 = icmp slt i16 %3, %4
  br i1 %cmp1, label %if.then2, label %if.else3

if.then2:                                         ; preds = %if.else
  %5 = load i16, ptr %b.addr, align 2
  store i16 %5, ptr %retval, align 2
  br label %return

if.else3:                                         ; preds = %if.else
  store i16 0, ptr %retval, align 2
  br label %return

return:                                           ; preds = %if.else3, %if.then2, %if.then
  %6 = load i16, ptr %retval, align 2
  ret i16 %6
}

; Function Attrs: noinline nounwind optnone
define dso_local i16 @normal_calls_discard(i16 noundef %a) #0 {
entry:
  %a.addr = alloca i16, align 2
  store i16 %a, ptr %a.addr, align 2
  %0 = load i16, ptr %a.addr, align 2
  %1 = load i16, ptr %a.addr, align 2
  %add = add nsw i16 %1, 1
  %call = call i16 @discard_no_locals(i16 noundef %0, i16 noundef %add)
  ret i16 %call
}

; Function Attrs: noinline nounwind optnone
define dso_local i16 @discard_calls_immediate(i16 noundef %a) #0 {
entry:
  %a.addr = alloca i16, align 2
  store i16 %a, ptr %a.addr, align 2
  %0 = load i16, ptr %a.addr, align 2
  %1 = load i16, ptr %a.addr, align 2
  %sub = sub nsw i16 %1, 1
  %call = call i16 @immediate_no_locals(i16 noundef %0, i16 noundef %sub)
  ret i16 %call
}

; Function Attrs: noinline nounwind optnone
define dso_local i16 @immediate_calls_normal(i16 noundef %a) #0 {
entry:
  %a.addr = alloca i16, align 2
  store i16 %a, ptr %a.addr, align 2
  %0 = load i16, ptr %a.addr, align 2
  %1 = load i16, ptr %a.addr, align 2
  %add = add nsw i16 %1, 2
  %call = call i16 @normal_no_locals(i16 noundef %0, i16 noundef %add)
  ret i16 %call
}

; Function Attrs: noinline nounwind optnone
define dso_local i16 @main() #0 {
entry:
  %retval = alloca i16, align 2
  %result = alloca i16, align 2
  store i16 0, ptr %retval, align 2
  store i16 0, ptr %result, align 2
  %call = call i16 @normal_no_locals(i16 noundef 1, i16 noundef 2)
  %0 = load i16, ptr %result, align 2
  %add = add nsw i16 %0, %call
  store i16 %add, ptr %result, align 2
  %call1 = call i16 @normal_with_small_locals(i16 noundef 3, i16 noundef 4)
  %1 = load i16, ptr %result, align 2
  %add2 = add nsw i16 %1, %call1
  store i16 %add2, ptr %result, align 2
  %call3 = call i16 @normal_with_large_locals(i16 noundef 5, i16 noundef 6)
  %2 = load i16, ptr %result, align 2
  %add4 = add nsw i16 %2, %call3
  store i16 %add4, ptr %result, align 2
  %call5 = call i16 @normal_with_call(i16 noundef 7, i16 noundef 8)
  %3 = load i16, ptr %result, align 2
  %add6 = add nsw i16 %3, %call5
  store i16 %add6, ptr %result, align 2
  %call7 = call i16 @discard_no_locals(i16 noundef 9, i16 noundef 10)
  %4 = load i16, ptr %result, align 2
  %add8 = add nsw i16 %4, %call7
  store i16 %add8, ptr %result, align 2
  %call9 = call i16 @discard_with_locals(i16 noundef 11, i16 noundef 12)
  %5 = load i16, ptr %result, align 2
  %add10 = add nsw i16 %5, %call9
  store i16 %add10, ptr %result, align 2
  %call11 = call i16 @discard_with_array(i16 noundef 13)
  %6 = load i16, ptr %result, align 2
  %add12 = add nsw i16 %6, %call11
  store i16 %add12, ptr %result, align 2
  %call13 = call i16 @immediate_no_locals(i16 noundef 14, i16 noundef 15)
  %7 = load i16, ptr %result, align 2
  %add14 = add nsw i16 %7, %call13
  store i16 %add14, ptr %result, align 2
  %call15 = call i16 @immediate_with_locals(i16 noundef 16, i16 noundef 17)
  %8 = load i16, ptr %result, align 2
  %add16 = add nsw i16 %8, %call15
  store i16 %add16, ptr %result, align 2
  %call17 = call i16 @immediate_with_array(i16 noundef 18)
  %9 = load i16, ptr %result, align 2
  %add18 = add nsw i16 %9, %call17
  store i16 %add18, ptr %result, align 2
  %call19 = call i16 @immediate_multiple_returns(i16 noundef 19, i16 noundef 20)
  %10 = load i16, ptr %result, align 2
  %add20 = add nsw i16 %10, %call19
  store i16 %add20, ptr %result, align 2
  %call21 = call i16 @normal_calls_discard(i16 noundef 21)
  %11 = load i16, ptr %result, align 2
  %add22 = add nsw i16 %11, %call21
  store i16 %add22, ptr %result, align 2
  %call23 = call i16 @discard_calls_immediate(i16 noundef 22)
  %12 = load i16, ptr %result, align 2
  %add24 = add nsw i16 %12, %call23
  store i16 %add24, ptr %result, align 2
  %call25 = call i16 @immediate_calls_normal(i16 noundef 23)
  %13 = load i16, ptr %result, align 2
  %add26 = add nsw i16 %13, %call25
  store i16 %add26, ptr %result, align 2
  %14 = load i16, ptr %result, align 2
  ret i16 %14
}

attributes #0 = { noinline nounwind optnone "no-trapping-math"="true" "stack-protector-buffer-size"="8" }

!llvm.module.flags = !{!0}
!llvm.ident = !{!1}

!0 = !{i32 1, !"wchar_size", i32 2}
!1 = !{!"clang version 22.0.0git (git@github.com:llvm/llvm-project.git 7e55a4c9937dfc2184636ad7f3c9f7eccfad6186)"}
!2 = distinct !{!2, !3}
!3 = !{!"llvm.loop.mustprogress"}
!4 = distinct !{!4, !3}
!5 = distinct !{!5, !3}
