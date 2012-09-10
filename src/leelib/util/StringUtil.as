package leelib.util
{
	import flash.utils.ByteArray;
	import flash.utils.getQualifiedClassName;
	
	import leelib.appropriated.Guid;
	import leelib.util.Out;


	// grab bag, meh
	//
	public class StringUtil
	{
		public function StringUtil()
		{
		}
		
		public static function makeIpsum($minLength:int, $maxLength:int):String
		{
			var s:String = 	"Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore " + 
							"et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip " + 
							"ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu " + 
							"fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt " + 
							"mollit anim id est laborum.";

			var len:int = $minLength  +  Math.round(Math.random() * ($maxLength - $minLength));
			var start:int = Math.random() * (s.length - len);
			
			// start with first letter of a word:
			while (s.substr(start-1,1) != " " && s.substr(start-1,1) != "," && s.substr(start-1,1) != "." && start > 0) {
				start--;
			}
			
			// capitalize 
			s = s.substr(start, len);
			s = s.substr(0,1).toUpperCase() + s.substr(1);
			
			// trim end
			s = trimBack(s, " ");
			s = trimBack(s, ",");
			s = trimBack(s, " ");
			s = trimBack(s, ",");
			
			return s;
		}
		
		public static function isValidEmail(address:String):Boolean
		{			
			return RegExp(/^[_a-zA-Z0-9-]+(\.[_a-zA-Z0-9-]+)*@[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)*\.(([0-9]{1,3})|([a-zA-Z]{2,3})|(aero|coop|info|museum|name))$/).exec(address);
		}
		
		public static function trim(str:String, char:String=" "):String {
			return trimBack(trimFront(str, char), char);
		}
		
		public static function trimFront(str:String, char:String):String {
			char = stringToCharacter(char);
			if (str.charAt(0) == char) {
				str = trimFront(str.substring(1), char);
			}
			return str;
		}
		
		public static function trimBack(str:String, char:String):String {
			char = stringToCharacter(char);
			if (str.charAt(str.length - 1) == char) {
				str = trimBack(str.substring(0, str.length - 1), char);
			}
			return str;
		}

		private static function stringToCharacter(str:String):String {
			if (str.length == 1) {
				return str;
			}
			return str.slice(0, 1);
		}

		/**
		 * Formats seconds value like this: #:## or ##:##
		 */
		public static function secondsToString($seconds:Number, $padMinutes:Boolean=false):String
		{
			$seconds = Math.floor($seconds);
			var min:String = int($seconds / 60).toString();
			if ($padMinutes && min.length == 1) min = "0" + min;
			var sec:String = ($seconds % 60).toString();
			if (sec.length == 1) sec = "0" + sec;
			return min + ":" + sec;
			
		}

		// meh
		public static function millisecondsToString($ms:int):String
		{
			var sec:int = int($ms / 1000);
			var min:int = int(sec / 60);
			sec = sec % 60;
			
			var s:String = min.toString() + ":";
			s += (sec <= 9) ? ("0" + sec.toString()) : sec.toString();
			return s;
		}
		
		public static function oneDecimalPlace($n:Number):String
		{
			$n = int($n * 10) / 10;
			if ($n == int($n)) 
				return $n.toString() + ".0";
			else
				return $n.toString();
		}
		
		public static function twoDecimalPlaces($n:Number):String
		{
			$n = int($n * 100) / 100;
			if ($n == int($n)) 
				return $n.toString() + ".00";
			else if ($n * 10 == int($n * 10))
				return $n.toString() + "0"; 
			else
				return $n.toString();
		}
        
        public static function isUuid($s:String):Boolean
        {
        	var re:RegExp = new RegExp("^(\{{0,1}([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}\}{0,1})$");
			var o:Object = re.exec($s);
            return Boolean(o);
        }
		
		public static function makeGuid():String
		{
			return Guid.create();
		}
		
		public static function printByteArray($b:ByteArray):void
		{
			var s:String = "";
			$b.position = 0;
			
			for (var i:int = 0; i < $b.length; i++) 
			{
				s += formattedByte($b.readUnsignedByte()) + " "
				if (i % 16 == 15) {
					Out.i(s);
					s = "";
				}
			}
			Out.i(s);
			$b.position = 0;
		}
		
		private static function formattedByte($i:int):String
		{
			var s:String = $i.toString();
			if (s.length == 1) return "00"+s;
			if (s.length == 2) return "0"+s;
			return s;
		}
		
		public static function responderObjectToString($o:Object):String
		{
			return "[lv] " + $o.level + " [code] " + $o.code + " [desc] " + $o.description;
		}
		
		public static function getClassName($o:Object):String
		{
			var s:String= getQualifiedClassName($o);
			var i:int = s.indexOf("::");
			if (i > -1) s = s.substr(i+2);
			return s;
		}
		
		// Not fully tested
		// URL-decode, etc?
		public static function getQueryStringObject($url:String):Object
		{
			var qs:String = $url.substring($url.indexOf("?")+1);
			
			var a:Array = qs.split("&");
			var o:Object = {};
			for (var i:int = 0; i < a.length; i++)
			{
				var s:String = a[i];
				var idxEq:int = s.indexOf("=");
				if (idxEq < 1 || idxEq + 1 >= s.length) {
					Out.i("StringUtil.getQueryStringObject() - skipping malformed element -", s);
					continue;
				}
				var key:String = s.substr(0, idxEq);
				var val:String = s.substr(idxEq+1);
				o[key] = val;
			}
			return o
		}
	}
}