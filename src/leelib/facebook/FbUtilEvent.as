package leelib.facebook
{
	import flash.events.Event;
	
	public class FbUtilEvent extends Event
	{
		public static const RESPONSE:String = "FbUtilEvent.response";
		
		public var success:Boolean;
		public var errorMessage:String;

		
		public function FbUtilEvent($success:Boolean, $errorMessage:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(RESPONSE, bubbles, cancelable);
			
			success = $success;
			errorMessage = $errorMessage
		}
	}
}