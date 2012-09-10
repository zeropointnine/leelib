package leelib.ui
{
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	/**
	 * Like 'ThreeStateButton', but the three states are now off/up, off/down(pressed), and on.
	 * Rem, visually, it will be transitioning from off to down to on.
	 * 
	 * TODO: Add logic for disabledness
	 */
	public class MobileButton extends BoxSprite
	{
		protected var _isSelected:Boolean;
		protected var _isReselectable:Boolean;
		protected var _isEnabled:Boolean;
		
		private var _doesMouseDownCancelEvent:Boolean;
		private var _selectEventBubbles:Boolean;
		private var _selectEventName:String = Event.SELECT;
		
		private var _stage:Stage;
		
		
		public function MobileButton()
		{
			setSelected(false, false);
		}
		
		public function get isReselectable():Boolean
		{
			return _isReselectable;
		}
		public function set isReselectable($b:Boolean):void
		{
			_isReselectable = $b;
		}
		
		public function get doesMouseDownCancelEvent():Boolean
		{
			return _doesMouseDownCancelEvent;
		}
		public function set doesMouseDownCancelEvent($b:Boolean):void
		{
			_doesMouseDownCancelEvent = $b;
		}
		
		public function get isSelected():Boolean
		{
			return _isSelected;
		}
		
		public function setSelected($isSelected:Boolean, $useTransition:Boolean):void
		{
			_isSelected = $isSelected;
			
			if (_isSelected) 
			{
				showSelected($useTransition);
				
				if (! _isReselectable) setListenersForDown(false);
				this.buttonMode = false;
			}
			else 
			{
				showUp($useTransition);
				setListenersForDown(true);
			}
		}
		
		public function get selectEventBubbles():Boolean
		{
			return _selectEventBubbles;
		}
		public function set selectEventBubbles($b:Boolean):void
		{
			_selectEventBubbles = $b;
		}
		
		public function get selectEventName():String
		{
			return _selectEventName;
		}
		public function set selectEventName($s:String):void
		{
			_selectEventName = $s;
		}
		
		public override function kill():void
		{
			super.kill();
			// loose listeners, nothing to do
		}
		
		protected function showUp($useTransition:Boolean):void
		{
		}
		
		protected function showDown($useTransition:Boolean):void
		{
		}
		
		protected function showSelected($useTransition:Boolean):void
		{
		}
		
		private function setListenersForDown($b:Boolean):void
		{
			if ($b) {
				this.addEventListener(MouseEvent.MOUSE_DOWN, onDown, false,0,true);
				this.addEventListener(MouseEvent.CLICK, onClick, false,0,true);
				this.buttonMode = true;
			}
			else {
				this.removeEventListener(MouseEvent.MOUSE_DOWN, onDown);
				this.removeEventListener(MouseEvent.CLICK, onClick);
				this.buttonMode = false;
			}
			
			// rem no stage dependency here
		}
		
		private function setListenersForUp($b:Boolean):void
		{
			if ($b)
			{
				if (_stage) _stage.addEventListener(MouseEvent.MOUSE_UP, onStageUp);
				this.addEventListener(MouseEvent.ROLL_OUT, onDownOut, false,0,true);
				this.addEventListener(MouseEvent.ROLL_OVER, onDownOver, false,0,true);
			}
			else
			{
				if (_stage) _stage.removeEventListener(MouseEvent.MOUSE_UP, onStageUp);
				this.removeEventListener(MouseEvent.ROLL_OUT, onDownOut);
				this.removeEventListener(MouseEvent.ROLL_OVER, onDownOver);
			}
		}
		
		//
		
		private function onDown($e:MouseEvent):void
		{
			if (! _stage) _stage = this.stage; // we're on the displaylist at this point
			
			setListenersForUp(true);
			
			showDown(true);
			
			if (_doesMouseDownCancelEvent) $e.stopImmediatePropagation();
		}
		
		private function onDownOut(e:*):void
		{
			if (! _isSelected) {
				showUp(true);
			}
			else {
				// do nothing
			}
				
		}
		private function onDownOver(e:*):void
		{
			showDown(true);
		}
		
		private function onStageUp(e:*):void
		{
			setListenersForUp(false);

			if (! _isSelected) {
				showUp(true);
			}
			else {
				// do nothing
			}
		}
		
		private function onClick(e:*):void
		{
			// trace('hello?', _selectEventBubbles, _selectEventName);

			this.dispatchEvent(new Event(_selectEventName, _selectEventBubbles));
			
			// client is responsible for setting selectedness
		}
	}
}
