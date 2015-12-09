// See LICENSE for license details.

module nasti_lite_reader
  #(
    BUF_DEPTH = 2,              // depth of the buffer
    MAX_TRANSACTION = 2,        // the number of parallel transactions
    ID_WIDTH = 1,               // id width
    ADDR_WIDTH = 8,             // address width
    NASTI_DATA_WIDTH = 8,       // width of data on the nasti side
    LITE_DATA_WIDTH = 32,       // width of data on the nasti-lite side
    USER_WIDTH = 1              // width of user field, must > 0, let synthesizer trim it if not in use
    )
   (
    input  clk, rstn,
    input  [ID_WIDTH-1:0]           nasti_ar_id,
    input  [ADDR_WIDTH-1:0]         nasti_ar_addr,
    input  [7:0]                    nasti_ar_len,
    input  [2:0]                    nasti_ar_size,
    input  [1:0]                    nasti_ar_burst,
    input                           nasti_ar_lock,
    input  [3:0]                    nasti_ar_cache,
    input  [2:0]                    nasti_ar_prot,
    input  [3:0]                    nasti_ar_qos,
    input  [3:0]                    nasti_ar_region,
    input  [USER_WIDTH-1:0]         nasti_ar_user,
    input                           nasti_ar_valid,
    output                          nasti_ar_ready,

    output [ID_WIDTH-1:0]           nasti_r_id,
    output [NASTI_DATA_WIDTH-1:0]   nasti_r_data,
    output [1:0]                    nasti_r_resp,
    output                          nasti_r_last,
    output [USER_WIDTH-1:0]         nasti_r_user,
    output                          nasti_r_valid,
    input                           nasti_r_ready,

    output [ID_WIDTH-1:0]           lite_ar_id,
    output [ADDR_WIDTH-1:0]         lite_ar_addr,
    output [2:0]                    lite_ar_prot,
    output [3:0]                    lite_ar_qos,
    output [3:0]                    lite_ar_region,
    output [USER_WIDTH-1:0]         lite_ar_user,
    output                          lite_ar_valid,
    input                           lite_ar_ready,

    input  [ID_WIDTH-1:0]           lite_r_id,
    input  [LITE_DATA_WIDTH-1:0]    lite_r_data,
    input  [1:0]                    lite_r_resp,
    input  [USER_WIDTH-1:0]         lite_r_user,
    input                           lite_r_valid,
    output                          lite_r_ready
    );

   localparam BUF_DATA_WIDTH = NASTI_DATA_WIDTH < LITE_DATA_WIDTH ? NASTI_DATA_WIDTH : LITE_DATA_WIDTH;
   localparam MAX_BURST_SIZE = NASTI_DATA_WIDTH/BUF_DATA_WIDTH;

   genvar                           i;

   initial begin
      assert(LITE_DATA_WIDTH == 32 || LITE_DATA_WIDTH == 64)
        else $fatal(1, "nasti-lite supports only 32/64-bit channels!");

      assert(BUF_DEPTH > 0)
        else $fatal(1, "nasti_lite_reader buffer depth too short!");
   end

   // transaction information
   logic [MAX_TRANSACTION-1:0][ID_WIDTH-1:0]      xact_id_vec;
   logic [MAX_TRANSACTION-1:0][ADDR_WIDTH-1:0]    xact_addr_vec;
   logic [MAX_TRANSACTION-1:0][8:0]               xact_len_vec, xact_ar_cnt_vec, xact_r_cnt_vec;
   logic [MAX_TRANSACTION-1:0][2:0]               xact_size_vec;
   logic [MAX_TRANSACTION-1:0][2:0]               xact_prot_vec;
   logic [MAX_TRANSACTION-1:0][3:0]               xact_qos_vec;
   logic [MAX_TRANSACTION-1:0][3:0]               xact_region_vec;
   logic [MAX_TRANSACTION-1:0][USER_WIDTH-1:0]    xact_ar_user_vec, xact_r_user_vec;
   logic [MAX_TRANSACTION-1:0][MAX_BURST_SIZE-1:0][BUF_DATA_WIDTH-1:0]
                                                  xact_data_vec;
   logic [MAX_TRANSACTION-1:0][1:0]               xact_resp_vec;
   logic [MAX_TRANSACTION-1:0]                    xact_valid_vec;
   logic                                          xact_id_conflict;
   logic                                          xact_vec_available;

   // nasti-lite side buf
   logic [BUF_DEPTH-1:0][ID_WIDTH-1:0]            lite_r_id_buf;
   logic [BUF_DEPTH-1:0][BUF_DATA_WIDTH-1:0]      lite_r_data_buf;
   logic [BUF_DEPTH-1:0][1:0]                     lite_r_resp_buf;
   logic [BUF_DEPTH-1:0][USER_WIDTH-1:0]          lite_r_user_buf;
   logic [BUF_DEPTH-1:0]                          lite_r_buf_valid;
   logic [$clog2(BUF_DEPTH)-1:0]                  lite_r_rp, lite_r_wp;

   // internal control
   logic [MAX_TRANSACTION-1:0][$clog2(MAX_BURST_SIZE):0]
                                                  xact_req_cnt, xact_resp_wp;

   // helper functions
   function logic [$clog2(BUF_DEPTH)-1:0] buf_incr(logic [$clog2(BUF_DEPTH)-1:0] p, step);
      return p + step >= BUF_DEPTH ? p + step - BUF_DEPTH : p + step;
   endfunction // incr

   function logic [7:0] nasti_byte_size (logic [2:0] s);
      return 1 << s;
   endfunction // nasti_byte_size

   function logic [$clog2(BUF_DEPTH)-1:0] lite_packet_size (logic [2:0] s);
      return nasti_byte_size(s) / BUF_DATA_WIDTH;
   endfunction // lite_packet_size

   function logic [$clog2(MAX_TRANSACTION)-1:0] toInt (logic [MAX_TRANSACTION-1:0] dat);
      int i;
      for(i=0; i<MAX_TRANSACTION; i++)
        if(dat[i]) return i;
      return 0;
   endfunction // toInt

   function logic [1:0] combine_resp(logic [1:0] resp_old, resp_new);
      return resp_new > resp_old ? resp_new : resp_old;
   endfunction

   // transactions control
   logic [MAX_TRANSACTION-1:0]             resp_xact_match, conflict_match,
                                           xact_ar_req, xact_ar_gnt,
                                           xact_r_req, xact_r_gnt;
   logic [$clog2(MAX_TRANSACTION)-1:0]     resp_xact_index, xact_avail_index,
                                           xact_ar_index, xact_r_index;
   generate
      for(i=0; i<MAX_TRANSACTION; i++) begin
         assign resp_xact_match[i] = lite_r_id_buf[lite_r_rp] == xact_id_vec[i] &&
                                     lite_r_buf_valid[lite_r_rp] && xact_valid_vec[i];
         assign conflict_match[i] = nasti_ar_id === xact_id_vec[i] && xact_valid_vec[i];
         assign xact_ar_req[i] = xact_valid_vec[i] &&
                                 (xact_ar_cnt_vec[i] ||
                                  xact_req_cnt[i] < lite_packet_size(xact_size_vec[i]));
         assign xact_r_req[i] = xact_valid_vec[i] &&
                                xact_resp_wp[i] == lite_packet_size(xact_size_vec[i]);
      end
   endgenerate

   assign resp_xact_index = toInt(resp_xact_match);
   assign xact_ar_index = toInt(xact_ar_gnt);
   assign xact_r_index = toInt(xact_r_gnt);
   assign xact_avail_index = toInt(~xact_valid_vec);
   assign xact_id_conflict = |conflict_match;
   assign xact_vec_available = |(~xact_valid_vec);

   arbiter_rr #(MAX_TRANSACTION)
   xact_ar_arb(.*, .req(xact_ar_req), .gnt(xact_ar_gnt));

   arbiter_rr #(MAX_TRANSACTION)
   xact_r_arb(.*, .req(xact_r_req), .gnt(xact_r_gnt));

   // handle transaction vectors
   always_ff @(posedge clk or negedge rstn)
     if(!rstn)
       xact_valid_vec <= 0;
     else begin
        if(nasti_ar_valid && nasti_ar_ready)
          xact_valid_vec[xact_avail_index] <= 1;

        if(nasti_r_valid && nasti_r_ready && xact_r_cnt_vec[xact_r_index] == 0)
          xact_valid_vec[xact_r_index] <= 0;
     end

   always_ff @(posedge clk) begin
      if(nasti_ar_valid && nasti_ar_ready) begin
         xact_id_vec[xact_avail_index]      <= nasti_ar_id;
         xact_addr_vec[xact_avail_index]    <= nasti_ar_addr;
         xact_len_vec[xact_avail_index]     <= nasti_ar_len;
         xact_ar_cnt_vec[xact_avail_index]  <= nasti_ar_len;
         xact_r_cnt_vec[xact_avail_index]   <= nasti_ar_len;
         xact_req_cnt[xact_avail_index]     <= 0;
         xact_resp_wp[xact_avail_index]     <= 0;
         xact_size_vec[xact_avail_index]    <= nasti_ar_size;
         xact_prot_vec[xact_avail_index]    <= nasti_ar_prot;
         xact_qos_vec[xact_avail_index]     <= nasti_ar_qos;
         xact_region_vec[xact_avail_index]  <= nasti_ar_region;
         xact_ar_user_vec[xact_avail_index] <= nasti_ar_user;
      end

      if(lite_ar_valid && lite_ar_ready) begin
         xact_addr_vec[xact_ar_index] <= xact_addr_vec[xact_ar_index] + BUF_DATA_WIDTH/8;
         if(xact_ar_cnt_vec[xact_ar_index]) begin
            if(xact_req_cnt[xact_ar_index] ==  lite_packet_size(xact_size_vec[xact_ar_index]) -1) begin
               xact_req_cnt[xact_ar_index] <= 0;
               xact_ar_cnt_vec[xact_ar_index] <= xact_ar_cnt_vec[xact_ar_index] - 1;
            end else
              xact_req_cnt[xact_ar_index] <= xact_req_cnt[xact_ar_index] + 1;
         end else
           xact_req_cnt[xact_ar_index] <= xact_req_cnt[xact_ar_index] + 1;
      end // if (lite_ar_valid && lite_ar_ready)

      if(|resp_xact_match &&
         xact_resp_wp[resp_xact_index] != xact_size_vec[resp_xact_index]) begin
         xact_data_vec[resp_xact_index][xact_resp_wp[resp_xact_index]] <= lite_r_data_buf[lite_r_rp];
         xact_resp_vec[resp_xact_index] <= combine_resp(xact_resp_vec[resp_xact_index],
                                                        lite_r_resp_buf[lite_r_rp]);
         xact_r_user_vec[resp_xact_index] <= lite_r_user_buf[lite_r_rp];
      end

      if(nasti_r_valid && nasti_r_ready && xact_r_cnt_vec[xact_r_index]) begin
         xact_r_cnt_vec[xact_r_index] <= xact_r_cnt_vec[xact_r_index] - 1;
         xact_resp_wp[xact_r_index] <= 0;
      end
   end // always_ff @

   // the nasti-lite side buffer
   always_ff @(posedge clk or negedge rstn)
     if(!rstn) begin
        lite_r_buf_valid <= 0;
        lite_r_rp <= 0;
        lite_r_wp <= 0;
     end else begin
        if(lite_r_valid && lite_r_ready) begin
           lite_r_buf_valid[lite_r_wp] <= 1;
           lite_r_wp <= incr(lite_r_wp, 1);
        end

        if(|resp_xact_match &&
           xact_resp_wp[resp_xact_index] != xact_size_vec[resp_xact_index]) begin
           lite_r_buf_valid[lite_r_rp] <= 0;
           lite_r_rp <= incr(lite_r_rp, 1);
        end
     end // else: !if(!rstn)

   always_ff @(posedge clk)
     if(lite_r_valid && lite_r_ready) begin
        lite_r_id_buf[lite_r_wp]   <= lite_r_id;
        lite_r_data_buf[lite_r_wp] <= lite_r_data;
        lite_r_resp_buf[lite_r_wp] <= lite_r_resp;
        lite_r_user_buf[lite_r_wp] <= lite_r_user;
     end

   // assign remaining signals
   assign nasti_ar_ready = !xact_id_conflict && xact_vec_available;
   assign nasti_r_id     = xact_id_vec[xact_r_index];
   assign nasti_r_data   = xact_data_vec[xact_r_index];
   assign nasti_r_resp   = xact_resp_vec[xact_r_index];
   assign nasti_r_last   = xact_r_cnt_vec[xact_r_index] == 0;
   assign nasti_r_user   = xact_r_user_vec[xact_r_index];
   assign nasti_r_valid  = |xact_r_req;

   assign lite_ar_id     = xact_id_vec[xact_ar_index];
   assign lite_ar_addr   = xact_addr_vec[xact_ar_index];
   assign lite_ar_prot   = xact_prot_vec[xact_ar_index];
   assign lite_ar_qos    = xact_qos_vec[xact_ar_index];
   assign lite_ar_region = xact_region_vec[xact_ar_index];
   assign lite_ar_user   = xact_ar_user_vec[xact_ar_index];
   assign lite_ar_valid  = |xact_ar_req;

   assign lite_r_ready   = !lite_r_buf_valid[lite_r_wp];

endmodule // nasti_lite_reader
