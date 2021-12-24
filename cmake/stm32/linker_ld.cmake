if((NOT CCRAM_SIZE) OR (CCRAM_SIZE STREQUAL "0K"))
    set(CCRAM_DEFINITION "")
    set(CCRAM_SECTION "")
else()
    set(CCRAM_DEFINITION "    CCMRAM (rw) : ORIGIN = ${CCRAM_ORIGIN}, LENGTH = ${CCRAM_SIZE}\n")
    set(CCRAM_SECTION "
_siccmram = LOADADDR(.ccmram);\n\
.ccmram :\n\
{\n\
. = ALIGN(4);\n\
_sccmram = .;\n\
*(.ccmram)\n\
*(.ccmram*)\n\
. = ALIGN(4);\n\
_eccmram = .;\n\
} >CCMRAM AT> FLASH\n\
        ")
endif()

if((NOT RAM_SHARE_SIZE) OR (RAM_SHARE_SIZE STREQUAL "0K"))
    set(RAM_SHARE_DEFINITION "")
    set(RAM_SHARE_SECTION "")
else()
    set(RAM_SHARE_DEFINITION "    RAM_SHARED (rw) : ORIGIN = ${RAM_SHARE_ORIGIN}, LENGTH = ${RAM_SHARE_SIZE}\n")
    set(RAM_SHARE_SECTION "
MAPPING_TABLE (NOLOAD) : { *(MAPPING_TABLE) } >RAM_SHARED\n\
MB_MEM1 (NOLOAD)       : { *(MB_MEM1) } >RAM_SHARED\n\
MB_MEM2 (NOLOAD)       : { _sMB_MEM2 = . ; *(MB_MEM2) ; _eMB_MEM2 = . ; } >RAM_SHARED\n\
    ")
endif()

file(STRINGS "${CMAKE_CURRENT_LIST_DIR}/template_script.ld.in" SCRIPT_TEXT_PLAIN NEWLINE_CONSUME)

string(CONFIGURE ${SCRIPT_TEXT_PLAIN} SCRIPT_TEXT)

file(WRITE "${LINKER_SCRIPT}" "${SCRIPT_TEXT}")


