package leelib.util
{
	import flash.utils.getTimer;
	
	public class Out
	{
		public static const SHOW_VERBOSE:uint = 5;
		public static const SHOW_DEBUG:uint = 4;
		public static const SHOW_INFO:uint = 3;
		public static const SHOW_WARNING:uint = 2;
		public static const SHOW_ERROR:uint = 1;
		public static const SHOW_NONE:uint = 0;
		
		public static const TIMESTAMPFORMAT_NONE:uint = 0;
		public static const TIMESTAMPFORMAT_DATE:uint = 1;
		public static const TIMESTAMPFORMAT_GETTIMER:uint = 2;

		public static var externalPrinter:IOutPrint;
		
		private static var _level:uint = SHOW_VERBOSE;
		private static var _timeStampFormat:uint = TIMESTAMPFORMAT_GETTIMER;
		
		
		public static function get level():uint
		{
			return _level;
		}
		public static function set level($u:uint):void
		{
			_level = $u;
			
			var a:Array = ['NONE', 'ERROR', 'WARNING', 'INFO', 'DEBUG', 'VERBOSE (ALL)'];
			trace('[Out level set to: ' + a[_level] + ']');
		}
		
		
		public static function get timeStampType():uint
		{
			return _timeStampFormat;
		}
		public static function set timeStampType($u:uint):void
		{
			_timeStampFormat = $u;
		}
		

		public static function v(...$rest):void
		{
			if (_level >= SHOW_VERBOSE) { 
				print2("[v" + timeStamp() + "]", $rest);
			}
		}

		public static function d(...$rest):void
		{
			if (_level >= SHOW_DEBUG) { 
				print2("[d" + timeStamp() + "]", $rest);
			}
		}
		
		public static function i(...$rest):void
		{
			if (_level >= SHOW_INFO) {
				print2("[i" + timeStamp() + "]", $rest);
			}
		}
		
		public static function w(...$rest):void
		{
			if (_level >= SHOW_WARNING) { 
				print2("[WARNING" + timeStamp() + "]", $rest);
			}
		}
		
		public static function e(...$rest):void
		{
			if (_level >= SHOW_ERROR) {
				print2("[ERROR ***" + timeStamp() + "]", $rest);
			}
		}
		
		private static function timeStamp():String
		{
			switch (_timeStampFormat)
			{
				case TIMESTAMPFORMAT_NONE:
					return "";
				case TIMESTAMPFORMAT_DATE:
					return " " + new Date().toString();
				case TIMESTAMPFORMAT_GETTIMER:
					return " " + (getTimer()/1000).toString();
			}
			return "";
		}
		
		private static function print($prefix:String, ... $rest):void
		{
			var string:String = $prefix + " ";
			
			if ($rest && $rest[0])
			{
				for each (var o:Object in $rest[0])
				{
					if (o != null)
						string += o.toString() + " ";
					else
						string += "null" + " ";
				}
			}
			
			trace(string);
		}

		private static function print2($prefix:String, ... $rest):void
		{
			var string:String = $prefix + " ";
			
			if ($rest && $rest[0])
			{
				for each (var o:Object in $rest[0])
				{
					if (o != null)
						string += o.toString() + " ";
					else
						string += "null" + " ";
				}
			}
			
			trace(string);	
			if (externalPrinter) externalPrinter.print(string); 
		}
	}
}
