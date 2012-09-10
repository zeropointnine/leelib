package leelib
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.StageQuality;
	import flash.filesystem.File;
	import flash.geom.Matrix;
	import flash.text.Font;
	import flash.utils.Dictionary;
	
	import leelib.util.DateUtil;

	
	/**
	 * 
	 * Including embedded asset classes.
	 */
	public class Constants
	{
		// DEBUG

		
		
		public static const DEBUG_TESTER_ACCOUNT:String	= "testuser@wk.com";
		
		// VISUAL-RELATED
		
		public static const STAGEQUALITY:String = StageQuality.LOW; // hah
	
		// FILE-RELATED
		public static const PACKAGEDIR_URL:String = File.applicationDirectory.url + "packaged/";
		public static const BAKED_DIMENSIONS_FILENAME:String = "resized_image_dimensions.bin";
		
		// SCREEN SUBCLASS NAMES
		// Make sure to use double-colons between packagename and classname 
		// or else any comparison using getQualifiedClassName will fail

		public static const SPLASH_SCREEN:String = "wk.adcolor.screens.startlogin::SplashScreen";
		

		
		// EMBEDS

		// fonts


		// =============================================================
		// 'BITMAP FACTORY' LOGIC
		
		private static var _bitmapCache:Dictionary; 

		public static function initBitmapCache():void
		{
			if (! _bitmapCache) _bitmapCache = new Dictionary(true);
		}

		public static function isCached($b:BitmapData):Boolean
		{
			// O(n)
			for each (var b:BitmapData in _bitmapCache)
			{
				if (b == $b) return true;
			}
			
			return false;
		}
		
		// Get a bitmap by asset-class whose bitmapData is already scaled
		//
		public static function getBitmapData($bitmapClass:Class, $addToCache:Boolean=false):BitmapData
		{
			if (_bitmapCache[$bitmapClass]) 
			{
				// exists in cache, just return it
				return _bitmapCache[$bitmapClass];
			}
			
			// instantiate bitmapdata
			var bitmapData:BitmapData = Bitmap(new $bitmapClass()).bitmapData;

			// resize it if necessary
			if (GlobalApp.scaleI4 != 1.0) 
			{
				bitmapData = resizeBitmapDataWithScale(bitmapData, GlobalApp.scaleI4, bitmapData.transparent, true);
			}
			
			if ($addToCache) // store a reference (add to cache)
			{
				_bitmapCache[$bitmapClass] = bitmapData;
			}
			return bitmapData;
		}
		
		private static function resizeBitmapDataWithScale($b:BitmapData, $scale:Number, $transparent:Boolean=false, $smoothing:Boolean=true):BitmapData
		{
			var b:BitmapData = new BitmapData($b.width * $scale, $b.height * $scale, $transparent, 0x0);
			var m:Matrix = new Matrix();
			m.scale( $scale,$scale );
			b.draw($b, m, null,null,null, $smoothing);
			return b;
		}
		
		public static function removeDispose($d:DisplayObjectContainer):void
		{
			
		}
	}
}
