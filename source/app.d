/* lilySV100 - Casio Loopy emulator written in D. */
/* Copyright (c) 2020, Lady Starbreeze */

import std.stdio : writeln;

import bus, cpu;

void main(string[] args)
{
    bus.init(args[1]);
    cpu.init();

    while (true)
    {
        cpu.run();
    }
}
