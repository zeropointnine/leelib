package leelib.util
{
	import flash.display.DisplayObject;
	import flash.external.ExternalInterface;
	import flash.geom.Point;
	import flash.system.Capabilities;
	import flash.utils.Dictionary;
	
	public class Util
	{
		public static function isValidEmail($s:String):Boolean
		{
		    var emailExpression:RegExp = /^[a-z][\w.-]+@\w[\w.-]+\.[\w.-]*[a-z][a-z]$/i;
		    return emailExpression.test($s);
		}
		
		public static function localToLocal(from:DisplayObject, to:DisplayObject):Point 
		{
			return to.globalToLocal(from.localToGlobal(new Point()));
		}
		
		public static function sequencer($a:Array):void
		{
			var fn:Function = $a.shift();

			if (fn == null && $a.length > 0) { trace('Util.sequencer() - WARNING: Function is null. Terminating sequence.', $a.length); return; }
			if (fn == null && $a.length == 0) return; // (ignore, we're done anyway);

			var cb:Function = function():void { sequencer($a); };

			if ($a.length > 0)
				fn( cb );
			else {
				fn(); 
			}
		}

		public static function randomArraySort(_array:Array):Array 
		{
			var _length:Number = _array.length;
			var mixed:Array = _array.slice();
			var rn:Number;
			var it:Number;
			var el:Object;

			for (it = 0; it<_length; it++) {
				el = mixed[it];
				rn = Math.floor(Math.random() * _length);
				mixed[it] = mixed[rn];
				mixed[rn] = el;
			}

			return mixed;
		}
		public static function randomVectorSort(_vector:Vector):Vector 
		{
			var _length:Number = _vector.length;
			var mixed:Vector = _vector.slice();
			var rn:Number;
			var it:Number;
			var el:Object;
			
			for (it = 0; it<_length; it++) {
				el = mixed[it];
				rn = Math.floor(Math.random() * _length);
				mixed[it] = mixed[rn];
				mixed[rn] = el;
			}
			
			return mixed;
		}
		
		public static function get isRunningLocally():Boolean
		{
			if (flash.system.Capabilities.playerType == "StandAlone") return true;

			var s:String = ExternalInterface.call("window.location.href.toString");
			if (s.indexOf("file:///") == 0) return true;
			
			return false;
		}
		
		public static function get isRunningStandalone():Boolean
		{
			return (flash.system.Capabilities.playerType == "StandAlone");
		}

		public static function get isAirApp():Boolean
		{
			return (flash.system.Capabilities.playerType == "Desktop");
		}
		
		public static function get isLocalHost():Boolean
		{
			if (! ExternalInterface.available) return undefined;
			var s:String = ExternalInterface.call("window.location.href.toString"); 
			return s.indexOf("localhost") > -1;
		}
		
		public static function printObject($o:Object, $prefix:String=""):void
		{
			for (var key:String in $o)
			{
				if ($o[key] is Object)
				{
					printObject($o[key], $prefix + "|" + key);
				}
				else
				{
					trace($prefix+": " + $o[key]);
				}
			}
		}
		
		public static function arrayOfObjectKeys($o:Object):Array
		{
			var a:Array = [];
			for (var key:String in $o) {
				a.push(key);
			}
			return a;
		}

		public static function arrayOfDictionaryKeys($d:Dictionary):Array
		{
			var a:Array = [];
			for (var key:String in $d) {
				a.push(key);
			}
			return a;
		}
		
	}
}