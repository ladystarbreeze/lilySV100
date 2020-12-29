/* lilySV100 - Casio Loopy emulator written in D. */
/* Copyright (c) 2020, Lady Starbreeze */

module bios;

import std.stdio;

import bus, cpu, type;

/** HLEs BIOS calls */
void hle_bios_routine(const u32 address)
{
    writefln("[BIOS] BIOS call @ %04Xh.", address);

    dump_registers();

    switch (address)
    {
        /*
    case 0x5F4C:
        convert_2bpp_4bpp_and_copy();
        break;
    case 0x61A0:
        decompress_rle();
        break;
        */
    case 0x66D0:
        memory_copy();
        break;
    default:
        break;
    }
}

/*
private void decompress_rle()
{
    //r4 - dst, r5 - ?, r6 - idx, r7 - tbl ptr
    auto dst_ptr   = regs.r[4];
    auto table_ptr = regs.r[7];
    auto offset = regs.r[6];
    auto src_ptr   = read_longword(table_ptr + 4 * offset);

    writefln("[BIOS] <Decompress RLE> Destination: %08Xh, Source: %08Xh", dst_ptr, src_ptr);

    const auto size = read_byte(src_ptr) >> 4;

    writefln("[BIOS] <Decompress RLE> Struct size: %02Xh", size);

    src_ptr += 2;

    for (auto i = 0; i < size; i += 2)
    {
        const auto length = read_byte(src_ptr + i + 0);
        const auto data   = read_byte(src_ptr + i + 1);

        writefln("[BIOS] <Decompress RLE> Data: %02Xh, Length: %02Xh", data, length);

        for (auto j = 0; j < length; j++)
        {
            write_byte(dst_ptr--, data);
        }
    }
}
*/
private void memory_copy()
{
    // r4 - struct ptr, r5 - DMA channel?
    const auto struct_ptr = regs.r[4];

    const auto mode = read_word(struct_ptr);

    auto dst_ptr = read_lword(struct_ptr + 4);
    auto src_ptr = read_lword(struct_ptr + 8);
    const auto t_count = read_word(struct_ptr + 12);

    writefln("[BIOS] <Copy> Mode: %Xh, Destination: %08Xh, Source: %08Xh, Count: %Xh", mode, dst_ptr, src_ptr, t_count);

    switch (mode)
    {
    case 0x1:
        for (auto i = 0; i < t_count; i++)
        {
            write_word(dst_ptr, read_word(src_ptr));

            dst_ptr += 2;
            src_ptr += 2;
        }
        break;
    case 0x4:
        break;
    default:
        writefln("[BIOS] <Copy> Unhandled mode %Xh.", mode);

        throw new Error("Unhandled mode");
    }
}

/*
// r4 - source pointer, r5 - destination pointer, r6 - count minus 1
private void convert_2bpp_4bpp_and_copy()
{
    auto src_ptr = regs.r[4];
    auto dst_ptr = regs.r[5];

    auto count = cast(int)regs.r[6];

    writefln("[BIOS] <2BPP->4BPP, Copy> Source: %08Xh, Destination: %08Xh, Count: %d", src_ptr, dst_ptr, count + 1);

    auto dst_count = 0;

    u32 data_buf = 0;

    for (int i = 0; i <= (count * 32); i++)
    {
        const auto data = read_byte(src_ptr++);

        u8 mask = 0xFF >> 6;

        auto src_count = 0;

        while (src_count < 8)
        {
            const auto data_masked = ((data & mask) >> src_count) + 2;

            data_buf  |= data_masked << dst_count;
            dst_count += 4;

            if (dst_count >= 32)
            {
                write_longword(dst_ptr, data_buf);

                dst_ptr  += 4;
                dst_count = 0, data_buf = 0;
            }

            mask <<= 2;

            src_count += 2;
        }
    }
}
*/
