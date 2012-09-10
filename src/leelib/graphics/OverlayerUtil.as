package leelib.graphics
{
	import com.greensock.TweenLite;
	import com.greensock.easing.Linear;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	
	/**
	 * Cheep cross-fade effect 
	 */
	public class OverlayerUtil
	{
		public function OverlayerUtil()
		{
		}

		/**
		 * Example usage: 
		 * 
		 * addOverlay(myObject);
		 * myObject.changeStuff();
		 * fadeOutOverlay(myObject);
		 * 
		 */
		public static function addOverlay($d:DisplayObject, $width:Number=NaN, $height:Number=NaN):Boolean
		{
			if (! $d.parent) {
				trace('Utils.addOverlay() - $d must have a parent.');
				return false;
			}
			
			if ($d.parent.getChildByName("overlay")) {
				trace('Utils.addOverlay() - Overlay already exists.');
				return false;
			}
			
			if (isNaN($width) || $width <= 0) $width = $d.width;
			if (isNaN($height) || $height <=0) $height = $d.height;
			if ($width <= 0 || $height <= 0) {
				trace('Utils.addOverlay() - DisplayObject has invalid dimensions');
				return false;
			} 
			
			var bmd:BitmapData = new BitmapData($width, $height, true, 0x00);
			
			try {
				bmd.draw($d, null,null,null,null,false);
			} catch (e:Error) {
				trace('* Utils.addOverlay() -', e.message); 
			}
			
			var b:Bitmap = new Bitmap(bmd);
			b.smoothing = false;
			b.name = "overlay";
			b.x = $d.x;
			b.y = $d.y;
			b.transform = $d.transform; // ?
			var p:DisplayObjectContainer = $d.parent;
			p.addChildAt(b, p.getChildIndex($d) + 1);
			
			return true;
			
			// BTW, don't use this on a Video object. Use its container instead. (Ugly scaling stuff)
		}

		public static function fadeOutOverlay($d:DisplayObject, $time:Number=0.4 ):Boolean
		{
			if (! $d.parent) {
				trace('Utils.fadeOutOverlay() - $d must have a parent.');
				return false;
			}
			var b:DisplayObject = $d.parent.getChildByName("overlay");
			if (! b) {
				trace('Utils.fadeOutOverlay() - could not find overlay bitmap');
				return false;
			} 
			
			TweenLite.to(b, $time, { alpha:0, ease:Linear.easeNone, onComplete:fadeOutOverlay_2, onCompleteParams:[b] } );
			
			return true;			
		}
		
		private static function fadeOutOverlay_2($b:Bitmap):void
		{
			if ($b.parent) $b.parent.removeChild($b);
			$b.visible = false;
			$b.bitmapData.dispose();
			$b = null;
		}
		
	}
}
