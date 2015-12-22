// See LICENSE for license details.

package uncore
import Chisel._
import junctions._
//--------------------------------------------------------------//
// parameter definitions
//--------------------------------------------------------------//


abstract trait TagCacheParameters extends UsesParameters {

  // define for the tag
  val tagBits = params(TagBits)                   // the number of bits in each tag
  val coreDataBits = params(XLen)         // the number of bits in a data word (xpr)

  // the tag memory partition
  val tagMemSize = params(TagMemSize)             // the size of the tag memory partition is 2**TagMemSize bytes
  val tagBaseAddr = params(TCBaseAddr)           // the base address of the tag partition

  // the cache parameters
  val tagBlockBytes = params(TagBlockBytes)       // the cache block size in the tag cache
  val tagRowBytes = params(TagRowBytes)         // the size of a row in the tag cache
  // always stores the tags for a L2 cache line
  val nWays = params(NWays)                // the number of ways in the tag cache
  val nSets = params(NSets)                // the number of sets in the tag cache

  // memory interface
  val mifDataBits = params(MIFDataBits)           // the width of a single memory read/write
  val mifDataBeats = params(MIFDataBeats)         // the number of packets in a memory IF burst

  // uncahched Tile link interface
  val tlDataBits = params(TLDataBits)             // the datawidth of a single tile linke packet
  val tlDataBeats = params(TLDataBeats)           // the number of packets in a tile link burst


  // structure parameters for the tag cache
  val nTrackers = params(TCTrackers)        // the number of concurrent trackers
  val acqQueueDepth = tlDataBeats * 2             // the size of the Acquire queue
  val memQueueDepth = mifDataBeats * 2            // the size of the queue on memory interface

  // other parameters
  val refillCycles = tagBlockBytes / tagRowBytes  // the number of cycle required to refill a cache line
  val paddrBits = params(PAddrBits)               // size of a physical address
  val tagCacheIdxBits = log2Up(nSets)             // size of the index field
  val tagBlockRows = tagBlockBytes / tagRowBytes  // number of rows in a tag block
  val tagRowBlocks = params(TagRowBlocks)         // number of L2 blocks in a tag row
  val tagBlockTagBits = params(TagBlockTagBits)   // number of tag bits for a L2 block
  val blockOffBits = params(CacheBlockOffsetBits)
  val tagCacheUnRowAddrBits = log2Up(params(TagRowBlocks))
  // the lower bits not used when access data array
  val tagCacheUnIndexBits = log2Up(params(TagBlockBlocks))
  // the lower address not used for index
  val tagCahceUnTagBits = tagCacheIdxBits + tagCacheUnIndexBits
  // the lower address not used for tag
  val tagCacheTagBits = paddrBits - tagCahceUnTagBits - blockOffBits
  // the size of a tag
}

// deriving classes from parameters
abstract trait TagCacheModule extends Module with TagCacheParameters

//----------------------------------------------------//
// I/O definitions
//--------------------------------------------------------------//
trait TagCacheId extends Bundle with TagCacheParameters        { val id = UInt(width  = log2Up(nTrackers)) }
trait TagCacheMetadata extends Bundle with TagCacheParameters  { val tag = Bits(width = tagCacheTagBits + 2) }
trait TagCacheIdx extends Bundle with TagCacheParameters       { val idx = Bits(width = tagCacheIdxBits) }
trait TagCacheHit extends Bundle with TagCacheParameters       { val hit = Bool() }

class TagCacheMetaReadReq extends TagCacheId with TagCacheMetadata with TagCacheIdx

class TagCacheMetaWriteReq extends TagCacheMetadata with TagCacheIdx {
  val way_en = Bits(width = nWays)
}

class TagCacheMetaResp extends TagCacheId with TagCacheMetadata with TagCacheHit {
  val way_en = Bits(width = nWays)
}

class TagCacheMetaRWIO extends Bundle {
  val read = Decoupled(new TagCacheMetaReadReq)
  val write = Decoupled(new TagCacheMetaWriteReq)
  val resp = Valid(new TagCacheMetaResp).flip
}

trait TagCacheData extends Bundle with TagCacheParameters  {
  val data = Bits(width = tagBlockTagBits * tagRowBlocks)
}

trait TagCacheAddr extends Bundle with TagCacheParameters {
  val addr = Bits(width = tagCacheIdxBits + log2Up(tagBlockRows))
}

class TagCacheDataReadReq extends TagCacheId with TagCacheAddr {
  val way_en = Bits(width = nWays)
}

class TagCacheDataWriteReq extends TagCacheData with TagCacheAddr {
  val way_en = Bits(width = nWays)
  val wmask = Bits(width = tagRowBlocks)
}

class TagCacheDataResp extends TagCacheId with TagCacheData

class TagCacheDataRWIO extends Bundle {
  val read = Decoupled(new TagCacheDataReadReq)
  val write = Decoupled(new TagCacheDataWriteReq)
  val resp = Valid(new TagCacheDataResp).flip
}


class TagCache extends TagCacheModule {
  val io = new Bundle {
    val inner = new ManagerTileLinkIO
    val mem = new MemIO
  }

  io.mem.req_cmd.valid := io.inner.acquire.valid
  io.inner.acquire.ready := io.mem.req_cmd.ready
}


// tag cache metadata array
class TagCacheMetadataArray extends TagCacheModule {
  val io = new TagCacheMetaRWIO().flip
  // the highest bit in the meta is the valid flag
  val meta_bits = tagCacheTagBits+2

  val metaArray = Mem(UInt(width = meta_bits*nWays), nSets, seqRead = true)
  val replacer = new RandomReplacement(nWays)

  // reset initial process
  val rst_cnt = Reg(init=UInt(0, log2Up(nSets+1)))
  val rst = rst_cnt < UInt(nSets)
  val rst_0 = rst_cnt === UInt(0)
  when (rst) { rst_cnt := rst_cnt+UInt(1) }

  // write request
  val waddr = Mux(rst, rst_cnt, io.write.bits.idx)
  val wdata = Mux(rst, UInt(0), io.write.bits.tag).toBits
  val wmask = Mux(rst, SInt(-1), io.write.bits.way_en)

  when (rst || (io.write.valid)) {
    metaArray.write(waddr, Fill(nWays, wdata), FillInterleaved(meta_bits, wmask))
  }

  // helpers
  def getTag(meta:Bits): Bits = meta(tagCacheTagBits-1,0)
  def isValid(meta:Bits): Bool = meta(tagCacheTagBits+1)
  def isDirty(meta:Bits): Bool = meta(tagCacheTagBits)

  // read from cache array
  val ctags = metaArray(RegEnable(io.read.bits.idx, io.read.valid))
  val ctagArray = Vec((0 until nWays).map(i => ctags((i+1)*meta_bits - 1, i*meta_bits)))

  // pipeline stage 1
  val s1_tag = RegEnable(io.read.bits.tag, io.read.valid)
  val s1_id = RegEnable(io.read.bits.id, io.read.valid)
  val s1_clk_en = Reg(next = io.read.fire())
  val s1_match_way = Vec((0 until nWays).map(i => (getTag(ctagArray(i)) === getTag(s1_tag) && isValid(ctagArray(i))))).toBits
  val s1_match_meta = ctagArray(OHToUInt(s1_match_way))
  val s1_hit = s1_match_way.orR()
  val s1_replace_way = UIntToOH(replacer.way)
  val s1_replace_meta = ctagArray(replacer.way)

  // pipeline stage 2
  val s2_match_way = RegEnable(s1_match_way, s1_clk_en)
  val s2_match_meta = RegEnable(s1_match_meta, s1_clk_en)
  val s2_hit = RegEnable(s1_hit, s1_clk_en)
  val s2_replace_way = RegEnable(s1_replace_way, s1_clk_en)
  val s2_replace_meta = RegEnable(s1_replace_meta, s1_clk_en)
  when(!io.resp.bits.hit && io.resp.valid) {replacer.miss}

  // response composition
  io.resp.valid := Reg(next = s1_clk_en)
  io.resp.bits.id := RegEnable(s1_id, s1_clk_en)
  io.resp.bits.hit := s2_hit
  io.resp.bits.way_en := Mux(s2_hit, s2_match_way, s2_replace_way)
  io.resp.bits.tag := Mux(s2_hit, s2_match_meta, s2_replace_meta)

  io.read.ready := !rst && !io.write.valid // so really this could be a 6T RAM
  io.write.ready := !rst
}

// tag cache data array
class TagCacheDataArray extends TagCacheModule {
  val io = new TagCacheDataRWIO().flip

  val waddr = io.write.bits.addr
  val raddr = io.read.bits.addr
  val wmask = FillInterleaved(tagBlockTagBits, io.write.bits.wmask)

  val resp = (0 until nWays).map { w =>
    val array = Mem(Bits(width=tagBlockTagBits*tagRowBlocks), nSets*refillCycles, seqRead = true)
    val reg_raddr = Reg(UInt())
    when (io.write.bits.way_en(w) && io.write.valid) {
      array.write(waddr, io.write.bits.data, wmask)
    }.elsewhen (io.read.bits.way_en(w) && io.read.valid) {
      reg_raddr := raddr
    }
    array(reg_raddr)
  }

  io.resp.valid := ShiftRegister(io.read.fire(), 1)
  io.resp.bits.id := ShiftRegister(io.read.bits.id, 1)
  io.resp.bits.data := Mux1H(ShiftRegister(io.read.bits.way_en, 1), resp)

  io.read.ready := !io.write.valid // TODO 1R/W vs 1R1W?
  io.write.ready := Bool(true)

}

// tag cache victim buffer
class TagCacheVictimBuffer extends TagCacheModule {
  val io = new TagCacheDataRWIO().flip

  val wmask = FillInterleaved(tagBlockTagBits, io.write.bits.wmask)
  // victim buffer is implemented in registers
  val array = Vec.fill(nWays){Reg(Bits(width=tagBlockTagBits * tagRowBlocks))}

  (0 until nWays).map { w =>
    when (io.write.bits.way_en(w) && io.write.valid) {
      array(w) := (array(w) & (~wmask)) | (io.write.bits.data & wmask)
    }
  }

  io.resp.valid := io.read.valid
  io.resp.bits.id := io.read.bits.id
  io.resp.bits.data := Mux1H(io.read.bits.way_en, array)
  io.read.ready := Bool(true)
  io.write.ready := Bool(true)
}