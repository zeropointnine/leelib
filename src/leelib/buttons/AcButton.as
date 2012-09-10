package leelib.buttons
{
	import com.greensock.TweenLite;
	import com.greensock.TweenMax;
	
	import flash.display.DisplayObject;
	import flash.display.Shape;
	
	import leelib.ui.MobileButton;
	
	public class AcButton extends MobileButton
	{
		protected var _off:DisplayObject;
		protected var _down:DisplayObject;
		protected var _on:DisplayObject;


		public function AcButton($off:DisplayObject, $down:DisplayObject, $on:DisplayObject=null)
		{
			_off = $off;
			this.addChild(_off);
			
			_down = $down;
			if (_down) {
				_down.alpha = 0;
				this.addChild(_down);
			}

			_on = $on;
			if (_on) this.addChild(_on);
			
			doesMouseDownCancelEvent = true;
			
			super();
			
			_sizeWidth = _off.width; // NB
			_sizeHeight = _off.height;
		}
		
		public function get offObject():DisplayObject
		{
			return _off;
		}
		
		public function get downObject():DisplayObject
		{
			return _down;
		}
		
		public function get onObject():DisplayObject
		{
			return _on;
		}

		// quick + dirty
		public function enable():void
		{
			this.alpha = 1.0;
			this.mouseEnabled = this.mouseChildren = true;
		}
		public function disable():void
		{
			this.alpha = 0.50;
			this.mouseEnabled = this.mouseChildren = false;
		}
		
		protected override function showUp($useTransition:Boolean):void
		{
			if (_down != null)
			{
				_off.visible = true;
				
				TweenLite.killTweensOf(_down);
				_down.alpha = 0;
				_down.visible = false;

				if (_on != null)
				{
					var duration:Number = $useTransition ? 0.33 : 0;
					TweenLite.killTweensOf(_on);
					TweenLite.to(_on, duration, { alpha:0, onComplete:function():void{_on.visible=false;} } );
				}
			}
			else
			{
				// just restore brightness to _off
				TweenLite.killTweensOf(_off);
				duration = $useTransition ? 0.33 : 0;
				TweenMax.to(_off, duration, { colorMatrixFilter:{brightness: 1} } );
			}
		}
		
		protected override function showDown($useTransition:Boolean):void
		{
			if (_down != null) 
			{
				TweenLite.killTweensOf(_down);
				var duration:Number = $useTransition ? 0.33 : 0;
				TweenLite.to(_down, duration, { autoAlpha:1 } );
			}
			else 
			{
				// just make _off darker
				TweenLite.killTweensOf(_off);
				duration = $useTransition ? 0.33 : 0;
				TweenMax.to(_off, duration, { colorMatrixFilter:{brightness: 0.85} } );
			}
		}
		
		protected override function showSelected($useTransition:Boolean):void
		{
			if(this.name=="foo") trace('SHOWSELECTED FOO', $useTransition);
			
			if (_on != null)
			{
				TweenLite.killTweensOf(_down); // rem at this moment, _down may be fading in
				_down.alpha = 1;
				_down.visible = true;
				
				TweenLite.killTweensOf(_on);
				var duration:Number = $useTransition ? 0.33 : 0;
				TweenLite.to(_on, duration, { autoAlpha:1, onComplete:function():void{_down.visible=false;} } );
			}
			else // use _down instead of _on
			{
				_down.visible = true; // no tween f u
				_down.alpha = 1; 
			}
		}
	}
}
