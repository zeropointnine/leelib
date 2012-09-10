package leelib.ui
{
	import com.greensock.TweenLite;
	import com.greensock.easing.Linear;
	
	import flash.display.Sprite;
	import flash.events.Event;

	
	/**
	 * Adds bounding-box dimension properties (sizeWidth, sizeHeight) to Sprite.
	 * Plus show(), hide(), and kill().
	 */
	public class BoxSprite extends Sprite
	{
		public static const EVENT_SHOWCOMPLETE:String = "eventShowComplete";
		public static const EVENT_HIDECOMPLETE:String = "eventHideComplete";

		protected var _sizeWidth:Number;
		protected var _sizeHeight:Number;
		
		
		public function BoxSprite()
		{
			super();
		}
		
		public function size():void
		{
			// Component does any _sizeWidth and _sizeHeight-dependent operations here.
			// Override in subclass.
		}

		public function get sizeWidth():Number
		{
			return _sizeWidth;
		}
		public function set sizeWidth($n:Number):void
		{
			_sizeWidth = $n;
			if (_sizeHeight) this.size();
		}
		
		public function get sizeHeight():Number
		{
			return _sizeHeight;
		}
		public function set sizeHeight($n:Number):void
		{
			_sizeHeight = $n;
			if (_sizeWidth) this.size();
		}
		
		public function show():void
		{
			this.visible = true;
			this.alpha = 0;
			TweenLite.killTweensOf(this);
			TweenLite.to(this, 0.5, { alpha:1, onComplete:this.dispatchEvent, onCompleteParams:[new Event(EVENT_SHOWCOMPLETE)] } );
		}
		
		public function hide():void
		{
			TweenLite.killTweensOf(this);
			TweenLite.to(this, 0.33, { alpha:0, ease:Linear.easeNone, onComplete:hide_2} );
		}
		private function hide_2():void
		{
			this.visible = false;
			this.dispatchEvent(new Event(EVENT_HIDECOMPLETE)); 			
		}
		
		public function kill():void
		{
		}

	}
}