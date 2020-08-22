module events.widget.createdevent;

import deventsystem.event : basicEventType, Event, EventType;

@EventType("CreatedEvent")
class CreatedEvent : Event
{
	mixin basicEventType!CreatedEvent;
}
