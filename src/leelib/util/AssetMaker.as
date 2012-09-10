package leelib.util
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.display.StageQuality;
	import flash.filters.DropShadowFilter;
	import flash.text.TextField;
	
	import leelib.graphics.GrUtil;
	import leelib.graphics.GradientTextSprite;
	import leelib.util.TextFieldUtil;
	
	import leelib.GlobalApp
	import leelib.Constants;

	public class AssetMaker
	{
		public static const RIBBONCOLOR_PURPLE:uint = 0;
		
		/**
		 * Takes properly cut-up asset, which was sized for iPhone 4.
		 * Creates new BitmapData, scaled for current environment.
		 * 
		 * Rem, Bitmap holder using resulting BitmapData should be set to false, and of course have a scale of 1 
		 */
		public static function makeResizedBitmapData($b:BitmapData):BitmapData
		{
			if (GlobalApp.scaleI4 == 1.0) return $b;

			GlobalApp.stage.quality = StageQuality.HIGH;
			var w:int = Math.round($b.width * GlobalApp.scaleI4); 
			var h:int = Math.round($b.height * GlobalApp.scaleI4); 
			var b:BitmapData = GrUtil.makeResizedBitmapData($b, w,h, $b.transparent, true);
			GlobalApp.stage.quality = Constants.STAGEQUALITY;
			return b;
		}
		
		/**
		 * Same gist
		 */
		public static function makeResizedAsset($c:Class):Bitmap
		{
			var bd:BitmapData = makeResizedBitmapData(Bitmap(new $c()).bitmapData);
			return new Bitmap(bd);

			/*
			if (! $resizeBitmapNotBitmapData)
			{
				// resize bitmapData rather than scaling bitmap
				
				var bd:BitmapData = makeResizedBitmapData(Bitmap(new $c()).bitmapData);
				return new Bitmap(bd);
			}
			else
			{
				// scale bitmap rather than resizing bitmapData 
				// (faster instantiation, but with scaling overhead (?))
				
				bd = Bitmap(new $c()).bitmapData;
				var b:Bitmap = new Bitmap(bd);
				b.smoothing = true;
				b.scaleX = b.scaleY = G.scaleI4;
				
				b.width = Math.round(b.width);
				b.height = Math.round(b.height); // ... so dimensions are exactly what they'd be if we did the former (I think)
				
				return b;
			}
			*/
		}

		//
		

		
		public static function makeGrayTitle($stringId:String, $style:String):Bitmap
		{
			var tf:TextField = TextFieldUtil.makeText(GlobalApp.strings[$stringId], $style);
			
			GlobalApp.stage.quality = StageQuality.HIGH;
			var gts:GradientTextSprite = new GradientTextSprite(tf, 0x8f8f8f, 0xffffff, 50,225);
			var b:Bitmap = gts.toBitmap();
			GlobalApp.stage.quality = Constants.STAGEQUALITY;
			return b;
		}
	}
}