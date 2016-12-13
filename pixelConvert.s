.data
.balign 4
y_8: .float 0.2126
.balign 4
y_9: .float 0.7152
.balign 4
y_10: .float 0.0722

.include "syscalls.asmh"
.text
.global setVFPLEN
.global loadPixelToVFP
.global convert
.global loadPixelFromVFP

@.global _start
@_start:
@mov r0, #2
@bl setVFPLEN
@
@mov r0, #0xFF
@mov r1, #0x0
@mov r2, #0x0
@bl loadPixelToVFP
@bl convert

@bl loadPixelFromVFP

@mov r0, #0
@bl setVFPLEN
@bl svcExit

setVFPLEN:
@ params: r0 = len to set
@ sets len to 0 if r0 > 9
cmp r0, #9
movgt r0, #0
mov r0, r0, lsl #16
vmrs r1, fpscr
orr r1, r1, r0
vmsr fpscr, r1
bx lr

loadPixelToVFP:
.irp reg,0,1,2
vmov s\reg, r\reg
vcvt.f32.u32 s\reg, s\reg
.endr
bx lr

loadPixelFromVFP:
vcvt.u32.f32 s0, s0
.irp reg,0,1,2
vmov r\reg, s0
.endr

convert:
@ params: s0 = R value (float)
@         s1 = G value (float)
@         s2 = B value (float)
@ return: s0 = Y value (float)
@
@ To save time, FPSCR must be set outide of this function
vpush {s8-s10}

@ Load luminance conversion factors
push {r8-r10}
.irp val,8,9,10
ldr r\val, =y_\val
vldr s\val, [r\val]
.endr
pop {r8-r10}

@ Multiply using SIMD 
vmul.f32 s8, s0, s8

@ Move values from vector bank to scalar bank
vmov.f32 s0, s8
vmov.f32 s1, s9
vmov.f32 s2, s10

@ Sum luminance value
vadd.f32 s0, s0, s1
vadd.f32 s0, s0, s2

@ Return
vpop {s8-s10}
bx lr
