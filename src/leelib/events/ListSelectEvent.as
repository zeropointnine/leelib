package leelib.events
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	public class ListSelectEvent extends Event
	{
		public var index:int 					= -1;
		public var data:Object 					= null;
		public var mouseEvent:MouseEvent 		= null;
		
		public static var EVENT_SELECT:String 	= "ListItem.eventSelect"; 
		
		public function ListSelectEvent(type:String,bubbles:Boolean=true,index:int=0,data:Object=null,mouseEvent:MouseEvent=null)
		{
			super(type, true, false);
			this.index = index;
			this.data = data;
			this.mouseEvent = mouseEvent;
		}
		
		override public function clone():Event
		{
			return new ListSelectEvent(type, bubbles, index,data,mouseEvent);
		}
	}
}