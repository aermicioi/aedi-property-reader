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
module aermicioi.aedi_property_reader.convertor.exception;

import aermicioi.aedi.exception.di_exception;
import aermicioi.aedi.util.range;

/**
Exception thrown when a problem related to conversion appeared.
**/
class ConvertorException : Exception {
    /**
     * Creates a new instance of Exception. The next parameter is used
     * internally and should always be $(D null) when passed by user code.
     * This constructor does not automatically throw the newly-created
     * Exception; the $(D throw) statement should be used for that purpose.
     */
    @nogc @safe pure nothrow this(
        string msg = "",
        string file = __FILE__,
        size_t line = __LINE__,
        Throwable next = null
    ) {
        super(msg, file, line, next);
    }

    /**
    ditto
    **/
    @nogc @safe pure nothrow this(string msg, Throwable next, string file = __FILE__, size_t line = __LINE__)
    {
        super(msg, file, line, next);
    }

    /**
    ditto
    **/
    @nogc @safe pure nothrow this(Throwable next, string msg = "", string file = __FILE__, size_t line = __LINE__)
    {
        super(msg, file, line, next);
    }

    void pushMessage(scope void delegate(in char[]) sink) const @system {
        sink(this.message);
    }

    mixin AdvancedExceptionPrinting!();
}

/**
Exception thrown when property is not found in document/component
**/
class NotFoundException : ConvertorException {
    string property;
    string component;

    /**
     * Creates a new instance of Exception. The next parameter is used
     * internally and should always be $(D null) when passed by user code.
     * This constructor does not automatically throw the newly-created
     * Exception; the $(D throw) statement should be used for that purpose.
     */
    @nogc @safe pure nothrow this(
        string msg,
        string property,
        string component,
        string file = __FILE__,
        size_t line = __LINE__,
        Throwable next = null
    ) {
        this.property = property;
        this.component = component;
        super(msg, file, line, next);
    }

    /**
    ditto
    **/
    @nogc @safe pure nothrow this(
        string msg,
        string property,
        string component,
        Throwable next,
        string file = __FILE__,
        size_t line = __LINE__
    ) {
        this.property = property;
        this.component = component;
        super(msg, file, line, next);
    }

    /**
    ditto
    **/
    @nogc @safe pure nothrow this(Throwable next, string msg = "", string file = __FILE__, size_t line = __LINE__)
    {
        super(msg, file, line, next);
    }

    override void pushMessage(scope void delegate(in char[]) sink) const @system {
        import std.algorithm : substitute;
        import std.utf : byChar;
		auto substituted = this.msg.substitute("${property}", property, "${component}", component).byChar;

        while (!substituted.empty) {
            auto buffer = BufferSink!(char[256])();
            import std.range;
            buffer.put(substituted);

            sink(buffer.slice);
        }
    }
}


/**
Exception thrown when property is not found in document/component
**/
class InvalidCastException : ConvertorException {
    TypeInfo from;
    TypeInfo to;

    /**
     * Creates a new instance of Exception. The next parameter is used
     * internally and should always be $(D null) when passed by user code.
     * This constructor does not automatically throw the newly-created
     * Exception; the $(D throw) statement should be used for that purpose.
     */
    @nogc @safe pure nothrow this(
        string msg,
        TypeInfo from,
        TypeInfo to,
        string file = __FILE__,
        size_t line = __LINE__,
        Throwable next = null
    ) {
        this.from = from;
        this.to = to;
        super(msg, file, line, next);
    }

    /**
    ditto
    **/
    @nogc @safe pure nothrow this(
        string msg,
        TypeInfo from,
        TypeInfo to,
        Throwable next,
        string file = __FILE__,
        size_t line = __LINE__
    ) {
        this.from = from;
        this.to = to;
        super(msg, file, line, next);
    }

    /**
    ditto
    **/
    @nogc @safe pure nothrow this(Throwable next, string msg = "", string file = __FILE__, size_t line = __LINE__)
    {
        super(msg, file, line, next);
    }

    override void pushMessage(scope void delegate(in char[]) sink) const @system {
        import std.algorithm : substitute;
        import std.utf : byChar;
		auto substituted = this.msg.substitute("${from}", from.toString, "${to}", to.toString).byChar;

        while (!substituted.empty) {
            auto buffer = BufferSink!(char[256])();
            import std.range;
            buffer.put(substituted);

            sink(buffer.slice);
        }
    }
}

/**
Exception thrown when passed argument is of wrong type.
**/
class InvalidArgumentException : Exception {
    /**
     * Creates a new instance of Exception. The next parameter is used
     * internally and should always be $(D null) when passed by user code.
     * This constructor does not automatically throw the newly-created
     * Exception; the $(D throw) statement should be used for that purpose.
     */
    @nogc @safe pure nothrow this(
        string msg = "",
        string file = __FILE__,
        size_t line = __LINE__,
        Throwable next = null
    ) {
        super(msg, file, line, next);
    }

    /**
    ditto
    **/
    @nogc @safe pure nothrow this(string msg, Throwable next, string file = __FILE__, size_t line = __LINE__)
    {
        super(msg, file, line, next);
    }

    /**
    ditto
    **/
    @nogc @safe pure nothrow this(Throwable next, string msg = "", string file = __FILE__, size_t line = __LINE__)
    {
        super(msg, file, line, next);
    }
}