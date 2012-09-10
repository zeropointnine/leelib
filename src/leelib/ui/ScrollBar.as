package leelib.ui
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import leelib.interfaces.*
	import leelib.graphics.GrUtil;
	
	
	public class ScrollBar extends Component
	{
		private var _up:Sprite;
		private var _down:Sprite;
		private var _track:Sprite;
		private var _thumb:Sprite;
		
		private var _value:Number = 0;
		private var _thumbHeightDefault:Number;
		private var _thumbPct:Number = -1; // -1 == default
		
		private var _arrowStep:Number = 0.15;
		
		private var _enabled:Boolean;
		
		/**
		 * All elements get reparented 
		 */		
		public function ScrollBar($height:Number, $arrowUp:Sprite, $arrowDown:Sprite, $track:Sprite, $thumb:Sprite )
		{
			_up = $arrowUp;
			_down = $arrowDown;
			_track = $track; // .. gets vertically scaled. use scale9 if necessary.
			_thumb = $thumb; // .. gets vertically scaled. use scale9 if necessary.

			if (_up) {
				_up.x = _up.y = 0;
				this.addChild(_up);
			}

			if (_down) {
				this.addChild(_down);
			}
			
			this.addChild(_track);
			_track.x = 0;
			if (_up) _track.y = _up.height;
			this.addChild(_track);
			
			_thumbHeightDefault = _thumb.height;
			this.addChild(_thumb);

			enabled = true;
			
			setSize(NaN, $height);
		}
		
		public function get enabled():Boolean
		{
			return _enabled;
		}
		public function set enabled($b:Boolean):void
		{
			if (_enabled == $b) return;

			_enabled = $b;

			if (_enabled) {
				_thumb.addEventListener(MouseEvent.MOUSE_DOWN, onThumbDown);
				if (_up) _up.addEventListener(MouseEvent.CLICK, onUpClick);
				if (_down) _down.addEventListener(MouseEvent.CLICK, onDownClick);
			}
			else {
				_thumb.removeEventListener(MouseEvent.MOUSE_DOWN, onThumbDown);
				if (_up) _up.removeEventListener(MouseEvent.CLICK, onUpClick);
				if (_down) _down.removeEventListener(MouseEvent.CLICK, onDownClick);
			}
			_thumb.buttonMode = _enabled;
			if (_up) _up.buttonMode = _enabled;
			if (_down) _down.buttonMode = _enabled;
			
			// override and change view based on value if desired
		}
		
		
		public function get arrowStep():Number
		{
			return _arrowStep;
		}
		public function set arrowStep($percent:Number):void
		{
			_arrowStep = $percent;
		}
		
		public function set thumbHeightPercentage($pct:Number):void
		{
			if (isNaN($pct) || $pct < 0)
				_thumbPct = -1;
			else
				_thumbPct = $pct;
			
			setSizeThumb();
			size();
		}

		private function onThumbDown(e:*):void
		{
			_thumb.startDrag(false, new Rectangle(_thumb.x, _track.y, 0, _track.height - _thumb.height));
			this.stage.addEventListener(MouseEvent.MOUSE_UP, onUp);
			this.stage.addEventListener(Event.MOUSE_LEAVE, onUp);
			this.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMove);
		}
		
		private function onMove(e:*):void
		{
			var range:Number = _track.height - _thumb.height;
			_value = (_thumb.y - _track.y) / range;
			this.dispatchEvent(new Event(Event.CHANGE));
		}
		
		private function onUp(e:*):void
		{
			_thumb.stopDrag();
			this.stage.removeEventListener(MouseEvent.MOUSE_UP, onUp);
			this.stage.removeEventListener(Event.MOUSE_LEAVE, onUp);
			this.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMove);
		}
		
		private function onUpClick(e:*):void
		{
			_value -= _arrowStep;
			if (_value < 0) _value = 0;
			size();
			this.dispatchEvent(new Event(Event.CHANGE));
		}
		private function onDownClick(e:*):void
		{
			_value += _arrowStep;
			if (_value > 1) _value = 1;
			size();
			this.dispatchEvent(new Event(Event.CHANGE));
		}
		
		override public function set sizeHeight($height:Number):void
		{
			setSize(NaN, $height);
		}
		
		public override function setSize($width:Number, $height:Number, $dontSizeYet:Boolean=false):void // $width not used
		{
			_sizeHeight = $height;

			// track height
			if (_up) {
				_track.height = _sizeHeight - _up.height - _down.height;
				_down.y = _track.y + _track.height;
			} else {
				_track.height = _sizeHeight;
			}
			
			if (!$dontSizeYet) size();

			setSizeThumb();
			
			size();
		}
		
		private function setSizeThumb():void
		{
			if (_thumbPct == -1) {
				_thumb.height = _thumbHeightDefault;
			}
			else {
				_thumb.height = _thumbPct * _track.height
			}
		}
		
		public override function size():void // positions thumb
		{
			var range:Number = _track.height - _thumb.height;
			_thumb.y = _track.y + range * _value;
		}

		public function get value():Number
		{
			return _value;
		}
		
		public function set value($n:Number):void
		{
			_value = $n;
			size();
		}
	}
}