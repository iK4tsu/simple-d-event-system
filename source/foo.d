module foo;

import createdevent : CreatedEvent;
import event : Event;
import eventdispacher : EventDispacher;

import std.typecons : scoped;

class Foo
{
public:
	@trusted
	this(in string str)
	{
		this(str, null);
	}

	this(in string str, void delegate(in Foo, in string) onCreated)
	{
		this.str = str;
		onEventCallback = &onEvent;
		onCreatedCallback = onCreated;
		auto event = scoped!CreatedEvent;
		onEventCallback(event);
	}


	void addOnCreatedEvent(void delegate(in Foo, in string) func)
	{
		onCreatedCallback = func;
	}

private:
	@trusted
	void onEvent(in Event e)
	{
		auto ed = scoped!EventDispacher(e);
		ed.dispach!CreatedEvent(&onCreatedDispached);
	}

	void onCreatedDispached(in CreatedEvent event)
	{
		if (onCreatedCallback.ptr is null)
			return;

		onCreatedCallback(this, str);
	}

	void onCreatedEvent(in Foo, in string) {}

	string str;
	void delegate(Event) onEventCallback;
	void delegate(in Foo sender, in string str) onCreatedCallback;
}
