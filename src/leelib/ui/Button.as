package leelib.ui
{
	import com.greensock.TweenLite;
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TouchEvent;
	
	/**
	 * Can be on (selected), over, or off.
	 * Can be enabled or disabled.
	 * 
	 * Can be reselectable. 
	 */	
	public class Button extends Component implements IItem
	{
		public var selectEventBubbles:Boolean = false;
		public var selectEventName:String = Event.SELECT;
		
		protected var _enabled:Boolean;
		protected var _selected:Boolean;
		
		protected var _reselectable:Boolean = false;
		
		protected var _mouseDownFlag:Boolean;
		

		public function Button()
		{
		}

		protected override function doInit():void
		{
			selected = false;
			enabled = true;
		}

		public function set reselectable($b:Boolean):void
		{
			_reselectable = $b;
			updateButtonMode();
		}
		public function get reselectable():Boolean
		{
			return _reselectable;
		}

		public function get enabled():Boolean
		{
			return _enabled;
		}
		public function set enabled($b:Boolean):void
		{
			if (_enabled == $b) return;
			
			_enabled = $b;
			
			if (_enabled)
			{
				this.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
				this.addEventListener(MouseEvent.ROLL_OUT, onRollOut);
				this.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
				// ... CLICK doesn't behave the way I'd expect (Android) so doing it on mouseup
			}
			else
			{
				this.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
				this.removeEventListener(MouseEvent.ROLL_OUT, onRollOut);
				this.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			}
			
			selected = _selected; // updates view
			
			_enabled ? showEnabled() : showDisabled();
			
			updateButtonMode();
		}

		public override function kill():void
		{
			enabled = false;
		}
		
		public function clear():void
		{
			// ...
		}
		
		public function set selected($b:Boolean):void
		{
			_selected = $b;
			
			(_selected) ? showOn() : showOff();
			
			updateButtonMode();
		}
		
		public function get selected():Boolean
		{
			return _selected;
		}
		
		public function showOverState():void
		{
			showOver();
		}
		public function showOffState():void
		{
			showOff();
		}
		public function showOnState():void
		{
			showOn();
		}
		
		public function showEnabledState():void
		{
			showEnabled();
		}
		public function showDisabledState():void
		{
			showDisabled();
		}

		protected function showOver():void
		{
			// OVERRIDE ME
			TweenLite.to(this, 0.3, { alpha:0.66 } );
		}
		
		protected function showOff():void
		{
			// OVERRIDE ME
			TweenLite.to(this, 0.3, { alpha:1 } );
		}
		
		protected function showOn():void
		{
			// OVERRIDE ME
		}
		
		protected function showEnabled():void
		{
			// OVERRIDE ME
		}
		
		protected function showDisabled():void
		{
			// OVERRIDE ME
		}
		
		protected function onMouseDown($e:MouseEvent):void
		{
			// trace('mousedown');
			
			if (_selected && ! _reselectable) return;

			_mouseDownFlag = true;
			$e.stopImmediatePropagation(); // make sure any parent interactiv-object doesn't get event ** CONFIRM THIS WORKS OUT

			showOver();
		}

		protected function onRollOut($e:MouseEvent):void
		{
			// trace('rollout');

			_mouseDownFlag = false;
			
			if (_selected) return;
			showOff();
		}
		
		protected function onMouseUp($e:MouseEvent):void
		{
			// trace('mouseup == select');
			
			var b:Boolean = _mouseDownFlag;
			_mouseDownFlag = false;

			if (_selected && ! _reselectable) return; // a little unsure of this
			
			if (! _selected) 
				showOff();
			else
				showOn();
			
			if (b) {
				this.dispatchEvent(new Event(selectEventName, selectEventBubbles));
			}
			else {
				// trace('didnt mousedown on button so not treating as a select');
			}
		}

		protected function updateButtonMode():void
		{
			var b:Boolean;
			if (_reselectable)
			{
				if (_enabled && _selected)
					b = true;
				else if (_enabled && ! _selected)
					b = true;
				else if (! _enabled && _selected)
					b = false;
				else if (! _enabled && ! _selected)
					b = false;
			}
			else
			{
				if (_enabled && _selected)
					b = false;
				else if (_enabled && ! _selected)
					b = true
				else if (! _enabled && _selected)
					b = false;
				else if (! _enabled && ! _selected)
					b = false;
			}
			this.buttonMode = b;
		}
	}
}
