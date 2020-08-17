module eventdispacher;

import event : Event;


/** Dispach an Event to a function
 *
 * Use this class whenever you want to redirect a specific event to a function. \
 */
@safe class EventDispacher
{
public:
	this(Event event)
	{
		this.event = event;
	}


	/** Dispach an event
	 *
	 * If the `event` variable in EventDispacher is the same type as T calls func.
	 *
	 * Params:
	 *     T = *Event* to compare to **event**
	 *     func = callback function
	 *
	 * Examples:
	 * --------------------
	 * void onEvent(in Event e)
	 * {
	 *     Eventdispacher ed = new EventDispacher(e);
	 *     ed.dispach!MyEvent(delegate void(MyEvent event) { event.toString().writeln; });
	 * }
	 * --------------------
	 * --------------------
	 * void onEvent(in Event e)
	 * {
	 *     Eventdispacher ed = new EventDispacher(e);
	 *     ed.dispach!MyEvent((MyEvent event) { event.toString().writeln; });
	 * }
	 * --------------------
	 * --------------------
	 * auto func = (MyEvent event) { event.toString.writeln; };
	 * void onEvent(in Event e)
	 * {
	 *     Eventdispacher ed = new EventDispacher(e);
	 *     ed.dispach!MyEvent(func);
	 * }
	 * --------------------
	 * --------------------
	 * void onMyEvent(MyEvent event) { event.toString.writeln; }
	 * void onEvent(in Event e)
	 * {
	 *     import std.functional : toDelegate;
	 *     Eventdispacher ed = new EventDispacher(e);
	 *     ed.dispach!MyEvent(toDelegate(&onMyEvent));
	 * }
	 * --------------------
	 */
	@system
	void dispach(T : Event)(in void delegate(T) func)
		in(func.ptr !is null)
	{
		if (event.isEventTypeOf(T.staticEventType))
			func(cast(T) event);
	}

private:
	Event event;
}


version(unittest)
{
	import aurorafw.unit;
	import event : EventType, basicEventType;

	@EventType("FooEvent")
	class FooEvent : Event
	{
		mixin basicEventType!FooEvent;
	}
}

@("EventDispacher: ctor") @safe
unittest
{
	FooEvent event = new FooEvent();
	EventDispacher ed = new EventDispacher(event);
	assertSame(ed.event, event);
}

@("EventDispacher: dispach") @system
unittest
{
	FooEvent event = new FooEvent();
	FooEvent event2 = new FooEvent();
	EventDispacher ed = new EventDispacher(event);

	ed.dispach!FooEvent(delegate void(in FooEvent _event)
	{
		assertSame(_event, event);
		assertNotSame(_event, event2);
	});


	ed.dispach!FooEvent((in FooEvent _event) {
		assertSame(_event, event);
		assertNotSame(_event, event2);
	});

	auto func = (in FooEvent _event) {
		assertSame(_event, event);
		assertNotSame(_event, event2);
	};

	ed.dispach!FooEvent(func);
}
