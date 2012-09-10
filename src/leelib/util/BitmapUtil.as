package leelib.util
{
	import flash.display.BitmapData;
	import flash.display.Bitmap;
	import flash.filters.ColorMatrixFilter;
	import flash.geom.Matrix;
	
	public class BitmapUtil
	{
			public static var INVERSE_ALPHA:Array
			public static var ERASE_MATRIX:Array  = []
			INVERSE_ALPHA = new Array();
			INVERSE_ALPHA = INVERSE_ALPHA.concat([1, 0, 0, 0, 0]); // red
			INVERSE_ALPHA = INVERSE_ALPHA.concat([0, 1, 0, 0, 0]); // green
			INVERSE_ALPHA = INVERSE_ALPHA.concat([0, 0, 1, 0, 0]); // blue
			INVERSE_ALPHA = INVERSE_ALPHA.concat([0, 0, 0, -1, 0xff]); // negate the alpha and add 255
	
	
		public static function invertAlpha($src:BitmapData):void
		{
			var bmd:BitmapData = new BitmapData($src.width, $src.height, true, 0x00000000);
			
			var tmp:Bitmap = new Bitmap($src);
			tmp.filters = [ new ColorMatrixFilter(ERASE_MATRIX) ];
			
			bmd.draw(tmp);
			
			tmp = null;
		}
		

	}
}