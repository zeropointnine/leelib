package leelib.vid
{
	import flash.display.Bitmap;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.display.StageDisplayState;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.events.NetStatusEvent;
	import flash.geom.Rectangle;
	import flash.media.SoundTransform;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.text.TextField;
	import flash.utils.setInterval;
	import flash.utils.setTimeout;
	
	import leelib.ExtendedEvent;
	import leelib.graphics.GrUtil;
	import leelib.ui.Component;

	
	public class MinVid extends Component
	{
		public static const EVENT_POSITION:String = "Vid.eventPosition";
		public static const EVENT_STREAMNOTFOUND:String = "MinVid.eventStreamNotFound";
		
		public static const STATE_CLOSED:String = "closed";
		public static const STATE_BUFFERING:String = "buffering";
		public static const STATE_READY:String = "ready";
		public static const STATE_PLAYING:String = "playing";
		public static const STATE_PAUSED:String = "paused";
		public static const STATE_END:String = "complete";
		
		private var _video:Video;
		
		private var _ns:NetStream;
		private var _nc:NetConnection;
		
		private var _url:String;
		private var _vidDuration:Number;
		
		private var _videoNativeWidth:Number;
		private var _videoNativeHeight:Number;
		
		private var _bufferTime:Number = 3.0;
		private var _autoRepeat:Boolean;
		private var _autoStart:Boolean;
		private var _state:String;
		private var _volume:Number = 1;
		private var _isDragging:Boolean;
		
		// optional controls
		private var _progressBar:VidProgressBar;
		private var _volumeControl:VolumeControl;
		private var _timeCode:TimeCode;
		private var _playPauseButton:PlayPauseButton;
		
		
		public function MinVid()
		{
			_video = new Video();
			_video.smoothing = true;
			this.addChild(_video);
		}
		
		public function set progressBar($minVidProgressBar:VidProgressBar):void
		{
			_progressBar = $minVidProgressBar;
			_progressBar.addEventListener(Event.CHANGE, onVidProgressBarChange);
			_progressBar.addEventListener(VidProgressBar.EVENT_DRAGSTART, onVidProgressBarDragStart);
			_progressBar.addEventListener(VidProgressBar.EVENT_DRAGEND, onVidProgressBarDragEnd);
		}
		
		public function set playPauseButton($ppb:PlayPauseButton):void
		{
			_playPauseButton = $ppb;
			_playPauseButton.addEventListener(PlayPauseButton.EVENT_DOPAUSE, onButtonDoPause);
			_playPauseButton.addEventListener(PlayPauseButton.EVENT_DOPLAY, onButtonDoPlay);
		}

		public function set volumeControl($volumeControl:VolumeControl):void
		{
			_volumeControl = $volumeControl;
			_volumeControl.addEventListener(Event.CHANGE, onVolumeControlChange);
		}
		
		public function set timeCode($timeCode:TimeCode):void
		{
			_timeCode = $timeCode;
		}
		

		/**
		 * If no forcedWidth/Height supplied, will use video's native dimensions, scaled to sizeWidth/Height
		 */
		public function go($url:String, $forcedWidth:Number=NaN, $forcedHeight:Number=NaN, $autoStart:Boolean=true, $autoRepeat:Boolean=false):void
		{
			_url = $url;
			_autoStart = $autoStart;
			_autoRepeat = $autoRepeat;
			
			// reset stuff
			_vidDuration = NaN;
			_video.visible = false;
			_isDragging = false; // ?
			_sizeWidth = $forcedWidth || NaN;
			_sizeHeight = $forcedHeight || NaN;
			
			// connect video; announce 'loadcomplete' when buffer is sufficiently full
			if (! _ns) 
			{
				_nc = new NetConnection();
				_nc.addEventListener(NetStatusEvent.NET_STATUS, onNetStatus);
				_nc.connect(null);
				
				_ns = new NetStream(_nc);
				_ns.addEventListener(NetStatusEvent.NET_STATUS, onNetStatus); // yes this too
				_ns.client = new CustomClient(this);	            
				_ns.checkPolicyFile = true;
				_ns.bufferTime = _bufferTime;
				_video.attachNetStream(_ns);
				volume = _volume;
			}
			
			//
			
			this.addEventListener(Event.ENTER_FRAME, pollBufferLength)
			
			trace('MinVid.start() - url:', _url);
				
			_state = STATE_BUFFERING;

			_ns.play(_url);
			_ns.pause();
			
			if (_playPauseButton) _playPauseButton.showPauseIcon();
		}
		
		public function get volume():Number
		{
			return _volume;
		}
		public function set volume($n:Number):void
		{
			_volume = $n;
			if (_ns) _ns.soundTransform = new SoundTransform($n);
		}

		public function get netStream():NetStream
		{
			return _ns;
		}
		
		public function get bytesLoaded():Number
		{
			return _ns.bytesLoaded;
		}
		
		public function get videoNativeWidth():Number
		{
			return _videoNativeWidth;
		}
		public function get videoNativeHeight():Number
		{
			return _videoNativeHeight;
		}
		
		public function get video():Video
		{
			return _video;
		}
		
		public function get state():String
		{
			return _state;
		}
		
		private function pollBufferLength(e:*=null):void
		{
			// start condition
			if (_ns.bufferLength > _bufferTime)
			{
				this.removeEventListener(Event.ENTER_FRAME, pollBufferLength)

				_state = STATE_READY;
				
				this.dispatchEvent(new Event(Component.EVENT_LOADED));

				if (_autoStart) play();
			}
		}

		private function pollPosition(e:*):void
		{
			if (_timeCode) {
				_timeCode.time = _ns.time;
			}
			
			if (_progressBar) {
				_progressBar.playProgress = _ns.time / _vidDuration;
				_progressBar.loadProgress = _ns.bytesLoaded / _ns.bytesTotal;
			}
			
			// end condition:
			
			if (_state == STATE_END) return;
			if (_progressBar && _isDragging) return;
			
			if (_ns.time > _vidDuration - 0.1) {
				if (! _autoRepeat) {
					this.removeEventListener(Event.ENTER_FRAME, pollPosition);
					_state = STATE_END;
					_ns.pause();
					if (_playPauseButton) _playPauseButton.showPlayIcon();
					if (_progressBar) _progressBar.playProgress = 1;
					this.dispatchEvent(new Event(Event.COMPLETE));
				}
				else {
					play();
				}	
			}
		}

		public function play():void
		{
			if (!_nc) {
				throw new Error("Must invoke go() first");
			}
			
			if (_state == STATE_CLOSED) 
			{
				// ie, 're-play'
				trace('REPLAY');
				_nc.connect(null);
				_video.attachNetStream(_ns);
				_ns.play(_url);
			}
			else if (_state == STATE_BUFFERING) 
			{
				this.removeEventListener(Event.ENTER_FRAME, pollBufferLength)
			}

			_state = STATE_PLAYING;
			
			_video.visible = true;
			_ns.seek(0);
			_ns.resume();

			if (_playPauseButton) _playPauseButton.showPauseIcon();			
			
			setTimeout(play_2, 100); // weak
		}
		private function play_2():void
		{
			this.addEventListener(Event.ENTER_FRAME, pollPosition);
		}
		
		public function pause():void
		{
			if (_state == STATE_BUFFERING) this.removeEventListener(Event.ENTER_FRAME, pollBufferLength)

			if (_ns) {
				_state = STATE_PAUSED;
				_ns.pause();
			}
			
			if (_playPauseButton) _playPauseButton.showPlayIcon();
		}
		
		public function resume():void
		{
			if (_state == STATE_BUFFERING || _state == STATE_PAUSED || _state == STATE_READY) {
				_state = STATE_PLAYING;
				this.removeEventListener(Event.ENTER_FRAME, pollBufferLength)
				_ns.resume();
			}
			else if (_state == STATE_END || _state == STATE_CLOSED) {
				play();
			} 
			else if (STATE_PLAYING) {
				//
			}
			
			if (_playPauseButton) _playPauseButton.showPauseIcon();
		}	
		
		public function close():void
		{
			this.removeEventListener(Event.ENTER_FRAME, pollPosition);
			this.removeEventListener(Event.ENTER_FRAME, pollBufferLength);
			
			_state = STATE_CLOSED;
			
			try { 
				if (_ns) _ns.close();
			}
			catch (e:*) {}
			
			if (_playPauseButton) _playPauseButton.showPlayIcon();
		}
		
		public function percentPlayed():int
		{
			try
			{
				return Math.ceil((_ns.time / _vidDuration) * 100);
			}
			catch (e:*) {
				return -1;
			}
			return -1;
		}
		
		public function set metaData(info:Object):void
		{
			if (! isNaN(_vidDuration)) return; // .. only do this once per video 
			
			_vidDuration = parseFloat(info.duration);
			if (_timeCode) _timeCode.duration = _vidDuration; 

			_videoNativeWidth = parseFloat(info.width); 
			_videoNativeHeight = parseFloat(info.height); 
			
			// if dimensions already set, ignore
			if (! _sizeWidth) _sizeWidth = parseFloat(info.width);
			if (! _sizeHeight) _sizeHeight = parseFloat(info.height);

			_video.visible = true;
			size();
		}
		
		private function onNetStatus($e:NetStatusEvent):void
		{
			// trace('onNetStatus:', $e.info.code)
			
			switch ($e.info.code) 
			{
				case "NetStream.Play.StreamNotFound":
					
					trace($e.info.code);
					close();
					this.dispatchEvent(new Event(EVENT_STREAMNOTFOUND));

				break;
			}
		}
		
		public override function size():void
		{
			GrUtil.fitInRect(_video, new Rectangle(0,0, _sizeWidth,_sizeHeight), false);
		}
		
		private function onVidProgressBarChange($e:ExtendedEvent):void
		{
			var n:Number = $e.object as Number;
			_ns.seek(n * _vidDuration);
		}
		private function onVidProgressBarDragStart(e:*):void
		{
			_isDragging = true;
			trace('startt');
		}
		private function onVidProgressBarDragEnd(e:*):void
		{
			_isDragging = false;
			trace('endd')
		}
		
		private function onVolumeControlChange(e:*):void
		{
			volume = _volumeControl.value;
		}
		
		private function onButtonDoPause(e:*):void
		{
			pause();
		}
		private function onButtonDoPlay(e:*):void
		{
			resume();
		}
	}
}

class SingletonEnforcer {}

//

import leelib.vid.MinVid;

internal class CustomClient 
{
	private var _c:MinVid;
	
	public function CustomClient($client:leelib.vid.MinVid)
	{
		_c = $client;
	}
	public function onMetaData(info:Object):void 
	{
		_c.metaData = info;
	}
	
	public function onXMPData(info:Object):void
	{
		// trace('xmp data', info);
	}
}
