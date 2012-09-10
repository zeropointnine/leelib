package leelib.managers
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.net.URLRequest;
	import flash.utils.clearInterval;
	import flash.utils.setInterval;
	
	import leelib.SingletonEnforcer;
	import leelib.managers.SoundObject;

	/**
	 * 
	 * Half-baked:
	 * Crude 'collection' type functionality, plus some 'pass-thru' methods.
	 * Not thoroughly tested
	 * 
	 * Useful to ensure only one sound plays at once.
	 * For 'polyphony', just use SoundObjects directly, without this manager class.
	 * 
	 */
	public class SoundManager extends EventDispatcher
	{
		private static var _instance:SoundManager;
		
		private var _items:Array = new Array();
		
		private var _selectedItem:SoundObject;
		
		private var _isSoundPlaying:Boolean;
		

		public function SoundManager($enforcer:SingletonEnforcer) 
		{
		}
		
		public static function get instance():SoundManager 
		{
			if (_instance == null) _instance = new SoundManager(new SingletonEnforcer());
			return _instance;
		}
		
		public function get isSoundPlaying():Boolean
		{
			return _isSoundPlaying;
		}
		
		public function get isSoundReady():Boolean
		{
			if (!_selectedItem) return false;
			
			return _selectedItem.isSoundReady;
		}
		
		public function get items():Array
		{
			return _items;
		}
		
		public function get selectedSound():SoundObject
		{
			return _selectedItem;
		}
		
		public function addItem($o:SoundObject):void
		{
			_items[$o.id] = $o;
		}
		
		public function item($id:String):SoundObject
		{
			return _items[$id];
		}
		
		public function loadSound($id:String):void
		{
			clearListeners();
			
			var item:SoundObject = _items[$id];
			_selectedItem = item; 
			item.addEventListener(IOErrorEvent.IO_ERROR, onSoundIoError);
			item.addEventListener(SoundObject.EVENT_SOUNDREADY, onSoundReady);
			item.loadSound();
		}
		private function onSoundIoError(e:*):void
		{
			this.dispatchEvent(e);
		}
		private function onSoundReady(e:*):void
		{
			this.dispatchEvent(e);
		}
		
		public function playSound($id:String):void
		{
			stopSound();
			
			_isSoundPlaying = true;
			
			_items[$id].playSound();
		}
		
		public function stopSound($fadeOut:Boolean=false):void
		{
			for each (var item:SoundObject in _items) {
				if (item.isSoundPlaying) item.stopSound($fadeOut);
			}
			
			_isSoundPlaying = false;
		}
		
		public function restartSelectedSound():void
		{
			
		}
		
		private function clearListeners():void
		{
			for each (var item:SoundObject in _items) {
				item.removeEventListener(IOErrorEvent.IO_ERROR, onSoundIoError);
				item.removeEventListener(SoundObject.EVENT_SOUNDREADY, onSoundReady);
			}
		}
	}
}
