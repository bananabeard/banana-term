.include "c64.inc"
.include "banana-c128-c64.inc"
.include "banana-c64-plus4.inc"

.if .not .defined(ULTIMATE64)
    SERIAL_BAUD = SER_BAUD_38400 ; ##SERIAL_BAUD
.endif
