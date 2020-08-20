module widget;

/** Main class which holds all common events of every extended class
 *
 * Examples of this are MouseEvents, KeyboardEvents, FocusedEvents,
 *     ActivatedEvents
 */
class Widget
{
	// widget imports
	import events.mouseclickedevent : MouseClickedEvent;
	import deventsystem.eventdispacher : EventDispacher;
	import deventsystem.event : Event, genCallback;

	// this is used in multiple functions
	import std.typecons : scoped;

	// callback declaration
	mixin genCallback!(Widget, MouseClickedEvent) onMouseClicked;

public:
	this()
	{
		// default callbacks
		onMouseClicked.connect(&onMouseClickedEvent);
	}

	// emit a MouseClickedEvent
	@system
	void click(in uint x, in uint y)
	{
		auto event = scoped!MouseClickedEvent(x, y);
		onEvent(event);
	}

protected:
	// dispach events
	@system
	void onEvent(Event event)
	{
		auto ed = scoped!EventDispacher(event);
		ed.dispach!MouseClickedEvent(&onMouseClicked.dispach);
	}

	// default callback
	@safe
	void onMouseClickedEvent(Widget widget, in MouseClickedEvent event)
	{
		import std.stdio : writeln;
		import std.string : format;

		"Widget: MouseClickedEvent(x = %s, y = %s)"
			.format(event.x, event.y)
			.writeln;
	}
}
