package leelib.util
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.NetStatusEvent;
	import flash.net.NetStream;
	
	
	public class NsClient extends NetClient
	{
		public static const EVENT_BUFFERFULL:String = "NsClient.eventBufferFull";
		public static const EVENT_RECORDSTART:String = "NsClient.eventRecordStart";
		public static const EVENT_STREAMNOTFOUND:String = "NsClient.eventStreamNotFound";
		public static const EVENT_PLAYSTOP:String = "NsClient.eventPlayStop";
		
		private var _ns:NetStream;
		
		public function NsClient($id:String, $netStream:NetStream)
		{
			// Snake swallows its own tail. 
			// Basically, allows class to parse the netstatus info and send events accordingly.
		
			id = $id;
			
			_ns = $netStream
			_ns.addEventListener(NetStatusEvent.NET_STATUS, onNetStatus);
		}
		
		public function clear():void
		{
			_ns.removeEventListener(NetStatusEvent.NET_STATUS, onNetStatus);
		}
		
		private function onNetStatus($e:NetStatusEvent):void
		{
			if ($e.info.code != "NetStream.Buffer.Flush") Out.v('NsClient.onNetStatus()', id, $e.info.code); // fuck flush
			
			switch ($e.info.code) 
			{
				case "NetStream.Play.StreamNotFound":
					this.dispatchEvent(new Event(NsClient.EVENT_STREAMNOTFOUND));  // ? never happens under FMS
					break;

				case "NetStream.Buffer.Full":
					this.dispatchEvent(new Event(NsClient.EVENT_BUFFERFULL)); 
					break;
				
				case "NetStream.Play.Stop":
					this.dispatchEvent(new Event(NsClient.EVENT_PLAYSTOP));
					break;

				//
				
				case "NetStream.Publish.Start":
					break;
				
				case "NetStream.Record.Start":
					this.dispatchEvent(new Event(NsClient.EVENT_RECORDSTART));
					break;
			}		
		}
	}
}
