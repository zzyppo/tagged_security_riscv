// See LICENSE for license details.

module nasti_lite_writer
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
    input  [ID_WIDTH-1:0]           nasti_aw_id,
    input  [ADDR_WIDTH-1:0]         nasti_aw_addr,
    input  [7:0]                    nasti_aw_len,
    input  [2:0]                    nasti_aw_size,
    input  [1:0]                    nasti_aw_burst,
    input                           nasti_aw_lock,
    input  [3:0]                    nasti_aw_cache,
    input  [2:0]                    nasti_aw_prot,
    input  [3:0]                    nasti_aw_qos,
    input  [3:0]                    nasti_aw_region,
    input  [USER_WIDTH-1:0]         nasti_aw_user,
    input                           nasti_aw_valid,
    output                          nasti_aw_ready,

    input  [NASTI_DATA_WIDTH-1:0]   nasti_w_data,
    input  [NASTI_DATA_WIDTH/8-1:0] nasti_w_strb,
    input                           nasti_w_last,
    input  [USER_WIDTH-1:0]         nasti_w_user,
    input                           nasti_w_valid,
    output                          nasti_w_ready,

    output [ID_WIDTH-1:0]           nasti_b_id,
    output [1:0]                    nasti_b_resp,
    output [USER_WIDTH-1:0]         nasti_b_user,
    output                          nasti_b_valid,
    input                           nasti_b_ready,

    output [ID_WIDTH-1:0]           lite_aw_id,
    output [ADDR_WIDTH-1:0]         lite_aw_addr,
    output [2:0]                    lite_aw_prot,
    output [3:0]                    lite_aw_qos,
    output [3:0]                    lite_aw_region,
    output [USER_WIDTH-1:0]         lite_aw_aw_user,
    output                          lite_aw_valid,
    input                           lite_aw_ready,

    output [LITE_DATA_WIDTH-1:0]    lite_w_data,
    output [LITE_DATA_WIDTH/8-1:0]  lite_w_strb,
    output [USER_WIDTH-1:0]         lite_w_user,
    output                          lite_w_valid,
    input                           lite_w_ready,

    input  [ID_WIDTH-1:0]           lite_b_id,
    input  [1:0]                    lite_b_resp,
    input  [USER_WIDTH-1:0]         lite_b_user,
    input                           lite_b_valid,
    output                          lite_b_ready
    );

   localparam BUF_DATA_WIDTH = NASTI_DATA_WIDTH < LITE_DATA_WIDTH ? NASTI_DATA_WIDTH : LITE_DATA_WIDTH;
   localparam MAX_BURST_SIZE = NASTI_DATA_WIDTH/BUF_DATA_WIDTH;

   genvar                           i;

   initial begin
      assert(LITE_DATA_WIDTH == 32 || LITE_DATA_WIDTH == 64)
        else $fatal(1, "nasti-lite supports only 32/64-bit channels!");

      assert(BUF_DEPTH >= (NASTI_DATA_WIDTH-1)/LITE_DATA_WIDTH + 1)
        else $fatal(1, "nasti_lite_writer buffer depth too short!");
   end

   // shared information
   logic [ID_WIDTH-1:0]             aw_id;
   logic [ADDR_WIDTH-1:0]           aw_addr;
   logic [2:0]                      aw_size;
   logic [2:0]                      aw_prot;
   logic [3:0]                      aw_qos;
   logic [3:0]                      aw_region;
   logic [USER_WIDTH-1:0]           aw_user, w_user;
   logic                            w_last;

   // packet information
   logic [BUF_DEPTH-1:0][ADDR_WIDTH-1:0]         addr_q;
   logic [BUF_DEPTH-1:0][BUF_DATA_WIDTH-1:0]     data_q;
   logic [BUF_DEPTH-1:0][BUF_DATA_WIDTH/8-1:0]   strb_q;

   // read/write pointer
   logic                                         lock;
   logic [$clog2(BUF_DEPTH)-1:0]                 w_wp, aw_rp, w_rp;
   logic [BUF_DEPTH-1:0]                         aw_q_valid, w_q_valid;
   logic                                         aw_empty, w_empty;

   logic [$clog2(BUF_DEPTH)-1:0]                 w_wp_step;
   logic [2*BUF_DEPTH-1:0]                       w_wp_start, w_wp_start_mask;
   logic [2*BUF_DEPTH-1:0]                       w_wp_end, w_wp_end_mask;
   logic [2*BUF_DEPTH-1:0]                       w_wp_update_ext;
   logic [BUF_DEPTH-1:0]                         w_wp_update;

   // response
   logic [MAX_TRANSACTION-1:0][ID_WIDTH-1:0]     resp_id_vec;   // store the id for response match
   logic [MAX_TRANSACTION-1:0][USER_WIDTH-1:0]   resp_user_vec; // store user info
   logic [MAX_TRANSACTION-1:0][$clog2(256*MAX_BURST_SIZE)-1:0]
                                                 resp_cnt_vec,  // counting the responses
                                                 resp_size_vec; // record the size of response
   logic [MAX_TRANSACTION-1:0][1:0]              resp_resp_vec; // resp vector
   logic [MAX_TRANSACTION-1:0]                   resp_last_vec; // last vector
   logic [MAX_TRANSACTION-1:0]                   resp_valid_vec; // valid vector
   logic                                         resp_id_conflict;
   logic                                         resp_vec_available;

   // help functions
   function logic [$clog2(BUF_DEPTH)-1:0] incr(logic [$clog2(BUF_DEPTH)-1:0] p, step);
      return p + step >= BUF_DEPTH ? p + step - BUF_DEPTH : p + step;
   endfunction // incr

   function logic [7:0] nasti_byte_size (logic [2:0] s);
      return 1 << s;
   endfunction // nasti_byte_size

   function logic [$clog2(BUF_DEPTH)-1:0] lite_packet_size (logic [2:0] s);
      return nasti_byte_size(s) / BUF_DATA_WIDTH;
   endfunction // lite_packet_size

   function logic [$clog2(MAX_BURST_SIZE)-1:0] busrt_index(logic [$clog2(BUF_DEPTH)-1:0] p, index);
      return index - p;
   endfunction

   // burst size calculator
   assign w_wp_step = lite_packet_size(aw_size);
   assign w_wp_start = 1 << w_wp;                // [00010000]
   assign w_wp_end = 1 << w_wp + w_wp_step;      // [00000100]
   generate
      for(i=1; i<2*BUF_DEPTH; i++) assign w_wp_start_mask[i] = w_wp_start_mask[i-1] | w_wp_start[i];
      for(i=2*BUF_DEPTH-1; i!=0; i--) assign w_wp_end_mask[i-1] = w_wp_end_mask[i] | w_wp_end[i];
      assign w_wp_start_mask[0] = w_wp_start[i]; // [00011111]
      assign w_wp_end_mask[2*BUF_DEPTH-1] = 0;   // [11111000]
   endgenerate
   assign w_wp_update_ext = w_wp_start_mask & w_wp_end_mask; // [00011000]
   assign w_wp_update = w_wp_update_ext[0 +: BUF_DEPTH] | w_wp_update_ext[BUF_DEPTH +: BUF_DEPTH]; // [1001]

   // valid/ready signals
   assign nasti_aw_ready = !lock && resp_vec_available && !resp_id_conflict;
   assign nasti_w_ready = lock && !(aw_q_valid & w_wp_update) && !(w_q_valid & w_wp_update);
   assign lite_aw_valid = aw_q_valid[aw_rp];
   assign lite_w_valid = w_q_valid[w_rp];
   assign aw_empty = w_wp == aw_rp && !aw_q_valid[aw_rp];
   assign w_empty = w_wp == w_rp && !w_q_valid[w_rp];

   always_ff @(posedge clk or negedge rstn)
     if(!rstn) begin
        lock <= 0;
        w_wp <= 0;
        aw_rp <= 0;
        w_rp <= 0;
        aw_q_valid <= 0;
        w_q_valid <= 0;
     end else begin
        if(nasti_aw_valid && nasti_aw_ready)
          lock <= 1'b1;
        else if(w_last && aw_empty && w_empty)
          lock <= 0;

        if(nasti_w_valid && nasti_w_ready) begin
           w_wp <= incr(w_wp, w_wp_step);
           aw_q_valid <= aw_q_valid | w_wp_update;
           w_q_valid <= w_q_valid | w_wp_update;
        end

        if(lite_aw_valid && lite_aw_ready) begin
           aw_rp <= incr(aw_rp, 1);
           aw_q_valid[aw_rp] <= 0;
        end

        if(lite_w_valid && lite_w_ready) begin
           w_rp <= incr(w_rp, 1);
           w_q_valid[w_rp] <= 0;
        end
     end // else: !if(!rstn)

   // buffer AW
   always_ff @(posedge clk)
     if(nasti_aw_valid && nasti_aw_ready) begin
        aw_id <= nasti_aw_id;
        aw_addr <= nasti_aw_addr;
        aw_size <= nasti_aw_size;
        aw_prot <= nasti_aw_prot;
        aw_qos <= nasti_aw_qos;
        aw_region <= nasti_aw_region;
        aw_user <= nasti_aw_user;
     end else if(nasti_w_valid && nasti_w_ready)
       aw_addr <= aw_addr + w_wp_step;

   // buffer data burst
   generate
      for(i=0; i<BUF_DEPTH; i++)
        always_ff @(posedge clk)
          if(nasti_w_valid && nasti_w_ready && w_wp_update[i]) begin
             addr_q[i] <= aw_addr + busrt_index(w_wp, i) * BUF_DATA_WIDTH / 8;
             data_q[i] <= nasti_w_data[busrt_index(w_wp, i) * BUF_DATA_WIDTH +: BUF_DATA_WIDTH];
             strb_q[i] <= nasti_w_strb[busrt_index(w_wp, i) * BUF_DATA_WIDTH/8 +: BUF_DATA_WIDTH/8];
          end
   endgenerate

   // drive lite
   assign lite_aw_id = aw_id;
   assign lite_aw_addr = addr_q[aw_rp];
   assign lite_aw_prot = aw_prot;
   assign lite_aw_qos = aw_qos;
   assign lite_aw_region = aw_region;
   assign lite_aw_aw_user = aw_user;
   assign lite_w_data = data_q[w_rp];
   assign lite_w_strb = strb_q[w_rp];
   assign lite_w_w_user = w_user;

   // response
   logic [$clog2(MAX_TRANSACTION)-1:0] write_xact_index, resp_xact_index,
                                       resp_avail_index, resp_b_index;
   logic [MAX_TRANSACTION-1:0]         write_xact_match, resp_xact_match,
                                       conflict_match,   resp_b_match;

   // help functions
   function logic [$clog2(MAX_TRANSACTION)-1:0] toInt (logic [MAX_TRANSACTION-1:0] dat);
      int i;
      for(i=0; i<MAX_TRANSACTION; i++)
        if(dat[i]) return i;
      return 0;
   endfunction // toInt

   function logic [1:0] combine_resp(logic [1:0] resp_old, resp_new);
      return resp_new > resp_old ? resp_new : resp_old;
   endfunction

   // control signals
   generate
      for(i=0; i<MAX_TRANSACTION; i++) begin
         assign write_xact_match[i] = aw_id === resp_id_vec[i] && resp_valid_vec[i];
         assign resp_xact_match[i] = lite_b_id === resp_id_vec[i] && resp_valid_vec[i];
         assign conflict_match[i] = nasti_aw_id === resp_id_vec[i] && resp_valid_vec[i];
         assign resp_b_match[i] = resp_size_vec[i] == resp_cnt_vec[i] && resp_last_vec[i] && resp_valid_vec[i];
      end
   endgenerate

   assign write_xact_index = toInt(write_xact_match);
   assign resp_xact_index = toInt(resp_xact_match);
   assign resp_avail_index = toInt(~resp_valid_vec);
   assign resp_b_index = toInt(resp_b_match);
   assign resp_id_conflict = |conflict_match;
   assign resp_vec_available = |(~resp_valid_vec);

   // update valid
   always_ff @(posedge clk or negedge rstn)
     if(!rstn)
        resp_valid_vec <= 0;
     else begin
        if(nasti_aw_valid && nasti_aw_ready)
           resp_valid_vec[resp_avail_index] <= 1;

        if(nasti_b_valid && nasti_b_ready)
           resp_valid_vec[resp_b_index] <= 0;
     end // else: !if(!rstn)

   // channel signals
   assign nasti_b_valid = |resp_b_match;
   assign nasti_b_id = resp_id_vec[resp_b_index];
   assign nasti_b_resp = resp_resp_vec[resp_b_index];
   assign nasti_b_user = resp_user_vec[resp_b_index];
   assign lite_b_ready = ~nasti_b_valid || |resp_xact_match; // needed to make sure resp_b_match is one-hot

   // store response
   always_ff @(posedge clk) begin
      if(nasti_aw_valid && nasti_aw_ready) begin
         resp_last_vec[resp_avail_index] <= 0;
         resp_id_vec[resp_avail_index] <= nasti_aw_id;
         resp_size_vec[resp_avail_index] <= 0;
         resp_cnt_vec[resp_avail_index] <= 0;
         resp_resp_vec[resp_avail_index] <= 0;
      end

      if(nasti_w_valid && nasti_w_ready) begin
         resp_size_vec[write_xact_index] <= resp_size_vec[write_xact_index] + lite_packet_size(aw_size);
         resp_last_vec[write_xact_index] <= nasti_w_last;
      end

      if(lite_b_valid && lite_b_ready) begin
         resp_cnt_vec[resp_xact_index] <= resp_cnt_vec[resp_xact_index] + 1;
         resp_user_vec[resp_xact_index] <= lite_b_user;
         resp_resp_vec[resp_xact_index] <= combine_resp(resp_resp_vec[resp_xact_index], lite_b_resp);   
      end
   end // always_ff @

endmodule // nasti_lite_write_buf
