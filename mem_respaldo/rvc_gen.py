"""RVC instruction encoder — matches decompressor.v bit-by-bit."""

# Common helpers
def hw(v): return f"{v & 0xFFFF:04X}"
def mem32(v): return f"{hw(v)}\n{hw(v >> 16)}"

# ========== Quadrant 0 (inst[1:0] = 00) ==========
def c_lw(rs1p, rdp, offset7):
    """rs1p,rdp: x8-x15 relative (0-7); offset7: 0-124 mult 4"""
    off = offset7 >> 2                      # bits 6:2
    v  = (0b010 << 13)                      # funct3
    v |= ((off >> 5) & 1) << 12             # off[5]
    v |= ((off >> 3) & 3) << 10             # off[4:3]
    v |= (rs1p << 7)
    v |= ((off >> 6) & 1) << 6              # off[6]
    v |= ((off >> 2) & 1) << 5              # off[2]
    v |= (rdp << 2)
    v |= 0b00                               # Q0
    return v

def c_sw(rs1p, rs2p, offset7):
    off = offset7 >> 2
    v  = (0b110 << 13)
    v |= ((off >> 5) & 1) << 12
    v |= ((off >> 3) & 3) << 10
    v |= (rs1p << 7)
    v |= ((off >> 6) & 1) << 6
    v |= ((off >> 2) & 1) << 5
    v |= (rs2p << 2)
    v |= 0b00
    return v

# ========== Quadrant 1 (inst[1:0] = 01) ==========
def c_addi(rd, imm6):
    """rd: 0-31; imm6: 6-bit signed (-32..31)"""
    imm = imm6 & 0x3F
    v  = (0b000 << 13)
    v |= ((imm >> 5) & 1) << 12
    v |= (rd << 7)
    v |= ((imm & 0x1F) << 2)
    v |= 0b01
    return v

def c_jal(offset_bytes):
    """
    Decompressor maps instr16 bits to JAL imm:
      instr16[12] -> imm[20]  = offset21[20]   (sign)
      instr16[8]  -> imm[10]  = offset21[10]
      instr16[10] -> imm[9]   = offset21[9]
      instr16[9]  -> imm[8]   = offset21[8]
      instr16[7]  -> imm[7]   = offset21[7]
      instr16[6]  -> imm[6]   = offset21[6]
      instr16[2]  -> imm[5]   = offset21[5]
      instr16[11] -> imm[4]   = offset21[4]
      instr16[5]  -> imm[3]   = offset21[3]
      instr16[4]  -> imm[2]   = offset21[2]
      instr16[3]  -> imm[1]   = offset21[1]
    offset21 = byte_offset >> 1  (pre-bit0 value)
    """
    off = offset_bytes >> 1                    # offset21 = byte offset / 2
    v  = (0b001 << 13)                        # funct3 = 001 (C.JAL)
    v |= ((off >> 10) & 1) << 12              # bit12 = off[10]
    v |= ((off >> 10) & 1) << 8               # bit8  = off[10]
    v |= ((off >> 9) & 1) << 10               # bit10 = off[9]
    v |= ((off >> 8) & 1) << 9                # bit9  = off[8]
    v |= ((off >> 7) & 1) << 7                # bit7  = off[7]
    v |= ((off >> 6) & 1) << 6                # bit6  = off[6]
    v |= ((off >> 5) & 1) << 2                # bit2  = off[5]
    v |= ((off >> 4) & 1) << 11               # bit11 = off[4]
    v |= ((off >> 3) & 1) << 5                # bit5  = off[3]
    v |= ((off >> 2) & 1) << 4                # bit4  = off[2]
    v |= ((off >> 1) & 1) << 3                # bit3  = off[1]
    v |= 0b01
    return v

def c_j(offset_bytes):
    """Same mapping as C.JAL but funct3=101 and rd=x0"""
    off = offset_bytes >> 1
    v = (0b101 << 13)
    v |= ((off >> 10) & 1) << 12
    v |= ((off >> 10) & 1) << 8
    v |= ((off >> 9) & 1) << 10
    v |= ((off >> 8) & 1) << 9
    v |= ((off >> 7) & 1) << 7
    v |= ((off >> 6) & 1) << 6
    v |= ((off >> 5) & 1) << 2
    v |= ((off >> 4) & 1) << 11
    v |= ((off >> 3) & 1) << 5
    v |= ((off >> 2) & 1) << 4
    v |= ((off >> 1) & 1) << 3
    v |= 0b01
    return v

def c_beqz(rs1p, offset_bytes):
    """
    Decompressor maps instr16 bits to B-type imm:
      instr16[12] -> B-type imm[12:8] (sign extension)
      instr16[6]  -> imm[7] -> offset[7]
      instr16[5]  -> imm[6] -> offset[6]
      instr16[2]  -> imm[5] -> offset[5]
      instr16[11] -> imm[4] -> offset[4]
      instr16[10] -> imm[3] -> offset[3]
      instr16[4]  -> imm[2] -> offset[2]
      instr16[3]  -> imm[1] -> offset[1]
    Decompressor output offset = {off[8]...off[1], 0} IN BYTES.
    So off = offset_bytes (NOT shifted), bit 0 implicit = 0.
    """
    off = offset_bytes                       # byte offset, NOT shifted
    v  = (0b110 << 13)                       # funct3=110
    v |= ((off >> 8) & 1) << 12              # off[8] (sign) -> bit12
    v |= ((off >> 4) & 1) << 11              # off[4] -> bit11
    v |= ((off >> 3) & 1) << 10              # off[3] -> bit10
    v |= (rs1p << 7)
    v |= ((off >> 7) & 1) << 6               # off[7] -> bit6
    v |= ((off >> 6) & 1) << 5               # off[6] -> bit5
    v |= ((off >> 2) & 1) << 4               # off[2] -> bit4
    v |= ((off >> 1) & 1) << 3               # off[1] -> bit3
    v |= ((off >> 5) & 1) << 2               # off[5] -> bit2
    v |= 0b01
    return v

def c_bnez(rs1p, offset_bytes):
    off = offset_bytes                       # byte offset, NOT shifted
    v  = (0b111 << 13)
    v |= ((off >> 8) & 1) << 12
    v |= ((off >> 4) & 1) << 11
    v |= ((off >> 3) & 1) << 10
    v |= (rs1p << 7)
    v |= ((off >> 7) & 1) << 6
    v |= ((off >> 6) & 1) << 5
    v |= ((off >> 2) & 1) << 4
    v |= ((off >> 1) & 1) << 3
    v |= ((off >> 5) & 1) << 2
    v |= 0b01
    return v

# ========== Quadrant 2 (inst[1:0] = 10) ==========
def c_lwsp(rd, offset8):
    """rd: 0-31; offset8: 0-508 mult 4"""
    off = offset8 >> 2                       # bits 7:2
    v  = (0b010 << 13)
    v |= ((off >> 4) & 1) << 12              # off[4] -> bit12
    v |= (rd << 7)
    v |= ((off >> 5) & 1) << 4               # off[5] -> bit4
    v |= ((off >> 6) & 3) << 2               # off[7:6] -> bits 3:2
    v |= 0b10
    return v

def c_swsp(rs2, offset8):
    off = offset8 >> 2
    v  = (0b110 << 13)
    v |= ((off >> 2) & 1) << 12              # off[2] -> bit12
    v |= (rs2 << 7)
    v |= ((off >> 3) & 7) << 2               # off[5:3] -> bits 4:2
    v |= 0b10
    return v

def c_jr(rs1):
    """c.jr rs1 -> jalr x0, rs1, 0"""
    return (0b100 << 13) | (0 << 12) | (rs1 << 7) | (0 << 2) | 0b10

def c_jalr(rs1):
    """c.jalr rs1 -> jalr x1, rs1, 0"""
    return (0b100 << 13) | (1 << 12) | (rs1 << 7) | (0 << 2) | 0b10

# RV32I
def rv32i_lui(rd, imm20):
    return ((imm20 & 0xFFFFF) << 12) | (rd << 7) | 0b0110111

def rv32i_addi(rd, rs1, imm12):
    return ((imm12 & 0xFFF) << 20) | (rs1 << 15) | (rd << 7) | 0b0010011

# ==============================
# PROGRAM 1: test_ls_rvc
print("="*60)
print("PROG1: test_ls_rvc.mem — C.LW, C.SW, C.LWSP, C.SWSP")
print("="*60)
# x8=16, x9=7, store/load via C.SW/C.LW, then C.SWSP/C.LWSP
p1 = [
    "// test_ls_rvc.mem",
    "// x8=16 (ptr), x9=7 (val), x10=mem[16], x11=mem[16]",
    hw(c_addi(8, 16)),       # 0000
    hw(c_addi(9, 7)),        # 0002
    hw(c_sw(0, 1, 0)),       # 0004  c.sw x9, 0(x8)   rs1p=0(x8), rs2p=1(x9)
    hw(c_lw(0, 2, 0)),       # 0006  c.lw x10, 0(x8)  rs1p=0(x8), rdp=2(x10)
    hw(c_addi(2, 16)),       # 0008
    hw(c_swsp(9, 0)),        # 000A
    hw(c_lwsp(11, 0)),       # 000C
]
for l in p1:
    print(l)

# ==============================
# PROGRAM 2: test_branch_rvc
print("\n" + "="*60)
print("PROG2: test_branch_rvc.mem — C.BEQZ, C.BNEZ")
print("="*60)
# x8=1, x9=0, beqz x9 +4 skips, bnez x8 +4 skips
p2 = [
    "// test_branch_rvc.mem",
    "// x8=1, x9=0, beqz x9 skips, bnez x8 skips, x12=1",
    hw(c_addi(8, 1)),        # 0000: x8=1
    hw(c_addi(9, 0)),        # 0002: x9=0
    hw(c_beqz(1, 4)),        # 0004: beqz x9 +4 -> skip 0006
    hw(c_addi(10, 7)),       # 0006: SKIPPED
    hw(c_bnez(0, 4)),        # 0008: bnez x8 +4 -> skip 000A
    hw(c_addi(11, 7)),       # 000A: SKIPPED
    hw(c_addi(12, 1)),       # 000C: x12=1
]
for l in p2:
    print(l)

# ==============================
# PROGRAM 3: test_jump_rvc
print("\n" + "="*60)
print("PROG3: test_jump_rvc.mem — C.J, C.JAL, C.JR")
print("="*60)
# 0000: c.addi x8, 5      x8=5
# 0002: c.j +4            -> 0006
# 0004: c.addi x8, 7       SKIP
# 0006: c.addi x9, 10     x9=10
# 0008: c.jal +4          -> 000C, x1=000A
# 000A: c.addi x10, 20     (after return) x10=20
# 000C: c.addi x10, 3      sub body: x10=3
# 000E: c.jr x1            return -> 000A
p3 = [
    "// test_jump_rvc.mem",
    "// x8=5, x9=10, c.j jumps, c.jal calls, c.jr returns, x10=20",
    hw(c_addi(8, 5)),
    hw(c_j(4)),              # 0002: jump +4 -> 0006
    hw(c_addi(8, 7)),       # 0004: SKIP
    hw(c_addi(9, 10)),      # 0006: x9=10
    hw(c_jal(4)),           # 0008: call +4 -> 000C, x1=000A
    hw(c_addi(10, 20)),     # 000A: after return -> x10=20
    hw(c_addi(10, 3)),      # 000C: sub body -> x10=3
    hw(c_jr(1)),            # 000E: return -> 000A
]
for l in p3:
    print(l)

# ==============================
# PROGRAM 4: test_isa_rvc (algoritmo mixto)
print("\n" + "="*60)
print("PROG4: test_isa_rvc.mem — Algoritmo mixto RV32I+RVC")
print("="*60)
# 0000: lui x8, 1            x8=0x1000
# 0004: addi x8, x8, 0x0C0   x8=0x10C0
# 0008: c.addi x9, 7         x9=7
# 000A: c.addi x10, 10       x10=10
# 000C: c.sw x10, 0(x8)      mem[0x10C0]=10
# 000E: c.lw x11, 0(x8)      x11=10
# 0010: c.addi x2, 16        SP=16
# 0012: c.swsp x9, 0(x2)     mem[16]=7
# 0014: c.lwsp x12, 0(x2)    x12=7
p4 = [
    "// test_isa_rvc.mem — Algoritmo mixto RV32I + RVC",
    "// x8=0x10C0, x9=7, x10=10, x11=10, x12=7, x2=16",
    mem32(rv32i_lui(8, 1)),             # 0000
    mem32(rv32i_addi(8, 8, 0x0C0)),    # 0004
    hw(c_addi(9, 7)),                   # 0008
    hw(c_addi(10, 10)),                 # 000A: 10 fits in signed 6-bit
    hw(c_sw(0, 2, 0)),                  # 000C  rs1p=0(x8), rs2p=2(x10)
    hw(c_lw(0, 3, 0)),                  # 000E  rs1p=0(x8), rdp=3(x11)
    hw(c_addi(2, 16)),                  # 0010
    hw(c_swsp(9, 0)),                   # 0012
    hw(c_lwsp(12, 0)),                  # 0012
]
for l in p4:
    print(l)

# ==============================
# VERIFICATION: trace decompressor behavior
print("\n" + "="*60)
print("VERIFY: c.beqz x9 +4")
print("="*60)
v16 = c_beqz(1, 4)
off = 4 >> 1
print(f"Encoding: 0x{v16:04X}")
print(f"  instr16[12]={ (v16>>12)&1 } [off[8]]")
print(f"  instr16[11]={ (v16>>11)&1 } [off[4]]")
print(f"  instr16[10]={ (v16>>10)&1 } [off[3]]")
print(f"  instr16[6] ={ (v16>>6)&1 } [off[7]]")
print(f"  instr16[5] ={ (v16>>5)&1 } [off[6]]")
print(f"  instr16[2] ={ (v16>>2)&1 } [off[5]]")
print(f"  instr16[4] ={ (v16>>4)&1 } [off[2]]")
print(f"  instr16[3] ={ (v16>>3)&1 } [off[1]]")
print(f"Decomp 13-bit offset: sign_ext({ (v16>>12)&1 },{(v16>>6)&1},{(v16>>5)&1},{(v16>>2)&1},{(v16>>11)&1},{(v16>>10)&1},{(v16>>4)&1},{(v16>>3)&1},0)")
# Calc what the decompressor produces
d12=(v16>>12)&1; d6=(v16>>6)&1; d5=(v16>>5)&1; d2=(v16>>2)&1
d11=(v16>>11)&1; d10=(v16>>10)&1; d4=(v16>>4)&1; d3=(v16>>3)&1
decomp_off = (d12 << 12) | (d12 << 11) | (d12 << 10) | (d12 << 9) | (d12 << 8) | (d6 << 7) | (d5 << 6) | (d2 << 5) | (d11 << 4) | (d10 << 3) | (d4 << 2) | (d3 << 1) | 0
print(f"  Decompressor offset = {decomp_off} bytes (should be 4)")

print(f"\nVERIFY: c.jal +4")
v16 = c_jal(4)
off = 4 >> 1
print(f"Encoding: 0x{v16:04X}")
j8=(v16>>8)&1; j10=(v16>>10)&1; j9=(v16>>9)&1; j7=(v16>>7)&1; j6=(v16>>6)&1; j2=(v16>>2)&1; j11=(v16>>11)&1; j5=(v16>>5)&1; j4=(v16>>4)&1; j3=(v16>>3)&1; j12=(v16>>12)&1
# JAL offset = {bit12, 8{bit12}, bit12, bit8, bit10, bit9, bit7, bit6, bit2, bit11, bit5, bit4, bit3, 0}
# = sign_ext({bit8, bit10, bit9, bit7, bit6, bit2, bit11, bit5, bit4, bit3, 0})
jal_off = (j12 << 20) | (j12 << 19) | (j12 << 18) | (j12 << 17) | (j12 << 16) | (j12 << 15) | (j12 << 14) | (j12 << 13) | (j12 << 12) | (j12 << 11) | (j8 << 10) | (j10 << 9) | (j9 << 8) | (j7 << 7) | (j6 << 6) | (j2 << 5) | (j11 << 4) | (j5 << 3) | (j4 << 2) | (j3 << 1) | 0
print(f"  Decompressor JAL offset = {jal_off}")
print(f"  Byte offset = {jal_off << 1} (should be 4)")
