/* lilySV100 - Casio Loopy emulator written in D. */
/* Copyright (c) 2020, Lady Starbreeze */

module bus;

import core.bitop : byteswap, bswap;
import std.file;
import std.stdio;

import bios, cpu, file, type;

/* RAM */
private u8[0x8_0000] ram;
/* ROM */
private u8[] rom;

private u8[0x200] pram;
private u8[0x10000] vram;

private u8[0x400] oram;

/* used for BIOS reads */
private u16 BIOS_NOP = 0x0009;
private u16 BIOS_RTS = 0x000B;
private bool BIOS_FIRST_READ = true;

/** initializes the `Bus` module */
void init(const string rom_path)
{
    rom = load_file(rom_path);

    writefln("[Bus] Successfully initialized.");
}

/* memory accessors */
/** returns the 8-bit byte located at `address` */
u8 read_byte(const u32 address)
{
    const auto region = (address >>> 24) & 0xFF;

    switch (region)
    {
    case 0x05:
        if (address >= 0x05FF_FF00)
        {
            const auto ocio_reg = address & 0xFF;

            switch (ocio_reg)
            {
            case 0x84:
                writefln("[Bus] <On-Chip IO> Byte read @ IPRA_LO.");
                break;
            case 0x89:
                writefln("[Bus] <On-Chip IO> Byte read @ IPRC_HI.");
                break;
            default:
                writefln("[Bus] <On-Chip IO> <Error> Unhandled byte read @ %02Xh.", ocio_reg);

                throw new Error("Unhandled byte read");
            }

            return 0x00;
        }
        goto default;
    case 0x09:
        if (address < 0x0908_0000)
        {
            return ram[address & 0x7_FFFF];
        }
        goto default;
    case 0x0E:
        if (address < 0x0E20_0000)
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
            if (BIOS_FIRST_READ)
            {
                hle_bios_routine(address);

                BIOS_FIRST_READ = !BIOS_FIRST_READ;

                return BIOS_RTS;
            }
            else
            {
                BIOS_FIRST_READ = !BIOS_FIRST_READ;

                return BIOS_NOP;
            }
        }
        goto default;
    case 0x05:
        if (address >= 0x05FF_FF00)
        {
            const auto ocio_reg = address & 0xFE;

            switch (ocio_reg)
            {
            case 0x48:
                writefln("[Bus] <On-Chip IO> Word read @ DMAOR.");
                break;
            default:
                writefln("[Bus] <On-Chip IO> <Error> Unhandled word write @ %02Xh.", ocio_reg);

                throw new Error("Unhandled word read");
            }

            return 0;
        }
        goto default;
    case 0x09:
        if (address < 0x0908_0000)
        {
            return byteswap(*cast(u16 *)(ram.ptr + (address & 0x7_FFFE)));
        }
        goto default;
    case 0x0C:
        const auto sub_region = (address >>> 12) & 0xFFF;

        switch (sub_region)
        {
        case 0x058:
            if (address == 0x0C05_8004)
            {
                static u16 VCOUNT = 0;

                writefln("[Bus] Read word @ VCOUNT.");

                VCOUNT = (VCOUNT + 1) & 0x1FF;

                return VCOUNT;
            }
            goto default;
        case 0x05A:
        case 0x05B:
            writefln("[Bus] <IO %03Xh> Unhandled word read @ %08Xh.", sub_region, address);

            return 0;
        default:
            break;
        }

        goto default;
    case 0x0E:
        if (address < 0x0E20_0000)
        {
            return byteswap(*cast(u16 *)(rom.ptr + (address & 0x1F_FFFE)));
        }
        goto default;
    default:
        writefln("[Bus] <Error> Unhandled word read @ %08Xh.", address);

        throw new Error("Unhandled word read");
    }
}

/** returns the 32-bit word located at `address` */
u32 read_lword(const u32 address)
{
    const auto region = (address >>> 24) & 0xFF;

    switch (region)
    {
    case 0x02:
        writefln("[Bus] <R02> Unhandled lword read @ %08Xh.", address);

        return 0xCAFE_CAFE;
    case 0x09:
        if (address < 0x0908_0000)
        {
            return bswap(*cast(u32 *)(ram.ptr + (address & 0x7_FFFC)));
        }
        goto default;
    case 0x0E:
        if (address < 0x0E20_0000)
        {
            return bswap(*cast(u32 *)(rom.ptr + (address & 0x1F_FFFC)));
        }
        goto default;
    default:
        writefln("[Bus] <Error> Unhandled lword read @ %08Xh.", address);

        throw new Error("Unhandled lword read");
    }
}

/** writes an 8-bit byte to `address` */
void write_byte(const u32 address, const u8 data)
{
    const auto region = (address >>> 24) & 0xFF;

    switch (region)
    {
    case 0x05:
        if (address >= 0x05FF_FF00)
        {
            const auto ocio_reg = address & 0xFF;

            switch (ocio_reg)
            {
            case 0x84:
                writefln("[Bus] <On-Chip IO> Byte write (%02Xh) to IPRA_LO.", data);
                break;
            case 0x89:
                writefln("[Bus] <On-Chip IO> Byte write (%02Xh) to IPRC_HI.", data);
                break;
            default:
                writefln("[Bus] <On-Chip IO> <Error> Unhandled byte write (%02Xh) to %02Xh.", data, ocio_reg);

                throw new Error("Unhandled byte write");
            }

            return;
        }
        goto default;
    case 0x09:
        if (address < 0x0908_0000)
        {
            ram[address & 0x7_FFFF] = data;

            return;
        }
        goto default;
    case 0x0F:
        oram[address & 0x3FF] = data;

        return;
    default:
        writefln("[Bus] <Error> Unhandled byte write (%02Xh) to %08Xh.", data, address);

        throw new Error("Unhandled byte write");
    }
}

/** writes a 16-bit word to `address` */
void write_word(const u32 address, const u16 data)
{
    const auto region = (address >>> 24) & 0xFF;

    switch (region)
    {
    case 0x05:
        if (address >= 0x05FF_FF00)
        {
            const auto ocio_reg = address & 0xFE;

            switch (ocio_reg)
            {
            case 0x48:
                writefln("[Bus] <On-Chip IO> Word write (%04Xh) to DMAOR.", data);
                break;
            default:
                writefln("[Bus] <On-Chip IO> <Error> Unhandled word write (%04Xh) to %02Xh.", data, ocio_reg);

                throw new Error("Unhandled word write");
            }

            return;
        }
        goto default;
    case 0x09:
        if (address < 0x0908_0000)
        {
            *cast(u16 *)(ram.ptr + (address & 0x7_FFFE)) = byteswap(data);

            return;
        }
        goto default;
    case 0x0C:
        const auto sub_region = (address >>> 12) & 0xFFF;

        switch (sub_region)
        {
        case 0x051:
            if (address < 0x0C05_1200)
            {
                writefln("[Bus] <PRAM> Unhandled word write (%04Xh) to %08Xh.", data, address); 
                break;
            }
            goto default;
        case 0x059:
        case 0x05A:
        case 0x05B:
        case 0x05C:
            writefln("[Bus] <IO %03Xh> Unhandled word write (%04Xh) to %08Xh.", sub_region, data, address);
            break;
        default:
            writefln("[Bus] <IO XXX> <Error> Unhandled word write (%04Xh) to %08Xh.", data, address);

            throw new Error("Unhandled word write");
        }

        return;
    default:
        writefln("[Bus] <Error> Unhandled word write (%04Xh) to %08Xh.", data, address);

        throw new Error("Unhandled word write");
    }
}

/** writes a 32-bit longword to `address` */
void write_lword(const u32 address, const u32 data)
{
    const auto region = (address >>> 24) & 0xFF;

    switch (region)
    {
    case 0x02:
        writefln("[Bus] <R02> Unhandled lword write (%08Xh) to %08Xh.", data, address);

        return;
    case 0x09:
        if (address < 0x0908_0000)
        {
            *cast(u32 *)(ram.ptr + (address & 0x7_FFFC)) = bswap(data);

            return;
        }
        goto default;
    default:
        writefln("[Bus] <Error> Unhandled lword write (%08Xh) to %08Xh.", data, address);

        throw new Error("Unhandled lword write");
    }
}

/** dumps video memory */
void dump_video_memory()
{
    auto pal_data  = File("Loopy/pal", "w");
    auto vram_data = File("Loopy/vram", "w");

    pal_data.rawWrite(pram);
    vram_data.rawWrite(vram);
}

/** dumps the contents of RAM */
void dump_ram()
{
    auto ram_data = File("Loopy/ram", "w");

    ram_data.rawWrite(ram);
}
