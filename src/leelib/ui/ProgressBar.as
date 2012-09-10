package leelib.ui
{
	import flash.display.Sprite;

	// very much nothing
	
	public class ProgressBar extends Component
	{
		private var _bg:Sprite;
		private var _bar:Sprite;
		
		private var _value:Number;
		
		
		public function ProgressBar($bg:Sprite, $bar:Sprite)
		{
			_bg = $bg;
			this.addChild(_bg);
			_bar = $bar;
			this.addChild(_bar);
			
			value = 0;
		}
		
		public override function setSize($width:Number, $height:Number, $dontSizeYet:Boolean=false):void
		{
			_sizeWidth = $width;
			_sizeHeight = $height;

			_bg.width = _sizeWidth;
			_bg.height = _sizeHeight;
			
			_bar.height = _sizeHeight;
			
			size();
		}
		
		public override function size():void
		{
			_bar.width = _value * _sizeWidth;
		}
		
		public function get value():Number
		{
			return _value;
		}
		
		public function set value($n:Number):void
		{
			if ($n > 1) $n = 1;
			_value = $n;
			size();
		}
	}
}