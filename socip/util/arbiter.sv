// See LICENSE for license details.

module arbiter_rr
  #(
    N = 2
    )
   (
    input clk, rstn,
    input [N-1:0]  req,
    output [N-1:0] gnt,
    input enable
    );

   logic [N-1:0] p;             // pointer of last grant
   logic [2*N-1:0] mask, req_ext, p_ext;
   logic           lock, locked; // make the arbiter stable

`ifdef VERILATOR
   logic [2*N-1:0] p_or, req_and;
`endif

   genvar          i;

   assign mask[0] = 1'b0;
   assign req_ext = {req, req};
   assign p_ext = p;

`ifdef VERILATOR
   generate
      assign p_or[0] = 0;
      assign req_and = req_ext & p_or;
      for(i=1; i<2*N; i++) begin
         assign p_or[i] = |p_ext[i-1:0];
         assign mask[i] = ~|req_and[i-1:0] & req_and[i];
      end
   endgenerate
`else
   generate
      for(i=1; i<2*N; i++)
        assign mask[i] = (mask[i-1] && !req_ext[i-1]) || p_ext[i-1];
   endgenerate
`endif

   assign gnt = enable ? (locked ? p : req & (mask[N-1:0] | mask[2*N-1:N])) : 0;

   always_ff @(posedge clk or negedge rstn)
     if(!rstn)
       p <= 1;
     else if(!locked && |gnt)
       p <= gnt;

   always_ff @(posedge clk or negedge rstn)
     if(!rstn)
       lock <= 0;
     else if(!lock || ~|(p&req))
       lock <= |gnt;

   assign locked = lock && |(p&req);
   
endmodule // arbiter_rr
