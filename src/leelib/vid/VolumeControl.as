package leelib.vid
{
	import flash.display.Sprite;
	
	import leelib.ui.Component;
	

	/**
	 * Should dispatch Event.CHANGE when user changes volume control. 
	 */
	public class VolumeControl extends Component
	{
		protected var _value:Number;
		
		public function VolumeControl()
		{
		}
		
		public function get value():Number
		{
			return _value;
		}
		
		public function set value($scalar:Number):void
		{
			_value = $scalar;
			size();
		}
	}
}