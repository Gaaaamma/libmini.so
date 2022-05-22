
%macro gensys 2
	global sys_%2:function
sys_%2:
	push	r10
	mov	r10, rcx
	mov	rax, %1
	syscall
	pop	r10
	ret
%endmacro

; RDI, RSI, RDX, RCX, R8, R9

extern	errno

	section .data

jmpregRBX:	dq	0x0
jmpregRSP:	dq	0x0
jmpregRBP:	dq	0x0
jmpregR12:	dq	0x0
jmpregR13:	dq	0x0
jmpregR14:	dq	0x0
jmpregR15:	dq	0x0
jmpregRET:	dq	0x0
sigMASK:	dq	0x0

	section .text

	gensys   0, read
	gensys   1, write
	gensys   2, open
	gensys   3, close
	gensys   9, mmap
	gensys  10, mprotect
	gensys  11, munmap
	gensys  13, rt_sigaction
	gensys  14, rt_sigprocmask
	gensys  22, pipe
	gensys  32, dup
	gensys  33, dup2
	gensys  34, pause
	gensys  35, nanosleep
	gensys  37, alarm
	gensys  57, fork
	gensys  60, exit
	gensys  79, getcwd
	gensys  80, chdir
	gensys  82, rename
	gensys  83, mkdir
	gensys  84, rmdir
	gensys  85, creat
	gensys  86, link
	gensys  88, unlink
	gensys  89, readlink
	gensys  90, chmod
	gensys  92, chown
	gensys  95, umask
	gensys  96, gettimeofday
	gensys 102, getuid
	gensys 104, getgid
	gensys 105, setuid
	gensys 106, setgid
	gensys 107, geteuid
	gensys 108, getegid
	gensys 127, rt_sigpending

	global open:function
open:
	call	sys_open
	cmp	rax, 0
	jge	open_success	; no error :)
open_error:
	neg	rax
%ifdef NASM
	mov	rdi, [rel errno wrt ..gotpc]
%else
	mov	rdi, [rel errno wrt ..gotpcrel]
%endif
	mov	[rdi], rax	; errno = -rax
	mov	rax, -1
	jmp	open_quit
open_success:
%ifdef NASM
	mov	rdi, [rel errno wrt ..gotpc]
%else
	mov	rdi, [rel errno wrt ..gotpcrel]
%endif
	mov	QWORD [rdi], 0	; errno = 0
open_quit:
	ret

	global sleep:function
sleep:
	sub	rsp, 32		; allocate timespec * 2
	mov	[rsp], rdi		; req.tv_sec
	mov	QWORD [rsp+8], 0	; req.tv_nsec
	mov	rdi, rsp	; rdi = req @ rsp
	lea	rsi, [rsp+16]	; rsi = rem @ rsp+16
	call	sys_nanosleep
	cmp	rax, 0
	jge	sleep_quit	; no error :)
sleep_error:
	neg	rax
	cmp	rax, 4		; rax == EINTR?
	jne	sleep_failed
sleep_interrupted:
	lea	rsi, [rsp+16]
	mov	rax, [rsi]	; return rem.tv_sec
	jmp	sleep_quit
sleep_failed:
	mov	rax, 0		; return 0 on error
sleep_quit:
	add	rsp, 32
	ret
	
	global sys_rt_sigreturn:function
sys_rt_sigreturn:
	mov rax,0xf
	syscall
	ret 

	global setjmp:function
setjmp:
	push rbp
	mov rbp, rsp 	;record the base
	; start to record REG
	mov [rdi], rbx 		; jb->reg[0] = RBX
	; use RCX as temp
	push rcx
	mov rcx, rbp		; rcx = rbp = base frame
	add rcx, 16			; rcx = original RSP address
	mov [rdi+8], rcx 	; jb->reg[1] = RSP
	mov rcx, [rbp]		; rcx = original RBP address
	mov [rdi+16], rcx 	; jb->reg[2] = RBP
	mov [rdi+24], r12 	; jb->reg[3] = R12
	mov [rdi+32], r13 	; jb->reg[4] = R13
	mov [rdi+40], r14 	; jb->reg[5] = R14
	mov [rdi+48], r15 	; jb->reg[6] = R15
	
	mov rcx, rbp		; rcx = rbp = base frame
	add rcx, 8			; rcx = original rtn address mem addr
	mov rax, [rcx]		; rax = true rtn address
	mov [rdi+56], rax	; jb->reg[7] = rtn addr
	pop rcx

	; use rax to store address of mask
	mov rax, rdi		; rax = rdi = &jb
	add rax, 64			; rax = rdi+64 = &mask

	; ready to get mask via sigprocmask
	push rdi
	push rsi
	push rdx
	push rcx

	mov rdi, 0x1	; setting arguments -> how = UNBLOCK
	mov rsi, 0x0	; setting arguments -> nset = 0 = NULL
	mov rdx, rax	; setting arguments -> oldset
	mov rcx, 0x8	; setting arguments -> sizeof(sigsize_t)
	call	sys_rt_sigprocmask
	pop rcx
	pop rdx
	pop rsi
	pop rdi


	mov rax, 0			; setjmp return 0
	leave
	ret

	global longjmp:function
longjmp:
	; reset reg (use rax as tmp)
	mov rax, [rdi]		; rax = *rdi
	mov rbx, rax		; rbx = rax

	mov rax, [rdi+24]	
	mov r12, rax		; r12 = rax
	mov rax, [rdi+32]	
	mov r13, rax		; r13 = rax
	mov rax, [rdi+40]	
	mov r14, rax		; r14 = rax
	mov rax, [rdi+48]	
	mov r15, rax		; r15 = rax

	mov rax, [rdi+16]	
	mov rbp, rax		; rbp = rax

	; magic is happening
	mov rax, [rdi+8]	; rax is rsp original address
	sub rax, 8			; rax -=8 as if it calls a function
	mov rsp, rax		; set rsp = rax 

	mov rax, [rdi+56] 	; setting return address to rax
	mov [rsp], rax		; [rsp] = rax

	mov rax, rsi ; set return value
	ret