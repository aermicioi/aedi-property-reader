module aermicioi.aedi_property_reader.core.exception;

class ConvertorException : Exception {
    /**
     * Creates a new instance of Exception. The next parameter is used
     * internally and should always be $(D null) when passed by user code.
     * This constructor does not automatically throw the newly-created
     * Exception; the $(D throw) statement should be used for that purpose.
     */
    @nogc @safe pure nothrow this(string msg = "", string file = __FILE__, size_t line = __LINE__, Throwable next = null)
    {
        super(msg, file, line, next);
    }

    @nogc @safe pure nothrow this(string msg, Throwable next, string file = __FILE__, size_t line = __LINE__)
    {
        super(msg, file, line, next);
    }

    @nogc @safe pure nothrow this(Throwable next, string msg = "", string file = __FILE__, size_t line = __LINE__)
    {
        super(msg, file, line, next);
    }
}