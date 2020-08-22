module events.button.clickedevent;

import deventsystem.event : basicEventType, Event, EventType;

@EventType("ClickedEvent")
class ClickedEvent : Event
{
	mixin basicEventType!ClickedEvent;

public:
	this(in uint x, in uint y)
	{
		this.x = x;
		this.y = y;
	}

	const uint x, y;
}
