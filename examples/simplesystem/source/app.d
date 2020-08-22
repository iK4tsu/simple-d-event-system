module app;

import events;
import widget : Widget;
import button : Button;


void main()
{
	import std.functional : toDelegate;
	import std.typecons : scoped;

	auto widget = new Widget();
	auto button = scoped!Button("MyButton");

	{
		import std.experimental.logger : info;

		info("Creating scoped object...");

		scope btn = new Button("", (Widget sender, in CreatedEvent) {
			import std.experimental.logger : trace;
			import std.string : format;
			trace("%s: I was created in a scope of a scope!".format(sender.classinfo.name));
			return true;
		});

		btn.onDestroyed.connect((Widget, in DestroyedEvent) {
			import std.experimental.logger : trace;
			trace("I Got destroyed! Here you can use memory alocation like this "
				~"logger class because I was created by scope, therefore I'm "
				~"not being ran (destructor) by the GC! #safe");
			return true;
		});

		scope(exit) info("Destroying scoped object...");
	}

	button.click(3, 5);
	assert(button.focused);

	button.onClicked.connect(toDelegate(&onButtonClicked));

	// lambdas are cool
	button.onFocused.connect((Widget widget, in FocusedEvent event) {
		import std.stdio : writeln;
		import std.string : format;
		"%s: I Got Focused with %s"
			.format(widget.classinfo.name, event.toString)
			.writeln;
		return true;
	});
	button.click(3, 5);
}

bool onButtonClicked(Button sender, in ClickedEvent event)
{
	import std.stdio : writeln;
	import std.string : format;
	"Button %s: %s(x = %s, y = %s)"
		.format(sender.name, event.eventType, event.x, event.y).writeln;

	// handle
	return true;
}
