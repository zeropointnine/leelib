package leelibExamples.flvEncoder.webcam.uiEtc
{
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	public class RecordButton extends Sprite
	{
		private var _tf:TextField;
		
		
		public function RecordButton()
		{
			this.graphics.beginFill(0xffffff);
			this.graphics.lineStyle(1, 0x0);
			this.graphics.drawRect(0,0,100,20);
			this.graphics.endFill();
			
			_tf = new TextField();
			with (_tf)
			{
				defaultTextFormat = new TextFormat("_sans", 12, 0x0, true, null,null,null,null,"center");
				width = 100;
				height = 18;
				selectable = mouseEnabled = false;
				x = 0;
				y = 0;
			}
			this.addChild(_tf);
			
			this.addEventListener(MouseEvent.ROLL_OVER, onOver);
			this.addEventListener(MouseEvent.ROLL_OUT, onOut);
			this.buttonMode = true;
			
			showRecord();
		}
		
		public function showRecord():void
		{
			_tf.text = "record";
		}
		
		public function showStop():void
		{
			_tf.text = "stop";
		}
		
		private function onOver(e:*):void
		{
			this.alpha = 0.66;
		}
		private function onOut(e:*):void
		{
			this.alpha = 1.0;
		}
	}
}