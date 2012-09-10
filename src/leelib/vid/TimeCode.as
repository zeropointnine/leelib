package leelib.vid
{
	import flash.display.Sprite;
	import flash.text.TextField;
	
	import leelib.util.StringUtil;

	
	public class TimeCode extends Sprite
	{
		private var _tf:TextField;
		private var _duration:Number;
		private var _seconds:Number;
		private var _delimiter:String = "/";
		private var _text:String;
		private var _textWas:String;
		
		
		public function TimeCode($textField:TextField)
		{
			_tf = $textField;
			this.addChild(_tf);
		}
		
		public function set duration($seconds:Number):void
		{
			_duration = $seconds;
			update();
		}
		
		public function set time($seconds:Number):void
		{
			_seconds = $seconds;
			update();
		}
		
		public function set delimiter($s:String):void
		{
			_delimiter = $s;
			update();
		}
		
		private function update():void
		{
			var sec:String = StringUtil.secondsToString(_seconds, true);
			var dur:String = StringUtil.secondsToString(_duration, true);
			_textWas = _text;
			_text = sec + _delimiter + dur;

			if (_text != _textWas) _tf.text = _text;
		}
	}
}
