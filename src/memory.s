.include "banana-term.inc"

.code

; input:
;   y: start index in page
;   ptr1: first destination page start
;   ptr2: second destination page start
;   ptr3: first source page start
;   ptr4: second source page start
; clobbers: a, y, status
; length: 256-y
; range: [ptr1/2/3/4+y, ptr1/2/3/4+$ff]
.proc memcpyDoubleAscending
    @loop:
        lda (ptr3),y
        sta (ptr1),y
        lda (ptr4),y
        sta (ptr2),y
        iny
        bne @loop
        rts
.endproc

; input:
;   a: value
;   y: length, $00 means $100
;   ptr1: address
; clobbers: y, status
; range: [ptr1, ptr1+length-1]
.proc memset
    @loop:
        dey
        sta (ptr1),y
        bne @loop
        rts
.endproc
