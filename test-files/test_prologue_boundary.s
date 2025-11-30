	.file	"test_prologue_boundary.c"
	.text
	.globl	normal_no_locals                ; -- Begin function normal_no_locals
	.p2align	1
	.type	normal_no_locals,@function
normal_no_locals:                       ; @normal_no_locals
; %bb.0:
	push	#0
	push	#48879
	push	#2
	push	r10
	mov	r13, r11
	mov	r12, r10
	add	r11, r10
	mov	r10, r12
	pop	r10
	add	#6, r1
	ret
.Lfunc_end0:
	.size	normal_no_locals, .Lfunc_end0-normal_no_locals
                                        ; -- End function
	.globl	normal_with_small_locals        ; -- Begin function normal_with_small_locals
	.p2align	1
	.type	normal_with_small_locals,@function
normal_with_small_locals:               ; @normal_with_small_locals
; %bb.0:
	push	#0
	push	#48879
	push	#2
	push	r10
	mov	r13, r11
	mov	r12, r10
	mov	r11, r12
	mov	#3, r13
	call	#__mspabi_mpyi
	mov	r12, r11
	add	r10, r10
	add	r10, r11
	mov	r11, r12
	pop	r10
	add	#6, r1
	ret
.Lfunc_end1:
	.size	normal_with_small_locals, .Lfunc_end1-normal_with_small_locals
                                        ; -- End function
	.globl	normal_with_large_locals        ; -- Begin function normal_with_large_locals
	.p2align	1
	.type	normal_with_large_locals,@function
normal_with_large_locals:               ; @normal_with_large_locals
; %bb.0:
	push	#0
	push	#48879
	push	#2
	push	r10
	mov	r13, r11
	mov	r12, r10
	add	r11, r10
	add	#5, r10
	mov	r10, r12
	pop	r10
	add	#6, r1
	ret
.Lfunc_end2:
	.size	normal_with_large_locals, .Lfunc_end2-normal_with_large_locals
                                        ; -- End function
	.globl	normal_with_call                ; -- Begin function normal_with_call
	.p2align	1
	.type	normal_with_call,@function
normal_with_call:                       ; @normal_with_call
; %bb.0:
	push	#0
	push	#48879
	push	#2
	push	r10
	mov	r13, r11
	mov	r12, r10
	add	r11, r10
	add	#10, r10
	mov	r10, r12
	pop	r10
	add	#6, r1
	ret
.Lfunc_end3:
	.size	normal_with_call, .Lfunc_end3-normal_with_call
                                        ; -- End function
	.globl	discard_no_locals               ; -- Begin function discard_no_locals
	.p2align	1
	.type	discard_no_locals,@function
discard_no_locals:                      ; @discard_no_locals
	.cfi_startproc
; %bb.0:
	push	#0
	push	#57005
	push	#0
	add	r13, r12
	add	#6, r1
	ret
.Lfunc_end4:
	.size	discard_no_locals, .Lfunc_end4-discard_no_locals
	.cfi_endproc
                                        ; -- End function
	.globl	discard_with_locals             ; -- Begin function discard_with_locals
	.p2align	1
	.type	discard_with_locals,@function
discard_with_locals:                    ; @discard_with_locals
	.cfi_startproc
; %bb.0:
	push	#0
	push	#57005
	push	#2
	sub	#2, r1
	.cfi_def_cfa_offset 4
	mov	r12, 0(r1)                      ; 2-byte Folded Spill
	mov	r13, r12
	mov	#3, r13
	call	#__mspabi_mpyi
	mov	0(r1), r13                      ; 2-byte Folded Reload
	add	r13, r13
	mov	r13, 0(r1)                      ; 2-byte Folded Spill
	mov	0(r1), r13                      ; 2-byte Folded Reload
	add	r13, r12
	add	#2, r1
	.cfi_def_cfa_offset 2
	add	#6, r1
	ret
.Lfunc_end5:
	.size	discard_with_locals, .Lfunc_end5-discard_with_locals
	.cfi_endproc
                                        ; -- End function
	.globl	discard_with_array              ; -- Begin function discard_with_array
	.p2align	1
	.type	discard_with_array,@function
discard_with_array:                     ; @discard_with_array
	.cfi_startproc
; %bb.0:
	push	#0
	push	#57005
	push	#0
	incd	r12
	add	#6, r1
	ret
.Lfunc_end6:
	.size	discard_with_array, .Lfunc_end6-discard_with_array
	.cfi_endproc
                                        ; -- End function
	.globl	immediate_no_locals             ; -- Begin function immediate_no_locals
	.p2align	1
	.type	immediate_no_locals,@function
immediate_no_locals:                    ; @immediate_no_locals
	.cfi_startproc
; %bb.0:
	push	#0
	push	#51966
	push	#2
	push	r10
	.cfi_def_cfa_offset 4
	.cfi_offset r10, -4
	mov	r13, r11
	mov	r12, r10
	sub	r11, r10
	mov	r10, r12
	pop	r10
	.cfi_def_cfa_offset 2
	.cfi_restore r10
	add	#6, r1
	ret
.Lfunc_end7:
	.size	immediate_no_locals, .Lfunc_end7-immediate_no_locals
	.cfi_endproc
                                        ; -- End function
	.globl	immediate_with_locals           ; -- Begin function immediate_with_locals
	.p2align	1
	.type	immediate_with_locals,@function
immediate_with_locals:                  ; @immediate_with_locals
	.cfi_startproc
; %bb.0:
	push	#0
	push	#51966
	push	#2
	push	r10
	.cfi_def_cfa_offset 4
	.cfi_offset r10, -4
	mov	r13, r11
	mov	r12, r10
	add	r10, r10
	rra	r11
	add	r11, r10
	mov	r10, r12
	pop	r10
	.cfi_def_cfa_offset 2
	.cfi_restore r10
	add	#6, r1
	ret
.Lfunc_end8:
	.size	immediate_with_locals, .Lfunc_end8-immediate_with_locals
	.cfi_endproc
                                        ; -- End function
	.globl	immediate_with_array            ; -- Begin function immediate_with_array
	.p2align	1
	.type	immediate_with_array,@function
immediate_with_array:                   ; @immediate_with_array
	.cfi_startproc
; %bb.0:
	push	#0
	push	#51966
	push	#0
	mov	#7, r13
	call	#__mspabi_mpyi
	add	#6, r1
	ret
.Lfunc_end9:
	.size	immediate_with_array, .Lfunc_end9-immediate_with_array
	.cfi_endproc
                                        ; -- End function
	.globl	immediate_multiple_returns      ; -- Begin function immediate_multiple_returns
	.p2align	1
	.type	immediate_multiple_returns,@function
immediate_multiple_returns:             ; @immediate_multiple_returns
	.cfi_startproc
; %bb.0:
	push	#0
	push	#51966
	push	#4
	push	r9
	.cfi_def_cfa_offset 4
	push	r10
	.cfi_def_cfa_offset 6
	.cfi_offset r9, -4
	.cfi_offset r10, -6
	mov	r13, r11
	mov	r12, r9
	cmp	r11, r9
	mov	r11, r10
	jl	.LBB10_2
; %bb.1:
	clr	r10
.LBB10_2:
	cmp	r9, r11
	jl	.LBB10_4
; %bb.3:
	mov	r10, r9
.LBB10_4:
	mov	r9, r12
	pop	r10
	.cfi_def_cfa_offset 4
	pop	r9
	.cfi_def_cfa_offset 2
	.cfi_restore r9
	.cfi_restore r10
	add	#6, r1
	ret
.Lfunc_end10:
	.size	immediate_multiple_returns, .Lfunc_end10-immediate_multiple_returns
	.cfi_endproc
                                        ; -- End function
	.globl	normal_calls_discard            ; -- Begin function normal_calls_discard
	.p2align	1
	.type	normal_calls_discard,@function
normal_calls_discard:                   ; @normal_calls_discard
; %bb.0:
	push	#0
	push	#48879
	push	#0
	mov	r12, r11
	add	r11, r11
	bis	#1, r11
	mov	r11, r12
	add	#6, r1
	ret
.Lfunc_end11:
	.size	normal_calls_discard, .Lfunc_end11-normal_calls_discard
                                        ; -- End function
	.globl	discard_calls_immediate         ; -- Begin function discard_calls_immediate
	.p2align	1
	.type	discard_calls_immediate,@function
discard_calls_immediate:                ; @discard_calls_immediate
	.cfi_startproc
; %bb.0:
	push	#0
	push	#57005
	push	#0
	mov	#1, r12
	add	#6, r1
	ret
.Lfunc_end12:
	.size	discard_calls_immediate, .Lfunc_end12-discard_calls_immediate
	.cfi_endproc
                                        ; -- End function
	.globl	immediate_calls_normal          ; -- Begin function immediate_calls_normal
	.p2align	1
	.type	immediate_calls_normal,@function
immediate_calls_normal:                 ; @immediate_calls_normal
	.cfi_startproc
; %bb.0:
	push	#0
	push	#51966
	push	#0
	mov	r12, r11
	add	r11, r11
	incd	r11
	mov	r11, r12
	add	#6, r1
	ret
.Lfunc_end13:
	.size	immediate_calls_normal, .Lfunc_end13-immediate_calls_normal
	.cfi_endproc
                                        ; -- End function
	.section	__interrupt_vector_2,"ax",@progbits
	.short	isr_normal
	.text
	.globl	isr_normal                      ; -- Begin function isr_normal
	.p2align	1
	.type	isr_normal,@function
isr_normal:                             ; @isr_normal
; %bb.0:
	push	#48879
	push	#2
	sub	#2, r1
	mov	#42, 0(r1)
	add	#2, r1
	add	#4, r1
	reti
.Lfunc_end14:
	.size	isr_normal, .Lfunc_end14-isr_normal
                                        ; -- End function
	.section	__interrupt_vector_3,"ax",@progbits
	.short	isr_discard
	.text
	.globl	isr_discard                     ; -- Begin function isr_discard
	.p2align	1
	.type	isr_discard,@function
isr_discard:                            ; @isr_discard
; %bb.0:
	push	#57005
	push	#2
	sub	#2, r1
	mov	#100, 0(r1)
	add	#2, r1
	add	#4, r1
	reti
.Lfunc_end15:
	.size	isr_discard, .Lfunc_end15-isr_discard
                                        ; -- End function
	.section	__interrupt_vector_4,"ax",@progbits
	.short	isr_immediate
	.text
	.globl	isr_immediate                   ; -- Begin function isr_immediate
	.p2align	1
	.type	isr_immediate,@function
isr_immediate:                          ; @isr_immediate
; %bb.0:
	push	#51966
	push	#2
	sub	#2, r1
	mov	#200, 0(r1)
	add	#2, r1
	add	#4, r1
	reti
.Lfunc_end16:
	.size	isr_immediate, .Lfunc_end16-isr_immediate
                                        ; -- End function
	.globl	main                            ; -- Begin function main
	.p2align	1
	.type	main,@function
main:                                   ; @main
; %bb.0:
	push	#0
	push	#48879
	push	#0
	mov	#431, r12
	add	#6, r1
	ret
.Lfunc_end17:
	.size	main, .Lfunc_end17-main
                                        ; -- End function
	.ident	"Apple clang version 17.0.0 (clang-1700.4.4.1)"
	.section	".note.GNU-stack","",@progbits
