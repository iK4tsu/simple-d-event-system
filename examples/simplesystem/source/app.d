module app;

import events;
import widget : Widget;
import button : Button;


void main()
{
	import std.functional : toDelegate;
	Widget widget = new Widget();
	Button button = new Button("MyButton");

	{
		import std.typecons : scoped;
		auto btn = scoped!Button("");
		import std.stdio : writeln;
		scope(exit) "EXITED".writeln;
	}

	widget.click(2, 4);
	button.click(3, 5);

	button.onMouseClicked.connect(toDelegate(&onButtonClicked));
	button.click(3, 5);

	// so that we don't get Invalid memory operation
	// we shouldn't have to do this
	// this is a workaround for now
	button.destroy();
	widget.destroy();
}

bool onButtonClicked(Widget widget, in MouseClickedEvent event)
{
	import std.stdio : writeln;
	import std.string : format;
	"Button %s: %s(x = %s, y = %s)"
		.format((cast(Button)widget).name, event.eventType, event.x, event.y).writeln;

	// don't propagete
	return true;
}
