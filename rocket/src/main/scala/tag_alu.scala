package rocket

import Chisel._
import Instructions._

/**
  * Created by Philipp Jantscher on 15.03.16.
  */

import ALU._

class TAGALUIO extends CoreBundle {
  val dw = Bits(INPUT, SZ_DW)
  val fn = Bits(INPUT, SZ_ALU_FN)
  val in2 = UInt(INPUT, tagLen)
  val in1 = UInt(INPUT, tagLen)
  val jal = Bool(INPUT)
  val jalr = Bool(INPUT)
  val out = UInt(OUTPUT, tagLen)
}

class TagALU extends Module
{
  val io = new TAGALUIO

  //Rules :
  //1) Tag bit 1 always resetted except for jalr on tegister R0
  //2) Tag bit 0 always propagated through or connection of both inputs

  val tag_out_alu =
    Mux(io.fn === FN_ADD || io.fn === FN_SUB,          UInt(0) << UInt(1) |  (io.in1(0) | io.in2(0)),
      Mux(io.fn === FN_SR  || io.fn === FN_SRA,        UInt(0) << UInt(1) |  (io.in1(0) | io.in2(0)),
        Mux(io.fn === FN_SL,                           UInt(0) << UInt(1) |  (io.in1(0) | io.in2(0)),
          Mux(io.fn === FN_AND,                        UInt(0) << UInt(1) |  (io.in1(0) | io.in2(0)),
            Mux(io.fn === FN_OR,                       UInt(0) << UInt(1) |  (io.in1(0) | io.in2(0)),
              Mux(io.fn === FN_XOR,                    UInt(0) << UInt(1) |  (io.in1(0) | io.in2(0)),
                /* all comparisons */                  UInt(0) << UInt(1) |  (io.in1(0) | io.in2(0))))))))


  io.out := Mux(io.jalr || io.jal, UInt("b10"), tag_out_alu)
}
