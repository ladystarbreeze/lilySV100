/* lilySV100 - Casio Loopy emulator written in D. */
/* Copyright (c) 2020, Lady Starbreeze */

module disassembler;

import std.conv  : to;
import std.stdio : writefln;

import type;

/** access width */
enum Width
{
    Byte,
    Word,
    Longword,
    None
}

/** CPU addressing modes */
enum Addressing_Mode
{
    /* register Rn */
    Register,
    /* register index R0 */
    Register_Index,
    /* indirect @Rn */
    Indirect,
    /* indirect pre-decrement @-Rn */
    Indirect_Pre_Decrement,
    /* indirect post-increment @Rn+ */
    Indirect_Post_Increment,
    /* indirect register @(R0, Rn) */
    Indirect_Register,
    /* indirect GBR @(R0, GBR) */
    Indirect_GBR,
    /* indirect displacement @(disp, Rn) */
    Indirect_Disp,
    /* indirect displacement GBR @(disp, GBR) */
    Indirect_Disp_GBR,
    /* indirect displacement PC @(disp, PC) */
    Indirect_Disp_PC,
    /* immediate #imm */
    Immediate,
    None
}

u32 get_reg_num(bool src_op)(const u16 instr)
{
    static if (src_op)
    {
        return (instr >>> 4) & 0xF;
    }
    else
    {
        return (instr >>> 8) & 0xF;
    }
}

private string get_operand(Addressing_Mode mode, bool src_op)(const u16 instr)
{
    static if (src_op)
    {
        const auto op = " ";
    }
    else
    {
        const auto op = ", ";
    }

    static if (mode == Addressing_Mode.Register)
    {
        return op ~ "R" ~ to!string(get_reg_num!(src_op)(instr));
    }
    else static if (mode == Addressing_Mode.Register_Index)
    {
        return op ~ "R0";
    }
    else static if (mode == Addressing_Mode.Indirect)
    {
        return op ~ "@R" ~ to!string(get_reg_num!(src_op)(instr));
    }
    else static if (mode == Addressing_Mode.Indirect_Pre_Decrement)
    {
        return op ~ "@-R" ~ to!string(get_reg_num!(src_op)(instr));
    }
    else static if (mode == Addressing_Mode.Indirect_Post_Increment)
    {
        return op ~ "@R" ~ to!string(get_reg_num!(src_op)(instr)) ~ "+";
    }
    else static if (mode == Addressing_Mode.Indirect_Register)
    {
        return op ~ "@(R0, R" ~ to!string(get_reg_num!(src_op)(instr)) ~ ")";
    }
    else static if (mode == Addressing_Mode.Indirect_GBR)
    {
        return op ~ "@(R0, GBR)";
    }
    else static if (mode == Addressing_Mode.Indirect_Disp)
    {
        return op ~ "@(" ~ to!string(instr & 0xFF) ~ ", R" ~ to!string(get_reg_num!(src_op)(instr)) ~ ")";
    }
    else static if (mode == Addressing_Mode.Indirect_Disp_GBR)
    {
        return op ~ "@(" ~ to!string(instr & 0xFF) ~ ", GBR)";
    }
    else static if (mode == Addressing_Mode.Indirect_Disp_PC)
    {
        return op ~ "@(" ~ to!string(instr & 0xFF) ~ ", PC)";
    }
    else static if (mode == Addressing_Mode.Immediate)
    {
        return op ~ "#" ~ to!string(instr & 0xFF);
    }
    else
    {
        return "";
    }
}

/** disassembles instructions and prints them out */
void disassemble(Addressing_Mode src_mode, Addressing_Mode dst_mode)(const string mnemonic, const Width width, const u16 instr)
{
    static const string[] STR_WIDTH = [ ".B", ".W", ".L", "" ];

    writefln("[CPU] %s%s%s%s", mnemonic, STR_WIDTH[width], get_operand!(src_mode, true)(instr), get_operand!(dst_mode, false)(instr));
}
