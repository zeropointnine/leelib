package leelibExamples.flvEncoder.webcam.uiEtc
{
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	
	public class CheckBox extends Sprite
	{
		private var _sprBg:Sprite;
		private var _sprOn:Sprite;
		private var _isOn:Boolean;
		
		
		public function CheckBox($text:String, $bold:Boolean, $italic:Boolean)
		{
			_sprBg = new Sprite();
			_sprBg.graphics.beginFill(0xffffff);
			_sprBg.graphics.lineStyle(1, 0x0);
			_sprBg.graphics.drawRect(4,4,12,12);
			_sprBg.graphics.endFill();
			this.addChild(_sprBg);
			
			_sprOn = new Sprite();
			_sprOn.graphics.beginFill(0x0);
			_sprOn.graphics.lineStyle(1, 0x0);
			_sprOn.graphics.drawRect(6,6,8,8);
			_sprOn.graphics.endFill();
			_sprBg.addChild(_sprOn);

			var tf:TextField = new TextField();
			with (tf)
			{
				defaultTextFormat = new TextFormat("_sans", 10, 0x0, $bold, $italic,null,null,null,"center");
				width = 80;
				height = 18;
				autoSize = TextFieldAutoSize.LEFT;
				selectable = mouseEnabled = false;
				x = this.width + 5;
				y = 2;
				text = $text;
			}
			this.addChild(tf);
			
			this.addEventListener(MouseEvent.ROLL_OVER, onOver);
			this.addEventListener(MouseEvent.ROLL_OUT, onOut);
			this.buttonMode = true;
			
			on = false;
		}
		
		public function set enabled($b:Boolean):void
		{
			this.mouseEnabled = this.mouseChildren = $b;
		}
		
		
		public function get on():Boolean
		{
			return _isOn;
		}
		public function set on($b:Boolean):void
		{
			_isOn = $b;
			_sprOn.visible = _isOn;
		}		
		
		private function onOver(e:*):void
		{
			_sprBg.alpha = 0.66;
		}
		private function onOut(e:*):void
		{
			_sprBg.alpha = 1.0;
		}
	}
}