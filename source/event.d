module event;


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


	pragma(inline, true) @safe pure
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
	pragma(inline, true) @safe pure
	static @property string staticEventType()
	{
		import std.traits : getUDAs;
		return getUDAs!(T, EventType)[0].name;
	}

	pragma(inline, true) @safe pure
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
 *     mixin genCallback!(const Foo, EventType, const x, const y) onClicked;
 *     // Note: you can leave the parameters blank, if you do, then the event
 *     //     itself will be passed as the second parameter as const
 * public :
 *     void click(in size_t x, in size_t y)
 *     {
 *         // click stuff here
 *         onClicked.dispach(new EventType(x, y));
 *     }
 * }
 *
 * void onFooClicked(in Foo sender, in size_t x, in size_t y)
 * {
 *     // do stuff here
 *     assert([x, y] == [4, 5]);
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

	/**
	 * if parameters as passed then use them as the callback delegate parameters,
	 * otherwise just pass the event itself
	 */
	static if (args.length)
	{
		import std.meta : AliasSeq, Filter, templateNot;
		import std.traits : isType;

		private alias _as = AliasSeq!args;
		private alias _types = Filter!(isType, _as);
		private enum _names = toEventFormat!(Filter!(templateNot!isType, _as));

		static assert(Filter!(templateNot!isType, _as).length == _types.length);
	}
	else
	{
		private alias _types = const E;
		private enum _names = ",event";
	}

public:
	pure
	void connect(void delegate (T, _types) dg)
		in (dg.ptr !is null)
	{
		callback = dg;
	}

protected:
	void dispach(E event)
	{
		import std.string : format;
		if (callback.ptr !is null)
			mixin("callback(this%s);".format(_names));
	}

	void delegate(T, _types) callback;
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
private template toEventFormat(args ...)
{
	@safe pure
	auto toEventFormat()
	{
		string ret;
		foreach (var; args)
		{
			import std.string : format;
			import std.traits : isType;
			static assert(!isType!var);
			static assert(is(typeof(var) == string));
			ret ~= ",event." ~ var;
		}
		return ret;
	}
}

@("Event: toEventFormat") @safe
unittest
{
	assertEquals(toEventFormat!("a", "b"), (",event.a,event.b"));
}


version(unittest) import aurorafw.unit;
version(unittest)
{
	@safe pure
	void onFooEvent(in Foo sender, in int a, in int b, in int c)
	{
		assertEquals([a,b,c], [2,4,5]);
	}

	@safe pure
	void onBarEvent(in Foo sender, in BarEvent event)
	{
		assertEquals(event.toString, "BarEvent");
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

	import std.typecons : scoped;
	class Foo
	{
		mixin genCallback!(const Foo, FooEvent, const int, "a", const int, "b", const int, "c") onFoo;
		mixin genCallback!(const Foo, BarEvent) onBar;

	public:
		this(in int a, in int b, in int c)
		{
			this.a = a;
			this.b = b;
			this.c = c;
		}

		@trusted
		void fireFoo()
		{
			/* some foo logic */

			/* fire the event */
			auto event = scoped!FooEvent(a,b,c);
			onEvent(event);
		}

		@trusted
		void bar()
		{
			/* bar logic */

			/* fire the event */
			auto event = scoped!BarEvent(4,5);
			onEvent(event);
		}
	private:
		void onEvent(Event e)
		{
			import eventdispacher : EventDispacher;
			auto ed = scoped!EventDispacher(e);
			ed.dispach!FooEvent(&onFoo.dispach);
			ed.dispach!BarEvent(&onBar.dispach);
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
	foo.fireFoo(); // nothing fires
	foo.bar();

	import std.functional : toDelegate;
	foo.onFoo.connect(toDelegate(&onFooEvent));
	foo.onBar.connect(toDelegate(&onBarEvent));
	foo.fireFoo(); // fires onFooEvent
	foo.bar(); // fires onBarEvent
}
