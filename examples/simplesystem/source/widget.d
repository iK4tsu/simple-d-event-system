module widget;

/** Main class which holds all common events of every extended class
 *
 * Examples of this are MouseEvents, KeyboardEvents, FocusedEvents,
 *     ActivatedEvents
 */
class Widget
{
	// widget imports
	import events.widget;
	import deventsystem.eventdispacher : EventDispacher;
	import deventsystem.event : Event, genCallback;
	import std.typecons : scoped;
	import std.stdio : writeln;
	import std.string : format;

	// callback declaration
	mixin genCallback!(Widget, MouseClickedEvent) onMouseClicked;
	mixin genCallback!(Widget, DestroyedEvent) onDestroyed;
	mixin genCallback!(Widget, CreatedEvent) onCreated;

public:
	this()
	{
		// default callbacks
		onMouseClicked.connect(&onMouseClickedEvent);
		onDestroyed.connect(&onDestroyedEvent);
		onCreated.connect(&onCreatedEvent);

		onCreated.emit();
	}

	~this()
	{
		// onDestroyedEvent(this, new DestroyedEvent());
		onDestroyed.emit();
	}

	// emit a MouseClickedEvent
	@system
	void click(in uint x, in uint y)
	{
		onMouseClicked.emit(scoped!MouseClickedEvent(x, y));
	}

protected:
	// dispach events
	void onEvent(Event event)
	{
		auto ed = scoped!EventDispacher(event);
		ed.dispach!MouseClickedEvent(&onMouseClicked.dispach);
		ed.dispach!DestroyedEvent(&onDestroyed.dispach);
		ed.dispach!CreatedEvent(&onCreated.dispach);
	}

	// default callback
	@safe
	bool onMouseClickedEvent(Widget widget, in MouseClickedEvent event)
	{
		"Widget: %s(x = %s, y = %s)"
			.format(event.eventType, event.x, event.y)
			.writeln;

		return true;
	}


	@safe
	bool onDestroyedEvent(Widget widget, in DestroyedEvent event)
	{
		"%s: %s"
			.format(widget.classinfo.name, event.eventType)
			.writeln;

		return true;
	}

	@safe
	bool onCreatedEvent(Widget widget, in CreatedEvent event)
	{
		"%s: %s"
			.format(widget.classinfo.name, event.eventType)
			.writeln;

		return true;
	}
}
