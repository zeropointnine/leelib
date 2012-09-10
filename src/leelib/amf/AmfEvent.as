package leelib.amf
{
	import flash.events.Event;
	
	/**
	 * Basically, there are three disagreeable scenarios, which we are categorizing as an AmfEvent of type 'ERROR':
	 * 
	 * 		- A fault from the responder
	 * 		- A NetStatusEvent
	 * 		- A timeout (lack of response from the server) 
	 * 
	 * - each of which corresponds to an errorType value.
	 * 
	 * The AmfService passes the fault info or the NetStatus info thru to the AmfEvent's object property.
	 * And of course passes the response object in it as well.
	 * 
	 * Note that the occurence of an ERROR/Timeout event doesn't mean another type of event may come afterwards, but oh well.
	 * 
	 */
	public class AmfEvent extends Event
	{
		public static const EVENT:String = "AmfEvent.event";
		
		/**
		 * For RESULT's, object is the payload
		 * For ERROR's, it is the error message 
		 */		
		public var object:Object;	 
		public var error:AmfError;
		
		public var timeElapsed:int;

		
		public function AmfEvent($object:Object, $error:AmfError, $timeElapsedMs:int)
		{
			super(AmfEvent.EVENT);
			
			object = $object;
			error = $error;
			timeElapsed = $timeElapsedMs
		}
	}
}