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
module aermicioi.aedi_property_reader.generic_convertor_container;

import aermicioi.aedi;
import aermicioi.aedi_property_reader.convertor_container;
import aermicioi.aedi_property_reader.convertor_factory;
import std.range;
import std.typecons;

/**
An implementation of ConvertorContainer.

Params:
    FromType = original form of data based on which components are constructed.
    DefaultConvertorFactory = convertor factory that is used by default in this container (used for some generic stuff)
**/
class GenericConvertorContainer(FromType, alias DefaultConvertorFactory) : 
    ConvertorContainer!(FromType, string), FactoryLocator!(Factory!Object) {
    
    private {
        
        Locator!(FromType, string) locator_;
        ObjectStorage!() instantiated;
        ObjectStorage!(ConvertorFactory!(FromType, Object), string) convertors;        
    }
    
    public {
        
        /**
        Default constructor for GenericConvertorContainer!(FromType, DefaultConvertorFactory)
        **/
        this() {
            this.instantiated = new ObjectStorage!();
            this.convertors = new ObjectStorage!(ConvertorFactory!(FromType, Object), string);
        }
        
        @property {
        	/**
			Set locator
			
			Params: 
				locator = locator that provides container with FromType data for convertor factories
			
			Returns:
				GenericConvertorContainer!(FromType, DefaultConvertorFactory)
			**/
            GenericConvertorContainer!(FromType, DefaultConvertorFactory) locator(Locator!(FromType, string) locator) @safe nothrow {
            	this.locator_ = locator;
            
            	return this;
            }
            
            /**
			Get locator of FromType data
			
			Returns:
				Locator!(FromType, string)
			**/
            Locator!(FromType, string) locator() @safe nothrow {
            	return this.locator_;
            }
        }
        
        /**
		Save a convertor factory in GenericConvertorContainer by key identity.
		
		Params:
			key = identity of element in GenericConvertorContainer.
			factory = convertor factory which is to be saved in GenericConvertorContainer.
			
		Return:
			GenericConvertorContainer!(FromType, DefaultConvertorFactory) 
		**/
        GenericConvertorContainer!(FromType, DefaultConvertorFactory) set(ConvertorFactory!(FromType, Object) factory, string key) {
            this.convertors.set(factory, key);
            
            return this;
        }
        
        /**
        Remove an convertor factory from GenericConvertorContainer with identity.
        
        Remove an convertor factory from GenericConvertorContainer with identity. If there is no convertor factory by provided identity, then no action is performed.
        
        Params:
        	key = the identity of convertor factory to be removed.
        	
    	Return:
    		GenericConvertorContainer!(FromType, DefaultConvertorFactory)
        **/
        GenericConvertorContainer!(FromType, DefaultConvertorFactory) remove(string key) {
            this.convertors.remove(key);
            this.instantiated.remove(key);
            
            return this;
        }
        
        /**
		Get a component that is associated with key.
		
		Params:
			key = the component id.
			
		Throws:
			NotFoundException in case if the component wasn't found.
		
		Returns:
			Object, component if it is available.
		**/
        Object get(string key) {
            
            if (!this.instantiated.has(key)) {
                if (!this.convertors.has(key)) {
                    
                    throw new NotFoundException("Object with id " ~ key ~ " not found.");
                }
                
                auto factory = this.convertors.get(key);
                factory.convertible = this.locator.get(key);
                
                this.instantiated.set( 
                    factory.factory(),
                    key,
                );
            }
            
            return this.instantiated.get(key);
        }
        
        /**
        Check if a component is present in Locator by key id.
        
        Params:
        	key = identity of element.
        	
    	Returns:
    		bool true if an component by key is present in Locator.
        **/
        bool has(in string key) inout {
            return this.convertors.has(key) && this.locator_.has(key);
        }
        
        /**
        Sets up the internal state of container.
        
        Sets up the internal state of container (Ex, for singleton container it will spawn all objects that locator contains).
        **/
        GenericConvertorContainer!(FromType, DefaultConvertorFactory) instantiate() {
            import std.algorithm : filter;
            
            return this;
        }
        
        /**
        Get factory for constructed component identified by identity.
        
        Get factory for constructed component identified by identity.
        Params:
        	identity = the identity of component that factory constructs.
        
        Throws:
        	NotFoundException when factory for it is not found.
        
        Returns:
        	T the factory for constructed component.
        **/
        ObjectFactory getFactory(string identity) {
            return this.convertors.get(identity);
        }
        
        /**
        Get all factories available in container.
        
        Get all factories available in container.
        
        Returns:
        	InputRange!(Tuple!(T, string)) a tuple of factory => identity.
        **/
        InputRange!(Tuple!(Factory!(Object), string)) getFactories() {
            import std.algorithm;
            
            return this.convertors.contents.byKeyValue.map!(
                a => tuple(cast(Factory!Object) a.value, a.key)
            ).inputRangeObject;
        }
    }
}