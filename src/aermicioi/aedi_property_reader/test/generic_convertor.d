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
	aermicioi
**/
module aermicioi.aedi_property_reader.test.generic_convertor;

import aermicioi.aedi_property_reader.generic_convertor_container;
import aermicioi.aedi_property_reader.generic_convertor_factory;
import aermicioi.aedi_property_reader.convertor_container;
import aermicioi.aedi_property_reader.convertor_factory;
import aermicioi.aedi_property_reader.test.fixture;
import aermicioi.aedi.exception.not_found_exception;
import aermicioi.aedi.test.fixture;
import aermicioi.aedi;
import std.exception;

unittest {
    auto intFactory 	= new GenericObjectWrappingConvertorFactory!(ConvertorFactoryString!(size_t))(new ConvertorFactoryString!(size_t));
    intFactory.convertible = "200";

    assert(intFactory.convertible == "200");
    assert(cast(Wrapper!size_t) intFactory.factory() == 200);
    assert(intFactory.type == typeid(size_t));
}

unittest {
    
    auto container = new GenericConvertorContainer!(string, ConvertorFactory!(string, Object))();
    auto locator = new MockLocator();
    container.locator = locator;

    auto intFactory 	= new GenericObjectWrappingConvertorFactory!(ConvertorFactoryString!(size_t))(new ConvertorFactoryString!(size_t));
    auto stringFactory 	= new GenericObjectWrappingConvertorFactory!(ConvertorFactoryString!(string))(new ConvertorFactoryString!(string));
    auto arrayFactory 	= new GenericObjectWrappingConvertorFactory!(ConvertorFactoryString!(size_t[]))(new ConvertorFactoryString!(size_t[]));
    
    container.set(intFactory, "size_t");
    container.set(stringFactory, "string");
    container.set(arrayFactory, "array");
        
    assert(container.locate!size_t("size_t") == 192);
    assert(container.locate!string == "some test");

    container.instantiate();
    assert(container.locate!(size_t[])("array") == [10, 20, 20]);
    
    assert(container.has("array"));
    assertThrown!NotFoundException(container.get("unknown"));
    
    assert(container.getFactory("size_t") is intFactory);
    
    {
        import std.range;
        ConvertorFactory!(string, Object)[] arr;
        arr ~= intFactory;
        arr ~= stringFactory;
        arr ~= arrayFactory;
        
        foreach (el; container.getFactories.zip(arr)) {
            assert(el[0][0] is el[1]);
        }
    }
    
    container.remove("array");
    assert(!container.has("array"));
}