package leelib.util
{
	public class ColorUtil
	{
		public static function getInbetweenColor($originalColor:uint, $targetColor:uint, $scalar:Number) : uint
		{
			var r0:int = $originalColor >> 16;
			var g0:int = $originalColor >> 8 & 0xff;
			var b0:int = $originalColor & 0xff;
			
			var r1:int = $targetColor >> 16;
			var g1:int = $targetColor >> 8 & 0xff;
			var b1:int = $targetColor & 0xff;
			
			var r2:int = Math.round( r0 + (r1 - r0) * $scalar );
			var g2:int = Math.round( g0 + (g1 - g0) * $scalar );
			var b2:int = Math.round( b0 + (b1 - b0) * $scalar );
			
			var newColor:uint = rgbToUint(r2,g2,b2);
			return newColor;
		}
		
		public static function rgbToUint($r:int, $g:int, $b:int):uint
		{
			return ($r << 16) + ($g << 8) + $b;
		}
	}
}