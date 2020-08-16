module eventdispacher;

import event : Event;

class EventDispacher
{
public:
	this(in Event event)
	{
		this.event = event;
	}


	@trusted
	void dispach(T : Event)(in void delegate(T) func)
		in(func.ptr !is null)
	{
		if (event.isEventTypeOf(T.staticEventType))
			func(cast(T) event);
	}

private:
	const Event event;
}

// TODO: unittesting
