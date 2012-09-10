package leelib.managers
{
	import com.greensock.TweenLite;
	import com.greensock.easing.Linear;
	import com.greensock.easing.Quad;
	import com.greensock.plugins.TweenPlugin;
	import com.greensock.plugins.VolumePlugin;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.net.URLRequest;
	import flash.utils.clearInterval;
	import flash.utils.setInterval;
	
	public class SoundObject extends EventDispatcher
	{
		public static const EVENT_SOUNDREADY:String = "SoundManager.eventSoundReady";
		
		private var _id:String;
		private var _label:String;
		private var _url:String;
		
		private var _sound:Sound;
		private var _soundChannel:SoundChannel;
		private var _loadSoundInterval:Number;
		private var _isSoundReady:Boolean;
		private var _isSoundPlaying:Boolean;
		
		
		public function SoundObject($id:String, $label:String, $url:String)
		{
			TweenPlugin.activate([VolumePlugin]);
			
			_id = $id;
			_label = $label;
			_url = $url;
		}
		
		public function get id():String
		{
			return _id;
		}
		
		public function label():String
		{
			return _label;
		}
		
		public function get url():String
		{
			return _url;
		}
		
		public function get isSoundReady():Boolean
		{
			return _isSoundReady;
		}
		
		public function get isSoundPlaying():Boolean
		{
			return _isSoundPlaying;
		}
		
		public function get position():int
		{
			return _soundChannel.position;
		}
			
		//
		
		public function loadSound():void
		{
			stopSound();
			
			_sound = new Sound();
			_loadSoundInterval = setInterval(pollLoadSound, 33);
			_sound.addEventListener(IOErrorEvent.IO_ERROR, onSoundIoError);
			_sound.load(new URLRequest(_url));
			
			/// add SecurityErrorEvent probably
		}
		
		private function onSoundIoError($e:IOErrorEvent):void
		{
			_sound.removeEventListener(IOErrorEvent.IO_ERROR, onSoundIoError);
			clearInterval(_loadSoundInterval);
			
			if (_soundChannel) _soundChannel.stop();
			if (_sound) {
				try { _sound.close(); } catch(e:Error){}
			}
			_sound = null;
			_soundChannel = null;
			
			this.dispatchEvent($e);
		}
		
		private function pollLoadSound():void
		{
			/// rethink this...
			if (_sound.bytesLoaded > 200000)
			{
				clearInterval(_loadSoundInterval);
				_isSoundReady = true;
				this.dispatchEvent(new Event(SoundObject.EVENT_SOUNDREADY));
			}
		}
		
		public function playSound():void
		{
			if (! _sound) throw new Error("First, loadSound()"); /// ?
				
			if (_soundChannel) { 
				TweenLite.killTweensOf(_soundChannel);
				_soundChannel.stop();
			}
			
			_soundChannel = _sound.play(0, 999999);
			
			_isSoundPlaying = true;
		}
		
		public function stopSound($fadeOut:Boolean=false):void
		{
			_isSoundPlaying = false;
			
			if (! $fadeOut) {
				stopSound_2();
				return;
			} 
			
			if (_soundChannel) {
				TweenLite.killTweensOf(_soundChannel);
				TweenLite.to(_soundChannel, 0.66, { volume:0, ease:Linear.easeNone, onComplete:stopSound_2 } );
			}
		}
		
		private function stopSound_2():void
		{
			if (_sound) 
			{
				_sound.removeEventListener(IOErrorEvent.IO_ERROR, onSoundIoError);
				
				if (_soundChannel) {
					TweenLite.killTweensOf(_soundChannel);
					_soundChannel.stop();
				}

				try { _sound.close(); } catch(e:Error){}
				return;
			}
		}
	}
}
