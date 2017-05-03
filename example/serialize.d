/******************************************************************************

    A simple example on how serialize and deserialize a non-versioned struct.

    Copyright:
        Copyright (c) 2009-2017 Sociomantic Labs GmbH.
        All rights reserved.

    License:
        Boost Software License Version 1.0. See LICENSE_BOOST.txt for details.
        Alternatively, this file may be distributed under the terms of the Tango
        3-Clause BSD License (see LICENSE_BSD.txt for details).

*******************************************************************************/

module serialize;

/// Struct that we will serialize and deserialize
struct S
{
    int foo;
    char[] arr;
}

import ocean.io.Stdout;
/// We create here an instance of struct S and serialize it, we then
/// deserialize it as another instance. Both instances are then compared and
/// printed.
void main ()
{
    auto instance = S(42, "Hello World".dup);
    auto binary_data = convert(instance);
    auto s = load(binary_data);
    assert(s == instance);
    stdout.formatln("{}", s);
}

import ocean.util.serialize.contiguous.Serializer;
/// Serializes an instance S into a new buffer and return that buffer
void[] convert (S instance)
{
    // Tip: Create a signle array and re-use for repeated serilizations
    // for better performance.
    void[] binary_data;
    Serializer.serialize(instance, binary_data);
    return binary_data;
}

import ocean.util.serialize.contiguous.Contiguous;
import ocean.util.serialize.contiguous.Deserializer;
/// Convert binary data in-place and return the data wrapped as a struct S
S load (void[] binary_data)
{
    // Tip: Create a signle contigous instance and re-use for repeated
    // deserilizations for better performance.
    Contiguous!(S) data_wrapper = Deserializer.deserialize!(S)(binary_data);
    S* s_ptr = data_wrapper.ptr;
    return *s_ptr;
}
