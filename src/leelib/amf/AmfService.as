package leelib.amf
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.NetStatusEvent;
	import flash.net.NetConnection;
	import flash.net.Responder;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	import flash.utils.clearTimeout;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	import flash.utils.setTimeout;
	
	import leelib.util.Out;
	
	
	/**
	 * AMF Service wrapper:
	 * 
	 * All possible results routed of call routed thru an AmfEvent of type AmfEvent.EVENT.
	 * 
	 * Note that all NetConnectionStatus events handled by wrapper are interpreted as an 'error'.
	 * This could be inadequate for various use cases.
	 */
	public class AmfService extends EventDispatcher
	{
		private var _url:String;
		private var _timeoutDurationMs:int;
		
		
		private var _gateway:NetConnection;
		private var _responder:Responder;
		
		private var _timeoutId:Number;

		private var _callTime:Number;


		
		public function AmfService($gatewayUrl:String, $timeoutDurationSeconds:Number=0)
		{
			_url = $gatewayUrl;
			_timeoutDurationMs = int($timeoutDurationSeconds * 1000);

			_gateway = new NetConnection();
			_gateway.addEventListener(NetStatusEvent.NET_STATUS, onNetStatusEvent);
			_gateway.connect(_url);			
			
			_responder = new Responder(onResult, onFault);
		}
		
		public function call($method:String, ...$o):void
		{
			_callTime = new Date().getTime();
			if (_timeoutDurationMs > 0) { 
				clearTimeout(_timeoutId);
				_timeoutId = setTimeout(onTimeout, _timeoutDurationMs);
			}
			
			if (Out.level >= Out.SHOW_INFO)
			{
				var s:String = "AmfService.request() - " + '"' + $method + '" - ';
				for (var i:int = 0; i < $o.length; i++) 
				{
					var ss:String;
					if (! $o[i]) 
						ss = "null";
					else if ($o[i] is ByteArray)
						ss = "[ByteArray " + $o[i].length.toString() + "]";
					else
						ss = $o[i].toString();
					s += i + ": " + ss + ' | ';
				}
				Out.i(s);
			}

			// unwrap "...rest" (oh well)
			switch($o.length) 
			{
				case 0:
					_gateway.call($method, _responder);
					break;
				case 1:
					_gateway.call($method, _responder, $o[0]);
					break;
				case 2:
					_gateway.call($method, _responder, $o[0], $o[1]); // w
					break;
				case 3:
					_gateway.call($method, _responder, $o[0], $o[1], $o[2]); // h
					break;
				case 4:
					_gateway.call($method, _responder, $o[0], $o[1], $o[2], $o[3]); // e
					break;
				case 5:
					_gateway.call($method, _responder, $o[0], $o[1], $o[2], $o[3], $o[4]); // e
					break;
				case 6:
					_gateway.call($method, _responder, $o[0], $o[1], $o[2], $o[3], $o[4], $o[5]); // !
					break;
				case 7:
					_gateway.call($method, _responder, $o[0], $o[1], $o[2], $o[3], $o[4], $o[5], $o[6]);
					break;
				case 8:
					_gateway.call($method, _responder, $o[0], $o[1], $o[2], $o[3], $o[4], $o[5], $o[6], $o[7]);
					break;
			}
		}
		
		public function clear():void
		{
			_gateway.removeEventListener(NetStatusEvent.NET_STATUS, onNetStatusEvent);
			clearTimeout(_timeoutId);
		}
		
		//
		
		private function onResult($o:Object): void 
		{
			clearTimeout(_timeoutId);
			
			Out.i('AmfService.onResult() - ' + ($o ? $o.toString() : "NULL"), '(' + getTimeElapsed().toString() + 'ms)' );
			
			this.dispatchEvent(new AmfEvent($o, null, getTimeElapsed()));
		}
		
		private function onNetStatusEvent($e:NetStatusEvent):void
		{
			clearTimeout(_timeoutId);
			
			Out.e('AmfService.onNetStatusEvent() - ' + $e.info.description);			
			
			var eo:AmfError = new AmfError(AmfError.NETSTATUS, $e.info, null);
			this.dispatchEvent(new AmfEvent(null, eo, getTimeElapsed())); 
			// ... note how it passes the NetStatusEvent's info object in the AmfEvent object
		}
		
		private function onFault($o:Object): void 
		{
			clearTimeout(_timeoutId);

			Out.e('AmfService.onFault() - ' + $o.details);			

			var eo:AmfError = new AmfError(AmfError.FAULT, null, $o);
			this.dispatchEvent(new AmfEvent(null, eo, getTimeElapsed()));
			// ... note how it passes the Responder's object in the AmfEvent object
		}
		
		private function onTimeout():void
		{
			clearTimeout(_timeoutId);

			var eo:AmfError = new AmfError(AmfError.TIMEOUT, null, null);
			this.dispatchEvent(new AmfEvent(null, eo, getTimeElapsed()));
		}
		
		private function getTimeElapsed():int
		{
			return new Date().getTime() - _callTime;
		}
		
	}
}
