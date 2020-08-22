module events.widget.destroyedevent;

import deventsystem.event;

@EventType("DestroyedEvent")
class DestroyedEvent : Event
{
	mixin basicEventType!DestroyedEvent;
}
