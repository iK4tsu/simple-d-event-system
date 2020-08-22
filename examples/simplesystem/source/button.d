module button;

import widget : Widget;

/** Child of Widget
 *
 * Has access to all Widget's events and can have it's own button callbacks
 * Examples of this are Clicked, Released, etc
 */
class Button : Widget
{
	import deventsystem.event;
	import events.button;
	import events.widget : CreatedEvent;
	import std.typecons : scoped;

	mixin genCallback!(Button, ClickedEvent) onClicked;


public:
	this(in string name)
	{
		this(name, null);
	}

	this(in string name, bool delegate(Widget, in CreatedEvent) func)
	{
		this.name = name;
		onClicked.connect(&onClickedEvent);
		super(func);
	}


	/** Click a button
	 *
	 * Focus the button and then emits onClicked event
	 *
	 * SeeAlso: void focus()
	 */
	void click(in uint x, in uint y)
	{
		focus();
		onClicked.emit(scoped!ClickedEvent(x, y));
	}

protected:
	override void onEvent(Event event)
	{
		import deventsystem.eventdispacher : EventDispacher;
		auto ed = scoped!EventDispacher(event);
		ed.dispach!ClickedEvent(&onClicked.dispach);

		import std.stdio : writeln;
		import std.string : format;
		if (!event.handled) super.onEvent(event);
		else "%s: I was handled! Stopping propagation..."
				.format(event.toString)
				.writeln;
	}

	@safe
	bool onClickedEvent(Button sender, in ClickedEvent event)
	{
		import std.stdio : writeln;
		import std.string : format;
		"%s: %s(x = %s, y = %s)"
			.format(sender.classinfo.name, event, event.x, event.y)
			.writeln;

		return true;
	}


public:
	const string name;
}
