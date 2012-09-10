package leelib.ui
{
	/**
	 * An item needs selection and enable logic 
	 */	
	public interface IItem
	{
		function get enabled():Boolean
		function set enabled($b:Boolean):void
		function get selected():Boolean		
		function set selected($b:Boolean):void
		function clear():void
			
		// function set reselectable($b:Boolean):void
		// function get reselectable():Boolean
	}
}