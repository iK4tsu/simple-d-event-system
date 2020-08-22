module events.widget.createdevent;

import deventsystem.event;

@EventType("CreatedEvent")
class CreatedEvent : Event
{
	mixin basicEventType!CreatedEvent;
}
