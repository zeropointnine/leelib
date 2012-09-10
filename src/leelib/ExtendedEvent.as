package leelib
{
	import flash.events.Event;

	public class ExtendedEvent extends Event
	{
		public var object:Object;
		
		public function ExtendedEvent(type:String, $object:Object, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			object = $object;
			super(type, bubbles, cancelable);
		}
		
	}
}