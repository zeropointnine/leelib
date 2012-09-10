package leelib.ui
{
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;
	
	import leelib.util.TextFieldUtil;
	
	public class FormInput extends Component
	{
		public static const HEIGHT:Number = 31;
		private var _bg:Sprite;
		private var _bgError:Sprite;
		private var _label:TextField;
		private var _input:TextField;
		private var _bgColor:uint = 0xffffff;
		private var _outlineColor:uint = 0xdddddd;
		private var _errorColor:uint = 0xff0000;
		
		private var _isError:Boolean;
		
		
		public function FormInput($width:Number, $label:String, $labelStyle:String, $inputStyle:String, $maxChars:int)
		{
			_sizeWidth = $width;
			_sizeHeight = HEIGHT;
			
			_label = TextFieldUtil.makeText($label, $labelStyle);
			this.addChild(_label);
			
			_bg = new Sprite();
			_bg.graphics.lineStyle(1, _outlineColor);
			_bg.graphics.beginFill(_bgColor);
			_bg.graphics.drawRect(0,0, _sizeWidth, _sizeHeight);
			_bg.graphics.endFill();
			_bg.y = _label.textHeight + 5;
			this.addChild(_bg);
			
			_bgError = new Sprite();
			_bgError.graphics.lineStyle(1, _errorColor);
			_bgError.graphics.drawRect(0,0, _sizeWidth, _sizeHeight);
			_bgError.y = _label.textHeight + 5;
			this.addChild(_bgError);
			
			_input = TextFieldUtil.makeInput("", $width - 10, $inputStyle, $maxChars);
			_input.x = 5;
			_input.y = _bg.y + 6;
			this.addChild(_input);
			
			isError = false;
		}
		
		public function get background():Sprite
		{
			return _bg;
		}
		
		public function get label():TextField
		{
			return _label;
		}
		public function get textInput():TextField
		{
			return _input;
		}
		
		public function set isError($b:Boolean):void
		{
			_isError = $b;
			_bgError.visible = _isError;
		}
		
		public function get isError():Boolean
		{
			return _isError;
		}
	}
}