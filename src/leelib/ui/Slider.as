package leelib.ui
{
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;

	public class Slider extends Button
	{
		internal static const EVENT_THUMB_RELEASED:String = "Slider.eventThumbReleased";
		
		private var _track:Sprite;
		
		private var _thumbHolder:Sprite;
		private var _thumb:Button;
		
		private var _thumbRange:int;
		
		private var _value:Number;

		private var _isDragging:Boolean;
		
		private var _stage:Stage;
		
		
		/**
		 * @param $track		Is expected to be already positioned as desired 
		 * @param $thumb		Is expected to be already positioned as desired, at its min position
		 * @param $xRange		Width of thumb movement. 
		 * 						To have slider increase in value as thumb moves left, use negative number 
		 * @param $stage
		 */
		public function Slider($track:Sprite, $thumb:Button, $rangeX:int, $stage:Stage)
		{
			_stage = $stage;
			
			_track = $track;
			this.addChild(_track);

			_thumbHolder = new Sprite();
			this.addChild(_thumbHolder);

				_thumb = $thumb;
				_thumbHolder.addChild(_thumb);
				
			_thumbRange = $rangeX

			value = 0;
			
			enabled = true;
		}
		
		internal function get thumb():Button
		{
			return _thumb;
		}
		
		public override function set enabled($b:Boolean):void
		{
			_enabled = $b;
			
			if (_enabled)
			{
				_thumb.enabled = true;
				_thumb.addEventListener(MouseEvent.MOUSE_DOWN, onThumbDown);
			}
			else
			{
				_thumb.enabled = false;
				_thumb.removeEventListener(MouseEvent.MOUSE_DOWN, onThumbDown);
			}
		}
		
		internal function get isDragging():Boolean
		{
			return _isDragging;
		}
		
		protected override function showOver():void
		{
			//
		}
		
		protected override function showOff():void
		{
			//
		}
		
		public function get value():Number
		{
			return _value;
		}
		
		public function set value($pct:Number):void
		{
			_value = $pct;
			_thumbHolder.x = _value * _thumbRange;
		}
		
		private function onThumbDown(e:*):void
		{
			_stage.addEventListener(MouseEvent.MOUSE_UP, onStageMouseUp);
			_stage.addEventListener(MouseEvent.MOUSE_MOVE, onStageMouseMove);
			
			_thumbHolder.startDrag(false, new Rectangle(0,0, _thumbRange,0));
			
			_isDragging = true;
		}
		
		private function onStageMouseUp(e:*):void
		{
			_stage.removeEventListener(MouseEvent.MOUSE_UP, onStageMouseUp);
			_thumbHolder.stopDrag();
			
			_isDragging = false;
			
			this.dispatchEvent(new Event(EVENT_THUMB_RELEASED));
		}
		
		private function onStageMouseMove(e:*):void
		{
			var v:Number = _thumbHolder.x / _thumbRange;
			if (v == _value) return;
			
			_value = v;
			
			this.dispatchEvent(new Event(Event.CHANGE));
		}
	}
}
