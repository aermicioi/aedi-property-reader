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
module aermicioi.aedi_property_reader.convertor_configurer;

import aermicioi.aedi.storage.storage;
import aermicioi.aedi.storage.locator;
import aermicioi.aedi_property_reader.convertor_factory;
import aermicioi.aedi_property_reader.convertor_container;
import aermicioi.aedi_property_reader.generic_convertor_factory;
import aermicioi.aedi_property_reader.generic_convertor_container;
import aermicioi.aedi_property_reader.env;
import aermicioi.aedi_property_reader.arg;
import aermicioi.aedi_property_reader.json;
import aermicioi.aedi_property_reader.xml;
import std.json;
import std.xml;

/**
Configuration context for convertor containers, that provides a nice property configuration interface.
**/
struct ConvertorContext(T : Storage!(ConvertorFactory!(FromType, Object), string), FromType) {
    
    public {
        /**
        Underlying container that is configured
        **/
        T container;

        alias container this;
        
        /**
        Register a property into converting container
        
        Params: 
            path = the path or identity of property
            ToType = the type of property that is registered
        
        Returns:
            ConvertorFactory!(FromType, ToType)
        **/
        auto property(Factory : ConvertorFactory!(FromType, ToType), ToType)(string path) {
            
            auto implementation = new Factory;
            auto wrapper = new GenericObjectWrappingConvertorFactory!(Factory!(ToType, FromType))(implementation);
            
            container.set(wrapper, path);
            
            return implementation;
        }

        static if (is(T : GenericConvertorContainer!(FromType, DefaultFactory), alias DefaultFactory)) {
            
            /**
            ditto
            **/
            auto property(ToType)(string path) {
                import std.traits;
                
                return this.property!(DefaultFactory!(ToType, FromType), ToType)(path);
            }
        }
    }
}

/**
Create a configuration context for container.

Params:
    container = container that is to be configured using ConvertorContext
**/
auto configure(T : Storage!(ConvertorFactory!(FromType, Object), string), FromType)(T container) {
    return ConvertorContext!(T, FromType)(container);
}

/**
Create a convertor container with data source being environment variables.

Params: 
    locator = source of data for container to use to construct components.
Returns:
    EnvironmentConvertorContainer
**/
auto environment() {
    return environment(new EnvironmentLocator());
}

/**
ditto
**/
auto environment(Locator!(string, string) locator) {
    auto container = new EnvironmentConvertorContainer;
    container.locator = locator;
    
    return container;
}

/**
Create a convertor container with data source being command line arguments.

Params: 
    locator = source of data for container to use to construct components.
Returns:
    GetoptConvertorContainer
**/
auto argument() {
    return argument(new GetoptIdentityLocator());
}

/**
ditto
**/
auto argument(Locator!(string, string) locator) {
    auto container = new GetoptConvertorContainer;
    container.locator = locator;
    
    return container;
}

/**
Create a convertor container with data source being json document.

Params: 
    locator = source of data for container to use to construct components.
Returns:
    JsonConvertorContainer
**/
auto json() {
    return json(new JsonLocator());
}

/**
ditto
**/
auto json(Locator!(JSONValue, string) locator) {
    auto container = new JsonConvertorContainer();
    container.locator = locator;
    
    return container;
}

/**
Create a convertor container with data source being json document.

Params: 
    value = source of data for container to use to construct components.
Returns:
    JsonConvertorContainer
**/
auto json(JSONValue value) {
    auto locator = new JsonLocator();
    locator.json = value;

    return json(locator);
}

/**
Create a convertor container with data source being json document.

Params: 
    pathOrData = path to source of data or source data itself in form of string for container to use to construct components.
    returnEmpty = wheter to return or not a locator with empty data source
Returns:
    JsonConvertorContainer
**/
auto json(string pathOrData, bool returnEmpty = true) {
    import std.file;

    if (pathOrData.exists) {
        pathOrData = pathOrData.readText();
    }

    try {

        return json(parseJSON(pathOrData));
    } catch (Exception e) {

        if (returnEmpty) {
            return json;
        }

        throw new Exception(
            "Could not create json convertor container from file or content passed in pathOrData: " ~ pathOrData, 
            e
        );
    }
}

/**
Create a convertor container with data source being xml document.

Params: 
    locator = source of data for container to use to construct components.
Returns:
    XmlConvertorContainer
**/
auto xml() {
    return xml(new XmlLocator);
}

/**
ditto
**/
auto xml(Locator!(Element, string) locator) {
    auto container = new XmlConvertorContainer;
    container.locator = locator;
    
    return container;
}

/**
Create a convertor container with data source being xml document.

Params: 
    element = root element used as data source
Returns:
    XmlConvertorContainer
**/
auto xml(Element element) {
    auto locator = new XmlLocator;
    locator.xml = element;
    return xml(locator);
}

/**
Create a convertor container with data source being xml document.

Params: 
    pathOrData = path to a xml file or xml data itself
    returnEmpty = wheter to return or not a locator with empty data source
Returns:
    XmlConvertorContainer
**/
auto xml(string pathOrData, bool returnEmpty = true) {
    import std.file;
    try {
        check(pathOrData);
        return xml(new Document(pathOrData));
    } catch (CheckException e) {

    }

    if (pathOrData.exists) {
        pathOrData = pathOrData.readText();

        try {
            check(pathOrData);
            return xml(new Document(pathOrData));
        } catch(CheckException e) {

            if (returnEmpty) {
                return xml();
            }

            throw new Exception("Could not create xml convertor container from file or content passed in pathOrData: " ~ pathOrData, e);
        }
    }

    if (returnEmpty) {
        return xml();
    }

    throw new Exception("Could not create xml convertor container from file or content passed in pathOrData: " ~ pathOrData);
}