module events.widget.destroyedevent;

import deventsystem.event : basicEventType, Event, EventType;

@EventType("DestroyedEvent")
class DestroyedEvent : Event
{
	mixin basicEventType!DestroyedEvent;
}
