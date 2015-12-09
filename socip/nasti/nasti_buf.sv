// See LICENSE for license details.

module nasti_buf
  #(
    DEPTH = 1,                  // buffer depth
    ID_WIDTH = 1,               // id width
    ADDR_WIDTH = 8,             // address width
    DATA_WIDTH = 8,             // width of data
    USER_WIDTH = 1,             // width of user field, must > 0, let synthesizer trim it if not in use
    BUF_REQ = 1,                // whether to buffer for AW/AR/W
    BUF_RESP = 1                // whether to buffer B/R
    )
   (
    input clk, rstn,
    nasti_channel.slave s,
    nasti_channel.master m
    );

   localparam DEPTH_LOC = DEPTH == 0 ? 1 : DEPTH;

   // a little bit awkward implementation due to the fact that
   // isim (Xilinx) is not happy with parameterized assign.
   // Code such as:
   //
   // generate
   //   if(A)
   //      assign sig = 1;
   //   else
   //      assign sig = 2;
   // endgenerate
   //
   // may result into sig == x
   //
   // but
   //
   // assign sig = A ? 1 : 2;
   //
   // seems working.
   //
   // And it is not happy with struct
   // Force me to use simple arrays

   function logic [$clog2(DEPTH_LOC)-1:0] incr(logic [$clog2(DEPTH_LOC)-1:0] p);
      logic [$clog2(DEPTH_LOC):0] p_incr;
      p_incr = {1'b0,p} + 1;
      return p_incr >= DEPTH_LOC ? p_incr - DEPTH_LOC : p_incr;
   endfunction // incr

   // AW
   logic [ID_WIDTH-1:0]           aw_q_id     [DEPTH_LOC-1:0];
   logic [ADDR_WIDTH-1:0]         aw_q_addr   [DEPTH_LOC-1:0];
   logic [7:0]                    aw_q_len    [DEPTH_LOC-1:0];
   logic [2:0]                    aw_q_size   [DEPTH_LOC-1:0];
   logic [1:0]                    aw_q_burst  [DEPTH_LOC-1:0];
   logic                          aw_q_lock   [DEPTH_LOC-1:0];
   logic [3:0]                    aw_q_cache  [DEPTH_LOC-1:0];
   logic [2:0]                    aw_q_prot   [DEPTH_LOC-1:0];
   logic [3:0]                    aw_q_qos    [DEPTH_LOC-1:0];
   logic [3:0]                    aw_q_region [DEPTH_LOC-1:0];
   logic [USER_WIDTH-1:0]         aw_q_user   [DEPTH_LOC-1:0];
   logic [DEPTH_LOC-1:0]          aw_valid;
   logic [$clog2(DEPTH_LOC)-1:0]  aw_wp, aw_rp;

   always_ff @(posedge clk or negedge rstn)
     if(!rstn) begin
        aw_rp <= 0;
        aw_wp <= 0;
        aw_valid <= 0;
     end else begin
        if(s.aw_valid && s.aw_ready) begin
           aw_wp <= incr(aw_wp);
           aw_valid[aw_wp] <= 1'b1;
        end

        if(m.aw_valid && m.aw_ready) begin
           aw_rp <= incr(aw_rp);
           aw_valid[aw_rp] <= 1'b0;
        end
     end

   always_ff @(posedge clk)
     if(s.aw_valid && s.aw_ready) begin
        aw_q_id    [aw_wp] <= s.aw_id;
        aw_q_addr  [aw_wp] <= s.aw_addr;
        aw_q_len   [aw_wp] <= s.aw_len;
        aw_q_size  [aw_wp] <= s.aw_size;
        aw_q_burst [aw_wp] <= s.aw_burst;
        aw_q_lock  [aw_wp] <= s.aw_lock;
        aw_q_cache [aw_wp] <= s.aw_cache;
        aw_q_prot  [aw_wp] <= s.aw_prot;
        aw_q_qos   [aw_wp] <= s.aw_qos;
        aw_q_region[aw_wp] <= s.aw_region;
        aw_q_user  [aw_wp] <= s.aw_user;
     end // if (s.aw_valid && s.aw_ready)

   assign s.aw_ready  = BUF_REQ && DEPTH > 0 ? !aw_valid[aw_wp]   : m.aw_ready;
   assign m.aw_id     = BUF_REQ && DEPTH > 0 ? aw_q_id    [aw_rp] : s.aw_id;
   assign m.aw_addr   = BUF_REQ && DEPTH > 0 ? aw_q_addr  [aw_rp] : s.aw_addr;
   assign m.aw_len    = BUF_REQ && DEPTH > 0 ? aw_q_len   [aw_rp] : s.aw_len;
   assign m.aw_size   = BUF_REQ && DEPTH > 0 ? aw_q_size  [aw_rp] : s.aw_size;
   assign m.aw_burst  = BUF_REQ && DEPTH > 0 ? aw_q_burst [aw_rp] : s.aw_burst;
   assign m.aw_lock   = BUF_REQ && DEPTH > 0 ? aw_q_lock  [aw_rp] : s.aw_lock;
   assign m.aw_cache  = BUF_REQ && DEPTH > 0 ? aw_q_cache [aw_rp] : s.aw_cache;
   assign m.aw_prot   = BUF_REQ && DEPTH > 0 ? aw_q_prot  [aw_rp] : s.aw_prot;
   assign m.aw_qos    = BUF_REQ && DEPTH > 0 ? aw_q_qos   [aw_rp] : s.aw_qos;
   assign m.aw_region = BUF_REQ && DEPTH > 0 ? aw_q_region[aw_rp] : s.aw_region;
   assign m.aw_user   = BUF_REQ && DEPTH > 0 ? aw_q_user  [aw_rp] : s.aw_user;
   assign m.aw_valid  = BUF_REQ && DEPTH > 0 ? aw_valid[aw_rp]    : s.aw_valid;

   // AR
   logic [ID_WIDTH-1:0]           ar_q_id     [DEPTH_LOC-1:0];
   logic [ADDR_WIDTH-1:0]         ar_q_addr   [DEPTH_LOC-1:0];
   logic [7:0]                    ar_q_len    [DEPTH_LOC-1:0];
   logic [2:0]                    ar_q_size   [DEPTH_LOC-1:0];
   logic [1:0]                    ar_q_burst  [DEPTH_LOC-1:0];
   logic                          ar_q_lock   [DEPTH_LOC-1:0];
   logic [3:0]                    ar_q_cache  [DEPTH_LOC-1:0];
   logic [2:0]                    ar_q_prot   [DEPTH_LOC-1:0];
   logic [3:0]                    ar_q_qos    [DEPTH_LOC-1:0];
   logic [3:0]                    ar_q_region [DEPTH_LOC-1:0];
   logic [USER_WIDTH-1:0]         ar_q_user   [DEPTH_LOC-1:0];
   logic [DEPTH_LOC-1:0]          ar_valid;
   logic [$clog2(DEPTH_LOC)-1:0]  ar_wp, ar_rp;

   always_ff @(posedge clk or negedge rstn)
     if(!rstn) begin
        ar_rp <= 0;
        ar_wp <= 0;
        ar_valid <= 0;
     end else begin
        if(s.ar_valid && s.ar_ready) begin
           ar_wp <= incr(ar_wp);
           ar_valid[ar_wp] <= 1'b1;
        end

        if(m.ar_valid && m.ar_ready) begin
           ar_rp <= incr(ar_rp);
           ar_valid[ar_rp] <= 1'b0;
        end
     end

   always_ff @(posedge clk)
     if(s.ar_valid && s.ar_ready) begin
        ar_q_id    [ar_wp] <= s.ar_id;
        ar_q_addr  [ar_wp] <= s.ar_addr;
        ar_q_len   [ar_wp] <= s.ar_len;
        ar_q_size  [ar_wp] <= s.ar_size;
        ar_q_burst [ar_wp] <= s.ar_burst;
        ar_q_lock  [ar_wp] <= s.ar_lock;
        ar_q_cache [ar_wp] <= s.ar_cache;
        ar_q_prot  [ar_wp] <= s.ar_prot;
        ar_q_qos   [ar_wp] <= s.ar_qos;
        ar_q_region[ar_wp] <= s.ar_region;
        ar_q_user  [ar_wp] <= s.ar_user;
     end // if (s.ar_valid && s.ar_ready)

   assign s.ar_ready  = BUF_REQ && DEPTH > 0 ? !ar_valid[ar_wp]   : m.ar_ready;
   assign m.ar_id     = BUF_REQ && DEPTH > 0 ? ar_q_id    [ar_rp] : s.ar_id;
   assign m.ar_addr   = BUF_REQ && DEPTH > 0 ? ar_q_addr  [ar_rp] : s.ar_addr;
   assign m.ar_len    = BUF_REQ && DEPTH > 0 ? ar_q_len   [ar_rp] : s.ar_len;
   assign m.ar_size   = BUF_REQ && DEPTH > 0 ? ar_q_size  [ar_rp] : s.ar_size;
   assign m.ar_burst  = BUF_REQ && DEPTH > 0 ? ar_q_burst [ar_rp] : s.ar_burst;
   assign m.ar_lock   = BUF_REQ && DEPTH > 0 ? ar_q_lock  [ar_rp] : s.ar_lock;
   assign m.ar_cache  = BUF_REQ && DEPTH > 0 ? ar_q_cache [ar_rp] : s.ar_cache;
   assign m.ar_prot   = BUF_REQ && DEPTH > 0 ? ar_q_prot  [ar_rp] : s.ar_prot;
   assign m.ar_qos    = BUF_REQ && DEPTH > 0 ? ar_q_qos   [ar_rp] : s.ar_qos;
   assign m.ar_region = BUF_REQ && DEPTH > 0 ? ar_q_region[ar_rp] : s.ar_region;
   assign m.ar_user   = BUF_REQ && DEPTH > 0 ? ar_q_user  [ar_rp] : s.ar_user;
   assign m.ar_valid  = BUF_REQ && DEPTH > 0 ? ar_valid[ar_rp]    : s.ar_valid;

   // W
   logic [DATA_WIDTH-1:0]   w_q_data  [DEPTH_LOC-1:0];
   logic [DATA_WIDTH/8-1:0] w_q_strb  [DEPTH_LOC-1:0];
   logic                    w_q_last  [DEPTH_LOC-1:0];
   logic [USER_WIDTH-1:0]   w_q_user  [DEPTH_LOC-1:0];
   logic [DEPTH_LOC-1:0]    w_valid;
   logic [$clog2(DEPTH_LOC)-1:0] w_wp, w_rp;

   always_ff @(posedge clk or negedge rstn)
     if(!rstn) begin
        w_rp <= 0;
        w_wp <= 0;
        w_valid <= 0;
     end else begin
        if(s.w_valid && s.w_ready) begin
           w_wp <= incr(w_wp);
           w_valid[w_wp] <= 1'b1;
        end

        if(m.w_valid && m.w_ready) begin
           w_rp <= incr(w_rp);
           w_valid[w_rp] <= 1'b0;
        end
     end

   always_ff @(posedge clk)
     if(s.w_valid && s.w_ready) begin
        w_q_data[w_wp] <= s.w_data;
        w_q_strb[w_wp] <= s.w_strb;
        w_q_last[w_wp] <= s.w_last;
        w_q_user[w_wp] <= s.w_user;
     end

   assign s.w_ready = BUF_REQ && DEPTH > 0 ? !w_valid[w_wp] : m.w_ready;
   assign m.w_data  = BUF_REQ && DEPTH > 0 ? w_q_data[w_rp] : s.w_data;
   assign m.w_strb  = BUF_REQ && DEPTH > 0 ? w_q_strb[w_rp] : s.w_strb;
   assign m.w_last  = BUF_REQ && DEPTH > 0 ? w_q_last[w_rp] : s.w_last;
   assign m.w_user  = BUF_REQ && DEPTH > 0 ? w_q_user[w_rp] : s.w_user;
   assign m.w_valid = BUF_REQ && DEPTH > 0 ? w_valid[w_rp]  : s.w_valid;

   // B
   logic [ID_WIDTH-1:0]   b_q_id    [DEPTH_LOC-1:0];
   logic [1:0]            b_q_resp  [DEPTH_LOC-1:0];
   logic [USER_WIDTH-1:0] b_q_user  [DEPTH_LOC-1:0];
   logic [DEPTH_LOC-1:0]  b_valid;
   logic [$clog2(DEPTH_LOC)-1:0] b_wp, b_rp;

   always_ff @(posedge clk or negedge rstn)
     if(!rstn) begin
        b_rp <= 0;
        b_wp <= 0;
        b_valid <= 0;
     end else begin
        if(m.b_valid && m.b_ready) begin
           b_wp <= incr(b_wp);
           b_valid[b_wp] <= 1'b1;
        end

        if(s.b_valid && s.b_ready) begin
           b_rp <= incr(b_rp);
           b_valid[b_rp] <= 1'b0;
        end
     end

   always_ff @(posedge clk)
     if(m.b_valid && m.b_ready) begin
        b_q_id[b_wp]   <= m.b_id;
        b_q_resp[b_wp] <= m.b_resp;
        b_q_user[b_wp] <= m.b_user;
     end

   assign m.b_ready = BUF_RESP && DEPTH > 0 ? !b_valid[b_wp] : s.b_ready;
   assign s.b_id    = BUF_RESP && DEPTH > 0 ? b_q_id[b_rp]   : m.b_id;
   assign s.b_resp  = BUF_RESP && DEPTH > 0 ? b_q_resp[b_rp] : m.b_resp;
   assign s.b_user  = BUF_RESP && DEPTH > 0 ? b_q_user[b_rp] : m.b_user;
   assign s.b_valid = BUF_RESP && DEPTH > 0 ? b_valid[b_rp]  : m.b_valid;

   // R
   logic [DATA_WIDTH-1:0]   r_q_data  [DEPTH_LOC-1:0];
   logic [DATA_WIDTH/8-1:0] r_q_strb  [DEPTH_LOC-1:0];
   logic                    r_q_last  [DEPTH_LOC-1:0];
   logic [ID_WIDTH-1:0]     r_q_id    [DEPTH_LOC-1:0];
   logic [1:0]              r_q_resp  [DEPTH_LOC-1:0];
   logic [USER_WIDTH-1:0]   r_q_user  [DEPTH_LOC-1:0];
   logic [DEPTH_LOC-1:0]    r_valid;
   logic [$clog2(DEPTH_LOC)-1:0] r_wp, r_rp;

   always_ff @(posedge clk or negedge rstn)
     if(!rstn) begin
        r_rp <= 0;
        r_wp <= 0;
        r_valid <= 0;
     end else begin
        if(m.r_valid && m.r_ready) begin
           r_wp <= incr(r_wp);
           r_valid[r_wp] <= 1'b1;
        end

        if(s.r_valid && s.r_ready) begin
           r_rp <= incr(r_rp);
           r_valid[r_rp] <= 1'b0;
        end
     end

   always_ff @(posedge clk)
     if(m.r_valid && m.r_ready) begin
        r_q_id[r_wp]   <= m.r_id;
        r_q_data[r_wp] <= m.r_data;
        r_q_resp[r_wp] <= m.r_resp;
        r_q_last[r_wp] <= m.r_last;
        r_q_user[r_wp] <= m.r_user;
     end

   assign m.r_ready = BUF_RESP && DEPTH > 0 ? !r_valid[r_wp] : s.r_ready;
   assign s.r_id    = BUF_RESP && DEPTH > 0 ? r_q_id[r_rp]   : m.r_id;
   assign s.r_data  = BUF_RESP && DEPTH > 0 ? r_q_data[r_rp] : m.r_data;
   assign s.r_resp  = BUF_RESP && DEPTH > 0 ? r_q_resp[r_rp] : m.r_resp;
   assign s.r_last  = BUF_RESP && DEPTH > 0 ? r_q_last[r_rp] : m.r_last;
   assign s.r_user  = BUF_RESP && DEPTH > 0 ? r_q_user[r_rp] : m.r_user;
   assign s.r_valid = BUF_RESP && DEPTH > 0 ? r_valid[r_rp]  : m.r_valid;

endmodule // nasti_buf
