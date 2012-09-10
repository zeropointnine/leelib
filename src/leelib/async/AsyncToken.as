package leelib.async
{
	import flash.events.EventDispatcher;
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import leelib.interfaces.IAsyncToken
	import leelib.events.AsyncTokenEvent;
	import flash.events.ErrorEvent;
	
	public class AsyncToken extends EventDispatcher implements IAsyncToken
	{
		public static const SUCCESS:String = "success";
		public static const FAILURE:String = "failure";
		
		private var _successfulEventTypes:Array = new Array();
		// events that will result in the async token completing successfully
		public function get successfulEventTypes():Array { return _successfulEventTypes.slice(0); }
		
		private var _failureEventTypes:Array = new Array();
		// events that will result in the async token completing with a failure
		public function get failureEventTypes():Array { return _failureEventTypes.slice(0); }
		
		private var _isComplete:Boolean = false;
		// Whether or not the token has completed.
		public function get isComplete():Boolean { return _isComplete; }
		
		private var _isSuccessful:Boolean;
		// Whether or not the token was successful, if isComplete is false, this will be null.
		public function get isSuccessful():Boolean { return _isSuccessful; }
		
		private var _owner:Object;
		// The object which owns this async token
		public function get owner():Object { return _owner; }
		
		/**
		 * Creates a new AsyncToken.
		 * 
		 * @param owner The object which dictates when this async token has completed.
		 * @param status The status of this AsyncToken if it can be decided before the token is created
		 * 				 Leave this argument null unless you want the asynctoken to automatically be completed.
		 * @param successfulEventTypes The event types which result in the token being successfully completed.
		 * @param failureEventTypes The event types which result in the token failing.
		 * 
		 * If the status argument is set the token will not dispatch any events, so if you think a token may have had
		 * it set during creation, then check it's IAsyncToken.isComplete property once you receive the token.
		 */
		public function AsyncToken( owner:Object, status:String=null, successfulEventTypes:Array=null, failureEventTypes:Array=null )
		{
			_owner = owner;
			
			// if success/failure event types were passed  work with them
			if ( successfulEventTypes )
				_successfulEventTypes = successfulEventTypes.slice(0);
			
			if ( failureEventTypes )
				_failureEventTypes = failureEventTypes.slice(0);
			
			configureListeners();
			
			if ( status )
				release( status );
		}
		
		/**
		 * Releases the AsyncToken with the status of either AsyncToken.SUCCESS or AsyncToken.FAILURE
		 */
		public function release( status:String ):void
		{
			// release the token manually
			if ( status == SUCCESS )
				onOwnerSuccess( null );
			else if ( status == FAILURE )
				onOwnerFailure( null );
		}
		
		/**
		 * The finalize method is what cleans up the token so that there are no references
		 * between it and it's owner.
		 */
		public function finalize():void
		{
			var ownerDispatcher:IEventDispatcher = owner as IEventDispatcher;
			
			if ( !ownerDispatcher )
				return;
			
			// listen for all of the events
			var count:uint = Math.max( _successfulEventTypes.length, _failureEventTypes.length );
			while ( count-- )
			{
				if ( count < _successfulEventTypes.length )
					ownerDispatcher.removeEventListener( _successfulEventTypes[ count ], onOwnerSuccess );
				
				if ( count < _failureEventTypes.length )
					ownerDispatcher.removeEventListener( _failureEventTypes[ count ], onOwnerFailure );
			}
			
			_owner = null;
		}
		
		// Executes when is successful with what it was doing
		private function onOwnerSuccess( event:Event ):void
		{
			_isComplete = true;
			_isSuccessful = true;
			
			dispatchEvent( new AsyncTokenEvent( AsyncTokenEvent.SUCCESS, this ) );
		}
		
		// Executes when the owner fails what it's doing
		private function onOwnerFailure( event:Event ):void
		{
			_isComplete = true;
			_isSuccessful = false;
			
			dispatchEvent( new AsyncTokenEvent( AsyncTokenEvent.FAILURE, this ) );
		}
		
		// If success/failure event types were passed and the owner is an IEventDispatcher
		// then listen for those events
		private function configureListeners():void
		{
			var ownerDispatcher:IEventDispatcher = owner as IEventDispatcher;
			
			if ( !ownerDispatcher )
				return;
			
			// we listen to two events by default Event.COMPLETE and ErrorEvent.ERROR
			if ( _successfulEventTypes.indexOf( Event.COMPLETE ) == -1 )
				_successfulEventTypes.push( Event.COMPLETE );
			
			if ( _failureEventTypes.indexOf( ErrorEvent.ERROR ) == -1 )
				_failureEventTypes.push( ErrorEvent.ERROR );
			
			// listen for all of the events
			var count:uint = Math.max( _successfulEventTypes.length, _failureEventTypes.length );
			while ( count-- )
			{
				if ( count < _successfulEventTypes.length )
					ownerDispatcher.addEventListener( _successfulEventTypes[ count ], onOwnerSuccess );
				
				if ( count < _failureEventTypes.length )
					ownerDispatcher.addEventListener( _failureEventTypes[ count ], onOwnerFailure );
			}
		}
	}
}