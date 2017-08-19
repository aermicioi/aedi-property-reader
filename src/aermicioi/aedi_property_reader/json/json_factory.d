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
module aermicioi.aedi_property_reader.json.json_factory;

import aermicioi.aedi_property_reader.convertor_factory;
import aermicioi.aedi.factory;
import aermicioi.aedi.storage.locator;
import aermicioi.aedi.storage.wrapper;
import aermicioi.aedi.storage.decorator;
import aermicioi.aedi.exception;
import std.json;
import std.traits;

class JsonConvertorFactory(To, From : JSONValue = JSONValue) : ConvertorFactory!(JSONValue, To) {
    
    private {
        
        Locator!() locator_;
        JSONValue convertible_;
    }
    
    public {
        
        @property {
        	JsonConvertorFactory!(To, From) convertible(JSONValue convertible) @safe nothrow {
        		this.convertible_ = convertible;
        	
        		return this;
        	}
        	
        	JSONValue convertible() @safe nothrow {
        		return this.convertible_;
        	}
        	
        	TypeInfo type() {
        	    return typeid(To);
        	}
        	
        	JsonConvertorFactory!(To, From) locator(Locator!() locator) @safe nothrow {
        		this.locator_ = locator;
        	
        		return this;
        	}
        }
        
        To factory() {
            return fromJson!To(this.convertible());
        }
    }
}

package {
    import std.conv : to;
    
    auto ref fromJson(T)(auto ref T value, auto ref JSONValue json) 
        if (isFloatingPoint!T) {
        
        if (json.type != JSON_TYPE.FLOAT) {
            throw new InvalidCastException("Could not convert json " ~ json.toString() ~ " value to type " ~ fullyQualifiedName!T);
        }
        
        value = json.floating.to!T;
        
        return value;
    }
        
    auto ref fromJson(T)(auto ref T value, auto ref JSONValue json) 
        if (isUnsigned!T && isIntegral!T) {
        
        if ((json.type == JSON_TYPE.INTEGER) && (json.integer >= 0)) {
            value = json.integer.to!T;
            return value;
        }
        
        if (json.type != JSON_TYPE.UINTEGER) {
            throw new InvalidCastException("Could not convert json " ~ json.toString() ~ " value to type " ~ fullyQualifiedName!T);
        }
        
        value = json.uinteger.to!T;
        
        return value;
    }
        
    auto ref fromJson(T)(auto ref T value, auto ref JSONValue json) 
        if (!isUnsigned!T && isIntegral!T) {
        
        if (json.type != JSON_TYPE.INTEGER) {
            throw new InvalidCastException("Could not convert json " ~ json.toString() ~ " value to type " ~ fullyQualifiedName!T);
        }
        
        value = json.integer.to!T;
        
        return value;
    }
        
    auto ref fromJson(T)(auto ref T value, auto ref JSONValue json) 
        if (isSomeString!T) {
        
        if (json.type != JSON_TYPE.STRING) {
            throw new InvalidCastException("Could not convert json " ~ json.toString() ~ " value to type " ~ fullyQualifiedName!T);
        }
        
        value = json.str.to!T;
        
        return value;
    }
    
    auto ref fromJson(T : Z[], Z)(auto ref T value, auto ref JSONValue json)
        if (!isSomeString!T) {
        
        if (json.type != JSON_TYPE.ARRAY) {
            throw new InvalidCastException("Could not convert json " ~ json.toString() ~ " value to type " ~ fullyQualifiedName!T);
        }
        
        foreach (index, ref el; value) {
            el = fromJson!Z(value[index], json.array[index]);
        }
        return value;
    }
    
    auto ref fromJson(T : Z[string], Z)(auto ref T value, auto ref JSONValue json) {
        
        if (json.type != JSON_TYPE.OBJECT) {
            throw new InvalidCastException("Could not convert json " ~ json.toString() ~ " value to type " ~ fullyQualifiedName!T);
        }
        
        auto jsonAssociativeArray = json.object;
        
        foreach (key, ref el; jsonAssociativeArray) {
            
            value[key] = fromJson!Z(el);
        }
        
        return value;
    }
    
    T fromJson(T)(auto ref JSONValue json)
        if (isNumeric!T) {
        
        T value;
        
        value.fromJson(json);
        return value;
    }
    
    T fromJson(T)(auto ref JSONValue json)
        if (isSomeString!T) {
        
        T value;
        value.fromJson(json);
        return value;
    }
    
    T fromJson(T : Z[], Z)(auto ref JSONValue json)
        if (!isSomeString!T) {
        if (json.type != JSON_TYPE.ARRAY) {
            throw new InvalidCastException("Could not convert json " ~ json.toString() ~ " value to type " ~ fullyQualifiedName!T);
        }
        
        auto jsonArray = json.array;
        T array = new Z[jsonArray.length];
        array.fromJson(json);
        
        return array;
    }
    
    T fromJson(T : Z[string], Z)(auto ref JSONValue json) {
        
        T assoc;
        assoc.fromJson(json);
        return assoc;
    }
}