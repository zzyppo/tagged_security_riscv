// See LICENSE for license details.

// bridge for NASTI/NASTI-Lite conversion

module nasti_lite_bridge
  #(
    WRITE_TRANSACTION = 2,      // maximal number of parallel write transactions
    WRITE_BUF_DEPTH = 4,        // depth of the lite side buffer for write transactions
    READ_TRANSACTION = 2,       // maximal number of parallel read transactions
    READ_BUF_DEPTH = 2,         // depth of the lite side buffers for read transactions
    ID_WIDTH = 1,               // id width
    ADDR_WIDTH = 8,             // address width
    NASTI_DATA_WIDTH = 64,      // width of data on the nasti side
    LITE_DATA_WIDTH = 32,       // width of data on the nasti-lite side
    USER_WIDTH = 1              // width of user field, must > 0, let synthesizer trim it if not in use
    )
   (
    input clk, rstn,
    nasti_channel.slave  nasti_s,
    nasti_channel.master lite_m
    );

   nasti_lite_writer
     #(
       .BUF_DEPTH        ( WRITE_BUF_DEPTH    ),
       .MAX_TRANSACTION  ( WRITE_TRANSACTION  ),
       .ID_WIDTH         ( ID_WIDTH           ),
       .ADDR_WIDTH       ( ADDR_WIDTH         ),
       .NASTI_DATA_WIDTH ( NASTI_DATA_WIDTH   ),
       .LITE_DATA_WIDTH  ( LITE_DATA_WIDTH    ),
       .USER_WIDTH       ( USER_WIDTH         )
       )
   writer
     (
      .*,
      .nasti_aw_id     ( nasti_s.aw_id     ),
      .nasti_aw_addr   ( nasti_s.aw_addr   ),
      .nasti_aw_len    ( nasti_s.aw_len    ),
      .nasti_aw_size   ( nasti_s.aw_size   ),
      .nasti_aw_burst  ( nasti_s.aw_burst  ),
      .nasti_aw_lock   ( nasti_s.aw_lock   ),
      .nasti_aw_cache  ( nasti_s.aw_cache  ),
      .nasti_aw_prot   ( nasti_s.aw_prot   ),
      .nasti_aw_qos    ( nasti_s.aw_qos    ),
      .nasti_aw_region ( nasti_s.aw_region ),
      .nasti_aw_user   ( nasti_s.aw_user   ),
      .nasti_aw_valid  ( nasti_s.aw_valid  ),
      .nasti_aw_ready  ( nasti_s.aw_ready  ),
      .nasti_w_data    ( nasti_s.w_data    ),
      .nasti_w_strb    ( nasti_s.w_strb    ),
      .nasti_w_last    ( nasti_s.w_last    ),
      .nasti_w_user    ( nasti_s.w_user    ),
      .nasti_w_valid   ( nasti_s.w_valid   ),
      .nasti_w_ready   ( nasti_s.w_ready   ),
      .nasti_b_id      ( nasti_s.b_id      ),
      .nasti_b_resp    ( nasti_s.b_resp    ),
      .nasti_b_user    ( nasti_s.b_user    ),
      .nasti_b_valid   ( nasti_s.b_valid   ),
      .nasti_b_ready   ( nasti_s.b_ready   ),
      .lite_aw_id      ( lite_m.aw_id      ),
      .lite_aw_addr    ( lite_m.aw_addr    ),
      .lite_aw_prot    ( lite_m.aw_prot    ),
      .lite_aw_qos     ( lite_m.aw_qos     ),
      .lite_aw_region  ( lite_m.aw_region  ),
      .lite_aw_aw_user ( lite_m.aw_aw_user ),
      .lite_aw_valid   ( lite_m.aw_valid   ),
      .lite_aw_ready   ( lite_m.aw_ready   ),
      .lite_w_data     ( lite_m.w_data     ),
      .lite_w_strb     ( lite_m.w_strb     ),
      .lite_w_user     ( lite_m.w_user     ),
      .lite_w_valid    ( lite_m.w_valid    ),
      .lite_w_ready    ( lite_m.w_ready    ),
      .lite_b_id       ( lite_m.b_id       ),
      .lite_b_resp     ( lite_m.b_resp     ),
      .lite_b_user     ( lite_m.b_user     ),
      .lite_b_valid    ( lite_m.b_valid    ),
      .lite_b_ready    ( lite_m.b_ready    )
      );

   nasti_lite_reader
     #(
       .BUF_DEPTH        ( READ_BUF_DEPTH     ),
       .MAX_TRANSACTION  ( READ_TRANSACTION   ),
       .ID_WIDTH         ( ID_WIDTH           ),
       .ADDR_WIDTH       ( ADDR_WIDTH         ),
       .NASTI_DATA_WIDTH ( NASTI_DATA_WIDTH   ),
       .LITE_DATA_WIDTH  ( LITE_DATA_WIDTH    ),
       .USER_WIDTH       ( USER_WIDTH         )
       )
   reader
     (
      .*,
      .nasti_ar_id     ( nasti_s.ar_id     ),
      .nasti_ar_addr   ( nasti_s.ar_addr   ),
      .nasti_ar_len    ( nasti_s.ar_len    ),
      .nasti_ar_size   ( nasti_s.ar_size   ),
      .nasti_ar_burst  ( nasti_s.ar_burst  ),
      .nasti_ar_lock   ( nasti_s.ar_lock   ),
      .nasti_ar_cache  ( nasti_s.ar_cache  ),
      .nasti_ar_prot   ( nasti_s.ar_prot   ),
      .nasti_ar_qos    ( nasti_s.ar_qos    ),
      .nasti_ar_region ( nasti_s.ar_region ),
      .nasti_ar_user   ( nasti_s.ar_user   ),
      .nasti_ar_valid  ( nasti_s.ar_valid  ),
      .nasti_ar_ready  ( nasti_s.ar_ready  ),
      .nasti_r_id      ( nasti_s.r_id      ),
      .nasti_r_data    ( nasti_s.r_data    ),
      .nasti_r_resp    ( nasti_s.r_resp    ),
      .nasti_r_last    ( nasti_s.r_last    ),
      .nasti_r_user    ( nasti_s.r_user    ),
      .nasti_r_valid   ( nasti_s.r_valid   ),
      .nasti_r_ready   ( nasti_s.r_ready   ),
      .lite_ar_id      ( lite_m.ar_id      ),
      .lite_ar_addr    ( lite_m.ar_addr    ),
      .lite_ar_prot    ( lite_m.ar_prot    ),
      .lite_ar_qos     ( lite_m.ar_qos     ),
      .lite_ar_region  ( lite_m.ar_region  ),
      .lite_ar_user    ( lite_m.ar_user    ),
      .lite_ar_valid   ( lite_m.ar_valid   ),
      .lite_ar_ready   ( lite_m.ar_ready   ),
      .lite_r_id       ( lite_m.r_id       ),
      .lite_r_data     ( lite_m.r_data     ),
      .lite_r_resp     ( lite_m.r_resp     ),
      .lite_r_user     ( lite_m.r_user     ),
      .lite_r_valid    ( lite_m.r_valid    ),
      .lite_r_ready    ( lite_m.r_ready    )
      );

endmodule // nasti_lite_bridge

module lite_nasti_bridge
  #(
    WRITE_TRANSACTION = 2,      // maximal number of parallel write transactions
    READ_TRANSACTION = 2,       // maximal number of parallel read transactions
    ID_WIDTH = 1,               // id width
    ADDR_WIDTH = 8,             // address width
    NASTI_DATA_WIDTH = 64,      // width of data on the nasti side
    LITE_DATA_WIDTH = 32,       // width of data on the nasti-lite side
    USER_WIDTH = 1              // width of user field, must > 0, let synthesizer trim it if not in use
    )
   (
    input clk, rstn,
    nasti_channel.slave  lite_s,
    nasti_channel.master nasti_m
    );

   lite_nasti_writer
     #(
       .MAX_TRANSACTION  ( WRITE_TRANSACTION  ),
       .ID_WIDTH         ( ID_WIDTH           ),
       .ADDR_WIDTH       ( ADDR_WIDTH         ),
       .NASTI_DATA_WIDTH ( NASTI_DATA_WIDTH   ),
       .LITE_DATA_WIDTH  ( LITE_DATA_WIDTH    ),
       .USER_WIDTH       ( USER_WIDTH         )
       )
   writer
     (
      .*,
      .lite_aw_id      ( lite_s.aw_id      ),
      .lite_aw_addr    ( lite_s.aw_addr    ),
      .lite_aw_prot    ( lite_s.aw_prot    ),
      .lite_aw_qos     ( lite_s.aw_qos     ),
      .lite_aw_region  ( lite_s.aw_region  ),
      .lite_aw_user    ( lite_s.aw_user    ),
      .lite_aw_valid   ( lite_s.aw_valid   ),
      .lite_aw_ready   ( lite_s.aw_ready   ),
      .lite_w_data     ( lite_s.w_data     ),
      .lite_w_strb     ( lite_s.w_strb     ),
      .lite_w_user     ( lite_s.w_user     ),
      .lite_w_valid    ( lite_s.w_valid    ),
      .lite_w_ready    ( lite_s.w_ready    ),
      .lite_b_id       ( lite_s.b_id       ),
      .lite_b_resp     ( lite_s.b_resp     ),
      .lite_b_user     ( lite_s.b_user     ),
      .lite_b_valid    ( lite_s.b_valid    ),
      .lite_b_ready    ( lite_s.b_ready    ),
      .nasti_aw_id     ( nasti_m.aw_id     ),
      .nasti_aw_addr   ( nasti_m.aw_addr   ),
      .nasti_aw_len    ( nasti_m.aw_len    ),
      .nasti_aw_size   ( nasti_m.aw_size   ),
      .nasti_aw_burst  ( nasti_m.aw_burst  ),
      .nasti_aw_lock   ( nasti_m.aw_lock   ),
      .nasti_aw_cache  ( nasti_m.aw_cache  ),
      .nasti_aw_prot   ( nasti_m.aw_prot   ),
      .nasti_aw_qos    ( nasti_m.aw_qos    ),
      .nasti_aw_region ( nasti_m.aw_region ),
      .nasti_aw_user   ( nasti_m.aw_user   ),
      .nasti_aw_valid  ( nasti_m.aw_valid  ),
      .nasti_aw_ready  ( nasti_m.aw_ready  ),
      .nasti_w_data    ( nasti_m.w_data    ),
      .nasti_w_strb    ( nasti_m.w_strb    ),
      .nasti_w_last    ( nasti_m.w_last    ),
      .nasti_w_user    ( nasti_m.w_user    ),
      .nasti_w_valid   ( nasti_m.w_valid   ),
      .nasti_w_ready   ( nasti_m.w_ready   ),
      .nasti_b_id      ( nasti_m.b_id      ),
      .nasti_b_resp    ( nasti_m.b_resp    ),
      .nasti_b_user    ( nasti_m.b_user    ),
      .nasti_b_valid   ( nasti_m.b_valid   ),
      .nasti_b_ready   ( nasti_m.b_ready   )
      );

   lite_nasti_reader
     #(
       .MAX_TRANSACTION  ( READ_TRANSACTION   ),
       .ID_WIDTH         ( ID_WIDTH           ),
       .ADDR_WIDTH       ( ADDR_WIDTH         ),
       .NASTI_DATA_WIDTH ( NASTI_DATA_WIDTH   ),
       .LITE_DATA_WIDTH  ( LITE_DATA_WIDTH    ),
       .USER_WIDTH       ( USER_WIDTH         )
       )
   reader
     (
      .*,
      .lite_ar_id      ( lite_s.ar_id      ),
      .lite_ar_addr    ( lite_s.ar_addr    ),
      .lite_ar_prot    ( lite_s.ar_prot    ),
      .lite_ar_qos     ( lite_s.ar_qos     ),
      .lite_ar_region  ( lite_s.ar_region  ),
      .lite_ar_user    ( lite_s.ar_user    ),
      .lite_ar_valid   ( lite_s.ar_valid   ),
      .lite_ar_ready   ( lite_s.ar_ready   ),
      .lite_r_id       ( lite_s.r_id       ),
      .lite_r_data     ( lite_s.r_data     ),
      .lite_r_resp     ( lite_s.r_resp     ),
      .lite_r_user     ( lite_s.r_user     ),
      .lite_r_valid    ( lite_s.r_valid    ),
      .lite_r_ready    ( lite_s.r_ready    ),
      .nasti_ar_id     ( nasti_m.ar_id     ),
      .nasti_ar_addr   ( nasti_m.ar_addr   ),
      .nasti_ar_len    ( nasti_m.ar_len    ),
      .nasti_ar_size   ( nasti_m.ar_size   ),
      .nasti_ar_burst  ( nasti_m.ar_burst  ),
      .nasti_ar_lock   ( nasti_m.ar_lock   ),
      .nasti_ar_cache  ( nasti_m.ar_cache  ),
      .nasti_ar_prot   ( nasti_m.ar_prot   ),
      .nasti_ar_qos    ( nasti_m.ar_qos    ),
      .nasti_ar_region ( nasti_m.ar_region ),
      .nasti_ar_user   ( nasti_m.ar_user   ),
      .nasti_ar_valid  ( nasti_m.ar_valid  ),
      .nasti_ar_ready  ( nasti_m.ar_ready  ),
      .nasti_r_id      ( nasti_m.r_id      ),
      .nasti_r_data    ( nasti_m.r_data    ),
      .nasti_r_resp    ( nasti_m.r_resp    ),
      .nasti_r_last    ( nasti_m.r_last    ),
      .nasti_r_user    ( nasti_m.r_user    ),
      .nasti_r_valid   ( nasti_m.r_valid   ),
      .nasti_r_ready   ( nasti_m.r_ready   )
      );

endmodule // lite_nasti_bridge
