/**
License:
    Boost Software License - Version 1.0 - August 17th, 2003

    Permission is hereby granted, free of charge, to any person or organization
    obtaining a copy of the software and accompanying documentation covered by
    this license (the "Software") to use, reproduce, display, distribute,
    execute, and transmit the Software, and to prepare derivative works of the
    Software, and to permit third-parties to whom the Software is furnished to
    do so, all subject to the following:

    The copyright notices in the Software and this entire statement, including
    the above license grant, this restriction and the following disclaimer,
    must be included in all copies of the Software, in whole or in part, and
    all derivative works of the Software, unless such copies or derivative
    works are solely in the form of machine-executable object code generated by
    a source language processor.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
    SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
    FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
    ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
    DEALINGS IN THE SOFTWARE.

Authors:
    Alexandru Ermicioi
**/
module aermicioi.aedi_property_reader.arg.convertor;

import std.string;
import std.algorithm;
import std.array;
import std.traits;
import std.conv;
import std.getopt;
import std.range;
import std.experimental.allocator;
import aermicioi.aedi_property_reader.core.convertor;

void convert(To, From : const(string)[])(in From from, ref To to, IAllocator allocator = theAllocator)
    if (isScalarType!To) {
    string[] args = cast(string[]) from;

    if (from.length == 2) {
        string identity = args.back.splitter("=").front.strip('-');

        getopt(args, identity, &to);
    }
}

void convert(To, From : const(string)[])(in From from, ref To to, IAllocator allocator = theAllocator)
    if (isSomeString!To) {
    string[] args = cast(string[]) from;

    if (from.length == 2) {
        string identity = args.back.splitter("=").front.strip('-');

        getopt(args, identity, &to);
    }
}

void convert(To, From : const(string)[])(in From from, ref To to, IAllocator allocator = theAllocator)
    if (!isSomeString!To && isArray!To) {
    string[] args = cast(string[]) from;

    string identity = args.drop(1).fold!commonPrefix.splitter("=").front.strip('-');

    getopt(args, identity, &to);
}

void convert(To, From : const(string)[])(in From from, ref To to, IAllocator allocator = theAllocator)
    if (isAssociativeArray!To) {
    string[] args = cast(string[]) from;

    string identity = args.drop(1).fold!commonPrefix.splitter("=").front.strip('-');

    getopt(args, identity, &to);
}

void destruct(To)(ref To to, IAllocator allocator = theAllocator) {
    destroy(to);
    to = To.init;
}

alias ArgumentAdvisedConvertor = AdvisedConvertor!(convert, destruct);
alias ArgumentAdvisedDocumentContainer = AdvisedDocumentContainer!(const(string)[], ArgumentAdvisedConvertor);