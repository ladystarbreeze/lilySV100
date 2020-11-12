/* lilySV100 - Casio Loopy emulator written in D. */
/* Copyright (c) 2020, Lady Starbreeze */

module registers;

import std.bitmanip : bitfields;
import std.meta     : Alias;

import type;

alias MACH = Alias!1u;
alias MACL = Alias!0u;

private const u32 SR_DEFAULT = 0x00000300;

/** SuperH status register */
union Status_Register
{
    /** raw representation of SR value */
    u32 raw = SR_DEFAULT;

    mixin(bitfields!(
        bool, "t", 1,
        bool, "s", 1,
        u32 , "unused1", 2,
        u32 , "i_mask" , 4,
        bool, "q", 1,
        bool, "m", 1,
        u32 , "unused2", 22));
}

/** multiply-accumulate register */
union MA_Register
{
    /** raw representation of mach + macl */
    u64 raw;
    /** macl/mach */
    u32[2] mac;
}

/** SuperH-1 CPU registers */
struct CPU_Registers
{
    /** 16 32-bit general-purpose registers */
    u32[16] r;

    /* control registers */

    /** status register */
    Status_Register sr;
    /** global base register*/
    u32 gbr;
    /** vector base register*/
    u32 vbr;

    /* system registers */

    /** multiply-accumulate high and low registers */
    MA_Register mac;
    /** procedure register */
    u32 pr;
    /** program counters */
    u32 pc, next_pc;

    @disable this();
    /** initializes CPU registers */
    this(const u32 vbr, const u32 pc)
    {
        this.vbr = vbr;
        /* SuperH systems normally initialize PC to a value stored in the vector address table.
           On the Loopy, this value is E000480h. */ 
        this.pc      = pc;
        this.next_pc = pc + 2; 
    }
}
