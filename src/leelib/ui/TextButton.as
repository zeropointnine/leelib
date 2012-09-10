package leelib.ui
{
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	
	import leelib.util.TextFieldUtil;
	
	public class TextButton extends Button
	{
		protected var _tf:TextField;
		protected var _hit:Sprite;
		
		protected var _overStyle:String;
		protected var _offStyle:String;
		protected var _onStyle:String;
		
		
		public function TextButton($text:String, $offStyle:String, $overStyle:String, $onStyle:String=null)
		{
			if (!$onStyle) $onStyle = $overStyle;

			_offStyle = $offStyle;
			_overStyle = $overStyle;
			_onStyle = $onStyle;
			
			_tf = TextFieldUtil.makeText($text, $offStyle);
			this.addChild(_tf);
			
			_hit = new Sprite();
			_hit.graphics.beginFill(0xff0000, 0);
			_hit.graphics.drawRect(0,0,_tf.width,_tf.height);
			_hit.graphics.endFill();
			this.addChild(_hit);

			selected = false;
			enabled = true;
		}
		
		public function get textField():TextField
		{
			return _tf;
		}
		
		public override function set enabled($b:Boolean):void
		{
			// .. using _hit for mouseevents instead of 'this'
			
			_enabled = $b;
			
			if (_enabled)
			{
				
				_hit.addEventListener(MouseEvent.ROLL_OUT, onRollOut);
				_hit.addEventListener(MouseEvent.CLICK, onClick);
				_hit.buttonMode = true;
			}
			else
			{
				
				_hit.removeEventListener(MouseEvent.ROLL_OUT, onRollOut);
				_hit.removeEventListener(MouseEvent.CLICK, onClick);
				_hit.buttonMode = false;
			}
			
			selected = _selected; // updates view
		}
		
		protected override function showOver():void
		{
			TextFieldUtil.applyAndMakeDefaultStyle(_tf, _overStyle);
		}
		
		protected override function showOff():void
		{
			TextFieldUtil.applyAndMakeDefaultStyle(_tf, _offStyle);
		}
		
		protected override function showOn():void
		{
			TextFieldUtil.applyAndMakeDefaultStyle(_tf, _onStyle);
		}
	}
}