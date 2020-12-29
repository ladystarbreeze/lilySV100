/* lilySV100 - Casio Loopy emulator written in D. */
/* Copyright (c) 2020, Lady Starbreeze */

module cpu;

import std.conv  : to;
import std.stdio : writefln;

import bus, disassembler, registers, type;

private auto VERSION_DISASSEMBLER = false;

/** SH-1 CPU registers */
CPU_Registers regs = CPU_Registers(0, 0x0E00_0480);

/* instruction decoding table */
private void function(const u16)[0x1_0000] instr_table;

/** initializes the `CPU` module */
void init()
{
    foreach (ref entry; instr_table)
    {
        entry = &i_invalid;
    }

    for (size_t i = 0; i < 0x1_0000; i++)
    {
        if ((i & 0xF000) == 0x0000)
        {
            if ((i & 0x00F) == 0x004)
            {
                instr_table[i] = &i_movbs0;
            }
            if ((i & 0x00F) == 0x005)
            {
                instr_table[i] = &i_movws0;
            }
            if ((i & 0x00F) == 0x006)
            {
                instr_table[i] = &i_movls0;
            }
            if ((i & 0x00F) == 0x00C)
            {
                instr_table[i] = &i_movbl0;
            }
            if ((i & 0x00F) == 0x00D)
            {
                instr_table[i] = &i_movwl0;
            }
            if ((i & 0x0FF) == 0x002)
            {
                instr_table[i] = &i_stcsr;
            }
            if ((i & 0xFFF) == 0x009)
            {
                instr_table[i] = &i_nop;
            }
            if ((i & 0xFFF) == 0x00B)
            {
                instr_table[i] = &i_rts;
            }
        }
        if ((i & 0xF000) == 0x1000)
        {
            instr_table[i] = &i_movls4;
        }
        if ((i & 0xF000) == 0x2000)
        {
            if ((i & 0xF) == 0x0)
            {
                instr_table[i] = &i_movbs;
            }
            if ((i & 0xF) == 0x1)
            {
                instr_table[i] = &i_movws;
            }
            if ((i & 0xF) == 0x2)
            {
                instr_table[i] = &i_movls;
            }
            if ((i & 0xF) == 0x6)
            {
                instr_table[i] = &i_movlm;
            }
            if ((i & 0xF) == 0x8)
            {
                instr_table[i] = &i_tst;
            }
            if ((i & 0xF) == 0x9)
            {
                instr_table[i] = &i_and;
            }
            if ((i & 0xF) == 0xB)
            {
                instr_table[i] = &i_or;
            }
            if ((i & 0xF) == 0xD)
            {
                instr_table[i] = &i_xtrct;
            }
        }
        if ((i & 0xF000) == 0x3000)
        {
            if ((i & 0xF) == 0x0)
            {
                instr_table[i] = &i_cmpeq;
            }
            if ((i & 0xF) == 0x2)
            {
                instr_table[i] = &i_cmphs;
            }
            if ((i & 0xF) == 0x3)
            {
                instr_table[i] = &i_cmpge;
            }
            if ((i & 0xF) == 0x6)
            {
                instr_table[i] = &i_cmphi;
            }
            if ((i & 0xF) == 0x7)
            {
                instr_table[i] = &i_cmpgt;
            }
            if ((i & 0xF) == 0x8)
            {
                instr_table[i] = &i_sub;
            }
            if ((i & 0xF) == 0xC)
            {
                instr_table[i] = &i_add;
            }
        }
        if ((i & 0xF000) == 0x4000)
        {
            if ((i & 0xFF) == 0x00)
            {
                instr_table[i] = &i_shll;
            }
            if ((i & 0xFF) == 0x01)
            {
                instr_table[i] = &i_shlr;
            }
            if ((i & 0xFF) == 0x08)
            {
                instr_table[i] = &i_shll2;
            }
            if ((i & 0xFF) == 0x09)
            {
                instr_table[i] = &i_shlr2;
            }
            if ((i & 0xFF) == 0x0B)
            {
                instr_table[i] = &i_jsr;
            }
            if ((i & 0xFF) == 0x0E)
            {
                instr_table[i] = &i_ldcsr;
            }
            if ((i & 0xFF) == 0x12)
            {
                instr_table[i] = &i_stsmmacl;
            }
            if ((i & 0xFF) == 0x15)
            {
                instr_table[i] = &i_cmppl;
            }
            if ((i & 0xFF) == 0x18)
            {
                instr_table[i] = &i_shll8;
            }
            if ((i & 0xFF) == 0x19)
            {
                instr_table[i] = &i_shlr8;
            }
            if ((i & 0xFF) == 0x1E)
            {
                instr_table[i] = &i_ldcgbr;
            }
            if ((i & 0xFF) == 0x22)
            {
                instr_table[i] = &i_stsmpr;
            }
            if ((i & 0xFF) == 0x26)
            {
                instr_table[i] = &i_ldsmpr;
            }
            if ((i & 0xFF) == 0x28)
            {
                instr_table[i] = &i_shll16;
            }
            if ((i & 0xFF) == 0x2B)
            {
                instr_table[i] = &i_jmp;
            }
            if ((i & 0xFF) == 0x2E)
            {
                instr_table[i] = &i_ldcvbr;
            }
        }
        if ((i & 0xF000) == 0x5000)
        {
            instr_table[i] = &i_movll4;
        }
        if ((i & 0xF000) == 0x6000)
        {
            if ((i & 0xF) == 0x0)
            {
                instr_table[i] = &i_movbl;
            }
            if ((i & 0xF) == 0x1)
            {
                instr_table[i] = &i_movwl;
            }
            if ((i & 0xF) == 0x2)
            {
                instr_table[i] = &i_movll;
            }
            if ((i & 0xF) == 0x3)
            {
                instr_table[i] = &i_mov;
            }
            if ((i & 0xF) == 0x4)
            {
                instr_table[i] = &i_movbp;
            }
            if ((i & 0xF) == 0x6)
            {
                instr_table[i] = &i_movlp;
            }
            if ((i & 0xF) == 0x9)
            {
                instr_table[i] = &i_swapw;
            }
            if ((i & 0xF) == 0xC)
            {
                instr_table[i] = &i_extub;
            }
            if ((i & 0xF) == 0xD)
            {
                instr_table[i] = &i_extuw;
            }
            if ((i & 0xF) == 0xF)
            {
                instr_table[i] = &i_extsw;
            }
        }
        if ((i & 0xF000) == 0x7000)
        {
            instr_table[i] = &i_addi;
        }
        if ((i & 0xF000) == 0x8000)
        {
            if ((i & 0xF00) == 0x100)
            {
                instr_table[i] = &i_movws4;
            }
            if ((i & 0xF00) == 0x500)
            {
                instr_table[i] = &i_movwl4;
            }
            if ((i & 0xF00) == 0x800)
            {
                instr_table[i] = &i_cmpim;
            }
            if ((i & 0xF00) == 0x900)
            {
                instr_table[i] = &i_bt;
            }
            if ((i & 0xF00) == 0xB00)
            {
                instr_table[i] = &i_bf;
            }
        }
        if ((i & 0xF000) == 0x9000)
        {
            instr_table[i] = &i_movwi;
        }
        if ((i & 0xF000) == 0xA000)
        {
            instr_table[i] = &i_bra;
        }
        if ((i & 0xF000) == 0xB000)
        {
            instr_table[i] = &i_bsr;
        }
        if ((i & 0xF000) == 0xC000)
        {
            if ((i & 0xF00) == 0x100)
            {
                instr_table[i] = &i_movwsg;
            }
            if ((i & 0xF00) == 0x900)
            {
                instr_table[i] = &i_andi;
            }
            if ((i & 0xF00) == 0xB00)
            {
                instr_table[i] = &i_ori;
            }
            if ((i & 0xF00) == 0xF00)
            {
                instr_table[i] = &i_orm;
            }
        }
        if ((i & 0xF000) == 0xD000)
        {
            instr_table[i] = &i_movli;
        }
        if ((i & 0xF000) == 0xE000)
        {
            instr_table[i] = &i_movi;
        }
    }
}

/* Add Binary */
private void i_add(const u16 instr)
{
    regs.r[get_n(instr)] += regs.r[get_m(instr)];
}

private void i_addi(const u16 instr)
{
    regs.r[get_n(instr)] += cast(u32)cast(i32)cast(i8)get_disp8(instr);
}

/* AND Logical*/
private void i_and(const u16 instr)
{
    regs.r[get_n(instr)] &= regs.r[get_m(instr)];
}

private void i_andi(const u16 instr)
{
    regs.r[0] &= get_disp8(instr);
}

/* Branch */
private void i_bra(const u16 instr)
{
    regs.next_pc = get_pc() + cast(u32)(cast(i32)(get_disp12(instr) << 20) >> 19);
}

/* Branch if False */
private void i_bf(const u16 instr)
{
    if (!regs.sr.t)
    {
        regs.pc = get_pc() + (cast(u32)cast(i32)cast(i8)get_disp8(instr) << 1);
        regs.next_pc = regs.pc + 2;
    }
}

/* Branch to Subroutine */
private void i_bsr(const u16 instr)
{
    regs.pr = regs.pc;
    regs.next_pc = get_pc() + cast(u32)(cast(i32)(get_disp12(instr) << 20) >> 19);
}

/* Branch if True */
private void i_bt(const u16 instr)
{
    if (regs.sr.t)
    {
        regs.pc = get_pc() + (cast(u32)cast(i32)cast(i8)get_disp8(instr) << 1);
        regs.next_pc = regs.pc + 2;
    }
}

/* Compare Conditionally */
private void i_cmpeq(const u16 instr)
{
    regs.sr.t = regs.r[get_n(instr)] == regs.r[get_m(instr)];
}

private void i_cmpge(const u16 instr)
{
    regs.sr.t = cast(i32)regs.r[get_n(instr)] >= cast(i32)regs.r[get_m(instr)];
}

private void i_cmpgt(const u16 instr)
{
    regs.sr.t = cast(i32)regs.r[get_n(instr)] > cast(i32)regs.r[get_m(instr)];
}

private void i_cmphi(const u16 instr)
{
    regs.sr.t = regs.r[get_n(instr)] > regs.r[get_m(instr)];
}

private void i_cmphs(const u16 instr)
{
    regs.sr.t = regs.r[get_n(instr)] >= regs.r[get_m(instr)];
}

private void i_cmpim(const u16 instr)
{
    regs.sr.t = regs.r[0] == cast(u32)cast(i32)cast(i8)get_disp8(instr);
}

private void i_cmppl(const u16 instr)
{
    regs.sr.t = cast(i32)regs.r[get_n(instr)] > 0;
}

/* Extend as Signed */
private void i_extsw(const u16 instr)
{
    regs.r[get_n(instr)] = cast(u32)cast(i32)cast(i16)regs.r[get_m(instr)];
}

/* Extend as Unsigned */
private void i_extub(const u16 instr)
{
    regs.r[get_n(instr)] = regs.r[get_m(instr)] & 0xFF;
}

private void i_extuw(const u16 instr)
{
    regs.r[get_n(instr)] = regs.r[get_m(instr)] & 0xFFFF;
}

/* Jump */
private void i_jmp(const u16 instr)
{
    regs.next_pc = regs.r[get_n(instr)];
}

/* Jump to Subroutine*/
private void i_jsr(const u16 instr)
{
    regs.pr = regs.pc;
    regs.next_pc = regs.r[get_n(instr)];
}

/* Load Control Register */
private void i_ldcgbr(const u16 instr)
{
    regs.gbr = regs.r[get_n(instr)];
}

private void i_ldcsr(const u16 instr)
{
    regs.sr.raw = regs.r[get_n(instr)];
}

private void i_ldcvbr(const u16 instr)
{
    regs.vbr = regs.r[get_n(instr)];
}

/* Load System Register */
private void i_ldsmpr(const u16 instr)
{
    const auto m = get_n(instr);

    regs.pr = read_lword(regs.r[m]);

    regs.r[m] += 4;
}

/* Move Data */
private void i_mov(const u16 instr)
{
    regs.r[get_n(instr)] = regs.r[get_m(instr)];
}

private void i_movbl(const u16 instr)
{
    regs.r[get_n(instr)] = cast(u32)cast(i32)cast(i8)read_byte(regs.r[get_m(instr)]);
}

private void i_movbl0(const u16 instr)
{
    regs.r[get_n(instr)] = cast(u32)cast(i32)cast(i8)read_byte(regs.r[get_m(instr)] + regs.r[0]);
}

private void i_movbp(const u16 instr)
{
    const auto m = get_m(instr);
    const auto n = get_n(instr);

    regs.r[n] = cast(u32)cast(i32)cast(i8)read_byte(regs.r[m]);

    if (n != m)
    {
        ++regs.r[m];
    }
}

private void i_movbs(const u16 instr)
{
    write_byte(regs.r[get_n(instr)], cast(u8)regs.r[get_m(instr)]);
}

private void i_movbs0(const u16 instr)
{
    write_byte(regs.r[get_n(instr)] + regs.r[0], cast(u8)regs.r[get_m(instr)]);
}

private void i_movll(const u16 instr)
{
    regs.r[get_n(instr)] = read_lword(regs.r[get_m(instr)]);
}

private void i_movlm(const u16 instr)
{
    const auto n = get_n(instr);

    regs.r[n] -= 4;

    write_lword(regs.r[n], regs.r[get_m(instr)]);
}

private void i_movls(const u16 instr)
{
    write_lword(regs.r[get_n(instr)], regs.r[get_m(instr)]);
}

private void i_movls0(const u16 instr)
{
    write_lword(regs.r[get_n(instr)] + regs.r[0], regs.r[get_m(instr)]);
}

private void i_movlp(const u16 instr)
{
    const auto m = get_m(instr);
    const auto n = get_n(instr);

    regs.r[n] = read_lword(regs.r[m]);

    if (n != m)
    {
        regs.r[m] += 4;
    }
}

private void i_movwl(const u16 instr)
{
    regs.r[get_n(instr)] = cast(u32)cast(i32)cast(i16)read_word(regs.r[get_m(instr)]);
}

private void i_movwl0(const u16 instr)
{
    regs.r[get_n(instr)] = cast(u32)cast(i32)cast(i16)read_word(regs.r[get_m(instr)] + regs.r[0]);
}

private void i_movws(const u16 instr)
{
    write_word(regs.r[get_n(instr)], cast(u16)regs.r[get_m(instr)]);
}

private void i_movws0(const u16 instr)
{
    write_word(regs.r[get_n(instr)] + regs.r[0], cast(u16)regs.r[get_m(instr)]);
}

/* Move Immediate Data */
private void i_movi(const u16 instr)
{
    regs.r[get_n(instr)] = cast(u32)cast(i32)cast(i8)get_disp8(instr);
}

private void i_movwi(const u16 instr)
{
    regs.r[get_n(instr)] = cast(u32)cast(i32)cast(i16)read_word(get_pc() + (get_disp8(instr) << 1)); 
}

private void i_movli(const u16 instr)
{
    regs.r[get_n(instr)] = read_lword((get_pc() & 0xFFFF_FFFC) + (get_disp8(instr) << 2)); 
}

/* Move Peripheral Data */
private void i_movwsg(const u16 instr)
{
    write_word(regs.gbr + (get_disp8(instr) << 1), cast(u16)regs.r[0]);
}

/* Move Structure Data */
private void i_movll4(const u16 instr)
{
    regs.r[get_n(instr)] = read_lword(regs.r[get_m(instr)] + (get_disp4(instr) << 2));
}

private void i_movls4(const u16 instr)
{
    write_lword(regs.r[get_n(instr)] + (get_disp4(instr) << 2), regs.r[get_m(instr)]);
}

private void i_movwl4(const u16 instr)
{
    regs.r[0] = cast(u32)cast(i32)cast(i16)read_word(regs.r[get_m(instr)] + (get_disp4(instr) << 1));
}

private void i_movws4(const u16 instr)
{
    write_word(regs.r[get_m(instr)] + (get_disp4(instr) << 1), cast(u16)regs.r[0]);
}

/* Multiply as Unsigned Word */
private void i_mulu(const u16 instr)
{
    
}

/* No Operation */
private void i_nop(const u16 instr)
{}

/* OR Logical */
private void i_or(const u16 instr)
{
    regs.r[get_n(instr)] |= regs.r[get_m(instr)];
}

private void i_ori(const u16 instr)
{
    regs.r[0] |= get_disp8(instr);
}

private void i_orm(const u16 instr)
{
    const auto address = regs.gbr + regs.r[0];

    write_byte(address, read_byte(address) | cast(u8)get_disp8(instr));
}

/* Return from Subroutine */
private void i_rts(const u16 instr)
{
    regs.next_pc = regs.pr;
}

/* Shift Logical Left */
private void i_shll(const u16 instr)
{
    const auto n = get_n(instr);

    regs.sr.t = (regs.r[n] & 0x8000_0000) != 0;
    regs.r[n] <<= 1;
}

private void i_shll2(const u16 instr)
{
    regs.r[get_n(instr)] <<= 2;
}

private void i_shll8(const u16 instr)
{
    regs.r[get_n(instr)] <<= 8;
}

private void i_shll16(const u16 instr)
{
    regs.r[get_n(instr)] <<= 16;
}

/* Shift Logical Right */
private void i_shlr(const u16 instr)
{
    const auto n = get_n(instr);

    regs.sr.t = (regs.r[n] & 1) != 0;
    regs.r[n] >>= 1;
}

private void i_shlr2(const u16 instr)
{
    regs.r[get_n(instr)] >>= 2;
}

private void i_shlr8(const u16 instr)
{
    regs.r[get_n(instr)] >>= 8;
}

/* Store Control Register */
private void i_stcsr(const u16 instr)
{
    regs.r[get_n(instr)] = regs.sr.raw;
}

/* Store System Register */
private void i_stsmmacl(const u16 instr)
{
    const auto n = get_n(instr);

    regs.r[n] -= 4;

    write_lword(regs.r[n], regs.mac.mac[MACL]);
}

private void i_stsmpr(const u16 instr)
{
    const auto n = get_n(instr);

    regs.r[n] -= 4;

    write_lword(regs.r[n], regs.pr);
}

/* Subtract Binary */
private void i_sub(const u16 instr)
{
    regs.r[get_n(instr)] -= regs.r[get_m(instr)];
}

/* Swap Register */
private void i_swapw(const u16 instr)
{
    const auto m = get_m(instr);

    regs.r[get_n(instr)] = (regs.r[m] >> 16) | (regs.r[m] << 16);
}

/* Test Logical */
private void i_tst(const u16 instr)
{
    regs.sr.t = (regs.r[get_n(instr)] & regs.r[get_m(instr)]) == 0;
}

/* Extract */
private void i_xtrct(const u16 instr)
{
    const auto m = get_m(instr);
    const auto n = get_n(instr);

    regs.r[n] = (regs.r[n] >> 16) | (regs.r[m] << 16);
}

private u32 get_disp4(const u16 instr)
{
    return cast(u32)(instr & 0x0F);
}

private u32 get_disp8(const u16 instr)
{
    return cast(u32)(instr & 0xFF);
}

private u32 get_disp12(const u16 instr)
{
    return cast(u32)(instr & 0xFFF);
}

private u32 get_m(const u16 instr)
{
    return cast(u32)((instr >> 4) & 0xF);
}

private u32 get_n(const u16 instr)
{
    return cast(u32)((instr >> 8) & 0xF);
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

private void i_invalid(const u16 instr)
{
    writefln("[CPU] <Error> Unhandled instruction %s (0b%016b) @ %08Xh.", get_mnemonic(instr), instr, regs.current_pc);

    dump_registers();

    throw new Error("Unhandled instruction");
}

/** prints out current CPU state */
void dump_registers()
{
    writefln("[CPU]  PC: %08Xh,  PR: %08Xh, GBR: %08Xh, VBR: %08Xh", regs.current_pc, regs.pr, regs.gbr, regs.vbr);
    writefln("[CPU]  r0: %08Xh,  r1: %08Xh,  r2: %08Xh,  r3: %08Xh", regs.r[0], regs.r[1], regs.r[2], regs.r[3]);
    writefln("[CPU]  r4: %08Xh,  r5: %08Xh,  r6: %08Xh,  r7: %08Xh", regs.r[4], regs.r[5], regs.r[6], regs.r[7]);
    writefln("[CPU]  r8: %08Xh,  r9: %08Xh, r10: %08Xh, r11: %08Xh", regs.r[8], regs.r[9], regs.r[10], regs.r[11]);
    writefln("[CPU] r12: %08Xh, r13: %08Xh, r14: %08Xh, r15: %08Xh", regs.r[12], regs.r[13], regs.r[14], regs.r[15]);
}

/** steps the CPU core instruction by instruction */
void run()
{
    regs.current_pc = regs.pc;

    const auto instr = fetch_instr();

    instr_table[instr](instr);
}
