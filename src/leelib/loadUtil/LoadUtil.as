package leelib.loadUtil
{
	import flash.display.*;
	import flash.events.*;
	import flash.filesystem.File;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	import leelib.graphics.GrUtil;
	import leelib.util.Out;
	
	import leelib.GlobalApp;

	/*
		queue by url
		v
		check object pool
		v
		check file cache
		v
		urlloader
		v
		bytearray > add to object pool, save to cache
		v
		loader.loadBytes
		v
		return bitmapdata
	*/
	
	/**
	 * Retrieves image from object pool, file cache, or over network, in that order.
	 * 
	 * Optimized for specific use case of mobile list scrollers with small icons.
	 * 
	 * Load errors get forwarded along in the LoaderEvent so that the client
	 * only needs to listen for the one loader event. 
	 * 
	 * No loaderContext logic.
	 * 
	 * Not a singleton on purpose. 
	 * For singleton-like behavior, attach it as an instance to your catch-all app singleton.
	 * 
	 * Added non-bitmap files functionality
	 * 
	 */
	public class LoadUtil extends EventDispatcher
	{
		public static const QUEUE_COMPLETE:String = "LoadUtil.QUEUE_COMPLETE";
		public static const NO_REACH:String = "NoReach";

		public static const TYPE_IMAGE:String = "image";
		public static const TYPE_STRING:String = "string";
		public static const TYPE_BINARY:String = "binary";

		private var _urlLoader:URLLoader;
		private var _loader:Loader;

		public var _queue:Vector.<Vo>;
		private var _bitmapPool:BitmapPool;
		private var _fileCache:FileCache;
		
		private var _currentVo:Vo;
		
		private var _showPinwheelFunction:Function;
		private var _hidePinwheelFunction:Function;
		
		
		public function LoadUtil($cachePath:String, $showPinwheelFn:Function=null, $hidePinwheelFn:Function=null, $useBitmapPool:Boolean=true, $bitmapPoolSize:int=8000000)
		{
			_urlLoader = new URLLoader();
			_urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
			
			_loader = new Loader();
			
			_showPinwheelFunction = $showPinwheelFn;
			_hidePinwheelFunction = $hidePinwheelFn;

			_queue = new Vector.<Vo>();
			if ($useBitmapPool) _bitmapPool = new BitmapPool($bitmapPoolSize);
			_fileCache = new FileCache($cachePath);
		}

		/**
		 * Rem, this can dispatch events synchronously under 2 circumstances, so listener must be added before calling
		 * Returns true if added to queue, false if not (ie, immediate error, or bitmapPool cache hit)
		 */
		public function load($urlString:String, $eventName:String, $assetType:String, $callbackData:Object=null, $now:Boolean=false, $ignoreCache:Boolean=false, $showPinwheel:Boolean=false):Boolean
		{
			if (! $urlString) {
				Out.e("LoadUtil.load() - URL IS NULL");
				var e:LoadUtilEvent = new LoadUtilEvent($eventName, null, $callbackData, "url is null");
				return false;
			}
			
			if ($assetType==TYPE_IMAGE && _bitmapPool && ! $ignoreCache)
			{
				var b:BitmapData = _bitmapPool.getBitmap($urlString); 
				if (b) {
					// Out.i('LoadUtil.load() - pool hit');
					e = new LoadUtilEvent($eventName, b, $callbackData, null);
					this.dispatchEvent(e);
					return true;
				}
			}
			
			var indexOrCode:int = queueIndexOrCode($urlString, $eventName); 
			if (indexOrCode == -2) {
				// no match, keep going
			}
			else if (indexOrCode == -1) {
				// Out.i("LoadUtil.load() - ignored, is currently loading", $urlString, $eventName);
				return false;
			}
			else if (indexOrCode >= 0) {
				if (! $now) {
					// Out.i("LoadUtil.load() - ignored, is already queued", indexOrCode, $urlString, $eventName);
				}
				else {
					// Out.i("LoadUtil.load() -  already queued, but bumped to top from", indexOrCode, $urlString, $eventName);
					var vo:Vo = _queue.splice(indexOrCode, 1)[0];
					_queue.unshift(vo);
				}
				return false; 
			}
			
			//
			
			var item:Vo = new Vo($urlString, $eventName, $assetType, $callbackData, $ignoreCache, $showPinwheel);

			if ($now)  {
				// Out.i("LoadUtil.load() - loading now", $urlString, $eventName);
				_queue.unshift(item);
			}
			else {
				// Out.i("LoadUtil.load() - loading", $urlString, $eventName);
				_queue.push(item);
			}

			if (! _currentVo) loadNext();
			
			return true;
		}

		// Ugly name.
		// returns _queue index if is in queue (ie, >= 0)
		// return -1 if is the item currently loading
		// returns -2 if NOT queued or currently loading
		//
		public function queueIndexOrCode($url:String, $eventName:String):int
		{
			if (_currentVo && _currentVo.url == $url && _currentVo.eventName == $eventName) return -1;
			
			for (var i:int = 0; i < _queue.length; i++) // O(n) lookup
			{
				var vo:Vo = _queue[i];
				if (vo.url == $url && vo.eventName == $eventName) return i;
			}
			
			return -2; // ie, not queued or currently loading
		}

		public function reset():void
		{
			_urlLoader.removeEventListener(Event.COMPLETE, onUrlLoaderComplete);
			_urlLoader.removeEventListener(IOErrorEvent.IO_ERROR, onUrlLoaderIoError);
			_loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onLoaderError);
			_loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onLoader);

			try { _urlLoader.close(); } catch (e:*) {}
			try { _loader.close(); } catch (e:*) {}
			
			if (_currentVo) {
				_currentVo.kill();
				_currentVo = null;
			}

			for (var i:int = 0; i < _queue.length; i++) {
				_queue[i].kill();
				_queue[i] = null;
			}			
			_queue = new Vector.<Vo>();
		}
		
		// TODO
		public function removeByUrlAndEventName($url:String, $eventName:String):Boolean
		{
			return false;
		}
		
		// Returns number of items removed
		public function removeByEventName($s:String, $alsoCheckCurrentlyLoading:Boolean):int
		{
			var count:int = 0;
			for (var i:int = _queue.length - 1; i > -1; i--)
			{
				if (_queue[i].eventName == $s) {
					var vo:Vo = _queue.splice(i, 1)[0];
					vo.kill();
					count++;
				}
			}
			
			if ($alsoCheckCurrentlyLoading)
			{
				if (_currentVo && _currentVo.eventName == $s)
				{
					try { _urlLoader.close(); } catch (e:*) {}
					try { _loader.close(); } catch (e:*) {}
					_currentVo.kill();
					_currentVo = null;
					count++;
				}
			}
			
			return count;
		}
		
		public function get queueLength():int
		{
			if (! _currentVo) 
				return 0;
			else
				return _queue.length + 1; // ie, currentvo + items in _queue
		}
		
		public function isCached($url:String):Boolean
		{
			return (_fileCache.getLocalPathOf($url) != null);
		}
		
		public function get fileCache():FileCache
		{
			return _fileCache;
		}

		//
		
		private function loadNext():void
		{
			if (_queue.length == 0) // end condition 
			{
				if (_currentVo) { 
					_currentVo.kill(); 
					_currentVo = null; 
				}
				this.dispatchEvent(new Event(LoadUtil.QUEUE_COMPLETE));
				return;
			}
			
			_currentVo = _queue.shift();

			if (_currentVo.ignoreCache)
			{
				loadFromNetwork();
			}
			else
			{
				var ba:ByteArray = _fileCache.load(_currentVo.url);
				if (! ba) 
				{
					loadFromNetwork();
				}
				else 
				{
					switch (_currentVo.type)
					{
						case TYPE_BINARY:
							var e:LoadUtilEvent = new LoadUtilEvent(_currentVo.eventName, ba, _currentVo.callbackData, null);
							this.dispatchEvent(e);
							
							_currentVo.kill();
							_currentVo = null;
							loadNext();	

							break;

						case TYPE_STRING:
							var s:String = ba.readMultiByte(ba.length, "iso-8859-1"); // not fully baked? make 'iso...' works on iphone also.
							e = new LoadUtilEvent(_currentVo.eventName, s, _currentVo.callbackData, null);
							this.dispatchEvent(e);
							
							_currentVo.kill();
							_currentVo = null;
							loadNext();	

							break;

						case TYPE_IMAGE:
							_loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onLoaderError);
							_loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoader);
							_loader.loadBytes(ba); // one more step
							break;
					}
				}
			}
		}
		private function loadFromNetwork():void
		{
		
			if (! GlobalApp.globalApp) 
			{
				//Out.e('LoaderManager.loadNext - NO REACH');
				var e:LoadUtilEvent = new LoadUtilEvent(_currentVo.eventName, null, _currentVo.callbackData, LoadUtil.NO_REACH);
				this.dispatchEvent(e);
			}
			else 
			{
				if (_currentVo.usePinwheel) _showPinwheelFunction();

				_urlLoader.addEventListener(Event.COMPLETE, onUrlLoaderComplete);
				_urlLoader.addEventListener(IOErrorEvent.IO_ERROR, onUrlLoaderIoError);
				_urlLoader.load(new URLRequest(_currentVo.url));
			}
		
		}
		private function onUrlLoaderIoError($e:IOErrorEvent):void
		{
			if (_currentVo.usePinwheel && (_queue.length == 0 || _queue[0].usePinwheel == false)) _hidePinwheelFunction();

			var e:LoadUtilEvent = new LoadUtilEvent(_currentVo.eventName, null, _currentVo.callbackData, IOErrorEvent($e).text);
			//Out.e('LoaderManager.onLoaderResponse - IOErrorEvent', e.errorText, '\rURL:', _currentVo.url);
			this.dispatchEvent(e);
			
			loadNext();
		}
		private function onUrlLoaderComplete($e:Event):void
		{
			// TODO: FIX:
			if (! _currentVo) { Out.e("HUH?"); return; }
			if (_currentVo.usePinwheel && (_queue.length == 0 || _queue[0].usePinwheel == false)) _hidePinwheelFunction();

			var ba:ByteArray = $e.target.data;
			_fileCache.save(_currentVo.url, ba);

			switch (_currentVo.type)
			{
				case TYPE_BINARY:
					
					var e:LoadUtilEvent = new LoadUtilEvent(_currentVo.eventName, ba, _currentVo.callbackData, null);
					this.dispatchEvent(e);
					
					_currentVo.kill();
					_currentVo = null;
					loadNext();	

					break;
				
				case TYPE_STRING:
					
					var s:String = ba.readMultiByte(ba.length, "iso-8859-1"); // not fully baked? make 'iso...' works on iphone also.
					e = new LoadUtilEvent(_currentVo.eventName, s, _currentVo.callbackData, null);
					this.dispatchEvent(e);
					
					_currentVo.kill();
					_currentVo = null;
					loadNext();	

					break;

				case TYPE_IMAGE:
					
					_loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onLoaderError);
					_loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoader);
					_loader.loadBytes(ba); // ie, one more step
					
					break;
			}
		}
		private function onLoaderError($e:IOErrorEvent):void
		{
			Out.e('LoaderManager.onLoaderError: ', $e.text);
			var e:LoadUtilEvent = new LoadUtilEvent(_currentVo.eventName, null, _currentVo.callbackData, $e.text);
			this.dispatchEvent(e);
		}
		private function onLoader($e:Event):void
		{
			var b:Bitmap = _loader.content as Bitmap;
			var bd:BitmapData;
			if (b) bd = b.bitmapData;

			if (_bitmapPool && bd) _bitmapPool.add(_currentVo.url, bd);

			var e:LoadUtilEvent = new LoadUtilEvent(_currentVo.eventName, bd, _currentVo.callbackData, null);
			this.dispatchEvent(e);
			
			_currentVo.kill();
			_currentVo = null;
			loadNext();	
		}
	}
}

// ===

import flash.display.Loader;
import flash.display.LoaderInfo;
import flash.net.URLLoader;

internal class Vo 
{
	public var url:String;
	public var eventName:String;
	public var type:String;
	public var callbackData:Object;
	public var ignoreCache:Boolean;
	public var usePinwheel:Boolean;

	public function Vo($url:String, $eventName:String, $type:String, $callbackData:Object, $noCache:Boolean, $showPinwheel:Boolean) 
	{
		url = $url;
		eventName = $eventName;
		type = $type;
		callbackData = $callbackData;
		ignoreCache = $noCache;
		usePinwheel = $showPinwheel;
	}
	
	public function kill():void
	{
		callbackData = null;
	}
}
