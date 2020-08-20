module button;

import widget : Widget;

/** Child of Widget
 *
 * Has access to all Widget's events and can have it's own button callbacks
 * Examples of this are Pressed, Released
 */
class Button : Widget
{
public:
	this(in string name)
	{
		this.name = name;
	}

	const string name;
}
