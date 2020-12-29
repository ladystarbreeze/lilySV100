/* lilySV100 - Casio Loopy emulator written in D. */
/* Copyright (c) 2020, Lady Starbreeze */

import std.stdio : writeln;

import bus, cpu;

/** ROM path for debugging purposes */
const auto ROM_PATH = "Loopy/ROMs/Dream_Change.bin";

void main(string[] args)
{
    bus.init(ROM_PATH);
    cpu.init();

    auto counter = 0;

    while (true)
    {
        cpu.run();
        ++counter;

        if (counter == 200_000)
        {
            bus.dump_video_memory();

            counter = 0;
        }
    }
}
