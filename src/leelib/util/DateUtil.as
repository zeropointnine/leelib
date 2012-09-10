package leelib.util
{
	/**
	 * Rem, int/uint too small to hold getTime() value, so use Number
	 */
	public class DateUtil
	{
		public static const MS_PER_HOUR:int	= 1000 * 60 * 60;
		public static const MS_PER_DAY:int 	= 1000 * 60 * 60 * 24; 
		
		public static const DAYS:Array = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"];
		public static const MONTHS:Array = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]; 
		public static const MONTHS_ABBR:Array = ["Jan.", "Feb.", "March", "Apr", "May", "June", "July", "Aug.", "Sept.", "Oct.", "Nov.", "Dec."]; 
	
		private static var _clientTimeDelta:int;
		
		
		/**
		 * General idea is to get a timestamp from the server, and keep client and server times 'synchronized'
		 * Call this function first, as soon as you get the timestamp from the server.
		 */
		public static function setSync($serverDateNow:Date):void
		{
			_clientTimeDelta = new Date().time - $serverDateNow.getTime();
		}
		
		/**
		 * The number of milliseconds the client time is off in relation to the server  
		 */		
		public static function get clientTimeDelta():int
		{
			return _clientTimeDelta;
		}
		public static function set clientTimeDelta($i:int):void // Normally you'd use 'setSync' 
		{
			_clientTimeDelta = $i;
		}

		public static function get currentServerTimeValue():Number
		{
			var n:Number = new Date().time;
			return n + _clientTimeDelta;
		}
		public static function get currentServerDate():Date
		{
			var d:Date = new Date();
			d.setTime( currentServerTimeValue );
			
			return d;
		}
		
		//

		// Could use tweaking
		public static function dateToNaturalString($serverDate:Date):String
		{
			var msAgo:Number = currentServerTimeValue - $serverDate.getTime();

			var sec:Number = Math.round(msAgo/1000);
			
			if (sec < 5) {
				return "Just now";
			}
			
			if (sec < 45) {
				return sec.toString() + " seconds ago";
			}
			
			var min:int = Math.round(sec / 60);
			
			if (min == 1) {
				return "1 minute ago"
			}
			
			if (min <= 90) {
				return min.toString() + " minutes ago";
			}
			
			var hr:int = Math.round(min/60);
			
			if (hr < 36) {
				return hr.toString() + " hours ago";
			}
			
			// At this point, use "Jan 1" or "Jan 1, 2000"
			// (Don't want to figure out the best logic for "X days ago")
			
			var s:String = "";
			
			s = MONTHS_ABBR[ $serverDate.getMonth() ] + " " + $serverDate.getDate(); 
			// if (currentServerDate.getFullYear() != $serverDate.getFullYear())
			s += ", " + $serverDate.getFullYear().toString(); 
			
			return s;
		}

		// "Monday"
		public static function getDayString($date:Date):String
		{
			var index:int = $date.dayUTC;
			return DateUtil.DAYS[index];
		}
		
		// "January 1, 2012"
		public static function getDateString($date:Date):String 
		{
			var month:String = DateUtil.MONTHS[$date.monthUTC];
			var s:String = month + " " + $date.dateUTC + ", " + $date.fullYearUTC;
			return s;
		}

		// "10:30AM"
		public static function getTimeString($date:Date):String
		{
			var h:int = $date.hoursUTC;
			var m:int = $date.minutesUTC;
			
			var sh:String;
			var ampm:String;
			if (h == 0) { 
				ampm = "AM";
				sh = "12";
			}
			else if (h < 12) {
				ampm = "AM";
				sh = h.toString();
			}
			else if (h == 12){
				ampm = "PM";
				sh = "12";
			}
			else {
				ampm = "PM";
				sh = (h-12).toString();
			}
			var sm:String = m.toString();
			if (sm.length == 1) sm = "0" + sm;
			
			return sh + ":" + sm + ampm; 
		}

		
		/**
		 * Expecting string like this: "2012-06-04 17:40:00Z" 
		 * Not fully tested.
		 * http://stackoverflow.com/questions/3163/actionscript-3-fastest-way-to-parse-yyyy-mm-dd-hhmmss-to-a-date-object
		 */
		public static function stringToDate(str:String, $isUtc:Boolean):Date 
		{
			var matches : Array = str.match(/(\d\d\d\d)-(\d\d)-(\d\d) (\d\d):(\d\d):(\d\d)Z/);
			
			var d : Date = new Date();

			if ($isUtc) {
				d.setUTCFullYear(int(matches[1]), int(matches[2]) - 1, int(matches[3]));
				d.setUTCHours(int(matches[4]), int(matches[5]), int(matches[6]), 0);
			}
			else {
				d.setFullYear(int(matches[1]), int(matches[2]) - 1, int(matches[3]));
				d.setHours(int(matches[4]), int(matches[5]), int(matches[6]), 0);
			}
			
			return d;
		}

		/**
		 * Not fully tested
		 * http://stackoverflow.com/questions/3163/actionscript-3-fastest-way-to-parse-yyyy-mm-dd-hhmmss-to-a-date-object 
		 */
		public static function dateToUtcString(date:Date, $isUtc:Boolean):String 
		{
			var tmp:Array = new Array();
			var char:String;
			var output:String = '';
			
			// create format YYMMDDhhmmssZ
			// ensure 2 digits are used for each format entry, so 0x00 suffuxed at each byte

			if ($isUtc)
			{
				tmp.push(date.secondsUTC);
				tmp.push(date.minutesUTC);
				tmp.push(date.hoursUTC);
				tmp.push(date.getUTCDate());
				tmp.push(date.getUTCMonth() + 1); // months 0-11
				tmp.push(date.getUTCFullYear() % 100);
			}
			else
			{
				tmp.push(date.seconds);
				tmp.push(date.minutes);
				tmp.push(date.hours);
				tmp.push(date.getDate());
				tmp.push(date.getMonth() + 1); // months 0-11
				tmp.push(date.getFullYear() % 100);
			}
			
			for(var i:int=0; i < 6/* 7 items pushed*/; ++i) {
				char = String(tmp.pop());
				trace("char: " + char);
				if(char.length < 2)
					output += "0";
				output += char;
			}
			
			output += 'Z';
			
			return output;
		}
	}
}
