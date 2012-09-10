package leelib.util
{

	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLVariables;
	
	import leelib.ExtendedEvent;
	import leelib.async.AsyncToken;
	import leelib.events.AsyncTokenEvent;
	import leelib.interfaces.IAsyncToken;
	import leelib.util.Out;
	
	public class Service extends EventDispatcher
	{
		public static const RETURNTYPE_STRING:String = "service.returnTypeString";
		public static const RETURNTYPE_JSON:String = "service.returnTypeJsonObject";
		public static const RETURNTYPE_XML:String = "service.returnTypeXml";
		
		protected var _returnType:String;
		

		
		public function request($url:String, $params:Object=null, $method:String="GET", $returnType:String=RETURNTYPE_JSON, $sendTypeJson:Boolean=false):IAsyncToken
		{
			Out.d('Service.request() ' + $url + "?" + printObject($params))
			_returnType = $returnType;
			var urlReq:URLRequest = new URLRequest($url);
			urlReq.method = $method;
			
			var urlVars:URLVariables = new URLVariables();
			
			if (! $sendTypeJson) 
			{
				for ( var i:* in $params ) { 
					urlVars[i] = $params[i];
				}
				urlReq.data = urlVars;
			}
			else
			{
				urlReq.data = JSON.stringify($params);
				urlReq.requestHeaders = [ new URLRequestHeader("Content-Type", "application/json"), new URLRequestHeader("charset", "utf-8") ];
			}

			//
			var urlLoader:URLLoader = new URLLoader(urlReq);
			var token:IAsyncToken = new AsyncToken( urlLoader, null, [ Event.COMPLETE ] );
			urlLoader.dataFormat = URLLoaderDataFormat.TEXT;
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, onError);
			urlLoader.load(urlReq); 
			token.addEventListener( AsyncTokenEvent.SUCCESS, onLoadSuccess );
			return token;
		}
		
		private function onLoadSuccess(event:AsyncTokenEvent):void
		{
			var s:String = event.token['owner'].data;
			var o:Object = castResponse(s);
			o = transform(o);
			this.dispatchEvent(new ExtendedEvent(Event.COMPLETE, o ));
		}
		
		protected function castResponse($responseData:String):Object
		{
			if (_returnType == RETURNTYPE_STRING) {
				return $responseData as Object;	
			}
			else if (_returnType == RETURNTYPE_JSON) {
				return JSON.parse($responseData)
			}
			else if (_returnType == RETURNTYPE_XML){
				return new XML($responseData) as Object;
			}
			
			return null;
		}
		
		/**
		 * The idea here is to take the XML, JSON, or whatever, and "transform" it 
		 * into ready-to-use value objects, or whatever  
		 */
		protected function transform($o:Object):Object
		{
			// OVERRIDE ME (OR NOT)
			
			return $o;
		}
		
		private function onError($event:IOErrorEvent):void
		{
			Out.e('Service.onError()', $event.text);
			this.dispatchEvent($event); 
		}
		
		private function printObject($o:Object):String
		{
			var string:String = "";
			for (var s:String in $o) {
				string += s + "=" + $o[s] + "&";
			}
			return string;
		}
	}
}

class SingletonEnforcer {}
