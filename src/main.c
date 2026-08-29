#include <serial.h>

void __fastcall__ mainAssembly(const void*);

void main(void) {
    mainAssembly(ser_static_stddrv);
}
