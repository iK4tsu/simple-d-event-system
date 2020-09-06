module deventsystem.event;

version(unittest) import aurorafw.unit;


/** Main event class
 *
 * This is class is abstract and only used to establish some default functions
 *     to every extended Event. \
 */
@safe abstract class Event
{
public:
	@safe pure
	abstract @property string eventType() const;


	@safe
	override string toString() const
	{
		return eventType;
	}


	/** Compare two EventTypes
	 *
	 * Params:
	 *     otherType = type to be compared
	 *
	 * Returns:
	 *     `true` if both types are equal. \
	 *     `false` otherwise
	 */
	@safe pure
	bool isEventTypeOf(in string otherType) const
	{
		return eventType == otherType;
	}


	// defaults to false
	bool handled;
}


/** Default EventType struct
 *
 * Used as the main data storage for the events. \
 * You must define this as an UDA when declaring your custom events. \
 *
 * Examples:
 * --------------------
 * @EventType("MyEvent")
 * class MyEvent : Event { // ... }
 * --------------------
 *
 * Note: To use the `basicEventType` mixin template you need to define an
 *     EventType UDA otherwise it'll not work! You CAN create your own EventType
 *     version without UDAs but keep in mind you'll have to implement your custom
 *     logic of the abstract methods. The EventDispacher is not afected by this.
 */
@safe struct EventType
{
	const string name;
}


/** Quick way to implement your default abstract and static methods
 *
 * Call this mixin template on your custom event. This will generate your getters
 *     for the EventType.
 *
 * Examples:
 * --------------------
 * @EventType("MyEvent")
 * class MyEvent : Event
 * {
 *     mixin basciEventType!MyEvent;
 * }
 * --------------------
 *
 * Note: You need to declare an EventType UDA otherwise this won't compile!
 *
 * Params:
 *     T = class type extended from Event
 */
mixin template basicEventType(T : Event)
{
public:
	@safe pure
	static @property string staticEventType()
	{
		import std.traits : getUDAs;
		return getUDAs!(T, EventType)[0].name;
	}

	@safe pure
	override @property string eventType() const
	{
		return staticEventType;
	}
}

@("Event: basicEventType")
unittest
{
	@EventType("MyEvent")
	class MyEvent : Event { mixin basicEventType!MyEvent; }
	MyEvent event = new MyEvent();
	assertEquals(event.staticEventType, "MyEvent");
	assertEquals(event.staticEventType, event.eventType);
	assertEquals(event.staticEventType, event.toString());
	assertTrue(event.isEventTypeOf(MyEvent.staticEventType));
}


/** Generate generic callback functions
 *
 * Params:
 *     T = class which sends the signal
 *     E = event to look for
 *     args = E var types and E var names
 *
 * Examples:
 * --------------------
 * @EventType("ClickEvent")
 * class ClickEvent : Event
 * {
 *     this(in size_t x, in size_t y)
 *     {
 *         this.x = x;
 *         this.y = y;
 *     }
 *     mixin basicEventType!ClickEvent;
 * private :
 *     const size_t x, y;
 * }
 *
 * class Foo
 * {
 *     mixin genCallback!(const Foo, ClickEvent, const size_t, "x", const size_t, "y") onClicked;
 *     // Note: you can leave the parameters blank, if you do, then the event
 *     //     itself will be passed as the second parameter as const
 * public :
 *     void click(in size_t x, in size_t y)
 *     {
 *         // click stuff here
 *         onClicked.emit(x, y);
 *     }
 *
 *     void onEvent(Event event)
 *     {
 *         // handle your events here
 *         auto dispacher = scoped!EventDispacher(event);
 *         dispacher.dispach!ClickEvent(&onClicked.dispach);
 *     }
 * }
 *
 * bool onFooClicked(in Foo sender, in size_t x, in size_t y)
 * {
 *     // do stuff here
 *     assert([x, y] == [4, 5]);
 *
 *     // true to handle the event
 *     // false to propagate
 *     return true;
 * }
 *
 * void main()
 * {
 *     Foo foo = new Foo();
 *     foo.onClicked.connect(toDelegate(&onFooClicked));
 *     foo.click(4,5); // callback!
 * }
 * --------------------
 */
mixin template genCallback(T, E : Event, args ...)
{
	static assert(is(T == class));

	import std.typecons : scoped;
	import std.string : format;

	/**
	 * if parameters as passed then use them as the callback delegate parameters,
	 * otherwise just pass the event itself
	 */
	static if (args.length)
	{
		import std.meta : AliasSeq, Filter, templateNot, Stride;
		import std.traits : isType;
		import deventsystem.event : toEventFormat, joinTypeName, stringTuple;

		private alias _as = AliasSeq!args;
		private alias _types = Filter!(isType, _as);
		private enum _eventnames = toEventFormat!(Filter!(templateNot!isType, _as));
		private enum _names = Filter!(templateNot!isType, _as);

		/**
		 * just check if types aren't followed by another type
		 * do not let the user insert args like (int, int, "foo", "bar")
		 */
		import std.typecons : Tuple;
		static assert(is(Tuple!_types == Tuple!(Stride!(2, _as))),
			"Cannot have sequential types!");
	}
	else
	{
		private alias _types = E;
		private enum _eventnames = ",event";
	}

public:
	@system pure
	void connect(bool delegate (T, _types) dg)
		in(dg.funcptr !is null || dg.ptr !is null)
	{
		callback = dg;
	}

	static if (args.length)
	{
		private alias ctorOverloads = __traits(getOverloads, E, "__ctor");
		private enum len = ctorOverloads.length;
		static foreach (j, t; ctorOverloads)
		{
			import std.traits : Parameters, isImplicitlyConvertible;
			alias par = Parameters!t;
			static foreach (i, type; _types)
			{
				static if (j == len - 1)
				{
					static if (_types.length != par.length)
					{
						static assert (_types.length == par.length,
							"Type(s) in %s are not valid in any of the %s ctor overloads!"
							.format(_types.stringof, E.stringof)
							~" Failed on: types.length <> ctor_parameters.length (%s <> %s) at %s"
							.format(_types.length, par.length, typeof(t).stringof));
					}
					else static if ((!isImplicitlyConvertible!(type, par[i])))
					{
						static assert (isImplicitlyConvertible!(type, par[i]),
							"Type(s) in %s are not valid in any of the %s ctor overloads!"
							.format(_types.stringof, E.stringof)
							~" Failed on: <%s> cannot convert to <%s> at %s"
							.format(type.stringof, par[i].stringof, typeof(t).stringof));
					}
				}
			}
		}
		mixin(q{
			void emit(},joinTypeName!args,q{)
			{
				import std.string : format;
				mixin(q{ auto event = scoped!E(%s); }.format(stringTuple!_names));
				emit(event);
			}});
	}
	else static if (__traits(compiles, scoped!E()))
	{
		void emit()
		{
			auto event = scoped!E;
			onEvent(event);
		}
	}

	/**
	 * in case the user wants to declare the event beforehand or if the user
	 *   wants a callback only with sender and the event but the event doesn't
	 *   have an empty ctor
	 */
	void emit(E event)
		in(event !is null, "%s cannot be null".format(E.stringof))
	{
		if (callback.funcptr !is null || callback.ptr !is null)
			onEvent(event);
	}

protected:
	void dispach(E event)
	{
		import std.string : format;
		if (callback.funcptr !is null || callback.ptr !is null)
			mixin(q{
				event.handled = callback(this%s);}
				.format(_eventnames));
	}

	bool delegate(T, _types) callback;
}


/** Generate a string with the format `,event.<args[0],event.args[1],...`
 *
 * This template is used **internaly** only!
 *
 * Params:
 *     args = string values to be formated
 *
 * Examples:
 * --------------------
 * enum str = toEventFormat!("a", "b", "c");
 * --------------------
 * --------------------
 * static assert(toEventFormat!("a", "b"), ",event.a,event.b");
 * --------------------
 *
 * Returns:
 *     string `enum`
 */
template toEventFormat(args ...)
{
	@safe pure
	auto toEventFormat()
	{
		import std.array : appender;
		auto ret = appender!string;
		foreach (var; args)
		{
			import std.string : format;
			import std.traits : isType;
			static assert(!isType!var);
			static assert(is(typeof(var) == string));
			ret ~= ",event." ~ var;
		}
		return ret.data;
	}
}


@safe
@("Event: toEventFormat")
unittest
{
	assertEquals(toEventFormat!("a", "b"), (",event.a,event.b"));
}


/** Generate function parameters with named types
 *
 * Takes in var types and literal strings alternatively and joins them in a
 *     string. \
 * \
 * This is used internaly only!
 *
 * Examples:
 * --------------------
 * enum params = joinTypeName!(int,"var1",const char,"var2",string,"var3");
 * assert(params == "int var1,const(char) var2,string var3");
 * --------------------
 *
 * Returns:
 *     `string` of named parameters
 */
template joinTypeName(args ...)
{
	@safe pure
	auto joinTypeName()
	{
		import std.array : appender;
		import std.meta : AliasSeq, Filter, templateNot;
		import std.traits : isType;
		import std.string : format;

		alias _as = AliasSeq!args;
		alias types = Filter!(isType, _as);
		enum names = Filter!(templateNot!isType, _as);

		static assert(names.length == types.length,
				"Types length and Names length do not match! (%s types and %s names)"
				.format(types.length, names.length));

		auto ret = appender!string;
		foreach (i, type; types)
		{
			ret ~= type.stringof ~ " " ~ names[i] ~ ",";
		}
		return ret.data[0 .. $ - 1];
	}
}


@safe
@("Event: joinTypeName")
unittest
{
	assertEquals(joinTypeName!(int,"foo",string,"bar"), "int foo,string bar");
	assertEquals(joinTypeName!(const int,"i",immutable char,"c"), "const(int) i,immutable(char) c");
}


/** Joins strings with a coma
 *
 * Takes in multiple strings and joins them into one string
 *     separated by comas;
 *
 * Examples:
 * --------------------
 * assertEquals(stringTuple!("hi", "there"), "hi,there");
 * --------------------
 *
 * Returns:
 *     `string` of joined string separated by comas
 */
template stringTuple(args ...)
{
	@safe pure
	auto stringTuple()
	{
		import std.array : appender;
		import std.string : format;
		import std.traits : isSomeString, isTypeTuple;

		foreach (v; args)
		{
			static assert(isSomeString!(typeof(v)),
				"Args must be a string! (%s of type \'%s\' is not a string)"
				.format(v, typeof(v).stringof));
		}

		auto ret = appender!string;
		foreach (str; args)
			ret ~= str ~ ",";
		return ret.data[0 .. $ - 1];
	}
}


@safe
@("Event: stringTuple")
unittest
{
	assertEquals(stringTuple!("hi", "there"), "hi,there");
}


private version(unittest)
{
	@safe
	bool onFooEvent(in Foo sender, in int a, int b, int c)
	{
		assertEquals([a,b,c], [2,4,5]);

		return true;
	}

	@safe
	bool onBarEvent(in Foo sender, in BarEvent event)
	{
		assertEquals(event.toString, "BarEvent");
		assertEquals([event.x, event.y], [2, 4]);

		// handle
		return true;
	}


	@EventType("FooEvent")
	@safe class FooEvent : Event
	{
		mixin basicEventType!FooEvent;

	public:
		this(in int a, in int b, in int c)
		{
			this.a = a;
			this.b = b;
			this.c = c;
		}

		const int a, b, c;
	}

	@EventType("BarEvent")
	@safe class BarEvent : Event
	{
		mixin basicEventType!BarEvent;

	public:
		this(in size_t x, in size_t y)
		{
			this.x = x;
			this.y = y;
		}

		const size_t x, y;
	}

	@EventType("BazEvent")
	@safe class BazEvent : BarEvent
	{
		mixin basicEventType!BazEvent;

	public:
		this()
		{
			super(3, 7);
		}
	}

	class Foo
	{
		mixin genCallback!(const Foo, FooEvent, const int, "a", int, "b", int, "c") onFoo;
		mixin genCallback!(const Foo, BarEvent) onBar;
		mixin genCallback!(Foo, BazEvent) onBaz;

	public:
		this(in int a, in int b, in int c)
		{
			this.a = a;
			this.b = b;
			this.c = c;

			onBaz.connect(delegate bool(Foo, BazEvent event) {
				assertEquals([event.x, event.y], [3, 7]);

				return true;
			});
		}

		void bar()
		{
			import std.typecons : scoped;
			auto event = scoped!BarEvent(a, b);
			onBar.emit(event);

			assertTrue(event.handled);
		}

		void foo()
		{
			onFoo.emit(a, b, c);
		}

		void baz()
		{
			onBaz.emit();
		}

	private:
		@system
		void onEvent(Event event)
		{
			import std.typecons : scoped;
			import deventsystem.eventdispacher : EventDispacher;
			auto ed = scoped!EventDispacher(event);
			ed.dispach!FooEvent(&onFoo.dispach);
			ed.dispach!BarEvent(&onBar.dispach);
			ed.dispach!BazEvent(&onBaz.dispach);
		}

		const int a, b, c;
	}
}

@("Event: event ctor") @safe
unittest
{
	FooEvent event = new FooEvent(1,2,3);
	assertEquals([1,2,3], [event.a, event.b, event.c]);
}

@("Event: connect to a delegate") @system
unittest
{
	Foo foo = new Foo(2,4,5);
	foo.foo(); // nothing fires
	foo.baz(); // fires the default onBaz event

	import std.functional : toDelegate;
	foo.onFoo.connect(toDelegate(&onFooEvent));
	foo.onBar.connect(toDelegate(&onBarEvent));

	foo.foo(); // fires onFooEvent
	foo.bar(); // fires onBarEvent
}
