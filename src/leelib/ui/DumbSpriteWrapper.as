package leelib.ui
{
	import flash.display.Sprite;

	public class DumbSpriteWrapper extends Component
	{
		private var _s:Sprite;

		
		public function DumbSpriteWrapper($s:Sprite)
		{
			_s = $s;
			this.addChild(_s);
		}
		
		public override function setSize($width:Number, $height:Number, $dontSizeYet:Boolean=false):void
		{
			_sizeWidth = $width;
			_sizeHeight = $height;

			_s.width = $width;
			_s.height = $height;
			
			if (!$dontSizeYet) size();
		}
	}
}
