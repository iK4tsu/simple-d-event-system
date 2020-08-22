module events.widget.focusedevent;

import deventsystem.event : basicEventType, Event, EventType;

@EventType("FocusedEvent")
class FocusedEvent : Event
{
	mixin basicEventType!FocusedEvent;
}
