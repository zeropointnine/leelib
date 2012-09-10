package leelib.ui
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	/**
	 * Abstract button class that manages three states:
	 * unselected/over, unselected/off, and selected.
	 * 
	 * TODO: Add logic for a 'reselectable' option.
	 * TODO: Add logic for disabled state (4th state)
	 */
	public class ThreeStateButton extends Sprite
	{
		protected var _isSelected:Boolean;

		private var _selectEventBubbles:Boolean = false;
		
		
		public function ThreeStateButton()
		{
			isSelected = false;
		}
		
		public function get isSelected():Boolean
		{
			return _isSelected;
		}
		
		public function set isSelected($b:Boolean):void
		{
			_isSelected = $b;
			
			if (_isSelected) {
				showSelected();
				this.removeEventListener(MouseEvent.ROLL_OVER, onUnselectedOver);
				this.removeEventListener(MouseEvent.ROLL_OUT, onUnselectedOut);
				this.removeEventListener(MouseEvent.CLICK, onUnselectedClick);
				this.buttonMode = false;
			}
			else {
				showUnselectedOut();
				this.addEventListener(MouseEvent.ROLL_OVER, onUnselectedOver);
				this.addEventListener(MouseEvent.ROLL_OUT, onUnselectedOut);
				this.addEventListener(MouseEvent.CLICK, onUnselectedClick);
				this.buttonMode = true;
			}
		}
		
		public function kill():void
		{
			this.removeEventListener(MouseEvent.CLICK, onUnselectedClick);
			this.removeEventListener(MouseEvent.ROLL_OVER, onUnselectedOver);
			this.removeEventListener(MouseEvent.ROLL_OUT, onUnselectedOut);
		}
		
		public function get selectEventBubbles():Boolean
		{
			return _selectEventBubbles;
		}
		public function set selectEventBubbles($b:Boolean):void
		{
			_selectEventBubbles = $b;
		}
		
		protected function showUnselectedOut():void
		{
		}
		
		protected function showUnselectedOver():void
		{
		}
		
		protected function showSelected():void
		{
		}
		
		//
		
		private function onUnselectedOver(e:*):void
		{
			showUnselectedOver();
		}
		
		private function onUnselectedOut(e:*):void
		{
			showUnselectedOut();
		}
		
		private function onUnselectedClick(e:*):void
		{
			this.dispatchEvent(new Event(Event.SELECT, _selectEventBubbles));
			// ... client is responsible for setting selected on or off
		}
	}
}
