// See LICENSE for license details.

// up to 8x8 slave ports
module nasti_crossbar
  #(
    N_INPUT = 1,                // number of input ports
    N_OUTPUT = 1,               // number of output ports
    IB_DEPTH = 0,               // input buffer depth
    OB_DEPTH = 0,               // output buffer depth
    W_MAX = 2,                  // maximal parallel write transactions
    R_MAX = 2,                  // maximal parallel read transactions
    ID_WIDTH = 1,               // id width
    ADDR_WIDTH = 8,             // address width
    DATA_WIDTH = 8,             // width of data
    USER_WIDTH = 1,             // width of user field, must > 0, let synthesizer trim it if not
    LITE_MODE = 0,              // whether work in Lite mode
    logic [ADDR_WIDTH-1:0] BASE0 = 0, // base address for port 0
    logic [ADDR_WIDTH-1:0] BASE1 = 0, // base address for port 1
    logic [ADDR_WIDTH-1:0] BASE2 = 0, // base address for port 2
    logic [ADDR_WIDTH-1:0] BASE3 = 0, // base address for port 3
    logic [ADDR_WIDTH-1:0] BASE4 = 0, // base address for port 4
    logic [ADDR_WIDTH-1:0] BASE5 = 0, // base address for port 5
    logic [ADDR_WIDTH-1:0] BASE6 = 0, // base address for port 6
    logic [ADDR_WIDTH-1:0] BASE7 = 0, // base address for port 7
    logic [ADDR_WIDTH-1:0] MASK0 = 0, // address mask for port 0
    logic [ADDR_WIDTH-1:0] MASK1 = 0, // address mask for port 1
    logic [ADDR_WIDTH-1:0] MASK2 = 0, // address mask for port 2
    logic [ADDR_WIDTH-1:0] MASK3 = 0, // address mask for port 3
    logic [ADDR_WIDTH-1:0] MASK4 = 0, // address mask for port 4
    logic [ADDR_WIDTH-1:0] MASK5 = 0, // address mask for port 5
    logic [ADDR_WIDTH-1:0] MASK6 = 0, // address mask for port 6
    logic [ADDR_WIDTH-1:0] MASK7 = 0  // address mask for port 7
    )
   (
    input clk, rstn,
    nasti_channel.slave  s,
    nasti_channel.master m
    );

   genvar i, j;

   // painful, why vivado does not support array of interfaces
   nasti_channel #(.ID_WIDTH(ID_WIDTH), .ADDR_WIDTH(ADDR_WIDTH),
                   .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH))
   ib_i0(), ib_i1(), ib_i2(), ib_i3(), ib_i4(), ib_i5(), ib_i6(), ib_i7();

   nasti_channel #(.ID_WIDTH(ID_WIDTH), .ADDR_WIDTH(ADDR_WIDTH),
                   .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH))
   ib_o0(), ib_o1(), ib_o2(), ib_o3(), ib_o4(), ib_o5(), ib_o6(), ib_o7();

   nasti_channel #(.N_PORT(8), .ID_WIDTH(ID_WIDTH), .ADDR_WIDTH(ADDR_WIDTH),
                   .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH))
   dm_o0(), dm_o1(), dm_o2(), dm_o3(), dm_o4(), dm_o5(), dm_o6(), dm_o7();

   nasti_channel #(.N_PORT(8), .ID_WIDTH(ID_WIDTH), .ADDR_WIDTH(ADDR_WIDTH),
                   .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH))
   mx_i0(), mx_i1(), mx_i2(), mx_i3(), mx_i4(), mx_i5(), mx_i6(), mx_i7();

   nasti_channel #(.ID_WIDTH(ID_WIDTH), .ADDR_WIDTH(ADDR_WIDTH),
                   .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH))
   ob_i0(), ob_i1(), ob_i2(), ob_i3(), ob_i4(), ob_i5(), ob_i6(), ob_i7();

   nasti_channel #(.ID_WIDTH(ID_WIDTH), .ADDR_WIDTH(ADDR_WIDTH),
                   .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH))
   ob_o0(), ob_o1(), ob_o2(), ob_o3(), ob_o4(), ob_o5(), ob_o6(), ob_o7();

   // slicing input channels and possibly insert input buffers
   nasti_channel_slicer #(N_INPUT)
   input_slicer (
                 .s  ( s      ),
                 .m0 ( ib_i0  ), .m1 ( ib_i1  ), .m2 ( ib_i2  ), .m3 ( ib_i3  ),
                 .m4 ( ib_i4  ), .m5 ( ib_i5  ), .m6 ( ib_i6  ), .m7 ( ib_i7  ));

   nasti_buf #(.DEPTH(IB_DEPTH), .ID_WIDTH(ID_WIDTH), .ADDR_WIDTH(ADDR_WIDTH),
               .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH),
               .BUF_REQ(IB_DEPTH), .BUF_RESP(IB_DEPTH))
   ibuf0 (.*, .s(ib_i0), .m(ib_o0));

   nasti_buf #(.DEPTH(IB_DEPTH), .ID_WIDTH(ID_WIDTH), .ADDR_WIDTH(ADDR_WIDTH),
               .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH),
               .BUF_REQ(IB_DEPTH), .BUF_RESP(IB_DEPTH))
   ibuf1 (.*, .s(ib_i1), .m(ib_o1));

   nasti_buf #(.DEPTH(IB_DEPTH), .ID_WIDTH(ID_WIDTH), .ADDR_WIDTH(ADDR_WIDTH),
               .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH),
               .BUF_REQ(IB_DEPTH), .BUF_RESP(IB_DEPTH))
   ibuf2 (.*, .s(ib_i2), .m(ib_o2));

   nasti_buf #(.DEPTH(IB_DEPTH), .ID_WIDTH(ID_WIDTH), .ADDR_WIDTH(ADDR_WIDTH),
               .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH),
               .BUF_REQ(IB_DEPTH), .BUF_RESP(IB_DEPTH))
   ibuf3 (.*, .s(ib_i3), .m(ib_o3));

   nasti_buf #(.DEPTH(IB_DEPTH), .ID_WIDTH(ID_WIDTH), .ADDR_WIDTH(ADDR_WIDTH),
               .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH),
               .BUF_REQ(IB_DEPTH), .BUF_RESP(IB_DEPTH))
   ibuf4 (.*, .s(ib_i4), .m(ib_o4));

   nasti_buf #(.DEPTH(IB_DEPTH), .ID_WIDTH(ID_WIDTH), .ADDR_WIDTH(ADDR_WIDTH),
               .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH),
               .BUF_REQ(IB_DEPTH), .BUF_RESP(IB_DEPTH))
   ibuf5 (.*, .s(ib_i5), .m(ib_o5));

   nasti_buf #(.DEPTH(IB_DEPTH), .ID_WIDTH(ID_WIDTH), .ADDR_WIDTH(ADDR_WIDTH),
               .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH),
               .BUF_REQ(IB_DEPTH), .BUF_RESP(IB_DEPTH))
   ibuf6 (.*, .s(ib_i6), .m(ib_o6));

   nasti_buf #(.DEPTH(IB_DEPTH), .ID_WIDTH(ID_WIDTH), .ADDR_WIDTH(ADDR_WIDTH),
               .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH),
               .BUF_REQ(IB_DEPTH), .BUF_RESP(IB_DEPTH))
   ibuf7 (.*, .s(ib_i7), .m(ib_o7));

   // demux according to addresses
   nasti_demux #(.ID_WIDTH(ID_WIDTH), .ADDR_WIDTH(ADDR_WIDTH),
                 .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH), .LITE_MODE(LITE_MODE),
                 .BASE0(BASE0), .BASE1(BASE1), .BASE2(BASE2), .BASE3(BASE3),
                 .BASE4(BASE4), .BASE5(BASE5), .BASE6(BASE6), .BASE7(BASE7),
                 .MASK0(MASK0), .MASK1(MASK1), .MASK2(MASK2), .MASK3(MASK3),
                 .MASK4(MASK4), .MASK5(MASK5), .MASK6(MASK6), .MASK7(MASK7))
   demux0 (.*, .s(ib_o0), .m(dm_o0));

   nasti_demux #(.ID_WIDTH(ID_WIDTH), .ADDR_WIDTH(ADDR_WIDTH),
                 .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH), .LITE_MODE(LITE_MODE),
                 .BASE0(BASE0), .BASE1(BASE1), .BASE2(BASE2), .BASE3(BASE3),
                 .BASE4(BASE4), .BASE5(BASE5), .BASE6(BASE6), .BASE7(BASE7),
                 .MASK0(MASK0), .MASK1(MASK1), .MASK2(MASK2), .MASK3(MASK3),
                 .MASK4(MASK4), .MASK5(MASK5), .MASK6(MASK6), .MASK7(MASK7))
   demux1 (.*, .s(ib_o1), .m(dm_o1));

   nasti_demux #(.ID_WIDTH(ID_WIDTH), .ADDR_WIDTH(ADDR_WIDTH),
                 .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH), .LITE_MODE(LITE_MODE),
                 .BASE0(BASE0), .BASE1(BASE1), .BASE2(BASE2), .BASE3(BASE3),
                 .BASE4(BASE4), .BASE5(BASE5), .BASE6(BASE6), .BASE7(BASE7),
                 .MASK0(MASK0), .MASK1(MASK1), .MASK2(MASK2), .MASK3(MASK3),
                 .MASK4(MASK4), .MASK5(MASK5), .MASK6(MASK6), .MASK7(MASK7))
   demux2 (.*, .s(ib_o2), .m(dm_o2));

   nasti_demux #(.ID_WIDTH(ID_WIDTH), .ADDR_WIDTH(ADDR_WIDTH),
                 .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH),
                 .BASE0(BASE0), .BASE1(BASE1), .BASE2(BASE2), .BASE3(BASE3),
                 .BASE4(BASE4), .BASE5(BASE5), .BASE6(BASE6), .BASE7(BASE7),
                 .MASK0(MASK0), .MASK1(MASK1), .MASK2(MASK2), .MASK3(MASK3),
                 .MASK4(MASK4), .MASK5(MASK5), .MASK6(MASK6), .MASK7(MASK7))
   demux3 (.*, .s(ib_o3), .m(dm_o3));

   nasti_demux #(.ID_WIDTH(ID_WIDTH), .ADDR_WIDTH(ADDR_WIDTH),
                 .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH), .LITE_MODE(LITE_MODE),
                 .BASE0(BASE0), .BASE1(BASE1), .BASE2(BASE2), .BASE3(BASE3),
                 .BASE4(BASE4), .BASE5(BASE5), .BASE6(BASE6), .BASE7(BASE7),
                 .MASK0(MASK0), .MASK1(MASK1), .MASK2(MASK2), .MASK3(MASK3),
                 .MASK4(MASK4), .MASK5(MASK5), .MASK6(MASK6), .MASK7(MASK7))
   demux4 (.*, .s(ib_o4), .m(dm_o4));

   nasti_demux #(.ID_WIDTH(ID_WIDTH), .ADDR_WIDTH(ADDR_WIDTH),
                 .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH), .LITE_MODE(LITE_MODE),
                 .BASE0(BASE0), .BASE1(BASE1), .BASE2(BASE2), .BASE3(BASE3),
                 .BASE4(BASE4), .BASE5(BASE5), .BASE6(BASE6), .BASE7(BASE7),
                 .MASK0(MASK0), .MASK1(MASK1), .MASK2(MASK2), .MASK3(MASK3),
                 .MASK4(MASK4), .MASK5(MASK5), .MASK6(MASK6), .MASK7(MASK7))
   demux5 (.*, .s(ib_o5), .m(dm_o5));

   nasti_demux #(.ID_WIDTH(ID_WIDTH), .ADDR_WIDTH(ADDR_WIDTH),
                 .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH), .LITE_MODE(LITE_MODE),
                 .BASE0(BASE0), .BASE1(BASE1), .BASE2(BASE2), .BASE3(BASE3),
                 .BASE4(BASE4), .BASE5(BASE5), .BASE6(BASE6), .BASE7(BASE7),
                 .MASK0(MASK0), .MASK1(MASK1), .MASK2(MASK2), .MASK3(MASK3),
                 .MASK4(MASK4), .MASK5(MASK5), .MASK6(MASK6), .MASK7(MASK7))
   demux6 (.*, .s(ib_o6), .m(dm_o6));

   nasti_demux #(.ID_WIDTH(ID_WIDTH), .ADDR_WIDTH(ADDR_WIDTH),
                 .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH), .LITE_MODE(LITE_MODE),
                 .BASE0(BASE0), .BASE1(BASE1), .BASE2(BASE2), .BASE3(BASE3),
                 .BASE4(BASE4), .BASE5(BASE5), .BASE6(BASE6), .BASE7(BASE7),
                 .MASK0(MASK0), .MASK1(MASK1), .MASK2(MASK2), .MASK3(MASK3),
                 .MASK4(MASK4), .MASK5(MASK5), .MASK6(MASK6), .MASK7(MASK7))
   demux7 (.*, .s(ib_o7), .m(dm_o7));

   // crossbar connection
   logic [7:0][7:0][ID_WIDTH-1:0]     cbi_aw_id,     cbi_ar_id;
   logic [7:0][7:0][ADDR_WIDTH-1:0]   cbi_aw_addr,   cbi_ar_addr;
   logic [7:0][7:0][7:0]              cbi_aw_len,    cbi_ar_len;
   logic [7:0][7:0][2:0]              cbi_aw_size,   cbi_ar_size;
   logic [7:0][7:0][1:0]              cbi_aw_burst,  cbi_ar_burst;
   logic [7:0][7:0]                   cbi_aw_lock,   cbi_ar_lock;
   logic [7:0][7:0][3:0]              cbi_aw_cache,  cbi_ar_cache;
   logic [7:0][7:0][2:0]              cbi_aw_prot,   cbi_ar_prot;
   logic [7:0][7:0][3:0]              cbi_aw_qos,    cbi_ar_qos;
   logic [7:0][7:0][3:0]              cbi_aw_region, cbi_ar_region;
   logic [7:0][7:0][USER_WIDTH-1:0]   cbi_aw_user,   cbi_ar_user;
   logic [7:0][7:0]                   cbi_aw_valid,  cbi_ar_valid;
   logic [7:0][7:0]                   cbi_aw_ready,  cbi_ar_ready;
   logic [7:0][7:0][DATA_WIDTH-1:0]   cbi_w_data,    cbi_r_data;
   logic [7:0][7:0][DATA_WIDTH/8-1:0] cbi_w_strb;
   logic [7:0][7:0]                   cbi_w_last,    cbi_r_last;
   logic [7:0][7:0][USER_WIDTH-1:0]   cbi_w_user;
   logic [7:0][7:0]                   cbi_w_valid;
   logic [7:0][7:0]                   cbi_w_ready;
   logic [7:0][7:0][ID_WIDTH-1:0]     cbi_b_id,      cbi_r_id;
   logic [7:0][7:0][1:0]              cbi_b_resp,    cbi_r_resp;
   logic [7:0][7:0][USER_WIDTH-1:0]   cbi_b_user,    cbi_r_user;
   logic [7:0][7:0]                   cbi_b_valid,   cbi_r_valid;
   logic [7:0][7:0]                   cbi_b_ready,   cbi_r_ready;

   logic [7:0][7:0][ID_WIDTH-1:0]     cbo_aw_id,     cbo_ar_id;
   logic [7:0][7:0][ADDR_WIDTH-1:0]   cbo_aw_addr,   cbo_ar_addr;
   logic [7:0][7:0][7:0]              cbo_aw_len,    cbo_ar_len;
   logic [7:0][7:0][2:0]              cbo_aw_size,   cbo_ar_size;
   logic [7:0][7:0][1:0]              cbo_aw_burst,  cbo_ar_burst;
   logic [7:0][7:0]                   cbo_aw_lock,   cbo_ar_lock;
   logic [7:0][7:0][3:0]              cbo_aw_cache,  cbo_ar_cache;
   logic [7:0][7:0][2:0]              cbo_aw_prot,   cbo_ar_prot;
   logic [7:0][7:0][3:0]              cbo_aw_qos,    cbo_ar_qos;
   logic [7:0][7:0][3:0]              cbo_aw_region, cbo_ar_region;
   logic [7:0][7:0][USER_WIDTH-1:0]   cbo_aw_user,   cbo_ar_user;
   logic [7:0][7:0]                   cbo_aw_valid,  cbo_ar_valid;
   logic [7:0][7:0]                   cbo_aw_ready,  cbo_ar_ready;
   logic [7:0][7:0][DATA_WIDTH-1:0]   cbo_w_data,    cbo_r_data;
   logic [7:0][7:0][DATA_WIDTH/8-1:0] cbo_w_strb;
   logic [7:0][7:0]                   cbo_w_last,    cbo_r_last;
   logic [7:0][7:0][USER_WIDTH-1:0]   cbo_w_user;
   logic [7:0][7:0]                   cbo_w_valid;
   logic [7:0][7:0]                   cbo_w_ready;
   logic [7:0][7:0][ID_WIDTH-1:0]     cbo_b_id,      cbo_r_id;
   logic [7:0][7:0][1:0]              cbo_b_resp,    cbo_r_resp;
   logic [7:0][7:0][USER_WIDTH-1:0]   cbo_b_user,    cbo_r_user;
   logic [7:0][7:0]                   cbo_b_valid,   cbo_r_valid;
   logic [7:0][7:0]                   cbo_b_ready,   cbo_r_ready;

   // painfully manuall connect them all to interfaces
   assign cbi_aw_id[0]      = dm_o0.aw_id;
   assign cbi_aw_addr[0]    = dm_o0.aw_addr;
   assign cbi_aw_len[0]     = dm_o0.aw_len;
   assign cbi_aw_size[0]    = dm_o0.aw_size;
   assign cbi_aw_burst[0]   = dm_o0.aw_burst;
   assign cbi_aw_lock[0]    = dm_o0.aw_lock;
   assign cbi_aw_cache[0]   = dm_o0.aw_cache;
   assign cbi_aw_prot[0]    = dm_o0.aw_prot;
   assign cbi_aw_qos[0]     = dm_o0.aw_qos;
   assign cbi_aw_region[0]  = dm_o0.aw_region;
   assign cbi_aw_user[0]    = dm_o0.aw_user;
   assign cbi_aw_valid[0]   = dm_o0.aw_valid;
   assign dm_o0.aw_ready    = cbi_aw_ready[0];
   assign cbi_ar_id[0]      = dm_o0.ar_id;
   assign cbi_ar_addr[0]    = dm_o0.ar_addr;
   assign cbi_ar_len[0]     = dm_o0.ar_len;
   assign cbi_ar_size[0]    = dm_o0.ar_size;
   assign cbi_ar_burst[0]   = dm_o0.ar_burst;
   assign cbi_ar_lock[0]    = dm_o0.ar_lock;
   assign cbi_ar_cache[0]   = dm_o0.ar_cache;
   assign cbi_ar_prot[0]    = dm_o0.ar_prot;
   assign cbi_ar_qos[0]     = dm_o0.ar_qos;
   assign cbi_ar_region[0]  = dm_o0.ar_region;
   assign cbi_ar_user[0]    = dm_o0.ar_user;
   assign cbi_ar_valid[0]   = dm_o0.ar_valid;
   assign dm_o0.ar_ready    = cbi_ar_ready[0];
   assign cbi_w_data[0]     = dm_o0.w_data;
   assign cbi_w_strb[0]     = dm_o0.w_strb;
   assign cbi_w_last[0]     = dm_o0.w_last;
   assign cbi_w_user[0]     = dm_o0.w_user;
   assign cbi_w_valid[0]    = dm_o0.w_valid;
   assign dm_o0.w_ready     = cbi_w_ready[0];
   assign dm_o0.b_id        = cbi_b_id[0];
   assign dm_o0.b_resp      = cbi_b_resp[0];
   assign dm_o0.b_user      = cbi_b_user[0];
   assign dm_o0.b_valid     = cbi_b_valid[0];
   assign cbi_b_ready[0]    = dm_o0.b_ready;
   assign dm_o0.r_id        = cbi_r_id[0];
   assign dm_o0.r_data      = cbi_r_data[0];
   assign dm_o0.r_resp      = cbi_r_resp[0];
   assign dm_o0.r_last      = cbi_r_last[0];
   assign dm_o0.r_user      = cbi_r_user[0];
   assign dm_o0.r_valid     = cbi_r_valid[0];
   assign cbi_r_ready[0]    = dm_o0.r_ready;

   assign cbi_aw_id[1]      = dm_o1.aw_id;
   assign cbi_aw_addr[1]    = dm_o1.aw_addr;
   assign cbi_aw_len[1]     = dm_o1.aw_len;
   assign cbi_aw_size[1]    = dm_o1.aw_size;
   assign cbi_aw_burst[1]   = dm_o1.aw_burst;
   assign cbi_aw_lock[1]    = dm_o1.aw_lock;
   assign cbi_aw_cache[1]   = dm_o1.aw_cache;
   assign cbi_aw_prot[1]    = dm_o1.aw_prot;
   assign cbi_aw_qos[1]     = dm_o1.aw_qos;
   assign cbi_aw_region[1]  = dm_o1.aw_region;
   assign cbi_aw_user[1]    = dm_o1.aw_user;
   assign cbi_aw_valid[1]   = dm_o1.aw_valid;
   assign dm_o1.aw_ready    = cbi_aw_ready[1];
   assign cbi_ar_id[1]      = dm_o1.ar_id;
   assign cbi_ar_addr[1]    = dm_o1.ar_addr;
   assign cbi_ar_len[1]     = dm_o1.ar_len;
   assign cbi_ar_size[1]    = dm_o1.ar_size;
   assign cbi_ar_burst[1]   = dm_o1.ar_burst;
   assign cbi_ar_lock[1]    = dm_o1.ar_lock;
   assign cbi_ar_cache[1]   = dm_o1.ar_cache;
   assign cbi_ar_prot[1]    = dm_o1.ar_prot;
   assign cbi_ar_qos[1]     = dm_o1.ar_qos;
   assign cbi_ar_region[1]  = dm_o1.ar_region;
   assign cbi_ar_user[1]    = dm_o1.ar_user;
   assign cbi_ar_valid[1]   = dm_o1.ar_valid;
   assign dm_o1.ar_ready    = cbi_ar_ready[1];
   assign cbi_w_data[1]     = dm_o1.w_data;
   assign cbi_w_strb[1]     = dm_o1.w_strb;
   assign cbi_w_last[1]     = dm_o1.w_last;
   assign cbi_w_user[1]     = dm_o1.w_user;
   assign cbi_w_valid[1]    = dm_o1.w_valid;
   assign dm_o1.w_ready     = cbi_w_ready[1];
   assign dm_o1.b_id        = cbi_b_id[1];
   assign dm_o1.b_resp      = cbi_b_resp[1];
   assign dm_o1.b_user      = cbi_b_user[1];
   assign dm_o1.b_valid     = cbi_b_valid[1];
   assign cbi_b_ready[1]    = dm_o1.b_ready;
   assign dm_o1.r_id        = cbi_r_id[1];
   assign dm_o1.r_data      = cbi_r_data[1];
   assign dm_o1.r_resp      = cbi_r_resp[1];
   assign dm_o1.r_last      = cbi_r_last[1];
   assign dm_o1.r_user      = cbi_r_user[1];
   assign dm_o1.r_valid     = cbi_r_valid[1];
   assign cbi_r_ready[1]    = dm_o1.r_ready;

   assign cbi_aw_id[2]      = dm_o2.aw_id;
   assign cbi_aw_addr[2]    = dm_o2.aw_addr;
   assign cbi_aw_len[2]     = dm_o2.aw_len;
   assign cbi_aw_size[2]    = dm_o2.aw_size;
   assign cbi_aw_burst[2]   = dm_o2.aw_burst;
   assign cbi_aw_lock[2]    = dm_o2.aw_lock;
   assign cbi_aw_cache[2]   = dm_o2.aw_cache;
   assign cbi_aw_prot[2]    = dm_o2.aw_prot;
   assign cbi_aw_qos[2]     = dm_o2.aw_qos;
   assign cbi_aw_region[2]  = dm_o2.aw_region;
   assign cbi_aw_user[2]    = dm_o2.aw_user;
   assign cbi_aw_valid[2]   = dm_o2.aw_valid;
   assign dm_o2.aw_ready    = cbi_aw_ready[2];
   assign cbi_ar_id[2]      = dm_o2.ar_id;
   assign cbi_ar_addr[2]    = dm_o2.ar_addr;
   assign cbi_ar_len[2]     = dm_o2.ar_len;
   assign cbi_ar_size[2]    = dm_o2.ar_size;
   assign cbi_ar_burst[2]   = dm_o2.ar_burst;
   assign cbi_ar_lock[2]    = dm_o2.ar_lock;
   assign cbi_ar_cache[2]   = dm_o2.ar_cache;
   assign cbi_ar_prot[2]    = dm_o2.ar_prot;
   assign cbi_ar_qos[2]     = dm_o2.ar_qos;
   assign cbi_ar_region[2]  = dm_o2.ar_region;
   assign cbi_ar_user[2]    = dm_o2.ar_user;
   assign cbi_ar_valid[2]   = dm_o2.ar_valid;
   assign dm_o2.ar_ready    = cbi_ar_ready[2];
   assign cbi_w_data[2]     = dm_o2.w_data;
   assign cbi_w_strb[2]     = dm_o2.w_strb;
   assign cbi_w_last[2]     = dm_o2.w_last;
   assign cbi_w_user[2]     = dm_o2.w_user;
   assign cbi_w_valid[2]    = dm_o2.w_valid;
   assign dm_o2.w_ready     = cbi_w_ready[2];
   assign dm_o2.b_id        = cbi_b_id[2];
   assign dm_o2.b_resp      = cbi_b_resp[2];
   assign dm_o2.b_user      = cbi_b_user[2];
   assign dm_o2.b_valid     = cbi_b_valid[2];
   assign cbi_b_ready[2]    = dm_o2.b_ready;
   assign dm_o2.r_id        = cbi_r_id[2];
   assign dm_o2.r_data      = cbi_r_data[2];
   assign dm_o2.r_resp      = cbi_r_resp[2];
   assign dm_o2.r_last      = cbi_r_last[2];
   assign dm_o2.r_user      = cbi_r_user[2];
   assign dm_o2.r_valid     = cbi_r_valid[2];
   assign cbi_r_ready[2]    = dm_o2.r_ready;

   assign cbi_aw_id[3]      = dm_o3.aw_id;
   assign cbi_aw_addr[3]    = dm_o3.aw_addr;
   assign cbi_aw_len[3]     = dm_o3.aw_len;
   assign cbi_aw_size[3]    = dm_o3.aw_size;
   assign cbi_aw_burst[3]   = dm_o3.aw_burst;
   assign cbi_aw_lock[3]    = dm_o3.aw_lock;
   assign cbi_aw_cache[3]   = dm_o3.aw_cache;
   assign cbi_aw_prot[3]    = dm_o3.aw_prot;
   assign cbi_aw_qos[3]     = dm_o3.aw_qos;
   assign cbi_aw_region[3]  = dm_o3.aw_region;
   assign cbi_aw_user[3]    = dm_o3.aw_user;
   assign cbi_aw_valid[3]   = dm_o3.aw_valid;
   assign dm_o3.aw_ready    = cbi_aw_ready[3];
   assign cbi_ar_id[3]      = dm_o3.ar_id;
   assign cbi_ar_addr[3]    = dm_o3.ar_addr;
   assign cbi_ar_len[3]     = dm_o3.ar_len;
   assign cbi_ar_size[3]    = dm_o3.ar_size;
   assign cbi_ar_burst[3]   = dm_o3.ar_burst;
   assign cbi_ar_lock[3]    = dm_o3.ar_lock;
   assign cbi_ar_cache[3]   = dm_o3.ar_cache;
   assign cbi_ar_prot[3]    = dm_o3.ar_prot;
   assign cbi_ar_qos[3]     = dm_o3.ar_qos;
   assign cbi_ar_region[3]  = dm_o3.ar_region;
   assign cbi_ar_user[3]    = dm_o3.ar_user;
   assign cbi_ar_valid[3]   = dm_o3.ar_valid;
   assign dm_o3.ar_ready    = cbi_ar_ready[3];
   assign cbi_w_data[3]     = dm_o3.w_data;
   assign cbi_w_strb[3]     = dm_o3.w_strb;
   assign cbi_w_last[3]     = dm_o3.w_last;
   assign cbi_w_user[3]     = dm_o3.w_user;
   assign cbi_w_valid[3]    = dm_o3.w_valid;
   assign dm_o3.w_ready     = cbi_w_ready[3];
   assign dm_o3.b_id        = cbi_b_id[3];
   assign dm_o3.b_resp      = cbi_b_resp[3];
   assign dm_o3.b_user      = cbi_b_user[3];
   assign dm_o3.b_valid     = cbi_b_valid[3];
   assign cbi_b_ready[3]    = dm_o3.b_ready;
   assign dm_o3.r_id        = cbi_r_id[3];
   assign dm_o3.r_data      = cbi_r_data[3];
   assign dm_o3.r_resp      = cbi_r_resp[3];
   assign dm_o3.r_last      = cbi_r_last[3];
   assign dm_o3.r_user      = cbi_r_user[3];
   assign dm_o3.r_valid     = cbi_r_valid[3];
   assign cbi_r_ready[3]    = dm_o3.r_ready;

   assign cbi_aw_id[4]      = dm_o4.aw_id;
   assign cbi_aw_addr[4]    = dm_o4.aw_addr;
   assign cbi_aw_len[4]     = dm_o4.aw_len;
   assign cbi_aw_size[4]    = dm_o4.aw_size;
   assign cbi_aw_burst[4]   = dm_o4.aw_burst;
   assign cbi_aw_lock[4]    = dm_o4.aw_lock;
   assign cbi_aw_cache[4]   = dm_o4.aw_cache;
   assign cbi_aw_prot[4]    = dm_o4.aw_prot;
   assign cbi_aw_qos[4]     = dm_o4.aw_qos;
   assign cbi_aw_region[4]  = dm_o4.aw_region;
   assign cbi_aw_user[4]    = dm_o4.aw_user;
   assign cbi_aw_valid[4]   = dm_o4.aw_valid;
   assign dm_o4.aw_ready    = cbi_aw_ready[4];
   assign cbi_ar_id[4]      = dm_o4.ar_id;
   assign cbi_ar_addr[4]    = dm_o4.ar_addr;
   assign cbi_ar_len[4]     = dm_o4.ar_len;
   assign cbi_ar_size[4]    = dm_o4.ar_size;
   assign cbi_ar_burst[4]   = dm_o4.ar_burst;
   assign cbi_ar_lock[4]    = dm_o4.ar_lock;
   assign cbi_ar_cache[4]   = dm_o4.ar_cache;
   assign cbi_ar_prot[4]    = dm_o4.ar_prot;
   assign cbi_ar_qos[4]     = dm_o4.ar_qos;
   assign cbi_ar_region[4]  = dm_o4.ar_region;
   assign cbi_ar_user[4]    = dm_o4.ar_user;
   assign cbi_ar_valid[4]   = dm_o4.ar_valid;
   assign dm_o4.ar_ready    = cbi_ar_ready[4];
   assign cbi_w_data[4]     = dm_o4.w_data;
   assign cbi_w_strb[4]     = dm_o4.w_strb;
   assign cbi_w_last[4]     = dm_o4.w_last;
   assign cbi_w_user[4]     = dm_o4.w_user;
   assign cbi_w_valid[4]    = dm_o4.w_valid;
   assign dm_o4.w_ready     = cbi_w_ready[4];
   assign dm_o4.b_id        = cbi_b_id[4];
   assign dm_o4.b_resp      = cbi_b_resp[4];
   assign dm_o4.b_user      = cbi_b_user[4];
   assign dm_o4.b_valid     = cbi_b_valid[4];
   assign cbi_b_ready[4]    = dm_o4.b_ready;
   assign dm_o4.r_id        = cbi_r_id[4];
   assign dm_o4.r_data      = cbi_r_data[4];
   assign dm_o4.r_resp      = cbi_r_resp[4];
   assign dm_o4.r_last      = cbi_r_last[4];
   assign dm_o4.r_user      = cbi_r_user[4];
   assign dm_o4.r_valid     = cbi_r_valid[4];
   assign cbi_r_ready[4]    = dm_o4.r_ready;

   assign cbi_aw_id[5]      = dm_o5.aw_id;
   assign cbi_aw_addr[5]    = dm_o5.aw_addr;
   assign cbi_aw_len[5]     = dm_o5.aw_len;
   assign cbi_aw_size[5]    = dm_o5.aw_size;
   assign cbi_aw_burst[5]   = dm_o5.aw_burst;
   assign cbi_aw_lock[5]    = dm_o5.aw_lock;
   assign cbi_aw_cache[5]   = dm_o5.aw_cache;
   assign cbi_aw_prot[5]    = dm_o5.aw_prot;
   assign cbi_aw_qos[5]     = dm_o5.aw_qos;
   assign cbi_aw_region[5]  = dm_o5.aw_region;
   assign cbi_aw_user[5]    = dm_o5.aw_user;
   assign cbi_aw_valid[5]   = dm_o5.aw_valid;
   assign dm_o5.aw_ready    = cbi_aw_ready[5];
   assign cbi_ar_id[5]      = dm_o5.ar_id;
   assign cbi_ar_addr[5]    = dm_o5.ar_addr;
   assign cbi_ar_len[5]     = dm_o5.ar_len;
   assign cbi_ar_size[5]    = dm_o5.ar_size;
   assign cbi_ar_burst[5]   = dm_o5.ar_burst;
   assign cbi_ar_lock[5]    = dm_o5.ar_lock;
   assign cbi_ar_cache[5]   = dm_o5.ar_cache;
   assign cbi_ar_prot[5]    = dm_o5.ar_prot;
   assign cbi_ar_qos[5]     = dm_o5.ar_qos;
   assign cbi_ar_region[5]  = dm_o5.ar_region;
   assign cbi_ar_user[5]    = dm_o5.ar_user;
   assign cbi_ar_valid[5]   = dm_o5.ar_valid;
   assign dm_o5.ar_ready    = cbi_ar_ready[5];
   assign cbi_w_data[5]     = dm_o5.w_data;
   assign cbi_w_strb[5]     = dm_o5.w_strb;
   assign cbi_w_last[5]     = dm_o5.w_last;
   assign cbi_w_user[5]     = dm_o5.w_user;
   assign cbi_w_valid[5]    = dm_o5.w_valid;
   assign dm_o5.w_ready     = cbi_w_ready[5];
   assign dm_o5.b_id        = cbi_b_id[5];
   assign dm_o5.b_resp      = cbi_b_resp[5];
   assign dm_o5.b_user      = cbi_b_user[5];
   assign dm_o5.b_valid     = cbi_b_valid[5];
   assign cbi_b_ready[5]    = dm_o5.b_ready;
   assign dm_o5.r_id        = cbi_r_id[5];
   assign dm_o5.r_data      = cbi_r_data[5];
   assign dm_o5.r_resp      = cbi_r_resp[5];
   assign dm_o5.r_last      = cbi_r_last[5];
   assign dm_o5.r_user      = cbi_r_user[5];
   assign dm_o5.r_valid     = cbi_r_valid[5];
   assign cbi_r_ready[5]    = dm_o5.r_ready;

   assign cbi_aw_id[6]      = dm_o6.aw_id;
   assign cbi_aw_addr[6]    = dm_o6.aw_addr;
   assign cbi_aw_len[6]     = dm_o6.aw_len;
   assign cbi_aw_size[6]    = dm_o6.aw_size;
   assign cbi_aw_burst[6]   = dm_o6.aw_burst;
   assign cbi_aw_lock[6]    = dm_o6.aw_lock;
   assign cbi_aw_cache[6]   = dm_o6.aw_cache;
   assign cbi_aw_prot[6]    = dm_o6.aw_prot;
   assign cbi_aw_qos[6]     = dm_o6.aw_qos;
   assign cbi_aw_region[6]  = dm_o6.aw_region;
   assign cbi_aw_user[6]    = dm_o6.aw_user;
   assign cbi_aw_valid[6]   = dm_o6.aw_valid;
   assign dm_o6.aw_ready    = cbi_aw_ready[6];
   assign cbi_ar_id[6]      = dm_o6.ar_id;
   assign cbi_ar_addr[6]    = dm_o6.ar_addr;
   assign cbi_ar_len[6]     = dm_o6.ar_len;
   assign cbi_ar_size[6]    = dm_o6.ar_size;
   assign cbi_ar_burst[6]   = dm_o6.ar_burst;
   assign cbi_ar_lock[6]    = dm_o6.ar_lock;
   assign cbi_ar_cache[6]   = dm_o6.ar_cache;
   assign cbi_ar_prot[6]    = dm_o6.ar_prot;
   assign cbi_ar_qos[6]     = dm_o6.ar_qos;
   assign cbi_ar_region[6]  = dm_o6.ar_region;
   assign cbi_ar_user[6]    = dm_o6.ar_user;
   assign cbi_ar_valid[6]   = dm_o6.ar_valid;
   assign dm_o6.ar_ready    = cbi_ar_ready[6];
   assign cbi_w_data[6]     = dm_o6.w_data;
   assign cbi_w_strb[6]     = dm_o6.w_strb;
   assign cbi_w_last[6]     = dm_o6.w_last;
   assign cbi_w_user[6]     = dm_o6.w_user;
   assign cbi_w_valid[6]    = dm_o6.w_valid;
   assign dm_o6.w_ready     = cbi_w_ready[6];
   assign dm_o6.b_id        = cbi_b_id[6];
   assign dm_o6.b_resp      = cbi_b_resp[6];
   assign dm_o6.b_user      = cbi_b_user[6];
   assign dm_o6.b_valid     = cbi_b_valid[6];
   assign cbi_b_ready[6]    = dm_o6.b_ready;
   assign dm_o6.r_id        = cbi_r_id[6];
   assign dm_o6.r_data      = cbi_r_data[6];
   assign dm_o6.r_resp      = cbi_r_resp[6];
   assign dm_o6.r_last      = cbi_r_last[6];
   assign dm_o6.r_user      = cbi_r_user[6];
   assign dm_o6.r_valid     = cbi_r_valid[6];
   assign cbi_r_ready[6]    = dm_o6.r_ready;

   assign cbi_aw_id[7]      = dm_o7.aw_id;
   assign cbi_aw_addr[7]    = dm_o7.aw_addr;
   assign cbi_aw_len[7]     = dm_o7.aw_len;
   assign cbi_aw_size[7]    = dm_o7.aw_size;
   assign cbi_aw_burst[7]   = dm_o7.aw_burst;
   assign cbi_aw_lock[7]    = dm_o7.aw_lock;
   assign cbi_aw_cache[7]   = dm_o7.aw_cache;
   assign cbi_aw_prot[7]    = dm_o7.aw_prot;
   assign cbi_aw_qos[7]     = dm_o7.aw_qos;
   assign cbi_aw_region[7]  = dm_o7.aw_region;
   assign cbi_aw_user[7]    = dm_o7.aw_user;
   assign cbi_aw_valid[7]   = dm_o7.aw_valid;
   assign dm_o7.aw_ready    = cbi_aw_ready[7];
   assign cbi_ar_id[7]      = dm_o7.ar_id;
   assign cbi_ar_addr[7]    = dm_o7.ar_addr;
   assign cbi_ar_len[7]     = dm_o7.ar_len;
   assign cbi_ar_size[7]    = dm_o7.ar_size;
   assign cbi_ar_burst[7]   = dm_o7.ar_burst;
   assign cbi_ar_lock[7]    = dm_o7.ar_lock;
   assign cbi_ar_cache[7]   = dm_o7.ar_cache;
   assign cbi_ar_prot[7]    = dm_o7.ar_prot;
   assign cbi_ar_qos[7]     = dm_o7.ar_qos;
   assign cbi_ar_region[7]  = dm_o7.ar_region;
   assign cbi_ar_user[7]    = dm_o7.ar_user;
   assign cbi_ar_valid[7]   = dm_o7.ar_valid;
   assign dm_o7.ar_ready    = cbi_ar_ready[7];
   assign cbi_w_data[7]     = dm_o7.w_data;
   assign cbi_w_strb[7]     = dm_o7.w_strb;
   assign cbi_w_last[7]     = dm_o7.w_last;
   assign cbi_w_user[7]     = dm_o7.w_user;
   assign cbi_w_valid[7]    = dm_o7.w_valid;
   assign dm_o7.w_ready     = cbi_w_ready[7];
   assign dm_o7.b_id        = cbi_b_id[7];
   assign dm_o7.b_resp      = cbi_b_resp[7];
   assign dm_o7.b_user      = cbi_b_user[7];
   assign dm_o7.b_valid     = cbi_b_valid[7];
   assign cbi_b_ready[7]    = dm_o7.b_ready;
   assign dm_o7.r_id        = cbi_r_id[7];
   assign dm_o7.r_data      = cbi_r_data[7];
   assign dm_o7.r_resp      = cbi_r_resp[7];
   assign dm_o7.r_last      = cbi_r_last[7];
   assign dm_o7.r_user      = cbi_r_user[7];
   assign dm_o7.r_valid     = cbi_r_valid[7];
   assign cbi_r_ready[7]    = dm_o7.r_ready;

   assign mx_i0.aw_id       = cbo_aw_id[0];
   assign mx_i0.aw_addr     = cbo_aw_addr[0];
   assign mx_i0.aw_len      = cbo_aw_len[0];
   assign mx_i0.aw_size     = cbo_aw_size[0];
   assign mx_i0.aw_burst    = cbo_aw_burst[0];
   assign mx_i0.aw_lock     = cbo_aw_lock[0];
   assign mx_i0.aw_cache    = cbo_aw_cache[0];
   assign mx_i0.aw_prot     = cbo_aw_prot[0];
   assign mx_i0.aw_qos      = cbo_aw_qos[0];
   assign mx_i0.aw_region   = cbo_aw_region[0];
   assign mx_i0.aw_user     = cbo_aw_user[0];
   assign mx_i0.aw_valid    = cbo_aw_valid[0];
   assign cbo_aw_ready[0]   = mx_i0.aw_ready;
   assign mx_i0.ar_id       = cbo_ar_id[0];
   assign mx_i0.ar_addr     = cbo_ar_addr[0];
   assign mx_i0.ar_len      = cbo_ar_len[0];
   assign mx_i0.ar_size     = cbo_ar_size[0];
   assign mx_i0.ar_burst    = cbo_ar_burst[0];
   assign mx_i0.ar_lock     = cbo_ar_lock[0];
   assign mx_i0.ar_cache    = cbo_ar_cache[0];
   assign mx_i0.ar_prot     = cbo_ar_prot[0];
   assign mx_i0.ar_qos      = cbo_ar_qos[0];
   assign mx_i0.ar_region   = cbo_ar_region[0];
   assign mx_i0.ar_user     = cbo_ar_user[0];
   assign mx_i0.ar_valid    = cbo_ar_valid[0];
   assign cbo_ar_ready[0]   = mx_i0.ar_ready;
   assign mx_i0.w_data      = cbo_w_data[0];
   assign mx_i0.w_strb      = cbo_w_strb[0];
   assign mx_i0.w_last      = cbo_w_last[0];
   assign mx_i0.w_user      = cbo_w_user[0];
   assign mx_i0.w_valid     = cbo_w_valid[0];
   assign cbo_w_ready[0]    = mx_i0.w_ready;
   assign cbo_b_id[0]       = mx_i0.b_id;
   assign cbo_b_resp[0]     = mx_i0.b_resp;
   assign cbo_b_user[0]     = mx_i0.b_user;
   assign cbo_b_valid[0]    = mx_i0.b_valid;
   assign mx_i0.b_ready     = cbo_b_ready[0];
   assign cbo_r_id[0]       = mx_i0.r_id;
   assign cbo_r_data[0]     = mx_i0.r_data;
   assign cbo_r_resp[0]     = mx_i0.r_resp;
   assign cbo_r_last[0]     = mx_i0.r_last;
   assign cbo_r_user[0]     = mx_i0.r_user;
   assign cbo_r_valid[0]    = mx_i0.r_valid;
   assign mx_i0.r_ready     = cbo_r_ready[0];

   assign mx_i1.aw_id       = cbo_aw_id[1];
   assign mx_i1.aw_addr     = cbo_aw_addr[1];
   assign mx_i1.aw_len      = cbo_aw_len[1];
   assign mx_i1.aw_size     = cbo_aw_size[1];
   assign mx_i1.aw_burst    = cbo_aw_burst[1];
   assign mx_i1.aw_lock     = cbo_aw_lock[1];
   assign mx_i1.aw_cache    = cbo_aw_cache[1];
   assign mx_i1.aw_prot     = cbo_aw_prot[1];
   assign mx_i1.aw_qos      = cbo_aw_qos[1];
   assign mx_i1.aw_region   = cbo_aw_region[1];
   assign mx_i1.aw_user     = cbo_aw_user[1];
   assign mx_i1.aw_valid    = cbo_aw_valid[1];
   assign cbo_aw_ready[1]   = mx_i1.aw_ready;
   assign mx_i1.ar_id       = cbo_ar_id[1];
   assign mx_i1.ar_addr     = cbo_ar_addr[1];
   assign mx_i1.ar_len      = cbo_ar_len[1];
   assign mx_i1.ar_size     = cbo_ar_size[1];
   assign mx_i1.ar_burst    = cbo_ar_burst[1];
   assign mx_i1.ar_lock     = cbo_ar_lock[1];
   assign mx_i1.ar_cache    = cbo_ar_cache[1];
   assign mx_i1.ar_prot     = cbo_ar_prot[1];
   assign mx_i1.ar_qos      = cbo_ar_qos[1];
   assign mx_i1.ar_region   = cbo_ar_region[1];
   assign mx_i1.ar_user     = cbo_ar_user[1];
   assign mx_i1.ar_valid    = cbo_ar_valid[1];
   assign cbo_ar_ready[1]   = mx_i1.ar_ready;
   assign mx_i1.w_data      = cbo_w_data[1];
   assign mx_i1.w_strb      = cbo_w_strb[1];
   assign mx_i1.w_last      = cbo_w_last[1];
   assign mx_i1.w_user      = cbo_w_user[1];
   assign mx_i1.w_valid     = cbo_w_valid[1];
   assign cbo_w_ready[1]    = mx_i1.w_ready;
   assign cbo_b_id[1]       = mx_i1.b_id;
   assign cbo_b_resp[1]     = mx_i1.b_resp;
   assign cbo_b_user[1]     = mx_i1.b_user;
   assign cbo_b_valid[1]    = mx_i1.b_valid;
   assign mx_i1.b_ready     = cbo_b_ready[1];
   assign cbo_r_id[1]       = mx_i1.r_id;
   assign cbo_r_data[1]     = mx_i1.r_data;
   assign cbo_r_resp[1]     = mx_i1.r_resp;
   assign cbo_r_last[1]     = mx_i1.r_last;
   assign cbo_r_user[1]     = mx_i1.r_user;
   assign cbo_r_valid[1]    = mx_i1.r_valid;
   assign mx_i1.r_ready     = cbo_r_ready[1];

   assign mx_i2.aw_id       = cbo_aw_id[2];
   assign mx_i2.aw_addr     = cbo_aw_addr[2];
   assign mx_i2.aw_len      = cbo_aw_len[2];
   assign mx_i2.aw_size     = cbo_aw_size[2];
   assign mx_i2.aw_burst    = cbo_aw_burst[2];
   assign mx_i2.aw_lock     = cbo_aw_lock[2];
   assign mx_i2.aw_cache    = cbo_aw_cache[2];
   assign mx_i2.aw_prot     = cbo_aw_prot[2];
   assign mx_i2.aw_qos      = cbo_aw_qos[2];
   assign mx_i2.aw_region   = cbo_aw_region[2];
   assign mx_i2.aw_user     = cbo_aw_user[2];
   assign mx_i2.aw_valid    = cbo_aw_valid[2];
   assign cbo_aw_ready[2]   = mx_i2.aw_ready;
   assign mx_i2.ar_id       = cbo_ar_id[2];
   assign mx_i2.ar_addr     = cbo_ar_addr[2];
   assign mx_i2.ar_len      = cbo_ar_len[2];
   assign mx_i2.ar_size     = cbo_ar_size[2];
   assign mx_i2.ar_burst    = cbo_ar_burst[2];
   assign mx_i2.ar_lock     = cbo_ar_lock[2];
   assign mx_i2.ar_cache    = cbo_ar_cache[2];
   assign mx_i2.ar_prot     = cbo_ar_prot[2];
   assign mx_i2.ar_qos      = cbo_ar_qos[2];
   assign mx_i2.ar_region   = cbo_ar_region[2];
   assign mx_i2.ar_user     = cbo_ar_user[2];
   assign mx_i2.ar_valid    = cbo_ar_valid[2];
   assign cbo_ar_ready[2]   = mx_i2.ar_ready;
   assign mx_i2.w_data      = cbo_w_data[2];
   assign mx_i2.w_strb      = cbo_w_strb[2];
   assign mx_i2.w_last      = cbo_w_last[2];
   assign mx_i2.w_user      = cbo_w_user[2];
   assign mx_i2.w_valid     = cbo_w_valid[2];
   assign cbo_w_ready[2]    = mx_i2.w_ready;
   assign cbo_b_id[2]       = mx_i2.b_id;
   assign cbo_b_resp[2]     = mx_i2.b_resp;
   assign cbo_b_user[2]     = mx_i2.b_user;
   assign cbo_b_valid[2]    = mx_i2.b_valid;
   assign mx_i2.b_ready     = cbo_b_ready[2];
   assign cbo_r_id[2]       = mx_i2.r_id;
   assign cbo_r_data[2]     = mx_i2.r_data;
   assign cbo_r_resp[2]     = mx_i2.r_resp;
   assign cbo_r_last[2]     = mx_i2.r_last;
   assign cbo_r_user[2]     = mx_i2.r_user;
   assign cbo_r_valid[2]    = mx_i2.r_valid;
   assign mx_i2.r_ready     = cbo_r_ready[2];

   assign mx_i3.aw_id       = cbo_aw_id[3];
   assign mx_i3.aw_addr     = cbo_aw_addr[3];
   assign mx_i3.aw_len      = cbo_aw_len[3];
   assign mx_i3.aw_size     = cbo_aw_size[3];
   assign mx_i3.aw_burst    = cbo_aw_burst[3];
   assign mx_i3.aw_lock     = cbo_aw_lock[3];
   assign mx_i3.aw_cache    = cbo_aw_cache[3];
   assign mx_i3.aw_prot     = cbo_aw_prot[3];
   assign mx_i3.aw_qos      = cbo_aw_qos[3];
   assign mx_i3.aw_region   = cbo_aw_region[3];
   assign mx_i3.aw_user     = cbo_aw_user[3];
   assign mx_i3.aw_valid    = cbo_aw_valid[3];
   assign cbo_aw_ready[3]   = mx_i3.aw_ready;
   assign mx_i3.ar_id       = cbo_ar_id[3];
   assign mx_i3.ar_addr     = cbo_ar_addr[3];
   assign mx_i3.ar_len      = cbo_ar_len[3];
   assign mx_i3.ar_size     = cbo_ar_size[3];
   assign mx_i3.ar_burst    = cbo_ar_burst[3];
   assign mx_i3.ar_lock     = cbo_ar_lock[3];
   assign mx_i3.ar_cache    = cbo_ar_cache[3];
   assign mx_i3.ar_prot     = cbo_ar_prot[3];
   assign mx_i3.ar_qos      = cbo_ar_qos[3];
   assign mx_i3.ar_region   = cbo_ar_region[3];
   assign mx_i3.ar_user     = cbo_ar_user[3];
   assign mx_i3.ar_valid    = cbo_ar_valid[3];
   assign cbo_ar_ready[3]   = mx_i3.ar_ready;
   assign mx_i3.w_data      = cbo_w_data[3];
   assign mx_i3.w_strb      = cbo_w_strb[3];
   assign mx_i3.w_last      = cbo_w_last[3];
   assign mx_i3.w_user      = cbo_w_user[3];
   assign mx_i3.w_valid     = cbo_w_valid[3];
   assign cbo_w_ready[3]    = mx_i3.w_ready;
   assign cbo_b_id[3]       = mx_i3.b_id;
   assign cbo_b_resp[3]     = mx_i3.b_resp;
   assign cbo_b_user[3]     = mx_i3.b_user;
   assign cbo_b_valid[3]    = mx_i3.b_valid;
   assign mx_i3.b_ready     = cbo_b_ready[3];
   assign cbo_r_id[3]       = mx_i3.r_id;
   assign cbo_r_data[3]     = mx_i3.r_data;
   assign cbo_r_resp[3]     = mx_i3.r_resp;
   assign cbo_r_last[3]     = mx_i3.r_last;
   assign cbo_r_user[3]     = mx_i3.r_user;
   assign cbo_r_valid[3]    = mx_i3.r_valid;
   assign mx_i3.r_ready     = cbo_r_ready[3];

   assign mx_i4.aw_id       = cbo_aw_id[4];
   assign mx_i4.aw_addr     = cbo_aw_addr[4];
   assign mx_i4.aw_len      = cbo_aw_len[4];
   assign mx_i4.aw_size     = cbo_aw_size[4];
   assign mx_i4.aw_burst    = cbo_aw_burst[4];
   assign mx_i4.aw_lock     = cbo_aw_lock[4];
   assign mx_i4.aw_cache    = cbo_aw_cache[4];
   assign mx_i4.aw_prot     = cbo_aw_prot[4];
   assign mx_i4.aw_qos      = cbo_aw_qos[4];
   assign mx_i4.aw_region   = cbo_aw_region[4];
   assign mx_i4.aw_user     = cbo_aw_user[4];
   assign mx_i4.aw_valid    = cbo_aw_valid[4];
   assign cbo_aw_ready[4]   = mx_i4.aw_ready;
   assign mx_i4.ar_id       = cbo_ar_id[4];
   assign mx_i4.ar_addr     = cbo_ar_addr[4];
   assign mx_i4.ar_len      = cbo_ar_len[4];
   assign mx_i4.ar_size     = cbo_ar_size[4];
   assign mx_i4.ar_burst    = cbo_ar_burst[4];
   assign mx_i4.ar_lock     = cbo_ar_lock[4];
   assign mx_i4.ar_cache    = cbo_ar_cache[4];
   assign mx_i4.ar_prot     = cbo_ar_prot[4];
   assign mx_i4.ar_qos      = cbo_ar_qos[4];
   assign mx_i4.ar_region   = cbo_ar_region[4];
   assign mx_i4.ar_user     = cbo_ar_user[4];
   assign mx_i4.ar_valid    = cbo_ar_valid[4];
   assign cbo_ar_ready[4]   = mx_i4.ar_ready;
   assign mx_i4.w_data      = cbo_w_data[4];
   assign mx_i4.w_strb      = cbo_w_strb[4];
   assign mx_i4.w_last      = cbo_w_last[4];
   assign mx_i4.w_user      = cbo_w_user[4];
   assign mx_i4.w_valid     = cbo_w_valid[4];
   assign cbo_w_ready[4]    = mx_i4.w_ready;
   assign cbo_b_id[4]       = mx_i4.b_id;
   assign cbo_b_resp[4]     = mx_i4.b_resp;
   assign cbo_b_user[4]     = mx_i4.b_user;
   assign cbo_b_valid[4]    = mx_i4.b_valid;
   assign mx_i4.b_ready     = cbo_b_ready[4];
   assign cbo_r_id[4]       = mx_i4.r_id;
   assign cbo_r_data[4]     = mx_i4.r_data;
   assign cbo_r_resp[4]     = mx_i4.r_resp;
   assign cbo_r_last[4]     = mx_i4.r_last;
   assign cbo_r_user[4]     = mx_i4.r_user;
   assign cbo_r_valid[4]    = mx_i4.r_valid;
   assign mx_i4.r_ready     = cbo_r_ready[4];

   assign mx_i5.aw_id       = cbo_aw_id[5];
   assign mx_i5.aw_addr     = cbo_aw_addr[5];
   assign mx_i5.aw_len      = cbo_aw_len[5];
   assign mx_i5.aw_size     = cbo_aw_size[5];
   assign mx_i5.aw_burst    = cbo_aw_burst[5];
   assign mx_i5.aw_lock     = cbo_aw_lock[5];
   assign mx_i5.aw_cache    = cbo_aw_cache[5];
   assign mx_i5.aw_prot     = cbo_aw_prot[5];
   assign mx_i5.aw_qos      = cbo_aw_qos[5];
   assign mx_i5.aw_region   = cbo_aw_region[5];
   assign mx_i5.aw_user     = cbo_aw_user[5];
   assign mx_i5.aw_valid    = cbo_aw_valid[5];
   assign cbo_aw_ready[5]   = mx_i5.aw_ready;
   assign mx_i5.ar_id       = cbo_ar_id[5];
   assign mx_i5.ar_addr     = cbo_ar_addr[5];
   assign mx_i5.ar_len      = cbo_ar_len[5];
   assign mx_i5.ar_size     = cbo_ar_size[5];
   assign mx_i5.ar_burst    = cbo_ar_burst[5];
   assign mx_i5.ar_lock     = cbo_ar_lock[5];
   assign mx_i5.ar_cache    = cbo_ar_cache[5];
   assign mx_i5.ar_prot     = cbo_ar_prot[5];
   assign mx_i5.ar_qos      = cbo_ar_qos[5];
   assign mx_i5.ar_region   = cbo_ar_region[5];
   assign mx_i5.ar_user     = cbo_ar_user[5];
   assign mx_i5.ar_valid    = cbo_ar_valid[5];
   assign cbo_ar_ready[5]   = mx_i5.ar_ready;
   assign mx_i5.w_data      = cbo_w_data[5];
   assign mx_i5.w_strb      = cbo_w_strb[5];
   assign mx_i5.w_last      = cbo_w_last[5];
   assign mx_i5.w_user      = cbo_w_user[5];
   assign mx_i5.w_valid     = cbo_w_valid[5];
   assign cbo_w_ready[5]    = mx_i5.w_ready;
   assign cbo_b_id[5]       = mx_i5.b_id;
   assign cbo_b_resp[5]     = mx_i5.b_resp;
   assign cbo_b_user[5]     = mx_i5.b_user;
   assign cbo_b_valid[5]    = mx_i5.b_valid;
   assign mx_i5.b_ready     = cbo_b_ready[5];
   assign cbo_r_id[5]       = mx_i5.r_id;
   assign cbo_r_data[5]     = mx_i5.r_data;
   assign cbo_r_resp[5]     = mx_i5.r_resp;
   assign cbo_r_last[5]     = mx_i5.r_last;
   assign cbo_r_user[5]     = mx_i5.r_user;
   assign cbo_r_valid[5]    = mx_i5.r_valid;
   assign mx_i5.r_ready     = cbo_r_ready[5];

   assign mx_i6.aw_id       = cbo_aw_id[6];
   assign mx_i6.aw_addr     = cbo_aw_addr[6];
   assign mx_i6.aw_len      = cbo_aw_len[6];
   assign mx_i6.aw_size     = cbo_aw_size[6];
   assign mx_i6.aw_burst    = cbo_aw_burst[6];
   assign mx_i6.aw_lock     = cbo_aw_lock[6];
   assign mx_i6.aw_cache    = cbo_aw_cache[6];
   assign mx_i6.aw_prot     = cbo_aw_prot[6];
   assign mx_i6.aw_qos      = cbo_aw_qos[6];
   assign mx_i6.aw_region   = cbo_aw_region[6];
   assign mx_i6.aw_user     = cbo_aw_user[6];
   assign mx_i6.aw_valid    = cbo_aw_valid[6];
   assign cbo_aw_ready[6]   = mx_i6.aw_ready;
   assign mx_i6.ar_id       = cbo_ar_id[6];
   assign mx_i6.ar_addr     = cbo_ar_addr[6];
   assign mx_i6.ar_len      = cbo_ar_len[6];
   assign mx_i6.ar_size     = cbo_ar_size[6];
   assign mx_i6.ar_burst    = cbo_ar_burst[6];
   assign mx_i6.ar_lock     = cbo_ar_lock[6];
   assign mx_i6.ar_cache    = cbo_ar_cache[6];
   assign mx_i6.ar_prot     = cbo_ar_prot[6];
   assign mx_i6.ar_qos      = cbo_ar_qos[6];
   assign mx_i6.ar_region   = cbo_ar_region[6];
   assign mx_i6.ar_user     = cbo_ar_user[6];
   assign mx_i6.ar_valid    = cbo_ar_valid[6];
   assign cbo_ar_ready[6]   = mx_i6.ar_ready;
   assign mx_i6.w_data      = cbo_w_data[6];
   assign mx_i6.w_strb      = cbo_w_strb[6];
   assign mx_i6.w_last      = cbo_w_last[6];
   assign mx_i6.w_user      = cbo_w_user[6];
   assign mx_i6.w_valid     = cbo_w_valid[6];
   assign cbo_w_ready[6]    = mx_i6.w_ready;
   assign cbo_b_id[6]       = mx_i6.b_id;
   assign cbo_b_resp[6]     = mx_i6.b_resp;
   assign cbo_b_user[6]     = mx_i6.b_user;
   assign cbo_b_valid[6]    = mx_i6.b_valid;
   assign mx_i6.b_ready     = cbo_b_ready[6];
   assign cbo_r_id[6]       = mx_i6.r_id;
   assign cbo_r_data[6]     = mx_i6.r_data;
   assign cbo_r_resp[6]     = mx_i6.r_resp;
   assign cbo_r_last[6]     = mx_i6.r_last;
   assign cbo_r_user[6]     = mx_i6.r_user;
   assign cbo_r_valid[6]    = mx_i6.r_valid;
   assign mx_i6.r_ready     = cbo_r_ready[6];

   assign mx_i7.aw_id       = cbo_aw_id[7];
   assign mx_i7.aw_addr     = cbo_aw_addr[7];
   assign mx_i7.aw_len      = cbo_aw_len[7];
   assign mx_i7.aw_size     = cbo_aw_size[7];
   assign mx_i7.aw_burst    = cbo_aw_burst[7];
   assign mx_i7.aw_lock     = cbo_aw_lock[7];
   assign mx_i7.aw_cache    = cbo_aw_cache[7];
   assign mx_i7.aw_prot     = cbo_aw_prot[7];
   assign mx_i7.aw_qos      = cbo_aw_qos[7];
   assign mx_i7.aw_region   = cbo_aw_region[7];
   assign mx_i7.aw_user     = cbo_aw_user[7];
   assign mx_i7.aw_valid    = cbo_aw_valid[7];
   assign cbo_aw_ready[7]   = mx_i7.aw_ready;
   assign mx_i7.ar_id       = cbo_ar_id[7];
   assign mx_i7.ar_addr     = cbo_ar_addr[7];
   assign mx_i7.ar_len      = cbo_ar_len[7];
   assign mx_i7.ar_size     = cbo_ar_size[7];
   assign mx_i7.ar_burst    = cbo_ar_burst[7];
   assign mx_i7.ar_lock     = cbo_ar_lock[7];
   assign mx_i7.ar_cache    = cbo_ar_cache[7];
   assign mx_i7.ar_prot     = cbo_ar_prot[7];
   assign mx_i7.ar_qos      = cbo_ar_qos[7];
   assign mx_i7.ar_region   = cbo_ar_region[7];
   assign mx_i7.ar_user     = cbo_ar_user[7];
   assign mx_i7.ar_valid    = cbo_ar_valid[7];
   assign cbo_ar_ready[7]   = mx_i7.ar_ready;
   assign mx_i7.w_data      = cbo_w_data[7];
   assign mx_i7.w_strb      = cbo_w_strb[7];
   assign mx_i7.w_last      = cbo_w_last[7];
   assign mx_i7.w_user      = cbo_w_user[7];
   assign mx_i7.w_valid     = cbo_w_valid[7];
   assign cbo_w_ready[7]    = mx_i7.w_ready;
   assign cbo_b_id[7]       = mx_i7.b_id;
   assign cbo_b_resp[7]     = mx_i7.b_resp;
   assign cbo_b_user[7]     = mx_i7.b_user;
   assign cbo_b_valid[7]    = mx_i7.b_valid;
   assign mx_i7.b_ready     = cbo_b_ready[7];
   assign cbo_r_id[7]       = mx_i7.r_id;
   assign cbo_r_data[7]     = mx_i7.r_data;
   assign cbo_r_resp[7]     = mx_i7.r_resp;
   assign cbo_r_last[7]     = mx_i7.r_last;
   assign cbo_r_user[7]     = mx_i7.r_user;
   assign cbo_r_valid[7]    = mx_i7.r_valid;
   assign mx_i7.r_ready     = cbo_r_ready[7];

   // do the matrix connection
   generate
      for(i=0; i<8; i++)
        for(j=0; j<8; j++) begin
           assign cbo_aw_id[i][j]      = cbi_aw_id[j][i];
           assign cbo_aw_addr[i][j]    = cbi_aw_addr[j][i];
           assign cbo_aw_len[i][j]     = cbi_aw_len[j][i];
           assign cbo_aw_size[i][j]    = cbi_aw_size[j][i];
           assign cbo_aw_burst[i][j]   = cbi_aw_burst[j][i];
           assign cbo_aw_lock[i][j]    = cbi_aw_lock[j][i];
           assign cbo_aw_cache[i][j]   = cbi_aw_cache[j][i];
           assign cbo_aw_prot[i][j]    = cbi_aw_prot[j][i];
           assign cbo_aw_qos[i][j]     = cbi_aw_qos[j][i];
           assign cbo_aw_region[i][j]  = cbi_aw_region[j][i];
           assign cbo_aw_user[i][j]    = cbi_aw_user[j][i];
           assign cbo_aw_valid[i][j]   = cbi_aw_valid[j][i];
           assign cbi_aw_ready[j][i]   = cbo_aw_ready[i][j];
           assign cbo_ar_id[i][j]      = cbi_ar_id[j][i];
           assign cbo_ar_addr[i][j]    = cbi_ar_addr[j][i];
           assign cbo_ar_len[i][j]     = cbi_ar_len[j][i];
           assign cbo_ar_size[i][j]    = cbi_ar_size[j][i];
           assign cbo_ar_burst[i][j]   = cbi_ar_burst[j][i];
           assign cbo_ar_lock[i][j]    = cbi_ar_lock[j][i];
           assign cbo_ar_cache[i][j]   = cbi_ar_cache[j][i];
           assign cbo_ar_prot[i][j]    = cbi_ar_prot[j][i];
           assign cbo_ar_qos[i][j]     = cbi_ar_qos[j][i];
           assign cbo_ar_region[i][j]  = cbi_ar_region[j][i];
           assign cbo_ar_user[i][j]    = cbi_ar_user[j][i];
           assign cbo_ar_valid[i][j]   = cbi_ar_valid[j][i];
           assign cbi_ar_ready[j][i]   = cbo_ar_ready[i][j];
           assign cbo_w_data[i][j]     = cbi_w_data[j][i];
           assign cbo_w_strb[i][j]     = cbi_w_strb[j][i];
           assign cbo_w_last[i][j]     = cbi_w_last[j][i];
           assign cbo_w_user[i][j]     = cbi_w_user[j][i];
           assign cbo_w_valid[i][j]    = cbi_w_valid[j][i];
           assign cbi_w_ready[j][i]    = cbo_w_ready[i][j];
           assign cbi_b_id[j][i]       = cbo_b_id[i][j];
           assign cbi_b_resp[j][i]     = cbo_b_resp[i][j];
           assign cbi_b_user[j][i]     = cbo_b_user[i][j];
           assign cbi_b_valid[j][i]    = cbo_b_valid[i][j];
           assign cbo_b_ready[i][j]    = cbi_b_ready[j][i];
           assign cbi_r_id[j][i]       = cbo_r_id[i][j];
           assign cbi_r_data[j][i]     = cbo_r_data[i][j];
           assign cbi_r_resp[j][i]     = cbo_r_resp[i][j];
           assign cbi_r_last[j][i]     = cbo_r_last[i][j];
           assign cbi_r_user[j][i]     = cbo_r_user[i][j];
           assign cbi_r_valid[j][i]    = cbo_r_valid[i][j];
           assign cbo_r_ready[i][j]    = cbi_r_ready[j][i];
        end // for (j=0; j<8; j++)
   endgenerate

   // multiplexers
   nasti_mux #(.W_MAX(W_MAX), .R_MAX(R_MAX),
               .ID_WIDTH(ID_WIDTH), .ADDR_WIDTH(ADDR_WIDTH),
               .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH),
               .LITE_MODE(LITE_MODE))
   mux0 (.*, .s(mx_i0), .m(ob_i0));

   nasti_mux #(.W_MAX(W_MAX), .R_MAX(R_MAX),
               .ID_WIDTH(ID_WIDTH), .ADDR_WIDTH(ADDR_WIDTH),
               .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH),
               .LITE_MODE(LITE_MODE))
   mux1 (.*, .s(mx_i1), .m(ob_i1));

   nasti_mux #(.W_MAX(W_MAX), .R_MAX(R_MAX),
               .ID_WIDTH(ID_WIDTH), .ADDR_WIDTH(ADDR_WIDTH),
               .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH),
               .LITE_MODE(LITE_MODE))
   mux2 (.*, .s(mx_i2), .m(ob_i2));

   nasti_mux #(.W_MAX(W_MAX), .R_MAX(R_MAX),
               .ID_WIDTH(ID_WIDTH), .ADDR_WIDTH(ADDR_WIDTH),
               .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH),
               .LITE_MODE(LITE_MODE))
   mux3 (.*, .s(mx_i3), .m(ob_i3));

   nasti_mux #(.W_MAX(W_MAX), .R_MAX(R_MAX),
               .ID_WIDTH(ID_WIDTH), .ADDR_WIDTH(ADDR_WIDTH),
               .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH),
               .LITE_MODE(LITE_MODE))
   mux4 (.*, .s(mx_i4), .m(ob_i4));

   nasti_mux #(.W_MAX(W_MAX), .R_MAX(R_MAX),
               .ID_WIDTH(ID_WIDTH), .ADDR_WIDTH(ADDR_WIDTH),
               .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH))
   mux5 (.*, .s(mx_i5), .m(ob_i5));

   nasti_mux #(.W_MAX(W_MAX), .R_MAX(R_MAX),
               .ID_WIDTH(ID_WIDTH), .ADDR_WIDTH(ADDR_WIDTH),
               .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH),
               .LITE_MODE(LITE_MODE))
   mux6 (.*, .s(mx_i6), .m(ob_i6));

   nasti_mux #(.W_MAX(W_MAX), .R_MAX(R_MAX),
               .ID_WIDTH(ID_WIDTH), .ADDR_WIDTH(ADDR_WIDTH),
               .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH),
               .LITE_MODE(LITE_MODE))
   mux7 (.*, .s(mx_i7), .m(ob_i7));

   // combine channel and possibly insert output buffers
   nasti_channel_combiner #(N_OUTPUT)
   output_combiner (
                    .s0 ( ob_o0  ), .s1 ( ob_o1  ), .s2 ( ob_o2  ), .s3 ( ob_o3  ),
                    .s4 ( ob_o4  ), .s5 ( ob_o5  ), .s6 ( ob_o6  ), .s7 ( ob_o7  ),
                    .m  ( m      ));

   nasti_buf #(.DEPTH(OB_DEPTH), .ID_WIDTH(ID_WIDTH), .ADDR_WIDTH(ADDR_WIDTH),
               .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH),
               .BUF_REQ(OB_DEPTH), .BUF_RESP(OB_DEPTH))
   obuf0 (.*, .s(ob_i0), .m(ob_o0));

   nasti_buf #(.DEPTH(OB_DEPTH), .ID_WIDTH(ID_WIDTH), .ADDR_WIDTH(ADDR_WIDTH),
               .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH),
               .BUF_REQ(OB_DEPTH), .BUF_RESP(OB_DEPTH))
   obuf1 (.*, .s(ob_i1), .m(ob_o1));

   nasti_buf #(.DEPTH(OB_DEPTH), .ID_WIDTH(ID_WIDTH), .ADDR_WIDTH(ADDR_WIDTH),
               .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH),
               .BUF_REQ(OB_DEPTH), .BUF_RESP(OB_DEPTH))
   obuf2 (.*, .s(ob_i2), .m(ob_o2));

   nasti_buf #(.DEPTH(OB_DEPTH), .ID_WIDTH(ID_WIDTH), .ADDR_WIDTH(ADDR_WIDTH),
               .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH),
               .BUF_REQ(OB_DEPTH), .BUF_RESP(OB_DEPTH))
   obuf3 (.*, .s(ob_i3), .m(ob_o3));

   nasti_buf #(.DEPTH(OB_DEPTH), .ID_WIDTH(ID_WIDTH), .ADDR_WIDTH(ADDR_WIDTH),
               .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH),
               .BUF_REQ(OB_DEPTH), .BUF_RESP(OB_DEPTH))
   obuf4 (.*, .s(ob_i4), .m(ob_o4));

   nasti_buf #(.DEPTH(OB_DEPTH), .ID_WIDTH(ID_WIDTH), .ADDR_WIDTH(ADDR_WIDTH),
               .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH),
               .BUF_REQ(OB_DEPTH), .BUF_RESP(OB_DEPTH))
   obuf5 (.*, .s(ob_i5), .m(ob_o5));

   nasti_buf #(.DEPTH(OB_DEPTH), .ID_WIDTH(ID_WIDTH), .ADDR_WIDTH(ADDR_WIDTH),
               .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH),
               .BUF_REQ(OB_DEPTH), .BUF_RESP(OB_DEPTH))
   obuf6 (.*, .s(ob_i6), .m(ob_o6));

   nasti_buf #(.DEPTH(OB_DEPTH), .ID_WIDTH(ID_WIDTH), .ADDR_WIDTH(ADDR_WIDTH),
               .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH),
               .BUF_REQ(OB_DEPTH), .BUF_RESP(OB_DEPTH))
   obuf7 (.*, .s(ob_i7), .m(ob_o7));

endmodule // nasti_crossbar
