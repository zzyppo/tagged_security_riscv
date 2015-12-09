// See LICENSE for license details.

module lite_nasti_reader
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
    input  [ID_WIDTH-1:0]           lite_ar_id,
    input  [ADDR_WIDTH-1:0]         lite_ar_addr,
    input  [2:0]                    lite_ar_prot,
    input  [3:0]                    lite_ar_qos,
    input  [3:0]                    lite_ar_region,
    input  [USER_WIDTH-1:0]         lite_ar_user,
    input                           lite_ar_valid,
    output                          lite_ar_ready,

    output [ID_WIDTH-1:0]           lite_r_id,
    output [LITE_DATA_WIDTH-1:0]    lite_r_data,
    output [1:0]                    lite_r_resp,
    output [USER_WIDTH-1:0]         lite_r_user,
    output                          lite_r_valid,
    input                           lite_r_ready,

    output  [ID_WIDTH-1:0]          nasti_ar_id,
    output  [ADDR_WIDTH-1:0]        nasti_ar_addr,
    output  [7:0]                   nasti_ar_len,
    output  [2:0]                   nasti_ar_size,
    output  [1:0]                   nasti_ar_burst,
    output                          nasti_ar_lock,
    output  [3:0]                   nasti_ar_cache,
    output  [2:0]                   nasti_ar_prot,
    output  [3:0]                   nasti_ar_qos,
    output  [3:0]                   nasti_ar_region,
    output  [USER_WIDTH-1:0]        nasti_ar_user,
    output                          nasti_ar_valid,
    input                           nasti_ar_ready,

    input  [ID_WIDTH-1:0]           nasti_r_id,
    input  [NASTI_DATA_WIDTH-1:0]   nasti_r_data,
    input  [1:0]                    nasti_r_resp,
    input                           nasti_r_last,
    input  [USER_WIDTH-1:0]         nasti_r_user,
    input                           nasti_r_valid,
    output                          nasti_r_ready
    );

   localparam BUF_DATA_WIDTH = NASTI_DATA_WIDTH < LITE_DATA_WIDTH ? NASTI_DATA_WIDTH : LITE_DATA_WIDTH;
   localparam MAX_BURST_SIZE = NASTI_DATA_WIDTH/BUF_DATA_WIDTH;

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

   function logic [1:0] combine_resp(logic [1:0] resp_old, resp_new);
      return resp_new > resp_old ? resp_new : resp_old;
   endfunction // combine_resp

   function logic [ADDR_WIDTH-1:0] nasti_addr(logic[ADDR_WIDTH-1:0] addr);
      return NASTI_DATA_WIDTH == BUF_DATA_WIDTH ? addr : (addr >>  $clog2(NASTI_DATA_WIDTH/8)) << $clog2(NASTI_DATA_WIDTH/8);
   endfunction // nasti_addr

   function logic [BUF_DATA_WIDTH-1:0] lite_data(logic [NASTI_DATA_WIDTH-1:0] data, logic[ADDR_WIDTH-1:0] addr);
      return NASTI_DATA_WIDTH == BUF_DATA_WIDTH ? data : data >> (BUF_DATA_WIDTH * addr[$clog2(NASTI_DATA_WIDTH/8)-1:$clog2(LITE_DATA_WIDTH/8)]);
   endfunction // lite_data

   // transaction vector
   logic [MAX_TRANSACTION-1:0][ID_WIDTH-1:0]      xact_id_vec;
   logic [MAX_TRANSACTION-1:0][ADDR_WIDTH-1:0]    xact_addr_vec;
   logic [MAX_TRANSACTION-1:0][MAX_BURST_SIZE-1:0][BUF_DATA_WIDTH-1:0]
                                                  xact_data_vec;
   logic [MAX_TRANSACTION-1:0][$clog2(MAX_BURST_SIZE):0]
                                                  xact_data_cnt_vec;
   logic [MAX_TRANSACTION-1:0][1:0]               xact_resp_vec;
   logic [MAX_TRANSACTION-1:0]                    xact_valid_vec;
   logic                                          xact_id_conflict;
   logic                                          xact_vec_available;

   // transaction control
   logic [MAX_TRANSACTION-1:0]                    conflict_match, resp_match;
   logic [$clog2(MAX_TRANSACTION)-1:0]            xact_avail_index, resp_index;

   generate
      for(i=0; i<MAX_TRANSACTION; i++) begin
         assign conflict_match[i] = lite_ar_id === xact_id_vec[i] && xact_valid_vec[i];
         assign resp_match[i] = nasti_r_id === xact_id_vec[i] && xact_valid_vec[i];
      end
   endgenerate

   assign xact_avail_index = toInt(~xact_valid_vec);
   assign xact_vec_available = |(~xact_valid_vec);
   assign xact_id_conflict = |conflict_match;
   assign resp_index = toInt(resp_match);

   always_ff @(posedge clk or negedge rstn)
     if(!rstn)
       xact_valid_vec <= 0;
     else begin
        if(lite_ar_valid && lite_ar_ready) begin
           xact_valid_vec[xact_avail_index] <= 1;
           xact_id_vec[xact_avail_index] <= lite_ar_id;
           xact_addr_vec[xact_avail_index] <= lite_ar_addr;
           xact_data_cnt_vec[xact_avail_index] <= 0;
           xact_resp_vec[xact_avail_index] <= 0;
        end

        if(nasti_r_valid && nasti_r_ready) begin
           xact_data_vec[resp_index][xact_data_cnt_vec[xact_avail_index]] <= nasti_r_data;
           xact_resp_vec[resp_index] <= combine_resp(xact_resp_vec[resp_index], nasti_r_resp);
           xact_data_cnt_vec[xact_avail_index] <= xact_data_cnt_vec[xact_avail_index] + 1;
        end

        if(lite_r_valid && lite_r_ready)
          xact_valid_vec[resp_index] <= 0;
     end // else: !if(!rstn)

   // connect signals
   assign lite_ar_ready = xact_vec_available && !xact_id_conflict && nasti_ar_ready;

   assign lite_r_id = nasti_r_id;
   assign lite_r_data = nasti_packet_size() == 1 ?
                        lite_data(nasti_r_data, xact_addr_vec[resp_index]) :
                        {xact_data_vec[resp_index][MAX_BURST_SIZE-1:1], nasti_r_data};
   assign lite_r_resp = nasti_packet_size() == 1 ?
                        nasti_r_resp :
                        combine_resp(xact_resp_vec[resp_index], nasti_r_resp);
   assign lite_r_user = nasti_r_user;
   assign lite_r_valid = |resp_match && nasti_r_valid &&
                         ( nasti_packet_size() == 1  ||
                           xact_data_cnt_vec[resp_index] == nasti_packet_size() - 1);

   assign nasti_ar_id = lite_ar_id;
   assign nasti_ar_addr = nasti_addr(lite_ar_addr);
   assign nasti_ar_len = nasti_packet_size() - 1;
   assign nasti_ar_size = nasti_byte_size();
   assign nasti_ar_burst = 2'b01; // support INCR only
   assign nasti_ar_lock = 0;      // NASTI 3 legacy signal, 0: normal access
   assign nasti_ar_cache = 4'b0001; // device bufferable
   assign nasti_ar_prot = lite_ar_prot;
   assign nasti_ar_qos = lite_ar_qos;
   assign nasti_ar_region = lite_ar_region;
   assign nasti_ar_user = lite_ar_user;
   assign nasti_ar_valid = xact_vec_available && !xact_id_conflict && lite_ar_valid;

   assign nasti_r_ready = |resp_match;

endmodule // lite_nasti_reader
