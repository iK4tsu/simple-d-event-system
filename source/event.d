module event;

abstract class Event
{
public:
	abstract @property EventType eventType() const;
	abstract @property string name() const;

	pragma(inline, true)
	override string toString() const
	{
		return name;
	}

	bool isEventTypeOf(in EventType eType) const
	{
		return eventType == eType;
	}
}

enum EventType
{
	None,
	CreatedEvent,
}

mixin template basicEventType(T)
{
public:
	pragma(inline, true)
	static @property EventType staticEventType()
	{
		import std.format : format;
		return mixin("EventType.%s".format(T.stringof));
	}

	pragma(inline, true)
	override @property EventType eventType() const
	{
		return staticEventType;
	}

	pragma(inline, true)
	override @property string name() const
	{
		import std.conv : to;
		return eventType.to!string;
	}
}

// TODO: unittesting
