module aermicioi.aedi_property_reader.convertor.chaining_convertor;

import std.algorithm;
import std.experimental.allocator;
import std.experimental.logger;
import std.conv;
import std.array;
import aermicioi.aedi_property_reader.convertor.convertor;
import aermicioi.aedi_property_reader.convertor.exception;
import aermicioi.aedi_property_reader.convertor.placeholder;

interface PricingStrategy {

    size_t rate(const TypeInfo from, const TypeInfo to) const;
}

class NumericPricingStrategy : PricingStrategy {

    private const TypeInfo[] unsigned = [typeid(ulong), typeid(uint), typeid(ushort), typeid(ubyte)];
    private const TypeInfo[] signed = [typeid(long), typeid(int), typeid(short), typeid(byte)];
    private const TypeInfo[] floating = [typeid(real), typeid(double), typeid(float)];
    private const TypeInfo[][] interchangeable;

    this() {
        this.interchangeable = [unsigned, signed, floating];
    }

    size_t rate(const TypeInfo from, const TypeInfo to) const {
        import std.math;

        const TypeInfo[] fromCategory = find(from);
        const TypeInfo[] toCategory = find(to);

        if ((fromCategory is null) && (toCategory is null)) {
            return size_t.max / 2;
        } else if (fromCategory is toCategory) {
            return compute(from, to, fromCategory);
        } else {
            return compute(fromCategory, toCategory, from, to);
        }
    }

    const(TypeInfo[]) find(const TypeInfo type) const {
        if (!signed.filter!(s => s is type).empty) {
            return signed;
        }

        if (!unsigned.filter!(s => s is type).empty) {
            return unsigned;
        }

        if (!floating.filter!(s => s is type).empty) {
            return floating;
        }

        return null;
    }

    private size_t compute(const TypeInfo from, const TypeInfo to, const TypeInfo[] priorities) const {
        auto price = priorities.countUntil(from) - priorities.countUntil(to);

        return price < 0 ? (size_t.max / 2) : price;
    }

    private size_t compute(const TypeInfo[] fromCategory, const TypeInfo[] toCategory, const TypeInfo from, const TypeInfo to) const {
        auto price = interchangeable.countUntil(fromCategory) - interchangeable.countUntil(toCategory);
        price *= fromCategory.countUntil(from) + toCategory.countUntil(to);

        return price;
    }
}

class DefaultPricingStrategy : PricingStrategy {
    private size_t price = 100;

    this(size_t price) {
        this.price = price;
    }

    size_t rate(const TypeInfo from, const TypeInfo to) const {
        return price;
    }
}

class MinimalBidPricingStrategy : PricingStrategy {

    private PricingStrategy[] strategies;

    size_t rate(const TypeInfo from, const TypeInfo to) const {
        return strategies.map!(strategy => strategy.rate(from, to)).minElement(size_t.max / 2);
    }
}

/**
A convertor tries to build a chain of convertors from source to destination.
**/
class ChainingConvertor : CombinedConvertor {
    import std.algorithm : canFind, find;

    private {
        struct Node {
            size_t price = size_t.max;
            bool visited;
            TypeInfo type;
            TypeInfo next;
        }

        Convertor[] convertors_;
        PricingStrategy appraiser;
    }

    public {

        /**
        Default constructor for AggregateConvertor
        **/
        this(PricingStrategy appraiser, Convertor[] convertors...) {
            this.convertors = convertors.dup;
            this.appraiser = appraiser;
        }

        /**
        Set convertors

        Params:
            convertors = convertors used to convert from one type to another

        Returns:
            typeof(this)
        **/
        typeof(this) convertors(Convertor[] convertors) @safe nothrow pure {
            this.convertors_ = convertors;

            return this;
        }

        /**
        Get convertors

        Returns:
            Convertor[]
        **/
        inout(Convertor[]) convertors() @safe nothrow pure inout {
            return this.convertors_;
        }

        /**
        Add a convertor to existing list

        Params:
            convertor = convertor to be added to

        Returns:
            typeof(this)
        **/
        typeof(this) add(Convertor convertor) @safe {
            this.convertors_ ~= convertor;

            return this;
        }

        /**
        Remove a convertor from existing list

        Params:
            convertor = convertor to be removed

        Returns:
            typeof(this)
        **/
        typeof(this) remove(Convertor convertor) @trusted nothrow {
            import std.algorithm : remove, countUntil;
            import std.array : array;

            try {

                this.convertors_ = this.convertors_.remove(this.convertors.countUntil!(c => c == convertor));
            } catch (Exception e) {
                assert(false, text("countUntil threw an exception: ", e));
            }

            return this;
        }

        @property {
            /**
            Get the type info of component that convertor can convert from.

            Get the type info of component that convertor can convert from.
            The method is returning the default type that it is able to convert,
            though it is not necessarily limited to this type only. More generalistic
            checks should be done by convertsFrom method.

            Returns:
                type info of component that convertor is able to convert.
            **/
            TypeInfo from() @safe nothrow pure const {
                return typeid(void);
            }

            /**
            Get the type info of component that convertor is able to convert to.

            Get the type info of component that convertor is able to convert to.
            The method is returning the default type that is able to convert,
            though it is not necessarily limited to this type only. More generalistic
            checks should be done by convertsTo method.

            Returns:
                type info of component that can be converted to.
            **/
            TypeInfo to() @safe nothrow pure const {
                return typeid(void);
            }
        }

        /**
        Check whether convertor is able to convert from.

        Params:
            from = the type info of component that could potentially be converted by convertor.
        Returns:
            true if it is able to convert from, or false otherwise.
        **/
        bool convertsFrom(TypeInfo from) const {
            return this.convertors.canFind!(c => c.convertsFrom(from));
        }

        /**
        ditto
        **/
        bool convertsFrom(in Object from) const {
            return this.convertors.canFind!(c => c.convertsFrom(from));
        }

        /**
        Check whether convertor is able to convert to.

        Params:
            to = type info of component that convertor could potentially convert to.

        Returns:
            true if it is able to convert to, false otherwise.
        **/
        bool convertsTo(TypeInfo to) const {
            return this.convertors.canFind!(c => c.convertsTo(to));
        }

        /**
        ditto
        **/
        bool convertsTo(in Object to) const {
            return this.convertors.canFind!(c => c.convertsTo(to));
        }

        /**
        Convert from component to component.

        Finds a right convertor from component to component and uses it
        to execute conversion from component to component.

        Params:
            from = typeal component that is to be converted.
            to = destination object that will be constructed out for typeal one.
            allocator = optional allocator that could be used to construct to component.
        Throws:
            ConvertorException when convertor is not able to convert from, or to component.
        Returns:
            Resulting converted component.
        **/
        Object convert(in Object from, TypeInfo to, RCIAllocator allocator = theAllocator) const // TODO dijkstra algorithm.
        {
            import std.algorithm;
            import std.range;

            Node[TypeInfo] nodes;
            this.convertors
                .filter!(c => (c.to !is c.from) || (c.to !is typeid(void)) || (c.from !is typeid(void)))
                .each!((convertor) { nodes[convertor.from] = Node(size_t.max, false, convertor.from); nodes[convertor.to] = Node(size_t.max, false, convertor.to); });

            Node current = Node(0, true, to);
            nodes[to] = current;
            Node[] unvisited;

            do {
                debug(trace) trace("Processing neighbors of ", current.type);

                const(Convertor)[] convertors = convertors.filter!(c => c.convertsTo(current.type)).array;

                foreach (convertor; convertors) {
                    size_t rate = appraiser.rate(convertor.from, convertor.to);

                    debug(trace) trace("Checking convertion price to ", convertor.to, " from ", convertor.from, " of ", rate);
                    if ((current.price + rate) < nodes[convertor.from].price) {

                        debug(trace) trace(rate, " less than typeal one of ", nodes[convertor.from].price, " setting new one.");
                        nodes[convertor.from].price = current.price + rate;
                        nodes[convertor.from].next = current.type;
                    }
                }

                unvisited ~= convertors.map!(convertor => nodes[convertor.from]).filter!(node => !node.visited).array;
                unvisited.sort!((f, s) => f.price < s.price);
                nodes[current.type] = current;

                debug(trace) trace("Selecting new unvisited node of ", unvisited.front.type);
                current = unvisited.front;
                current.visited = true;

                if (current.type is from.identify) {
                    debug(trace) trace("Currently selected node is the type of conversion path, commencing conversion of ", path(current, nodes), ".");

                    Object value = this.convertors.filter!(c => c.convertsFrom(current.type) && c.convertsTo(current.next)).front.convert(from, current.next, allocator);
                    current = nodes[current.next];

                    while (current.next !is null) {
                        Object temporary = this.convertors.filter!(c => c.convertsFrom(current.type) && c.convertsTo(current.next)).front.convert(value, current.next, allocator);
                        theAllocator.dispose(value);
                        value = temporary;
                    }

                    return value;
                }

                unvisited = unvisited[1 .. $];

            } while (!unvisited.empty);

            throw new ConvertorException(text("Failed to convert ", from.identify, " to destination of ", to));
        }

        /**
        Destroy component created using this convertor.

        Find a suitable convertor for destruction and use it to execute destruction.

        Params:
            converted = component that should be destroyed.
            allocator = allocator used to allocate converted component.
        **/
        void destruct(ref Object converted, RCIAllocator allocator = theAllocator) const {
            auto convertors = this.convertors.find!(c => c.convertsTo(converted));

            if (convertors.empty) {
                throw new ConvertorException(text("Could not destroy ", converted));
            }

            convertors[0].destruct(converted, allocator);
        }

        mixin ToStringMixin!();
        mixin OpCmpMixin!();

        override size_t toHash() @trusted {
            import std.digest.murmurhash : MurmurHash3;
            import std.digest : digest;

            MurmurHash3!128 hasher;

            hasher.start();
            foreach (convertor; convertors) {
                Object hashable = cast(Object) convertor;

                size_t hash = (hashable !is null) ? hashable.toHash() : typeid(convertor).getHash(cast(void*) convertor);

                foreach (datum; (cast(ubyte*) &hash)[0 .. hash.sizeof]) {
                    hasher.put(datum);
                }
            }
            return cast(size_t) *(&hasher.finish()[0]);
        }

        override bool opEquals(Object o) {
            return super.opEquals(o) || ((this.classinfo is o.classinfo) && this.opEquals(cast(ChainingConvertor) o));
        }

        bool opEquals(ChainingConvertor convertor) {
            import std.algorithm : equal;
            return (convertor !is null) && (this.convertors.equal(convertor.convertors));
        }
    }

    private TypeInfo[] path(Node step, Node[TypeInfo] graph) const {
        TypeInfo[] path = [  ];

        for (; step.next !is null; step = graph[step.next]) {
            path ~= step.type;
        }

        return path ~ step.type;
    }
}