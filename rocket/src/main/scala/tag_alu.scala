package rocket

import Chisel._
import Instructions._
import rocket._
import uncore._
/**
  * Created by Philipp Jantscher on 15.03.16.
  */

import ALU._

class TAGALUIO extends CoreBundle {
  val dw = Bits(INPUT, SZ_DW)
  val fn = Bits(INPUT, SZ_ALU_FN)
  val is_mv = Bool(INPUT)
  val in1 = UInt(INPUT, tagLen)
  val in2 = UInt(INPUT, tagLen)
  val jal = Bool(INPUT)
  val jalr = Bool(INPUT)
  val out = UInt(OUTPUT, tagLen)
}

class TagALU(resetSignal:Bool = null) extends Module(_reset = resetSignal) with CoreParameters
{
  val io = new TAGALUIO

  //val retTag = log2Down(RET_TAG)
  val invTag = log2Down(INV_TAG)

  val ret_tag_mask = ~UInt(RET_TAG, width = tagLen - USER_TAG_OFFS)

  //Rules :
  //1) Tag bit 1 always resetted except for jalr on register R0
  //2) Tag bit 0 always propagated through or connection of both inputs


  val tag_out_alu =
    Mux(io.fn === FN_ADD || io.fn === FN_SUB,          UInt(0) << UInt(1) |  (io.in1(0) | io.in2(0)),
      Mux(io.fn === FN_SR  || io.fn === FN_SRA,        UInt(0) << UInt(1) |  (io.in1(0) | io.in2(0)),
        Mux(io.fn === FN_SL,                           UInt(0) << UInt(1) |  (io.in1(0) | io.in2(0)),
          Mux(io.fn === FN_AND,                        UInt(0) << UInt(1) |  (io.in1(0) | io.in2(0)),
            Mux(io.fn === FN_OR,                       UInt(0) << UInt(1) |  (io.in1(0) | io.in2(0)),
              Mux(io.fn === FN_XOR,                    UInt(0) << UInt(1) |  (io.in1(0) | io.in2(0)),
                /* all comparisons */                  UInt(0) << UInt(1) |  (io.in1(0) | io.in2(0))))))))

  val tag_out = Mux(io.is_mv, io.in1, tag_out_alu  | ((io.in1(3,2) | io.in2(3,2)) << UInt(2)))

/*
  val tag_out_alu =
    Mux(io.fn === FN_ADD || io.fn === FN_SUB,          ret_tag_mask |  (io.in1(invTag) | io.in2(invTag)),
      Mux(io.fn === FN_SR  || io.fn === FN_SRA,        ret_tag_mask |  (io.in1(invTag) | io.in2(invTag)),
        Mux(io.fn === FN_SL,                           ret_tag_mask |  (io.in1(invTag) | io.in2(invTag)),
          Mux(io.fn === FN_AND,                        ret_tag_mask |  (io.in1(invTag) | io.in2(invTag)),
            Mux(io.fn === FN_OR,                       ret_tag_mask |  (io.in1(invTag) | io.in2(invTag)),
              Mux(io.fn === FN_XOR,                    ret_tag_mask |  (io.in1(invTag) | io.in2(invTag)),
                /* all comparisons */                  ret_tag_mask |  (io.in1(invTag) | io.in2(invTag))))))))

  val tag_out = Mux(io.is_mv, io.in1,
                    tag_out_alu | ((io.in1(tagLen-1 ,USER_TAG_OFFS) | io.in2(tagLen-1,USER_TAG_OFFS)) << USER_TAG_OFFS))
                    */

  io.out := Mux(io.jalr || io.jal, UInt(0, width = tagLen) | UInt(RET_TAG), tag_out) // output function
}
