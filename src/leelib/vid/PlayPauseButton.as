package leelib.vid
{
	import flash.display.Bitmap;
	import flash.events.Event;
	
	import leelib.ui.Button;
	
	public class PlayPauseButton extends Button
	{
		public static const EVENT_DOPLAY:String = "ppb.eventDoPlay";
		public static const EVENT_DOPAUSE:String = "ppb.eventDoPause";
		
		private var _play:Bitmap;
		private var _pause:Bitmap;
		
		public function PlayPauseButton($playIcon:Bitmap, $pauseIcon:Bitmap)
		{
			_play = $playIcon;
			this.addChild(_play);
			
			_pause = $pauseIcon;
			this.addChild(_pause);
			
			showPauseIcon();
		}
		
		public function showPlayIcon():void
		{
			_play.alpha = 1;
			_pause.alpha = 0;
		}
		public function showPauseIcon():void
		{
			_pause.alpha = 1;
			_play.alpha = 0;
		}
		
		protected override function onClick(e:*):void
		{
			var type:String = (_play.alpha != 1) ? EVENT_DOPAUSE : EVENT_DOPLAY;
			this.dispatchEvent(new Event(type));
		}
	}
}