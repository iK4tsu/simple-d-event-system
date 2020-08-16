module createdevent;

import event;

class CreatedEvent : Event
{
	mixin basicEventType!CreatedEvent;
}
