package leelib.interfaces
{
		import flash.events.IEventDispatcher;
		public interface IAsyncToken extends IEventDispatcher
		{
			function get isComplete():Boolean;
			function get isSuccessful():Boolean;
			
			function release( status:String ):void;
		}
}