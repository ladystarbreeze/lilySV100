/* lilySV100 - Casio Loopy emulator written in D. */
/* Copyright (c) 2020, Lady Starbreeze */

module bus;

import core.bitop : byteswap, bswap;
import std.file   : read;
import std.stdio  : writefln;

import file, type;

/* RAM */
private u8[0x8_0000] ram;
/* ROM */
private u8[] rom;

/* used for BIOS reads */
private u16 BIOS_NOP = 0x0009;
private u16 BIOS_RTS = 0x000B;

/** initializes the `Bus` module */
void init(const string rom_path)
{
    rom = load_file(rom_path);

    writefln("[Bus] Successfully initialized.");
}

/* memory accessors */

u8 read_byte(const u32 address)
{
    const auto region = (address >>> 24) & 0xFF;

    switch (region)
    {
    case 0x0E:
        if (address < 0x0E1F_FFFF)
        {
            return rom[address & 0x1F_FFFF];
        }
        goto default;
    default:
        writefln("[Bus] <Error> Unhandled byte read @ %08Xh.", address);

        throw new Error("Unhandled byte read");
    }
}

/** returns the 16-bit word located at `address` */
u16 read_word(const u32 address)
{
    const auto region = (address >>> 24) & 0xFF;

    switch (region)
    {
    case 0x00:
        if (address < 0x0000_8000)
        {
            writefln("[Bus] <Warning> Unhandled BIOS word read @ %08Xh.", address);

            if ((address & 3) == 0)
            {
                return BIOS_RTS;
            }

            return BIOS_NOP;
        }
        goto default;
    case 0x0E:
        if (address < 0x0E1F_FFFF)
        {
            return byteswap(*cast(u16*)(rom.ptr + (address & 0x1F_FFFF)));
        }
        goto default;
    default:
        writefln("[Bus] <Error> Unhandled word read @ %08Xh.", address);

        throw new Error("Unhandled word read");
    }
}

/** returns the 32-bit long word located at `address` */
u32 read_longword(const u32 address)
{
    const auto region = (address >>> 24) & 0xFF;

    switch (region)
    {
    case 0x0E:
        if (address < 0x0E1F_FFFF)
        {
            return bswap(*cast(u32*)(rom.ptr + (address & 0x1F_FFFF)));
        }
        goto default;
    default:
        writefln("[Bus] <Error> Unhandled longword read @ %08Xh.", address);

        throw new Error("Unhandled longword read");
    }
}

/** writes the 16-bit word data to `address` */
void write_word(const u32 address, const u16 data)
{
    const auto region = (address >>> 24) & 0xFF;

    switch (region)
    {
    case 0x04:
    case 0x0C:
        const auto sub_region = (address >>> 12) & 0xFFF;

        switch (sub_region)
        {
        case 0x051:
            if ((address & 0xFFF) < 0x200)
            {
                writefln("[Bus] [PRAM] <Warning> Unhandled word write (%04Xh) @ %08Xh.", data, address);
            }
            else
            {
                goto default;
            }
            break;
        case 0x059:
        case 0x05A:
            writefln("[Bus] <Warning> Unhandled word write (%04Xh) @ %08Xh.", data, address);
            break;
        default:
            writefln("[Bus] <Error> Unhandled word write (%04Xh) @ %08Xh.", data, address);

            throw new Error("Unhandled word write");
        }

        return;
    default:
        writefln("[Bus] <Error> Unhandled word write (%04Xh) @ %08Xh.", data, address);

        throw new Error("Unhandled word write");
    }
}

/** writes the 32-bit long word data to `address` */
void write_longword(const u32 address, const u32 data)
{
    const auto region = (address >>> 24) & 0xFF;

    switch (region)
    {
    case 0x09:
        if (address < 0x0907_FFFF)
        {
            *cast(u32*)(ram.ptr + (address & 0x7_FFFF)) = data;

            return;
        }
        goto default;
    default:
        writefln("[Bus] <Error> Unhandled longword write (%08Xh) @ %08Xh.", data, address);

        throw new Error("Unhandled longword write");
    }
}
