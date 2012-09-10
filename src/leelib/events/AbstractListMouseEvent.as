package leelib.events
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	public class AbstractListMouseEvent extends Event
	{
		public var data:Object 					= null;
		public var mouseEvent:MouseEvent 		= null;
		
		public static var EVENT_MOUSE_DOWN:String 	= "ListItem.eventMouseDown"; 
		
		public function AbstractListMouseEvent(type:String,bubbles:Boolean=true,data:Object=null,mouseEvent:MouseEvent=null)
		{
			super(type, true, false);
			this.data = data;
			this.mouseEvent = mouseEvent;
		}
		
		override public function clone():Event
		{
			return new AbstractListMouseEvent(type, bubbles, data,mouseEvent);
		}
	}
}