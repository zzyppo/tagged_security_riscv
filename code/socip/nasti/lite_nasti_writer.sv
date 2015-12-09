// See LICENSE for license details.

module lite_nasti_writer
  #(
    MAX_TRANSACTION = 2,        // the number of parallel transactions
    ID_WIDTH = 1,               // id width
    ADDR_WIDTH = 8,             // address width
    NASTI_DATA_WIDTH = 8,       // width of data on the nasti side
    LITE_DATA_WIDTH = 32,       // width of data on the nasti-lite side
    USER_WIDTH = 1              // width of user field, must > 0, let synthesizer trim it if not in use
    )
   (
    input  clk, rstn,
    input  [ID_WIDTH-1:0]           lite_aw_id,
    input  [ADDR_WIDTH-1:0]         lite_aw_addr,
    input  [2:0]                    lite_aw_prot,
    input  [3:0]                    lite_aw_qos,
    input  [3:0]                    lite_aw_region,
    input  [USER_WIDTH-1:0]         lite_aw_user,
    input                           lite_aw_valid,
    output                          lite_aw_ready,

    input  [LITE_DATA_WIDTH-1:0]    lite_w_data,
    input  [LITE_DATA_WIDTH/8-1:0]  lite_w_strb,
    input  [USER_WIDTH-1:0]         lite_w_user,
    input                           lite_w_valid,
    output                          lite_w_ready,

    output [ID_WIDTH-1:0]           lite_b_id,
    output [1:0]                    lite_b_resp,
    output [USER_WIDTH-1:0]         lite_b_user,
    output                          lite_b_valid,
    input                           lite_b_ready,

    output [ID_WIDTH-1:0]           nasti_aw_id,
    output [ADDR_WIDTH-1:0]         nasti_aw_addr,
    output [7:0]                    nasti_aw_len,
    output [2:0]                    nasti_aw_size,
    output [1:0]                    nasti_aw_burst,
    output                          nasti_aw_lock,
    output [3:0]                    nasti_aw_cache,
    output [2:0]                    nasti_aw_prot,
    output [3:0]                    nasti_aw_qos,
    output [3:0]                    nasti_aw_region,
    output [USER_WIDTH-1:0]         nasti_aw_user,
    output                          nasti_aw_valid,
    input                           nasti_aw_ready,

    output [NASTI_DATA_WIDTH-1:0]   nasti_w_data,
    output [NASTI_DATA_WIDTH/8-1:0] nasti_w_strb,
    output                          nasti_w_last,
    output [USER_WIDTH-1:0]         nasti_w_user,
    output                          nasti_w_valid,
    input                           nasti_w_ready,

    input  [ID_WIDTH-1:0]           nasti_b_id,
    input  [1:0]                    nasti_b_resp,
    input  [USER_WIDTH-1:0]         nasti_b_user,
    input                           nasti_b_valid,
    output                          nasti_b_ready
    );

   localparam BUF_DATA_WIDTH = NASTI_DATA_WIDTH < LITE_DATA_WIDTH ? NASTI_DATA_WIDTH : LITE_DATA_WIDTH;
   localparam MAX_BURST_SIZE = LITE_DATA_WIDTH/BUF_DATA_WIDTH;

   genvar                           i;

   initial begin
      assert(LITE_DATA_WIDTH == 32 || LITE_DATA_WIDTH == 64)
        else $fatal(1, "nasti-lite supports only 32/64-bit channels!");
   end

   // helper functions
   function logic [$clog2(MAX_TRANSACTION)-1:0] toInt (logic [MAX_TRANSACTION-1:0] dat);
      int i;
      for(i=0; i<MAX_TRANSACTION; i++)
        if(dat[i]) return i;
      return 0;
   endfunction // toInt

   function logic [2:0] nasti_byte_size ();
      return $clog2(NASTI_DATA_WIDTH/8);
   endfunction // nasti_byte_size

   function logic [7:0] nasti_packet_size ();
      return  LITE_DATA_WIDTH / BUF_DATA_WIDTH;
   endfunction // lite_packet_size

   function logic [ADDR_WIDTH-1:0] nasti_addr(logic[ADDR_WIDTH-1:0] addr);
      return NASTI_DATA_WIDTH == BUF_DATA_WIDTH ? addr : (addr >>  $clog2(NASTI_DATA_WIDTH/8)) << $clog2(NASTI_DATA_WIDTH/8);
   endfunction // nasti_addr

   function logic [NASTI_DATA_WIDTH/8-1:0] nasti_wmask(logic [LITE_DATA_WIDTH/8-1:0] mask, logic[ADDR_WIDTH-1:0] addr);
      return NASTI_DATA_WIDTH == BUF_DATA_WIDTH ? mask : mask << (BUF_DATA_WIDTH/8 * addr[$clog2(NASTI_DATA_WIDTH/8)-1:$clog2(LITE_DATA_WIDTH/8)]);
   endfunction // nasti_addr

   function logic [NASTI_DATA_WIDTH-1:0] nasti_data(logic [NASTI_DATA_WIDTH-1:0] data, logic[ADDR_WIDTH-1:0] addr);
      return NASTI_DATA_WIDTH == BUF_DATA_WIDTH ? data : data << (BUF_DATA_WIDTH * addr[$clog2(NASTI_DATA_WIDTH/8)-1:$clog2(LITE_DATA_WIDTH/8)]);
   endfunction // lite_data

   // transaction vector
   logic [MAX_TRANSACTION-1:0][ID_WIDTH-1:0]      xact_id_vec;
   logic [ADDR_WIDTH-1:0]                         xact_addr;
   logic [MAX_BURST_SIZE-1:0][BUF_DATA_WIDTH-1:0] xact_data;
   logic [MAX_BURST_SIZE-1:0][BUF_DATA_WIDTH/8-1:0]
                                                  xact_strb;
   logic [$clog2(MAX_BURST_SIZE):0]               xact_data_cnt;
   logic [USER_WIDTH-1:0]                         xact_w_user;
   logic [MAX_TRANSACTION-1:0]                    xact_valid_vec;
   logic                                          xact_id_conflict;
   logic                                          xact_vec_available;

   // transaction control
   logic [MAX_TRANSACTION-1:0]                    conflict_match, resp_match;
   logic [$clog2(MAX_TRANSACTION)-1:0]            xact_avail_index, resp_index;
   logic                                          lock;

   generate
      for(i=0; i<MAX_TRANSACTION; i++) begin
         assign conflict_match[i] = lite_aw_id === xact_id_vec[i] && xact_valid_vec[i];
         assign resp_match[i] = nasti_b_id === xact_id_vec[i] && xact_valid_vec[i];
      end
   endgenerate

   assign xact_avail_index = toInt(~xact_valid_vec);
   assign xact_vec_available = |(~xact_valid_vec);
   assign xact_id_conflict = |conflict_match;
   assign resp_index = toInt(resp_match);

   always_ff @(posedge clk or negedge rstn)
     if(!rstn)
       lock <= 0;
     else if(lite_aw_valid && lite_aw_ready)
       lock <= 1;
     else if(nasti_w_valid && nasti_w_ready && nasti_w_last)
       lock <= 0;

   always_ff @(posedge clk or negedge rstn)
     if(!rstn)
       xact_valid_vec <= 0;
     else begin
        if(lite_aw_valid && lite_aw_ready) begin
           xact_valid_vec[xact_avail_index] <= 1;
           xact_id_vec[xact_avail_index] <= lite_aw_id;
           xact_addr <= lite_aw_addr;
        end

        if(lite_b_valid && lite_b_ready)
          xact_valid_vec[resp_index] <= 0;
     end

   always_ff @(posedge clk) begin
      if(lite_w_valid && lite_w_ready) begin
         xact_data <= lite_w_data;
         xact_strb <= lite_w_strb;
         xact_w_user <= lite_w_user;
      end

      if(lite_aw_valid && lite_aw_ready)
        xact_data_cnt <= 0;
      else if(nasti_w_valid && nasti_w_ready && MAX_BURST_SIZE > 1)
        xact_data_cnt <= xact_data_cnt + 1;
   end

   // connect signals
   assign lite_aw_ready = !lock && xact_vec_available && !xact_id_conflict && nasti_aw_ready;

   assign lite_w_ready = lock && nasti_w_ready;

   assign lite_b_id = nasti_b_id;
   assign lite_b_resp = nasti_b_resp;
   assign lite_b_user = nasti_b_user;
   assign lite_b_valid = nasti_b_valid && |resp_match;

   assign nasti_aw_id = lite_aw_id;
   assign nasti_aw_addr = nasti_addr(lite_aw_addr);
   assign nasti_aw_len = nasti_packet_size() - 1;
   assign nasti_aw_size = nasti_byte_size();
   assign nasti_aw_burst = 2'b01; // support INCR only
   assign nasti_aw_lock = 0;      // NASTI 3 legacy signal, 0: normal access
   assign nasti_aw_cache = 4'b0001; // device bufferable
   assign nasti_aw_prot = lite_aw_prot;
   assign nasti_aw_qos = lite_aw_qos;
   assign nasti_aw_region = lite_aw_region;
   assign nasti_aw_user = lite_aw_user;
   assign nasti_aw_valid = !lock && xact_vec_available && !xact_id_conflict && lite_aw_valid;

   assign nasti_w_data = nasti_packet_size() == 1 || xact_data_cnt == 0 ?
                         nasti_data(lite_w_data, xact_addr) : xact_data[xact_data_cnt];
   assign nasti_w_strb = nasti_packet_size() == 1 || xact_data_cnt == 0 ?
                         nasti_wmask(lite_w_strb, xact_addr) : xact_strb[xact_data_cnt];
   assign nasti_w_last = xact_data_cnt == nasti_packet_size() - 1;
   assign nasti_w_user = nasti_packet_size() == 1 || xact_data_cnt == 0 ?
                         lite_w_user : xact_w_user;
   assign nasti_w_valid = lock && (
                          (xact_data_cnt == 0 && lite_w_valid) ||
                          (xact_data_cnt != 0 && xact_data_cnt != nasti_packet_size()));

   assign nasti_b_ready = |resp_match;

endmodule // lite_nasti_writer
