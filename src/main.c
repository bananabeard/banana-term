#ifndef ULTIMATE64
    #include <serial.h>
#endif

void __fastcall__ mainAssembly(const void*);

void main(void) {
    #ifdef ULTIMATE64
        mainAssembly(0);
    #else
        mainAssembly(ser_static_stddrv);
    #endif
}
