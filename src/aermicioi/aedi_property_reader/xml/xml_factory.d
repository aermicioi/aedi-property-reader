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
module aermicioi.aedi_property_reader.xml.xml_factory;

import aermicioi.aedi_property_reader.convertor_factory;
import aermicioi.aedi.factory;
import aermicioi.aedi.storage.locator;
import aermicioi.aedi.storage.wrapper;
import aermicioi.aedi.storage.decorator;
import aermicioi.aedi.exception;
import std.traits;
import std.xml;

/**
A convertor factory that uses custom fromXml family of functions to convert xml Element into To types.

Params:
	FromType = original representation form of data to be converted.
	ToType = type of component that is built based on FromType data.
**/
class XmlConvertorFactory(To, From : Element = Element) : ConvertorFactory!(Element, To) {
    
    private {
        
        Locator!() locator_;
        Element convertible_;
    }
    
    public {
        
        @property {
            /**
            Set convertible
            
            Params: 
                convertible = data that the factory should convert into ToType component
            Returns:
                XmlConvertorFactory!(To, From)
            **/
        	XmlConvertorFactory!(To, From) convertible(Element convertible) @safe nothrow {
        		this.convertible_ = convertible;
        	
        		return this;
        	}
        	
            /**
            Get convertible data
            
            Returns:
                FromType
            **/
        	Element convertible() @safe nothrow {
        		return this.convertible_;
        	}
        	
            /**
    		Get the type info of T that is created.
    		
    		Returns:
    			TypeInfo object of created component.
    		**/
        	TypeInfo type() {
        	    return typeid(To);
        	}
        	
            /**
            Set a locator to object.
            
            Params:
                locator = the locator that is set to oject.
            
            Returns:
                LocatorAware.
            **/
        	XmlConvertorFactory!(To, From) locator(Locator!() locator) @safe nothrow {
        		this.locator_ = locator;
        	
        		return this;
        	}
        }
        
        /**
		Instantiates component of type To.
		
		Returns:
			To instantiated component.
		**/
        To factory() {
            return fromXml!To(this.convertible());
        }
    }
}

package {
    import std.conv : to, ConvException;
    
    /**
    Convert xml Element into T scalar/array/assocarray value.
    
    As converting value only text of xml element is taken into consideration.

    Params: 
        value = storage where to put converted xml Element
        xml = the data that is to be converted.
    Throws: 
        InvalidCastException when the type of value does not match stored data.
    Returns:
        value
    **/
    auto ref T fromXml(T)(auto ref T value, auto ref Element xml) 
        if (isNumeric!T) {
        
        try {

            value = xml.text.to!T;
        } catch (ConvException e) {
            throw new InvalidCastException(
                "Could not convert xml " ~ 
                xml.toString() ~ 
                " value to type " ~ 
                fullyQualifiedName!T, 
                e
            );
        }
        
        return value;
    }
    
    /**
    ditto
    **/
    auto ref T fromXml(T)(auto ref T value, auto ref Element xml) 
        if (isSomeString!T) {
        
        try {

            value = xml.text.to!T;
        } catch (ConvException e) {
            throw new InvalidCastException(
                "Could not convert xml " ~ 
                xml.toString() ~ 
                " value to type " ~ 
                fullyQualifiedName!T, 
                e
            );
        }
        return value;
    }
    
    /**
    ditto
    **/
    auto ref T fromXml(T : Z[], Z)(auto ref T value, auto ref Element xml)
        if (!isSomeString!T) {
        
        foreach (index, ref el; value) {
            el.fromXml(xml.elements[index]);
        }
        
        return value;
    }
    
    /**
    ditto
    **/
    auto ref T fromXml(T : Z[string], Z)(auto ref T value, auto ref Element xml) {
        
        foreach (ref el; xml.elements) {
            
            value[el.tag.name] = el.fromXml!Z;
        }
        
        return value;
    }
    
    /**
    ditto
    **/
    T fromXml(T)(auto ref Element xml)
        if (isNumeric!T) {
        
        T value;
        value.fromXml!T(xml);
        
        return value;
    }
    
    /**
    ditto
    **/
    T fromXml(T)(auto ref Element xml)
        if (isSomeString!T) {
        
        T value;
        value.fromXml(xml);
        
        return value;
    }
    
    /**
    ditto
    **/
    T fromXml(T : Z[], Z)(auto ref Element xml)
        if (!isSomeString!T) {

        T array = new Z[xml.elements.length];
        array.fromXml(xml);
        
        return array;
    }
    
    /**
    ditto
    **/
    T fromXml(T : Z[string], Z)(auto ref Element xml) {
        
        T assoc;
        assoc.fromXml(xml);
        
        return assoc;
    }
}