#*****************************************************************************
# ltag.S
#-----------------------------------------------------------------------------
#
# Test ltag and stag instructions.
#

#include "riscv_test.h"
#include "test_macros.h"

RVTEST_RV64S
RVTEST_CODE_BEGIN

  #-------------------------------------------------------------
  # Basic tests for LTAG/STAG
  #-------------------------------------------------------------

  TEST_ST_OP( 2, ltag, stag, 0x00, 0,  tdat );
  TEST_ST_OP( 3, ltag, stag, 0x01, 8,  tdat );
  TEST_ST_OP( 4, ltag, stag, 0x02, 16, tdat );
  TEST_ST_OP( 5, ltag, stag, 0x03, 24, tdat );

  TEST_LD_OP( 6, ltag, 0x00, 0,  tdat );
  TEST_LD_OP( 7, ltag, 0x01, 8,  tdat );
  TEST_LD_OP( 8, ltag, 0x02, 16, tdat );
  TEST_LD_OP( 9, ltag, 0x03, 24, tdat );

  # Test with negative offset
  TEST_ST_OP( 10, ltag, stag, 0x03, -24, tdat4 );
  TEST_ST_OP( 11, ltag, stag, 0x02, -16, tdat4 );
  TEST_ST_OP( 12, ltag, stag, 0x01, -8,  tdat4 );
  TEST_ST_OP( 13, ltag, stag, 0x00, 0,   tdat4 );

  TEST_LD_OP( 14, ltag, 0x03, -24, tdat4 );
  TEST_LD_OP( 15, ltag, 0x02, -16, tdat4 );
  TEST_LD_OP( 16, ltag, 0x01, -8,  tdat4 );
  TEST_LD_OP( 17, ltag, 0x00, 0,   tdat4 );

  #-------------------------------------------------------------
  # Bypassing tests
  #-------------------------------------------------------------

  TEST_LD_DEST_BYPASS( 18, 0, ltag, 0x01, 8, tdat2 );
  TEST_LD_DEST_BYPASS( 19, 1, ltag, 0x00, 8, tdat3 );
  TEST_LD_DEST_BYPASS( 20, 2, ltag, 0x02, 8, tdat1 );

  TEST_LD_SRC1_BYPASS( 21, 0, ltag, 0x01, 8, tdat2 );
  TEST_LD_SRC1_BYPASS( 22, 1, ltag, 0x00, 8, tdat3 );
  TEST_LD_SRC1_BYPASS( 23, 2, ltag, 0x02, 8, tdat1 );

  TEST_ST_SRC12_BYPASS( 24, 0, 0, ltag, stag, 0x00, 0,  tdat );
  TEST_ST_SRC12_BYPASS( 25, 0, 1, ltag, stag, 0x01, 8,  tdat );
  TEST_ST_SRC12_BYPASS( 26, 0, 2, ltag, stag, 0x02, 16, tdat );
  TEST_ST_SRC12_BYPASS( 27, 1, 0, ltag, stag, 0x03, 24, tdat );
  TEST_ST_SRC12_BYPASS( 28, 1, 1, ltag, stag, 0x02, 0, tdat );
  TEST_ST_SRC12_BYPASS( 29, 2, 0, ltag, stag, 0x01, 8, tdat );

  TEST_ST_SRC21_BYPASS( 30, 0, 0, ltag, stag, 0x00, 0,  tdat );
  TEST_ST_SRC21_BYPASS( 31, 0, 1, ltag, stag, 0x01, 8,  tdat );
  TEST_ST_SRC21_BYPASS( 32, 0, 2, ltag, stag, 0x02, 16, tdat );
  TEST_ST_SRC21_BYPASS( 33, 1, 0, ltag, stag, 0x03, 24, tdat );
  TEST_ST_SRC21_BYPASS( 34, 1, 1, ltag, stag, 0x02, 0, tdat );
  TEST_ST_SRC21_BYPASS( 35, 2, 0, ltag, stag, 0x01, 8, tdat );

  #-------------------------------------------------------------
  # Test write-after-write hazard
  #-------------------------------------------------------------

  TEST_CASE( 36, x2, 2, \
    la    x3, tdat; \
    ltag  x2, 0(x3); \
    li    x2, 2; \
  )

  TEST_CASE( 37, x2, 2, \
    la    x3, tdat; \
    ltag  x2, 0(x3); \
    nop; \
    li    x2, 2; \
  )

  #-------------------------------------------------------------
  # Test for L2 Cache
  # L1D 128 set 4-Way 64 Byte Cache Block
  # addr and addr+2^15 (32768) should be located in the same set
  #-------------------------------------------------------------
  TEST_ST_OP( 38, ltag, stag, 0x00, 0,  tdat );
  TEST_ST_OP( 39, ltag, stag, 0x01, 8,  tdat );
  TEST_ST_OP( 40, ltag, stag, 0x02, 16, tdat );
  TEST_ST_OP( 41, ltag, stag, 0x03, 24, tdat );

  TEST_ST_OP( 42, ltag, stag, 0x03, 0,  tdat_w1 );
  TEST_ST_OP( 43, ltag, stag, 0x02, 8,  tdat_w1 );
  TEST_ST_OP( 44, ltag, stag, 0x01, 16, tdat_w1 );
  TEST_ST_OP( 45, ltag, stag, 0x00, 24, tdat_w1 );

  TEST_ST_OP( 46, ltag, stag, 0x01, 0,  tdat_w2 );
  TEST_ST_OP( 47, ltag, stag, 0x01, 8,  tdat_w2 );
  TEST_ST_OP( 48, ltag, stag, 0x01, 16, tdat_w2 );
  TEST_ST_OP( 49, ltag, stag, 0x01, 24, tdat_w2 );

  TEST_ST_OP( 50, ltag, stag, 0x02, 0,  tdat_w3 );
  TEST_ST_OP( 51, ltag, stag, 0x02, 8,  tdat_w3 );
  TEST_ST_OP( 52, ltag, stag, 0x03, 16, tdat_w3 );
  TEST_ST_OP( 53, ltag, stag, 0x03, 24, tdat_w3 );

  TEST_ST_OP( 54, ltag, stag, 0x01, 0,  tdat_w4 );
  TEST_ST_OP( 55, ltag, stag, 0x03, 8,  tdat_w4 );
  TEST_ST_OP( 56, ltag, stag, 0x00, 16, tdat_w4 );
  TEST_ST_OP( 57, ltag, stag, 0x02, 24, tdat_w4 );

  TEST_LD_OP( 58, ltag, 0x00, 0,  tdat );
  TEST_LD_OP( 59, ltag, 0x01, 8,  tdat );
  TEST_LD_OP( 60, ltag, 0x02, 16, tdat );
  TEST_LD_OP( 61, ltag, 0x03, 24, tdat );

  TEST_LD_OP( 62, ltag, 0x03, 0,  tdat_w1 );
  TEST_LD_OP( 63, ltag, 0x02, 8,  tdat_w1 );
  TEST_LD_OP( 64, ltag, 0x01, 16, tdat_w1 );
  TEST_LD_OP( 65, ltag, 0x00, 24, tdat_w1 );

  TEST_LD_OP( 66, ltag, 0x01, 0,  tdat_w2 );
  TEST_LD_OP( 67, ltag, 0x01, 8,  tdat_w2 );
  TEST_LD_OP( 68, ltag, 0x01, 16, tdat_w2 );
  TEST_LD_OP( 69, ltag, 0x01, 24, tdat_w2 );

  TEST_LD_OP( 70, ltag, 0x02, 0,  tdat_w3 );
  TEST_LD_OP( 71, ltag, 0x02, 8,  tdat_w3 );
  TEST_LD_OP( 72, ltag, 0x03, 16, tdat_w3 );
  TEST_LD_OP( 73, ltag, 0x03, 24, tdat_w3 );

  TEST_LD_OP( 74, ltag, 0x01, 0,  tdat_w4 );
  TEST_LD_OP( 75, ltag, 0x03, 8,  tdat_w4 );
  TEST_LD_OP( 76, ltag, 0x00, 16, tdat_w4 );
  TEST_LD_OP( 77, ltag, 0x02, 24, tdat_w4 );

  #-------------------------------------------------------------
  # Make sure data are reserved
  #-------------------------------------------------------------

  TEST_LD_OP( 78, ld, 0x00ff00ff00ff00ff, 0,  tdat );
  TEST_LD_OP( 79, ld, 0xff00ff00ff00ff00, 8,  tdat );
  TEST_LD_OP( 80, ld, 0x0ff00ff00ff00ff0, 16, tdat );
  TEST_LD_OP( 81, ld, 0xf00ff00ff00ff00f, 24, tdat );

  TEST_LD_OP( 82, ld, 0x1111222233334444, 0,  tdat_w1 );
  TEST_LD_OP( 83, ld, 0x5555666677778888, 8,  tdat_w1 );
  TEST_LD_OP( 84, ld, 0x9999aaaabbbbcccc, 16, tdat_w1 );
  TEST_LD_OP( 85, ld, 0xddddeeeeffff0000, 24, tdat_w1 );

  TEST_LD_OP( 86, ld, 0x1234123412341234, 0,  tdat_w2 );
  TEST_LD_OP( 87, ld, 0x5678567856785678, 8,  tdat_w2 );
  TEST_LD_OP( 88, ld, 0x9abc9abc9abc9abc, 16, tdat_w2 );
  TEST_LD_OP( 89, ld, 0xdef0def0def0def0, 24, tdat_w2 );

  TEST_LD_OP( 90, ld, 0x5c5c5c5c5c5c5c5c, 0,  tdat_w3 );
  TEST_LD_OP( 91, ld, 0xc5c5c5c5c5c5c5c5, 8,  tdat_w3 );
  TEST_LD_OP( 92, ld, 0xcccccccc55555555, 16, tdat_w3 );
  TEST_LD_OP( 93, ld, 0x55555555cccccccc, 24, tdat_w3 );

  TEST_LD_OP( 94, ld, 0x0123456789abcdef, 0,  tdat_w4 );
  TEST_LD_OP( 95, ld, 0xfedcba9876543210, 8,  tdat_w4 );
  TEST_LD_OP( 96, ld, 0xfedcba9801234567, 16, tdat_w4 );
  TEST_LD_OP( 97, ld, 0x7654321089abcdef, 24, tdat_w4 );
  TEST_PASSFAIL

RVTEST_CODE_END

  .data
RVTEST_DATA_BEGIN

  TEST_DATA

tdat:
tdat1:       .dword 0x00ff00ff00ff00ff
tdat2:       .dword 0xff00ff00ff00ff00
tdat3:       .dword 0x0ff00ff00ff00ff0
tdat4:       .dword 0xf00ff00ff00ff00f
.skip 32736
tdat_w1:
tdat_w1_d1:  .dword 0x1111222233334444
tdat_w1_d2:  .dword 0x5555666677778888
tdat_w1_d3:  .dword 0x9999aaaabbbbcccc
tdat_w1_d4:  .dword 0xddddeeeeffff0000
.skip 32736
tdat_w2:
tdat_w2_d1:  .dword 0x1234123412341234
tdat_w2_d2:  .dword 0x5678567856785678
tdat_w2_d3:  .dword 0x9abc9abc9abc9abc
tdat_w2_d4:  .dword 0xdef0def0def0def0
.skip 32736
tdat_w3:
tdat_w3_d1:  .dword 0x5c5c5c5c5c5c5c5c
tdat_w3_d2:  .dword 0xc5c5c5c5c5c5c5c5
tdat_w3_d3:  .dword 0xcccccccc55555555
tdat_w3_d4:  .dword 0x55555555cccccccc
.skip 32736
tdat_w4:
tdat_w4_d1:  .dword 0x0123456789abcdef
tdat_w4_d2:  .dword 0xfedcba9876543210
tdat_w4_d3:  .dword 0xfedcba9801234567
tdat_w4_d4:  .dword 0x7654321089abcdef
        

RVTEST_DATA_END
