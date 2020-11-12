/* lilySV100 - Casio Loopy emulator written in D. */
/* Copyright (c) 2020, Lady Starbreeze */

module file;

import std.file : read;

import type;

/** reads a file into a u8 array and returns it */
u8[] load_file(string path)
{
    /* TODO: error handling!! */

    const auto data = read(path);

    return cast(u8[])data;
}
