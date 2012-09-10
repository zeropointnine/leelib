package leelib.vid
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import leelib.ExtendedEvent;
	import leelib.ui.Component;
	import leelib.util.MathUtil;
	
	public class VidProgressBar extends Component
	{
		public static const EVENT_DRAGSTART:String = "VidProgressBar.eventDragStart";
		public static const EVENT_DRAGEND:String = "VidProgressBar.eventDragEnd";
		
		private var _bgBar:Component;
		private var _loadBar:Component;
		private var _playBar:Component;
		
		private var _loadProgress:Number = 0;
		private var _playProgress:Number = 0;
		private var _scrubbable:Boolean;
		
		/**
		 * Elements get reparented 
		 */		
		public function VidProgressBar($backgroundBar:Component, $loadProgressBar:Component, $playProgressBar:Component, $scrubbable:Boolean, $width:Number, $height:Number)
		{
			_bgBar = $backgroundBar;
			this.addChild(_bgBar);
			
			_loadBar = $loadProgressBar;
			this.addChild(_loadBar);
			
			_playBar = $playProgressBar;
			this.addChild(_playBar);

			_scrubbable = $scrubbable;
			if (_scrubbable) {
				this.buttonMode = true;
				this.addEventListener(MouseEvent.MOUSE_DOWN, onDown);
			}

			setSize($width, $height);
			
		}
		
		public function get loadProgress():Number
		{
			return _loadProgress;
		}
		public function set loadProgress($scalar:Number):void
		{
			_loadProgress = MathUtil.clamp($scalar, 0,1);
			sizeLoadBar();
		}
		
		public function get playProgress():Number
		{
			return _playProgress;
		}
		public function set playProgress($scalar:Number):void
		{
			_playProgress = MathUtil.clamp($scalar, 0,1);
			sizePlayBar();
		}
		
		public override function setSize($width:Number, $height:Number, $dontSizeYet:Boolean=false):void
		{
			_sizeWidth = $width;
			_sizeHeight = $height;

			_bgBar.setSize(_sizeWidth, _sizeHeight);

			if (!$dontSizeYet) size();
		}
		
		public override function size():void
		{
			sizeLoadBar();
			sizePlayBar();
		}
		
		private function sizeLoadBar():void
		{
			_loadBar.setSize(_sizeWidth * _loadProgress, _sizeHeight);
		}
		
		private function sizePlayBar():void
		{
			_playBar.setSize(_sizeWidth * _playProgress, _sizeHeight);
		}
		
		private function onDown(e:*):void
		{
			this.dispatchEvent(new Event(EVENT_DRAGSTART));

			onEf(null);
//			Global.getInstance().stage.addEventListener(Event.ENTER_FRAME, onEf);
//			Global.getInstance().stage.addEventListener(MouseEvent.MOUSE_UP, onUp);
//			Global.getInstance().stage.addEventListener(Event.MOUSE_LEAVE, onUp);
		}
		
		private function onEf(e:*):void
		{
			var n:Number = this.mouseX / _sizeWidth;
			n = MathUtil.clamp(n, 0,1);
			this.dispatchEvent(new ExtendedEvent(Event.CHANGE, n as Object));
		}
		
		private function onUp(e:*):void
		{
//			Global.getInstance().stage.removeEventListener(Event.ENTER_FRAME, onEf);
//			Global.getInstance().stage.removeEventListener(MouseEvent.MOUSE_UP, onUp);
//			Global.getInstance().stage.removeEventListener(Event.MOUSE_LEAVE, onUp);
			onEf(null);
			
			this.dispatchEvent(new Event(EVENT_DRAGEND));
		}
	}
}
