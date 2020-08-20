module events.mouseclickedevent;

import deventsystem.event;

/** Simple MouseClickedEvent
 */
@EventType("MouseClicked")
class MouseClickedEvent : Event
{
	// necessary functions
	mixin basicEventType!MouseClickedEvent;

public:
	this(in uint x, in uint y)
	{
		this.x = x;
		this.y = y;
	}

	const uint x, y;
}
