package leelib.events
{

		import flash.events.Event;
		import leelib.interfaces.IAsyncToken;
		
		public class AsyncTokenEvent extends Event
		{
			public static const SUCCESS:String = 'async_success';
			public static const FAILURE:String = 'async_failure';
			
			private var _token:IAsyncToken;
			public function get token():IAsyncToken { return _token; }
			
			/**
			 * Dispatched by an IAsyncToken to notify listeners of when it completes, and whether it was successful or not.
			 */
			public function AsyncTokenEvent( type:String, token:IAsyncToken, bubbles:Boolean=false, canceable:Boolean=false )
			{
				_token = token;
				super ( type, bubbles, cancelable );
			}
		}
	}