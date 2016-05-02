package rocket

import Chisel._
import Instructions._
import rocket.ALU._
import uncore.InitMemBase
import uncore.InitMemMask
import uncore.PCRUpdate
import uncore.PCRs
import uncore._


class TAGCHECKIO extends CoreBundle {
  val tag_in = UInt(INPUT, tagLen)
  val jalr = Bool(INPUT)
  val jump_register = UInt(INPUT)
  val update = new ValidIO(new PCRUpdate).flip
  val invalid_jump = Bool(OUTPUT)
  val debug_tag_in1 =  UInt(INPUT, tagLen)
  val debug_tag_in2 =  UInt(INPUT, tagLen)
  val debug_trap = Bool(OUTPUT)

}

/**
  * Created by zaepo on 16.03.16.
  */
class TagCheckUnit(resetSignal:Bool = null) extends Module(_reset = resetSignal) with CoreParameters {

  val io = new TAGCHECKIO

  val reg_tag_ctrl = Reg(UInt(width=xLen))

  when(this.reset) {
    reg_tag_ctrl := UInt(params(InitTagCtrl))
  }

  //Update the tag control register
  when(io.update.valid && io.update.bits.addr === UInt(PCRs.ptagctrl)) {
    reg_tag_ctrl := io.update.bits.data
  }

  def hasRetTag(tag:UInt): Bool = {
    (tag & UInt(RET_TAG)) === UInt(RET_TAG)
  }

  def hasInvTag(tag:UInt): Bool = {
    (tag & UInt(INV_TAG)) === UInt(INV_TAG)
  }

  def registerIsRA(adress:UInt) : Bool = {
    adress === UInt(1)
  }

  //Rules
  //1) Register is RA -> check if RET tag is set to be valid
  //2) Register is not RA -> check if INV tag is not set to be valid

  def rule1CheckActivated(tag_ctrl:UInt) : Bool = {
    (tag_ctrl & RET_TAG_CHECK) === RET_TAG_CHECK
  }

  def rule2CheckActivated(tag_ctrl:UInt) : Bool = {
    (tag_ctrl & INV_TAG_CHECK) === INV_TAG_CHECK
  }

  def debugCheckActivated(tag_ctrl:UInt) : Bool = {
    (tag_ctrl & DEBUG_TAG_CHECK) === DEBUG_TAG_CHECK
  }

  //val is_valid = (hasRetTag(io.tag_in) && registerIsRA(io.jump_register)) || (!hasInvTag(io.tag_in) && !registerIsRA(io.jump_register))

  val rule1_invalid = (!hasRetTag(io.tag_in) && registerIsRA(io.jump_register) && rule1CheckActivated(reg_tag_ctrl))
  val rule2_invalid = (hasInvTag(io.tag_in) && !registerIsRA(io.jump_register) && rule2CheckActivated(reg_tag_ctrl))

  val is_invalid = rule1_invalid || rule2_invalid
  //io.invalid_jump := Mux(rule1CheckActivated(reg_tag_ctrl),  Mux(io.jalr, !is_valid, Bool(false)) , Bool(false)) //If no jalr instrunction output is always valid, otherwise check valid condition
  io.invalid_jump :=  Mux(io.jalr, is_invalid, Bool(false))  //If no jalr instrunction output is always valid, otherwise check valid condition

  val trigger_debug_trap = (debugCheckActivated(reg_tag_ctrl) && (io.debug_tag_in1(3) || io.debug_tag_in1(2) || io.debug_tag_in2(3) || io.debug_tag_in2(2)))
  io.debug_trap := trigger_debug_trap

  when(trigger_debug_trap)
  {
    reg_tag_ctrl := UInt(0)
  }

  //io.invalid_jump := Bool(false)

}
