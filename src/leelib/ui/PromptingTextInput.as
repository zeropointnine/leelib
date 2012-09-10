package leelib.ui
{
	import flash.display.*;
	import flash.events.*;
	import flash.text.*;
	
	public class PromptingTextInput extends Sprite
	{
		public var _tf:TextField;
		private var _normalFormat:TextFormat;
		private var _promptFormat:TextFormat;

		private var _prompt:String;
		private var _text:String;
		
		private var _enabled:Boolean;
		
		/**
		 * NOT FINISHED.
		 * 
		 * Reparents $textField.
		 * If value of text is _prompt, returns "".
		 */
		public function PromptingTextInput($textField:TextField, $normalFormat:TextFormat=null, $promptFormat:TextFormat=null)
		{
			_tf = $textField;
			this.addChild(_tf);
			_text = _tf.text;
			
			_normalFormat = $normalFormat || _tf.defaultTextFormat;
			_promptFormat = $promptFormat || _normalFormat;
			
			enabled = true;
			update();
		}
		
		public function get enabled():Boolean
		{
			return _enabled;
		}
		
		public function set enabled($b:Boolean):void
		{
			_enabled = $b;
			
			if (_enabled) {
				_tf.addEventListener(FocusEvent.FOCUS_IN, onFocusIn);
				_tf.addEventListener(FocusEvent.FOCUS_OUT, onFocusOut);
			}
			else {
				_tf.addEventListener(FocusEvent.FOCUS_IN, onFocusIn);
				_tf.addEventListener(FocusEvent.FOCUS_OUT, onFocusOut);
			}
		}
		
		public function get text():String
		{
			return _text;
		}
		
		public function set text($s:String):void
		{
			_text = $s;
			if (_text == _prompt) {
				_text = "";
			}
			
			update();
		}
		
		private function update():void
		{
			var f:TextFormat = (_text == "") ? _promptFormat : _normalFormat;
			var s:String = (_text == "") ? _prompt : _text;
			
			_tf.text = s;
			_tf.setTextFormat(f);
		}
		
		private function onFocusIn(e:FocusEvent):void
		{
			if (_text == "") {
				_tf.text = "";
			}
		}
		
		private function onFocusOut(e:FocusEvent):void
		{
			if (_text == "") {
				text = _tf.text;
			}
		}
		

	}
}