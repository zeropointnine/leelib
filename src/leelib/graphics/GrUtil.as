package leelib.graphics
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.filters.ColorMatrixFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	
	import leelib.appropriated.JPEGEncoder;
	
	
	public class GrUtil
	{
		public static function localToLocal(from:DisplayObject, to:DisplayObject):Point 
		{
			return to.globalToLocal(from.localToGlobal(new Point()));
		}
		
		//
		// Graphics related
		//
		
		public static function makeRect($width:Number, $height:Number, $color:uint=0xff0000, $alpha:Number=1):Sprite
		{
			var s:Sprite = new Sprite();
			s.graphics.beginFill($color, $alpha);
			s.graphics.drawRect(0,0, $width, $height);
			s.graphics.endFill();
			return s;
		}
		
		public static function makeRoundRectRect($width:Number, $height:Number, $radius:Number, $color:uint=0xff0000, $alpha:Number=1):Sprite
		{
			var s:Sprite = new Sprite();
			s.graphics.beginFill($color, $alpha);
			s.graphics.drawRoundRect(0,0, $width, $height, $radius, $radius);
			s.graphics.endFill();
			return s;
		}
		
		public static function replaceRect($shape:Sprite, $width:Number, $height:Number, $color:uint=0xff0000, $alpha:Number=1):void
		{
			$shape.graphics.clear();
			$shape.graphics.beginFill($color, $alpha);
			$shape.graphics.drawRect(0,0, $width, $height);
			$shape.graphics.endFill();
		}
		
		//
		// Bitmap related
		//
		
		public static function makeBitmap($width:Number, $height:Number, $color32:uint=0xffff8888):Bitmap
		{
			var bmd:BitmapData = new BitmapData($width,$height,true,$color32);
			return new Bitmap(bmd);
		}
		
		public static function makeBitmapDataFromSprite($s:Sprite):BitmapData
		{
			var b:BitmapData = new BitmapData($s.width,$s.height,true,0x0);
			b.draw($s);
			return b;
		}

		public static function makeBitmapFromSprite($s:Sprite, $w:Number=NaN, $h:Number=NaN):Bitmap
		{
			var b:BitmapData = new BitmapData($w || $s.width, $h || $s.height,true,0x0);
			b.draw($s);
			return new Bitmap(b);
		}
		
		public static function makePerlinBitmap($width:Number, $height:Number, $bw:Boolean=true):Bitmap
		{
			var bmd:BitmapData = new BitmapData($width,$height,false,0xffffffff);
			bmd.perlinNoise($width,$height,2, int(Math.random()*0xffffffff),false,false,2,$bw);
			return new Bitmap(bmd);
		}
		
		public static function makeResizedBitmapData($b:BitmapData, $w:Number, $h:Number, $transparent:Boolean=false, $smoothing:Boolean=true):BitmapData
		{
			var b:BitmapData = new BitmapData($w,$h, $transparent, 0x0);
			var m:Matrix = new Matrix();
			m.scale( $w / $b.width, $h / $b.height );
			b.draw($b, m, null,null,null, $smoothing);
			return b;
		}
		
		// Good for a quick 1-time scale9'ed resize
		//
		public static function makeResizedBitmapDataUsingScale9($b:BitmapData, $newWidth:Number, $newHeight:Number, $padding:Number):BitmapData
		{
			var s:Sprite = new Scale9BitmapSprite($b, new Rectangle($padding,$padding,$b.width-$padding*2,$b.height-$padding*2));
			s.width = $newWidth;
			s.height = $newHeight;
			var b:BitmapData = new BitmapData($newWidth, $newHeight, true, 0x0);
			b.draw(s);
			return b;
		}
		
		public static function makeCroppedBitmapData($b:BitmapData, $w:int, $h:int):BitmapData
		{
			var b:BitmapData = new BitmapData($w,$h, true, 0x0);
			b.draw($b);
			return b;
		}
		
		/**
		 * Fills in a BitmapData of dimensions $w,$h with the graphics from $bitmap, 
		 * cropping what sticks out vertically or horizontally   
		 */
		public static function makeCroppedFittedBitmapData($bitmap:Bitmap, $w:Number,$h:Number):BitmapData
		{
			var wSrc:Number = $bitmap.width;
			var wDest:Number = $w;
			var hSrc:Number = $bitmap.height;
			var hDest:Number = $h;
			var arSrc:Number = wSrc/hSrc;
			var arDest:Number = wDest/hDest;
			
			var b:BitmapData = new BitmapData(wDest,hDest,false,0x0);
			
			var sca:Number;
			
			var offX:Number = 0;
			var offY:Number = 0;
			
			if (arSrc > arDest) { 
				sca = hDest / hSrc;
				offX = ((wSrc * sca) - wDest) / -2;
			}
			else {
				sca = wDest / wSrc;
				offY = ((hSrc * sca) - hDest) / -2;
			}
			
			var m:Matrix = new Matrix();
			m.scale(sca,sca);
			m.tx = offX;
			m.ty = offY;
			b.draw($bitmap, m, null,null,null, true);
			
			return b;
		}		
		
		public static function makeBitmapRotated180($bd:BitmapData):BitmapData
		{
			var m:Matrix = new Matrix();
			m.rotate(Math.PI);
			m.translate($bd.width, $bd.height);
			
			var bd:BitmapData = new BitmapData($bd.width, $bd.height, $bd.transparent, 0x0);
			bd.draw($bd, m);
			return bd;
		}
		
		public static function makeBitmapRotated90Right($bd:BitmapData):BitmapData
		{
			var m:Matrix = new Matrix();
			m.rotate(+Math.PI/2);
			m.translate($bd.height, 0);
			
			var bd:BitmapData = new BitmapData($bd.height, $bd.width, $bd.transparent, 0x0);
			bd.draw($bd, m);
			return bd;
		}
		
		public static function makeBitmapRotated90Left($bd:BitmapData):BitmapData
		{
			var m:Matrix = new Matrix();
			m.rotate(-Math.PI/2);
			m.translate(0, +$bd.width);
			
			var bd:BitmapData = new BitmapData($bd.height, $bd.width, $bd.transparent, 0x0);
			bd.draw($bd, m);
			return bd;
		}

		public static function makeBitmapDataGrayScale($bd:BitmapData):void
		{
			$bd.applyFilter( $bd, new Rectangle( 0,0,$bd.width,$bd.height ), new Point(0,0), grayScaleFilter() )
		}
		
		public static function addGrayScaleFilter($o:DisplayObject):void
		{
			$o.filters = [ grayScaleFilter() ];
		}
		
		public static function grayScaleFilter():ColorMatrixFilter
		{
			/*
			OLD
				var cmat:Array = [
					0.3, 0.59, 0.11, 0, 0,
					0.3, 0.59, 0.11, 0, 0,
					0.3, 0.59, 0.11, 0, 0,
					0, 0, 0, 1, 0];
			*/
			
			var rLum : Number = 0.2225;
			var gLum : Number = 0.7169;
			var bLum : Number = 0.0606; 
			
			var matrix:Array = [ 
				rLum, gLum, bLum, 0, 0,
				rLum, gLum, bLum, 0, 0,
				rLum, gLum, bLum, 0, 0,
				0,    0,    0,    1, 0 ];
			
			var filter:ColorMatrixFilter = new ColorMatrixFilter(matrix);
			return filter;
		}
		
		public static function bitmapDataToJpeg($b:BitmapData, $quality:int):ByteArray
		{
			var j:JPEGEncoder = new JPEGEncoder($quality);
			return j.encode($b);
		}
		
		public static function makeCrossHatchBitmapData($color1:uint=0xffffffff, $color2:uint=0xff000000):BitmapData
		{
			var b:BitmapData = new BitmapData(2,2,true,0x0);
			b.setPixel32(0,0, $color1);
			b.setPixel32(1,1, $color1);
			b.setPixel32(0,1, $color2);
			b.setPixel32(1,0, $color2);
			return b;
		}
		
		public static function makeCrossHatchRect($width:Number, $height:Number, $color1:uint=0xffffffff, $color2:uint=0xff000000):Sprite
		{
			var b:BitmapData = makeCrossHatchBitmapData($color1,$color2);
			
			var s:Sprite = new Sprite();
			s.graphics.beginBitmapFill(b, null, true, false);
			s.graphics.drawRect(0,0,$width,$height);
			s.graphics.endFill();
			
			return s;
		}
		
		public static function replaceCrossHatchRect($sprite:Sprite, $width:Number, $height:Number, $color1:uint=0xffffffff, $color2:uint=0xff000000):void
		{
			var b:BitmapData = makeCrossHatchBitmapData($color1,$color2);
			
			$sprite.graphics.clear();
			$sprite.graphics.beginBitmapFill(b, null, true, false);
			$sprite.graphics.drawRect(0,0,$width,$height);
			$sprite.graphics.endFill();
		}
		
		//
		// Rectangle tricks
		//
		
		public static function centerInParent($d:DisplayObject, $mathRound:Boolean=false):void
		{
			$d.x = ($d.parent.width - $d.width) * .5;
			$d.y = ($d.parent.height - $d.height) * .5;
			
			if ($mathRound) {
				$d.x = Math.round($d.x);
				$d.y = Math.round($d.y);
			}
		}
		public static function centerHorizontallyInParent($d:DisplayObject, $mathRound:Boolean=false):void
		{
			$d.x = ($d.parent.width - $d.width) * .5;
			
			if ($mathRound) {
				$d.x = Math.round($d.x);
			}
		}
		
		public static function centerInRect($d:DisplayObject, $r:Rectangle, $mathFloor:Boolean=false):void
		{
			$d.x = $r.x + ($r.width - $d.width) / 2;
			$d.y = $r.y + ($r.height - $d.height) / 2;
			
			if ($mathFloor) {
				$d.x = Math.floor($d.x);
				$d.y = Math.floor($d.y);
			}
		}
		
		/**
		 * Scales and positions object to fit in rectangle  
		 */
		public static function fitInRect($d:DisplayObject, $r:Rectangle, $fillInRectInstead:Boolean=false):void
		{
			// xxx refactor with "rectFit" below
			
			var offx:Number = 0;
			var offy:Number = 0;
			
			var isTaller:Boolean = $r.width/$r.height > $d.width/$d.height;
			
			if ((isTaller && ! $fillInRectInstead) || (! isTaller && $fillInRectInstead)) {
				$d.height = $r.height;
				$d.scaleX = $d.scaleY;
				offx = ($r.width - $d.width) / 2;
			}
			else {
				$d.width = $r.width;
				$d.scaleY = $d.scaleX;
				offy = ($r.height - $d.height) / 2;
			}
			$d.x = $r.x + offx;
			$d.y = $r.y + offy;
		}
		
		/**
		 * An API-independent method for fitting one rectangle into another.
		 * Useful for, eg, a Video object, whose 'internal' dimensions are always 320x240 or whatever
		 */
		public static function getFittedRect($srcWidth:Number, $srcHeight:Number, $destWidth:Number, $destHeight:Number):Rectangle
		{
			var result:Rectangle = new Rectangle();
			
			var isDestWider:Boolean = $destWidth/$destHeight > $srcWidth/$srcHeight;
			var scale:Number;
			
			if (isDestWider) {
				result.height = $destHeight;
				scale = $destHeight / $srcHeight;
				result.width = $srcWidth * scale;
				result.y = 0;
				result.x = ($destWidth - result.width) * .5;
			}
			else {
				result.width = $destWidth;
				scale = $destWidth / $srcWidth;
				result.height = $srcHeight * scale;
				result.x = 0;
				result.y = ($destHeight - result.height) * .5;
			}
			
			return result;
		}
		
		public static function applyRectangleToDisplayObject($d:DisplayObject, $r:Rectangle):void
		{
			$d.x = $r.x;
			$d.y = $r.y;
			$d.width = $r.width;
			$d.height = $r.height;
		}
		
		public static function getRectangleOfDisplayObject($d:DisplayObject):Rectangle
		{
			return new Rectangle($d.x, $d.y, $d.width, $d.height);
		}
		
		/**
		 * 
		 * @param $old			The original object
		 * @param $new			The object to take its place
		 * @param $placement	"position" - Position new based on old
		 * 						"resize" - Position and resize new based on old
		 * 						"center" - Center new based on old
		 * @return 				Bounding box of original object
		 */		
		public static function swap($old:DisplayObject, $new:DisplayObject, $placement:String="position"):Rectangle
		{
			var parent:DisplayObjectContainer = $old.parent;
			var index:int = parent.getChildIndex($old);
			parent.addChildAt($new, index);
			
			switch ($placement)
			{
				case "resize":
					$new.x = $old.x;
					$new.y = $old.y;
					$new.width = $old.width;
					$new.height = $old.height;
					break;
				
				case "center":
					$new.x = $old.x + ($old.width - $new.width) / 2; // note no Math.floor()
					$new.y = $old.y + ($old.height - $new.height) / 2;
					break;
				
				case "position":
				default:
					$new.x = $old.x;
					$new.y = $old.y;
					break;
			}
			
			return removeAndGetRect($old);
		}
		
		// Being used for FPO objects coming from Flash assets
		//
		public static function removeAndGetRect($old:DisplayObject):Rectangle
		{
			$old.parent.removeChild($old);
			return new Rectangle($old.x, $old.y, $old.width, $old.height);
		}


		/*
		//
		// Appropriates the object that's passed in.
		// Object is expected to be already parented, 
		// and new Sprite swaps itself for it, in situ. 
		//
		public static function gradientifyAndSwap($object:DisplayObject, $colorTop:uint, $colorBottom:uint):Sprite
		{
			var parent:DisplayObjectContainer = $object.parent;
			var index:int = parent.getChildIndex($object); 
			var s:Sprite = new Sprite();
			s.x = $object.x;
			s.y = $object.y;
			$object.x = 0;
			$object.y = 0;
			s.addChild($object);
			parent.addChildAt(s, index);
			
			//
			
			s.mask = $object;
			s.graphics.beginGradientFill(GradientTextSprite ... ???
			s.graphics.drawRect(0,0, $object.width, $object.height);
			s.graphics.endFill();
				
			return s;
		}
		*/
	}
}
