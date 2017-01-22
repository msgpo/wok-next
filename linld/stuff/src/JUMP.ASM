;***************************************************************
;****** This file is distributed under GPL
;***************************************************************
                ideal
                %crefref
                %noincl
                %nomacs
                p386

        group   DGROUP  _TEXT,_BSS
        assume  cs:DGROUP,ds:DGROUP

        segment _BSS byte public use16 'BSS'

        global  _pm_high:byte
        global  _pm:dword

        ends    _BSS


        segment _TEXT byte public use16 'CODE'

;***************************************************************
;void set_sregs_jump_seg_ofs(u32 csip, u32 sssp);
;****** Never returns
;***************************************************************
        global  _set_sregs_jump_seg_ofs:near
        proc    _set_sregs_jump_seg_ofs near

		extrn	dos_shutdown:near

		pop	ax			;caller return address
		test	[byte _pm_high],-1	; load high ? clear CF
		jne	isbzimage
		; finish loading
		extrn   @last_ditch$qv:near
		push	cs
		call	@last_ditch$qv
		mov	bx,[word _pm+2+2]	; get pm->fallback high word
		; self move
		cld
		push	9900h			; 4096 bytes for cmdline
	;push	9820h			; 512 bytes for cmdline
		pop	es			; min 2048 bytes for stack
		xor	si,si			;  A000 -9000 -0800(>movedend)
		xor	di,di			; set ZF
		mov	cx,offset movedend
        global  _bss_end:byte
	;mov	cx,offset _bss_end
		rep
		  movsb
		push	es
		call	near doretf		; mov cs,es
		stc
isbzimage:
		pop	cx			; ip
		pop	dx			; cs
		pop	ax			; sp
		pop	ss			; ss
		xchg	sp,ax
		push	dx cx
		jnc	nomove
		push	cs
		pop	ds
		push	bx
		call	near dos_shutdown
		;in	al,70h
		;or	al,80h			; disable NMI
		;out	70h,al
		pop	bx
		; move zImage pm
		mov	ax,8
		cwd
		cmp	bx,ax
		ja	bufhigh
		sub	ax,bx
		inc	ax
bufhigh:
		push	ax
		push	dx			; size=up to 512k
		push	bx			; src ofs= pm.fallback
		push	dx
		push	dx			; srcseg=0
		push	1			; dst
		push	dx			;    ofs=64k
		extrn   _memcpy32:near
		call	_memcpy32
		add	sp,14

		ifndef  noelks
		push	ss
		pop	ds
		ifndef	NO386
		cmp	[dword 1E6h],'SKLE'
		else
		cmp	[word 1E6h],'LE'
		jne	notelks
		cmp	[word 1E8h],'SK'
		endif
		jne	notelks
		push	100h
		pop	es
		xor	si,si
		xor	di,di
		mov	ch,05h
		rep
		  movsw
		push	es
		pop	ss
		push	120h
		push	0
notelks:
		endif

nomove:
		push	ss
		pop	ds
		push	ss
		pop	es
		push	ss
		pop	fs
		push	ss
		pop	gs
		assume	nothing
		assume	cs:DGROUP

doretf:
                retf

movedend:
        endp    _set_sregs_jump_seg_ofs

        ends    _TEXT

        end

;###### END OF FILE ############################################