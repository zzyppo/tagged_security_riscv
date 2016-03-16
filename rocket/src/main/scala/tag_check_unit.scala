package rocket

import Chisel._
import Instructions._
import rocket.ALU._


class TAGCHECKIO extends CoreBundle {
  val tag_in = UInt(INPUT, tagLen)
  val jalr = Bool(INPUT)
  val jump_register = UInt(INPUT)
  val invalid_jump = Bool(OUTPUT)
}

/**
  * Created by zaepo on 16.03.16.
  */
class TagCheckUnit extends Module {

  val io = new TAGCHECKIO


  def hasRetTag(tag:UInt): Bool = {
    (tag & UInt(2)) === UInt(2)
  }

  def hasInvTag(tag:UInt): Bool = {
    (tag & UInt(1)) === UInt(1)
  }

  def registerIsRA(adress:UInt) : Bool = {
    adress === UInt(1)
  }

  //Rules
  //1) Register is RA -> check if RET tag is set to be valid
  //2) Register is not RA -> check if INV tag is not set to be valid

  val is_valid = (hasRetTag(io.tag_in) && registerIsRA(io.jump_register)) || (!hasInvTag(io.tag_in) && !registerIsRA(io.jump_register))

  io.invalid_jump := Mux(io.jalr, !is_valid, Bool(false) ) //If no jalr instrunction output is always valid, otherwise check valid condition
  //io.invalid_jump := Bool(false)

}
