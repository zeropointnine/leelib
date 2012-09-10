package leelib.ui
{
	import com.greensock.TweenLite;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;

	
	/**
	 * Uses one DisplayObject for off state, and another for over and on state.
	 */	
	public class TwoImageButton extends ThreeStateButton
	{
		public static const OVERTREATMENT_SWAP:uint = 0;
		public static const OVERTREATMENT_FADEONTOP:uint = 1;
		
		public var fadeDuration:Number = 0.25;
		
		private var _off:DisplayObject;
		private var _over:DisplayObject;
		
		private var _overTreatment:uint;
		
		
		public function TwoImageButton($off:DisplayObject, $overAndOn:DisplayObject, $overTreatment:uint=OVERTREATMENT_SWAP)
		{
			_overTreatment = $overTreatment;
			
			_off = $off;
			this.addChild(_off);
			
			_over = $overAndOn;
			this.addChild(_over);
			
			super();
		}
		
		protected override function showUnselectedOut():void
		{
			switch (_overTreatment) 
			{
				case OVERTREATMENT_FADEONTOP:
					TweenLite.to(_over, fadeDuration, { alpha:0 } );
					break;
				
				case OVERTREATMENT_SWAP:
				default:
					_off.visible = true;
					_over.visible = false;
					break;
			}
		}
		
		protected override function showUnselectedOver():void
		{
			switch (_overTreatment) 
			{
				case OVERTREATMENT_FADEONTOP:
					TweenLite.to(_over, fadeDuration, { alpha:1 } );
					break;
				
				case OVERTREATMENT_SWAP:
				default:
					_off.visible = false;
					_over.visible = true;
					break;
			}
		}
		
		protected override function showSelected():void
		{
			showUnselectedOver();
		}
	}
}
