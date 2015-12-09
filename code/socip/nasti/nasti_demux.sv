// See LICENSE for license details.

// up to 8 master ports
module nasti_demux
  #(
    ID_WIDTH = 1,               // id width
    ADDR_WIDTH = 8,             // address width
    DATA_WIDTH = 8,             // width of data
    USER_WIDTH = 1,             // width of user field, must > 0, let synthesizer trim it if not in use
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

   genvar i;

   // function to find active channel
   function logic [2:0] sel_active (logic [7:0] rdy);
      // assume rdy arbitrated and one-hot
      int i;
      for(i=0; i<8; i++)
        if(rdy[i]) return i;
      return 0;
   endfunction // sel_active

   // port matcher
   function logic [2:0] port_match(logic [ADDR_WIDTH-1:0] addr);
      if(MASK0 != 0 && (addr & ~MASK0) == BASE0) return 0;
      if(MASK1 != 0 && (addr & ~MASK1) == BASE1) return 1;
      if(MASK2 != 0 && (addr & ~MASK2) == BASE2) return 2;
      if(MASK3 != 0 && (addr & ~MASK3) == BASE3) return 3;
      if(MASK4 != 0 && (addr & ~MASK4) == BASE4) return 4;
      if(MASK5 != 0 && (addr & ~MASK5) == BASE5) return 5;
      if(MASK6 != 0 && (addr & ~MASK6) == BASE6) return 6;
      if(MASK7 != 0 && (addr & ~MASK7) == BASE7) return 7;
      return 0;
   endfunction // port_match

   // AW and W channels
   logic       lock;
   logic [2:0] locked_port;
   logic [2:0] aw_port_sel;

   assign aw_port_sel = lock ? locked_port : port_match(s.aw_addr);

   always_ff @(posedge clk or negedge rstn)
     if(!rstn)
       lock <= 1'b0;
     else if(s.aw_valid && s.aw_ready) begin
        lock <= 1'b1;
        locked_port <= aw_port_sel;
     end else if((LITE_MODE || s.w_last) && s.w_valid && s.w_ready)
       lock <= 1'b0;

   generate
      for(i=0; i<8; i++) begin
         assign m.aw_id[i]      = s.aw_id;
         assign m.aw_addr[i]    = s.aw_addr;
         assign m.aw_len[i]     = s.aw_len;
         assign m.aw_size[i]    = s.aw_size;
         assign m.aw_burst[i]   = s.aw_burst;
         assign m.aw_lock[i]    = s.aw_lock;
         assign m.aw_cache[i]   = s.aw_cache;
         assign m.aw_prot[i]    = s.aw_prot;
         assign m.aw_qos[i]     = s.aw_qos;
         assign m.aw_region[i]  = s.aw_region;
         assign m.aw_user[i]    = s.aw_user;
         assign m.aw_valid[i]   = !lock && aw_port_sel == i && s.aw_valid;
         assign m.w_data[i]     = s.w_data;
         assign m.w_strb[i]     = s.w_strb;
         assign m.w_last[i]     = s.w_last;
         assign m.w_user[i]     = s.w_user;
         assign m.w_valid[i]    = lock && aw_port_sel == i && s.w_valid;
      end // for (i=0; i<8; i++)
   endgenerate

   assign s.aw_ready = !lock && m.aw_ready[aw_port_sel];
   assign s.w_ready = lock && m.w_ready[aw_port_sel];

   // AR channel
   logic [2:0] ar_port_sel;
   assign ar_port_sel = port_match(s.ar_addr);

   generate
      for(i=0; i<8; i++) begin
         assign m.ar_id[i]      = s.ar_id;
         assign m.ar_addr[i]    = s.ar_addr;
         assign m.ar_len[i]     = s.ar_len;
         assign m.ar_size[i]    = s.ar_size;
         assign m.ar_burst[i]   = s.ar_burst;
         assign m.ar_lock[i]    = s.ar_lock;
         assign m.ar_cache[i]   = s.ar_cache;
         assign m.ar_prot[i]    = s.ar_prot;
         assign m.ar_qos[i]     = s.ar_qos;
         assign m.ar_region[i]  = s.ar_region;
         assign m.ar_user[i]    = s.ar_user;
         assign m.ar_valid[i]   = ar_port_sel == i && s.ar_valid;
      end // for (i=0; i<8; i++)
   endgenerate

   assign s.ar_ready = m.ar_ready[ar_port_sel];
   
   // B channel
   logic [7:0] b_valid, b_gnt;
   logic [2:0] b_port_sel;

   assign b_valid[0] = (MASK0 != 0) && m.b_valid[0];
   assign b_valid[1] = (MASK1 != 0) && m.b_valid[1];
   assign b_valid[2] = (MASK2 != 0) && m.b_valid[2];
   assign b_valid[3] = (MASK3 != 0) && m.b_valid[3];
   assign b_valid[4] = (MASK4 != 0) && m.b_valid[4];
   assign b_valid[5] = (MASK5 != 0) && m.b_valid[5];
   assign b_valid[6] = (MASK6 != 0) && m.b_valid[6];
   assign b_valid[7] = (MASK7 != 0) && m.b_valid[7];

   arbiter_rr #(8)
   b_arb (
          .*,
          .req     ( b_valid ),
          .gnt     ( b_gnt   ),
          .enable  ( 1'b1    )
          );
   assign b_port_sel = sel_active(b_gnt);

   assign s.b_id    = m.b_id[b_port_sel];
   assign s.b_resp  = m.b_resp[b_port_sel];
   assign s.b_user  = m.b_user[b_port_sel];
   assign s.b_valid = m.b_valid[b_port_sel];
   assign m.b_ready = s.b_ready ? b_gnt : 0;

   // R channel
   logic [7:0] r_valid, r_gnt;
   logic [2:0] r_port_sel;

   assign r_valid[0] = (MASK0 != 0) && m.r_valid[0];
   assign r_valid[1] = (MASK1 != 0) && m.r_valid[1];
   assign r_valid[2] = (MASK2 != 0) && m.r_valid[2];
   assign r_valid[3] = (MASK3 != 0) && m.r_valid[3];
   assign r_valid[4] = (MASK4 != 0) && m.r_valid[4];
   assign r_valid[5] = (MASK5 != 0) && m.r_valid[5];
   assign r_valid[6] = (MASK6 != 0) && m.r_valid[6];
   assign r_valid[7] = (MASK7 != 0) && m.r_valid[7];

   arbiter_rr #(8)
   r_arb (
          .*,
          .req     ( r_valid ),
          .gnt     ( r_gnt   ),
          .enable  ( 1'b1    )
          );
   assign r_port_sel = sel_active(r_gnt);

   assign s.r_id    = m.r_id[r_port_sel];
   assign s.r_data  = m.r_data[r_port_sel];
   assign s.r_resp  = m.r_resp[r_port_sel];
   assign s.r_last  = m.r_last[r_port_sel];
   assign s.r_user  = m.r_user[r_port_sel];
   assign s.r_valid = m.r_valid[r_port_sel];
   assign m.r_ready = s.r_ready ? r_gnt : 0;

endmodule // nasti_demux
