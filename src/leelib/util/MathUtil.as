package leelib.util
{
	import flash.geom.Point;
	import flash.geom.Rectangle;

	public class MathUtil
	{
		public static var DEGREE:Number = Math.PI/180;


		public static function findClosestMultiple($value:Number, $multiple:Number):Number
		{
			var a:Number = Math.floor( $value / $multiple ) * $multiple;
			var b:Number = Math.ceil( $value / $multiple ) * $multiple;
			var dif1:Number = Math.abs($value - a);
			var dif2:Number = Math.abs($value - b);
			return (dif2 > dif1) ? a : b;
		}
		
		public static function lerp($normalizedValue:Number, $min:Number, $max:Number):Number
		{
			return $min + ($max - $min) * $normalizedValue;
		}
		public static function lerpClamped($normalizedValue:Number, $min:Number, $max:Number):Number
		{
			if ($normalizedValue < 0) $normalizedValue = 0;
			if ($normalizedValue > 1) $normalizedValue = 1;
			return lerp($normalizedValue, $min, $max);
		}
		
		public static function map($value:Number, $min1:Number, $max1:Number, $min2:Number, $max2:Number):Number
		{
			return lerp( normalize($value, $min1, $max1), $min2, $max2);
		}		
		
		public static function mapClamped($value:Number, $min1:Number, $max1:Number, $min2:Number, $max2:Number):Number
		{
			return lerpClamped( normalize($value, $min1, $max1), $min2, $max2);
		}		

		public static function normalize($value:Number, $min:Number, $max:Number):Number
		{
			return ($value - $min) / ($max - $min);
		}		
		
		public static function clamp($value:Number, $min:Number, $max:Number):Number
		{
			$value = Math.min($value, $max);
			$value = Math.max($value, $min);
			return $value;
		}
		
		public static function randomizeRadius($value:Number, $percentRadius:Number):Number
		{
			var pct:Number = 1  +  (Math.random() * $percentRadius - ($percentRadius/2));
			return $value * pct;
		}
		
		public static function distance(p1:Point, p2:Point):Number
		{
			return Math.sqrt( (p2.x-p1.x)*(p2.x-p1.x) + (p2.y-p1.y)*(p2.y-p1.y) ); 
		}

		public static function pointIsInRectangle($pt:Point, $rect:Rectangle):Boolean
		{
			return (
				$pt.x >= $rect.x && 
				$pt.x <= $rect.x + $rect.width && 
				$pt.y >= $rect.y && 
				$pt.y <= $rect.y + $rect.height
			);
		}
		
		/**
		 * Given a value between 0 and 1, and a number of steps within that range, 
		 * returns the two closest interval numbers, with a value that represents the 
		 * proportion/magnitude/ratio of each, where that value is determined by 
		 * the proximity of the original value to that interval number. !!
		 * 
		 * @param $n		A value between 0 and 1
		 * @param $steps	Defines the interval 
		 * @param $special	Special case, where 
		 * @return 			Object property "a" is an index value; 	property "a_magnitude" is a Number between 0 and 1.
		 * 					Object property "b"						property "b_magnitude"  
		 */
		public static function getRatios($n:Number, $steps:int, $special:Boolean=false):Object
		{
			var interval:Number = 1 / $steps; 
			
			var a:int;
			var b:int;
			var a_ratio:Number = 0;
			var b_ratio:Number = 0;
			
			if ($n <= interval/2)
			{
				a = 0;
				a_ratio = 1;
				b = -1; 
			}	
			else if ($n >= 1 - interval/2)
			{
				a = $steps-1;
				a_ratio = 1;
				b = -1;
			}
			else
			{
				a = int($n / interval);									
				b = ($n % interval <= interval/2) ? (a - 1) : (a + 1);
				
				var a_center:Number = a * interval + interval/2;
				var a_center_distance:Number = Math.abs($n - a_center); 
				a_ratio = 1 - (a_center_distance * $steps);
				var b_center:Number = b * interval + interval/2;
				var b_center_distance:Number = Math.abs($n - b_center); 
				b_ratio = 1 - (b_center_distance * $steps);
				
				if ($special)
				{
					// convert from linear to sine wave-based easeInOut curve
					var da:Number = (a_ratio * 180) - 90; // range -90 to 90;
					a_ratio = Math.sin(da*DEGREE); // -1 to 1;
					a_ratio = (a_ratio + 1) / 2; // 0 to 1
					
					var db:Number = (b_ratio * 180) - 90; // range -90 to 90;
					b_ratio = Math.sin(db*DEGREE); // -1 to 1;
					b_ratio = (b_ratio + 1) / 2; // 0 to 1
				}
			}
			
			trace(a, a_ratio, b, b_ratio);
			
			return { a:a, a_ratio:a_ratio, b:b, b_ratio:b_ratio}
			
			/*
			My original comments on this general relationship...
			
			$n - expected range 0 to 1
			
			0.0		0.33	0.66	1.0
			|-------|-------|-------|
			0		1		2	
			
			Three 'sectors', numbered 0 to 2.
			The closer a value is to the center of that sector, the greater the alpha for the associated video.
			The adjacent-most sector also gets an alpha value for its associated video.
			*/
		}
		
		public static function round($value:Number, $step:Number):Number
		{
			var a:Number = Math.floor($value/$step) * $step;
			var b:Number = Math.ceil($value/$step) * $step;
			var da:Number = Math.abs($value - a);
			var db:Number = Math.abs($value - b);
			if (da < db) 
				return a;
			else
				return b;
		}
		
		private function calcAngle(x:Number, y:Number) : Number
		{
			var originX:Number = 0;
			var originY:Number = 0;
			
			var adjside:Number = x - originX;
			var oppside:Number = -1 * (y - originY);
			
			var angle:Number = Math.atan2(oppside, adjside); // in radians
			angle = angle / Math.PI * 180; // convert to degrees
			
			// adjust for my specific need here:
			angle = -angle + 90; // (top == 0)
			if (angle < 0 && angle > 180< 0) angle += 360; // range -90 to 0 becomes 270 to ~360, for a whole range of 0 to ~360
			if (angle >180) angle -= 360 // range 180 to ~360 becomes ~180 to 0, for a whole range of -180 to +180
			return angle;
		}
	}
}
