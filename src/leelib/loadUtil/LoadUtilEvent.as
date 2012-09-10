package leelib.loadUtil
{
	import flash.display.BitmapData;
	import flash.events.Event;

	public class LoadUtilEvent extends Event
	{
		static public var COMPLETE:String = "COMPLETE";
		
		public var originalEvent:Object;
		// ... 	the event that is 'relayed' from within LoaderManager
		
		public var callbackData:Object;
		// ... 	user-defined info, originally stored in the Manager when the item was queued

		public var errorText:String;
		// ... 	is populated with the error description when there's an error
		//		(in other words, you check for the error on the this response object
		//		rather than listening for a separate error event)	
		
		public var data:Object;
		// ...	the actual output

		
		public function LoadUtilEvent($type:String, $data:Object, $callbackData:Object=null, $errorText:String=null, $bubbles:Boolean=false, $cancelable:Boolean=false)
		{
			super($type, $bubbles, $cancelable);
			
			errorText = $errorText;
			callbackData = $callbackData;
			data = $data;
		}
		
		public function get isError():Boolean
		{
			return Boolean(errorText);
		}
	}
}
