module widget;

/** Main class which holds all common events of every extended class
 *
 * Examples of this are FocusedEvents, ActivatedEvents, etc
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
	mixin genCallback!(Widget, FocusedEvent) onFocused;
	mixin genCallback!(Widget, DestroyedEvent) onDestroyed;
	mixin genCallback!(Widget, CreatedEvent) onCreated;


public:
	this() { this(null); }
	this(bool delegate(Widget, in CreatedEvent) func)
	{
		// default callbacks
		onFocused.connect(&onFocusedEvent);
		onDestroyed.connect(&onDestroyedEvent);

		if (func.funcptr)
			onCreated.connect(func);
		else
			onCreated.connect(&onCreatedEvent);

		onCreated.emit();
	}

	~this()
	{
		onDestroyed.emit();
	}


	/** Focus the widget
	 *
	 * Emits the onFocused event
	 */
	void focus()
	{
		_focused = true;
		onFocused.emit();
	}


	/** Focused property getter
	 *
	 * Returns:
	 *     `true` if focused \
	 *     `false` otherwise
	 */
	@property bool focused() const
	{
		return _focused;
	}


protected:
	// dispach events
	void onEvent(Event event)
	{
		auto ed = scoped!EventDispacher(event);
		ed.dispach!FocusedEvent(&onFocused.dispach);
		ed.dispach!DestroyedEvent(&onDestroyed.dispach);
		ed.dispach!CreatedEvent(&onCreated.dispach);
	}


	@safe
	bool onFocusedEvent(Widget widget, in FocusedEvent event)
	{
		import std.experimental.logger : trace;
		trace("%s: %s".format(widget.classinfo.name, event.eventType));
		return true;
	}


	/** Runs when Widget is destroyed
	 *
	 * Disclamer:
	 *     If you decide to implement an onDestroyed signal be sure to NOT use
	 *       any functions or calls which alocate memory with the DEFAULT GC
	 *       as this will get you an *Invalid Memory Access* error when freeing
	 *       memory from heap alocated objects. You CAN however do this, but
	 *       you'll have to call `.destroy` manualy and then `GC.free` if you
	 *       wan't to free all memory alocated by the object.
	 *
	 *     If you want to implment an onDestroyed signal AND use functions or
	 *       or calls which allocate memory with the DEFAULT GC, then you'll have
	 *       to implment your **@nogc** callback from scratch.
	 */
	@safe
	bool onDestroyedEvent(Widget widget, in DestroyedEvent event)
	{
		// writeln directly is good to go!
		// functions like format use the apender, meaning they alocate memory :(
		// classes like logger from std.experimental.logger the same
		writeln(widget.classinfo.name, ": ", event);

		return true;
	}


	@safe
	bool onCreatedEvent(Widget widget, in CreatedEvent event)
	{
		import std.experimental.logger : trace;
		trace("%s: %s".format(widget.classinfo.name, event.eventType));

		return true;
	}


	bool _focused;
}
