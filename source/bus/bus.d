/* lilySV100 - Casio Loopy emulator written in D. */
/* Copyright (c) 2020, Lady Starbreeze */

module bus;

import core.bitop : byteswap, bswap;
import std.file   : read;
import std.stdio  : writefln;

import file, type;

/* RAM */
private u8[] ram;
/* ROM */
private u8[] rom;

/** initializes the `Bus` module */
void init(const string rom_path)
{
    rom = load_file(rom_path);

    writefln("[Bus] Successfully initialized.");
}

/* memory accessors */

/** returns the 16-bit word located at `address` */
u16 read_word(const u32 address)
{
    const auto region = (address >>> 24) & 0xF;

    switch (region)
    {
    case 0x0E:
        if (address < 0x0E1F_FFFF)
        {
            return byteswap(*cast(u16*)(rom.ptr + (address & 0x1F_FFFF)));
        }
        goto default;
    default:
        writefln("[Bus] <Error> Unhandled read_word @ %08Xh.", address);

        throw new Error("Unhandled read_word");
    }
}

/** returns the 32-bit long word located at `address` */
u32 read_longword(const u32 address)
{
    const auto region = (address >>> 24) & 0xF;

    switch (region)
    {
    case 0x0E:
        if (address < 0x0E1F_FFFF)
        {
            return bswap(*cast(u32*)(rom.ptr + (address & 0x1F_FFFF)));
        }
        goto default;
    default:
        writefln("[Bus] <Error> Unhandled read_longword @ %08Xh.", address);

        throw new Error("Unhandled read_longword");
    }
}
