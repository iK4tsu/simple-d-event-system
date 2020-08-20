module app;

import events.mouseclickedevent : MouseClickedEvent;
import widget : Widget;
import button : Button;


void main()
{
	import std.functional : toDelegate;
	Widget widget = new Widget();
	Button button = new Button("MyButton");

	widget.click(2, 4);
	button.click(3, 5);

	button.onMouseClicked.connect(toDelegate(&onButtonClicked));
	button.click(3, 5);
}

void onButtonClicked(Widget widget, in MouseClickedEvent event)
{
	import std.stdio : writeln;
	import std.string : format;
	"Button %s: %s(x = %s, y = %s)"
		.format((cast(Button)widget).name, event.eventType, event.x, event.y).writeln;
}
