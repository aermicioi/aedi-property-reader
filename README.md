# Aedi property reader, a configuration reader

[![Dub license](https://img.shields.io/dub/l/aedi-property-reader.svg)]()
[![Travis CI](https://img.shields.io/travis/aermicioi/aedi-property-reader/master.svg)](https://travis-ci.org/aermicioi/aedi-property-reader)
[![Code cov](https://img.shields.io/codecov/c/github/aermicioi/aedi-property-reader.svg)]()
[![Dub version](https://img.shields.io/dub/v/aedi-property-reader.svg)](https://code.dlang.org/packages/aedi-property-reader)

Aedi property reader is a library for loading config properties from various sources,
like xml, json, yaml, or sdlang.

## Features

- Simple - Init container, define properties, use it.
- Powerful - Hierarchical organization of multiple files.
- Flexible - Supports multiple config formats and sources.
- Smart - Uses document syntax to guess D types for properties.

## Installation

Add Aedi property reader as a dependency to a dub project:

Json configuration:

```json
"aedi-property-reader": "~>0.2.0"
```

SDL configuration:

```sdl
dependency "aedi-property-reader" version="~>0.2.0"
```

## Quickstart

Aedi property reader provides an unified interface for reading config properties out of
a multitude of sources. It is able to read configuration out of following sources:

- command line
- environment
- xml
- json
- sdlang
- yaml
- java like property files

To use aedi property reader to load configuration following steps are required:

1. Create a property container out of a string or a file in specified format
3. Define config properties to be read from source
4. Use properties from config container

The example below shows the simplest use case presented in steps above:

```d
module app;
import std.stdio;

import aermicioi.aedi;
import aermicioi.aedi_property_reader;

void properties(T : ConvertorContainer!(FromType, ToType), FromType, ToType)(T container) {
	with (container.configure) { // Create a configuration context for config container
		register!string("protocol"); // Define `protocol` property of type `string`
		register!string("host");
		register!string("resource");
		register!ushort("port");
		register!(string[string])("arguments"); // Define `arguments` property of type `string[string]`
		register!(size_t[])("nope-an-array");
	}
}

auto load() {
	auto cont = json("config.json");

	cont.properties();
	return cont;
}

void main()
{
	auto cont = load(); // Initialize config container

	writeln("Dumping network connection information:");
	writeln("Protocol: ", cont.locate!string("protocol")); // Write property found in configuration
	writeln("Host: ", cont.locate!string("host"));
	writeln("Port: ", cont.locate!ushort("port"));
	writeln("Arguments: ", cont.locate!(string[string])("arguments")); // Write property found in configuration
	writeln("nope-an-array: ", cont.locate!(size_t[])("nope-an-array"));
}
```

The output of example, will yield following answers:
```d
Dumping network connection information:
Protocol: http
Host: host.io
Port: 8080
Arguments: ["pass":"json.weak-pass", "user":"json.bold-logic"]
nope-an-array: [6, 5, 4, 3, 2, 1]
```

## Documentation

All public api documentation is available on [aermicioi.github.io/aedi-property-reader/](https://aermicioi.github.io/aedi-property-reader/).
