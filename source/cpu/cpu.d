/* lilySV100 - Casio Loopy emulator written in D. */
/* Copyright (c) 2020, Lady Starbreeze */

module cpu;

import std.stdio : writefln;

import bus, disassembler, registers, type;

private CPU_Registers regs = CPU_Registers(0, 0x0E00_0480);

/* instruction decoding table */
private void function(const u16)[0x1_0000] instr_table;

/** initializes the `CPU` module */
void init()
{
    foreach (ref entry; instr_table)
    {
        entry = &i_invalid;
    }

    instr_table[0x0009] = &i_nop;

    for (umax i = 0x2000; i < 0x3000; i += 0x10)
    {
        instr_table[i | 0x2] = &i_mov!(Width.Longword, Addressing_Mode.Register, Addressing_Mode.Indirect);
        instr_table[i | 0x6] = &i_mov!(Width.Longword, Addressing_Mode.Register, Addressing_Mode.Indirect_Pre_Decrement);
    }

    for (umax i = 0x4000; i < 0x5000; i += 0x100)
    {
        instr_table[i | 0x07] = &i_ldc!(Width.Longword, Addressing_Mode.Indirect_Post_Increment, Addressing_Mode.Register_SR);
        instr_table[i | 0x0B] = &i_jmp!(true);
        instr_table[i | 0x0E] = &i_ldc!(Width.None, Addressing_Mode.Register, Addressing_Mode.Register_SR);
        instr_table[i | 0x17] = &i_ldc!(Width.Longword, Addressing_Mode.Indirect_Post_Increment, Addressing_Mode.Register_GBR);
        instr_table[i | 0x1E] = &i_ldc!(Width.None, Addressing_Mode.Register, Addressing_Mode.Register_GBR);
        instr_table[i | 0x22] = &i_sts!(Width.Longword, Addressing_Mode.Register_PR, Addressing_Mode.Indirect_Pre_Decrement);
        instr_table[i | 0x27] = &i_ldc!(Width.Longword, Addressing_Mode.Indirect_Post_Increment, Addressing_Mode.Register_VBR);
        instr_table[i | 0x2B] = &i_jmp!(false);
        instr_table[i | 0x2E] = &i_ldc!(Width.None, Addressing_Mode.Register, Addressing_Mode.Register_VBR);
    }

    for (umax i = 0x6006; i < 0x7006; i += 0x10)
    {
        instr_table[i] = &i_mov!(Width.Longword, Addressing_Mode.Indirect_Post_Increment, Addressing_Mode.Register);
    }

    for (umax i = 0xA000; i < 0xB000; i++)
    {
        instr_table[i] = &i_bra!(false);
        instr_table[i | 0x1000] = &i_bra!(true);
    }

    /* mova @(disp, pc), R0 */
    for (umax i = 0xC700; i < 0xC800; i++)
    {
        instr_table[i] = &i_mova;
    }

    /* mov.l @(disp, pc), Rn */
    for (umax i = 0xD000; i < 0xE000; i++)
    {
        instr_table[i] = &i_mov!(Width.Longword, Addressing_Mode.Indirect_Disp_PC, Addressing_Mode.Register);
    }

    /* mov #imm, Rn */
    for (umax i = 0xE000; i < 0xF000; i++)
    {
        instr_table[i] = &i_mov!(Width.None, Addressing_Mode.Immediate, Addressing_Mode.Register);
    }
}

/* memory accessor helpers */
private u16 fetch_instr()
{
    const auto instr = read_word(regs.pc);

    regs.pc = regs.next_pc;
    regs.next_pc += 2;

    return instr;
}

private u32 get_pc()
{
    return regs.pc + 2;
}

/* instruction helpers */
private u32 get_operand(Width width, Addressing_Mode mode, bool src_op)(const u16 instr)
{
    static if (mode == Addressing_Mode.Register)
    {
        const auto reg = get_reg_num!(src_op)(instr);

        static if ((width == Width.Longword) || (width == Width.None))
        {
            return regs.r[reg];
        }
        else
        {
            writefln("[CPU] <Error> Unhandled width.");

            throw new Error("Unhandled width");
        }
    }
    else static if (mode == Addressing_Mode.Register_PR)
    {
        return regs.pr;
    }
    else static if (mode == Addressing_Mode.Indirect_Post_Increment)
    {
        const auto reg = get_reg_num!(src_op)(instr);

        const auto base = regs.r[reg];

        static if (width == Width.Longword)
        {
            const auto op = read_longword(base);

            regs.r[reg] += 4;
        }
        else
        {
            writefln("[CPU] <Error> Unhandled width.");

            throw new Error("Unhandled width");
        }

        return op;
    }
    else static if (mode == Addressing_Mode.Indirect_Disp_PC)
    {
        const auto disp = cast(u32)(instr & 0xFF);

        static if (width == Width.Longword)
        {
            return read_longword(disp * 4 + (get_pc() & 0xFFFF_FFFC));
        }
        else
        {
            writefln("[CPU] <Error> Unhandled width.");

            throw new Error("Unhandled width");
        }
    }
    else static if (mode == Addressing_Mode.Immediate)
    {
        return cast(u32)cast(i32)cast(i8)(instr & 0xFF);
    }
    else
    {
        writefln("[CPU] <Error> Unhandled addressing mode. ",);

        throw new Error("Unhandled addressing mode");
    }
}

private void write_operand(Width width, Addressing_Mode dst_mode)(const u16 instr, const u32 data)
{
    static if (dst_mode == Addressing_Mode.Register)
    {
        const auto reg = get_reg_num!(false)(instr);

        regs.r[reg] = data;
    }
    else static if (dst_mode == Addressing_Mode.Register_SR)
    {
        regs.sr.raw = data & 0x0000_03F3;
    }
    else static if (dst_mode == Addressing_Mode.Register_GBR)
    {
        regs.gbr = data;
    }
    else static if (dst_mode == Addressing_Mode.Register_VBR)
    {
        regs.vbr = data;
    }
    else static if (dst_mode == Addressing_Mode.Indirect)
    {
        const auto reg = get_reg_num!(false)(instr);

        const auto address = regs.r[reg];

        static if (width == Width.Longword)
        {
            write_longword(address, data);
        }
        else
        {
            writefln("[CPU] <Error> Unhandled width.");

            throw new Error("Unhandled width");
        }
    }
    else static if (dst_mode == Addressing_Mode.Indirect_Pre_Decrement)
    {
        const auto reg = get_reg_num!(false)(instr);

        static if (width == Width.Longword)
        {
            regs.r[reg] -= 4;
            
            const auto address = regs.r[reg];

            write_longword(address, data);
        }
        else
        {
            writefln("[CPU] <Error> Unhandled width.");

            throw new Error("Unhandled width");
        }
    }
    else
    {
        writefln("[CPU] <Error> Unhandled addressing mode. ",);

        throw new Error("Unhandled addressing mode");
    }
}

/* instruction handlers */
private void i_bra(bool save_pc)(const u16 instr)
{
    /* sign-extend 12-bit displacement */
    const auto disp = cast(u32)(cast(i32)(cast(u32)(instr & 0xFFF) << 20) >> 20);

    static if (save_pc)
    {
        regs.pr = get_pc();
    }

    regs.next_pc = disp * 2 + get_pc();

    debug
    {
        /* TODO: disassembler support for bra/bsr */
        static const string[] STR_BRA = [ "BRA", "BSR" ];

        writefln("[CPU] %s %08Xh", STR_BRA[save_pc], regs.next_pc);
    }
}

private void i_jmp(bool save_pc)(const u16 instr)
{
    static if (save_pc)
    {
        regs.pr = get_pc();
    }

    regs.next_pc = get_operand!(Width.None, Addressing_Mode.Register, false)(instr);

    debug
    {
        /* TODO: disassembler support for jmp/jsr */
        static const string[] STR_JMP = [ "JMP", "JSR" ];

        writefln("[CPU] %s %08Xh", STR_JMP[save_pc], regs.next_pc);
    }
}

private void i_ldc(Width width, Addressing_Mode src_mode, Addressing_Mode dst_mode)(const u16 instr)
{
    /* setting src_op to false is hacky but it works */
    const auto op = get_operand!(width, src_mode, false)(instr);

    write_operand!(width, dst_mode)(instr, op);

    debug
    {
        disassemble!(src_mode, dst_mode, true)("LDC", width, instr);
    }
}

private void i_mov(Width width, Addressing_Mode src_mode, Addressing_Mode dst_mode)(const u16 instr)
{
    const auto op = get_operand!(width, src_mode, true)(instr);

    write_operand!(width, dst_mode)(instr, op);

    debug
    {
        disassemble!(src_mode, dst_mode, false)("MOV", width, instr);
    }
}

private void i_mova(const u16 instr)
{
    const auto disp = cast(u32)(instr & 0xFF);

    regs.r[0] = disp * 4 + (get_pc() & 0xFFFF_FFFC);

    debug
    {
        disassemble!(Addressing_Mode.Indirect_Disp_PC, Addressing_Mode.Register_Index, false)("MOVA", Width.None, instr);
    }
}

private void i_nop(const u16 instr)
{
    debug
    {
        writefln("[CPU] NOP");
    }
}

private void i_sts(Width width, Addressing_Mode src_mode, Addressing_Mode dst_mode)(const u16 instr)
{
    const auto op = get_operand!(width, src_mode, true)(instr);

    write_operand!(width, dst_mode)(instr, op);

    debug
    {
        disassemble!(src_mode, dst_mode, false)("STS", width, instr);
    }
}

private void i_invalid(const u16 instr)
{
    writefln("[CPU] <Error> Unhandled instruction %04Xh (0b%016b).", instr, instr);

    throw new Error("Unhandled instruction");
}

/** steps the CPU core instruction by instruction */
void run()
{
    debug
    {
        const auto pc = regs.pc;
    }

    const auto instr = fetch_instr();

    debug
    {
        writefln("[CPU] [%08Xh:%04Xh]", pc, instr);
    }

    instr_table[instr](instr);

    debug
    {
        writefln("[CPU]  r0: %08Xh,  r1: %08Xh,  r2: %08Xh,  r3: %08Xh", regs.r[0], regs.r[1], regs.r[2], regs.r[3]);
        writefln("[CPU]  r4: %08Xh,  r5: %08Xh,  r6: %08Xh,  r7: %08Xh", regs.r[4], regs.r[5], regs.r[6], regs.r[7]);
        writefln("[CPU]  r8: %08Xh,  r9: %08Xh, r10: %08Xh, r11: %08Xh", regs.r[8], regs.r[9], regs.r[10], regs.r[11]);
        writefln("[CPU] r12: %08Xh, r13: %08Xh, r14: %08Xh, r15: %08Xh", regs.r[12], regs.r[13], regs.r[14], regs.r[15]);
    }
}
