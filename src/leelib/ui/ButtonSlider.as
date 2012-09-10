package leelib.ui
{
	import com.greensock.TweenLite;
	import com.greensock.TweenMax;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	/**
	 * Slider comes out when you click button, eg, like with a volume control
	 */
	public class ButtonSlider extends Button
	{
		private var _hit:Sprite;
		private var _button:Button;
		private var _slider:Slider;
		private var _sliderMask:Sprite;

		private var _sliderFromX:Number;
		private var _sliderToX:Number;

		private var _isOver:Boolean

		/**
		 * Elements are expected to be already positioned as desired.
		 * 
		 * $sliderMask width defines distance slider travels on-show
		 * (this should maybe be parameterized or something else) 
		 */		
		public function ButtonSlider($button:Button, $slider:Slider, $sliderMask:Sprite, $hitArea:Sprite)
		{
			_hit = $hitArea;
			this.addChild(_hit);
			
			_button = $button;
			this.addChild(_button);
			
			_slider = $slider;
			this.addChild(_slider);
			
			_sliderMask = $sliderMask;
			this.addChild(_sliderMask);

			_slider.mask = _sliderMask;
			
			_sliderToX = _slider.x;
			_sliderFromX = _sliderToX - _sliderMask.width;

			enabled = true;
			
			//
			
			_hit.visible = false;
			_slider.visible = false;
			_slider.x = _sliderFromX;
		}
		
		public function get value():Number
		{
			return _slider.value;
		}
		public function set value($pct:Number):void
		{
			_slider.value = $pct;
		}
		
		public override function set enabled($b:Boolean):void
		{
			_enabled = $b;
			
			if (_enabled)
			{
				_button.enabled = true;
				_slider.enabled = true;

				_button.addEventListener(Component.EVENT_ROLLOVER, onButtonOver);
				_slider.addEventListener(Event.CHANGE, onSliderChange);
			}
			else
			{
				_button.enabled = false;
				_slider.enabled = false;
				
				_button.removeEventListener(Event.SELECT, onButtonOver);
				this.removeEventListener(MouseEvent.ROLL_OVER, onThisOver);
				this.removeEventListener(MouseEvent.ROLL_OUT, onThisOut);
				_slider.removeEventListener(Slider.EVENT_THUMB_RELEASED, onSliderThumbReleased);
				_slider.removeEventListener(Event.CHANGE, onSliderChange);
				
				onThisOut(null);
			}
		}
		
		protected override function showOver():void
		{
			//
		}
		
		protected override function showOff():void
		{
			//
		}
		
		private function onButtonOver(e:*):void
		{
			if (_slider.x == _sliderToX) return;

			_isOver = true;
			
			_hit.visible = true;
			this.addEventListener(MouseEvent.ROLL_OUT, onThisOut);
			this.addEventListener(MouseEvent.ROLL_OVER, onThisOver);
			_slider.addEventListener(Slider.EVENT_THUMB_RELEASED, onSliderThumbReleased);
			
			_slider.visible = true;
			TweenLite.killTweensOf(_slider);
			TweenLite.to(_slider, 0.30, { x:_sliderToX } );
		}
		
		private function onThisOver(e:*):void
		{
			_isOver = true;
		}
		
		private function onThisOut(e:*):void
		{
			_isOver = false;

			if (_slider.isDragging) return;
			
			this.removeEventListener(MouseEvent.ROLL_OUT, onThisOut);
			_slider.removeEventListener(Slider.EVENT_THUMB_RELEASED, onThisOut);
			this.removeEventListener(MouseEvent.ROLL_OVER, onThisOver);
			
			TweenLite.to(_slider, 0.3, { x:_sliderFromX, onComplete:onThisOut_2 } );
		}
		
		private function onSliderThumbReleased(e:*):void
		{
			_slider.removeEventListener(Slider.EVENT_THUMB_RELEASED, onSliderThumbReleased);
			
			if (! _isOver) onThisOut(null);
		}
		
		private function onThisOut_2():void
		{
			_slider.visible = false;
			_hit.visible = false;
		}
		
		private function onSliderChange($e:Event):void
		{
			this.dispatchEvent($e);
		}
		 
	}
}