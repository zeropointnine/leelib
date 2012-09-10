package leelib.util
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.NetStatusEvent;
	import flash.utils.getQualifiedClassName;
	
	import leelib.ExtendedEvent;

	/**
	 * Client class for NetConnection.
	 * Is also the base class for the custom client class for NetStream.
	 * Sends out a couple events, which are possibly useful.
	 *  
	 */
	public class NetClient extends EventDispatcher
	{
		public static const EVENT_PLAYCOMPLETE:String = "NetClient.eventPlayComplete";
		public static const EVENT_METADATA:String = "NetClient.eventMetaData";
		
		public var id:String = "";

		public function NetClient()
		{
		}
		
		public function onTimeCoordInfo($o:Object):void
		{
			Out.v(StringUtil.getClassName(this) + '.onTimeCoordInfo()', $o["stream-absolute"]);
		}
		
		public function onMetaData($info:Object):void 
		{
			if (Out.level == Out.SHOW_VERBOSE) {
				var s:String = "";
				for (var key:String in $info) {
					s += key + ": " + $info[key] + " | ";
				}
				Out.v(StringUtil.getClassName(this) + '.onMetaData()', id, $info, s);
			}
			
			this.dispatchEvent(new ExtendedEvent(EVENT_METADATA, $info));
		}

		public function onXMPData(info:Object):void
		{
			Out.v(StringUtil.getClassName(this) + '.onXMPData()', id, info);
		}
		
		/**
		 * Called by FMS after initial bandwidth test
		 */
		public function onBWDone():void
		{
			Out.v(StringUtil.getClassName(this) + '.onBwDone()', id);
		}
		
		public function onPlayStatus($o:Object):void
		{
			Out.v(StringUtil.getClassName(this) + '.onPlayStatus()', id, $o.code);
			
			if ($o.code == "NetStream.Play.Complete")
			{
				this.dispatchEvent(new Event(NetClient.EVENT_PLAYCOMPLETE));
			}
		}
		
	}
}
