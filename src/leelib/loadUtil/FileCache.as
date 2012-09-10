package leelib.loadUtil
{
	import com.adobe.crypto.MD5;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	import leelib.appropriated.Guid;
	import leelib.util.AirUtil;
	import leelib.util.Out;
	import leelib.GlobalApp;
	
	
	/**
	 * Simple file cache (does not test for date-modified or file-size).
	 * Coding for use case of a mobile list scroller.
	 * Saves to flat directory using hash as filename.
	 * 
	 * Saving of files done with mobile in mind -- asynchronously and in a queue to avoid simultaneous writes.
	 */
	public class FileCache
	{
		private var _basePath:String;
		private var _separator:String;

		private var _saveQueue:Array;
		private var _currentSaveVo:Vo;
		
		private var _fsSave:FileStream;
		
		
		public function FileCache($basePath:String)
		{
			_separator = File.separator;
			_basePath = $basePath;
			if (_basePath.lastIndexOf(_separator) != _basePath.length-1) _basePath += _separator;
			// Out.i('FileCache basePath:', _basePath);
			
			initDirectoryIfNeeded();
			
			_saveQueue = [];

			_fsSave = new FileStream();
			_fsSave.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_fsSave.addEventListener(Event.CLOSE, onSaveClose);
		}

		private function initDirectoryIfNeeded():void
		{
			var f:File = new File(_basePath);
			if (f.exists) return;
			
			try {
				f.createDirectory();
			}
			catch (e:Error) {
				Out.e("initDirectoryIfNeeded()", e.message);
				return;	
			}
		}
		
		public function get basePath():String
		{
			return _basePath;
		}

		public function saveSync($sourceUrl:String, $ba:ByteArray):Boolean
		{
			// Rem, mobile writes are slow-ish

			var id:String = getIdFromString($sourceUrl);
			var f:File = new File(_basePath + id); // no file-exists check

			try
			{
				var fs:FileStream = new FileStream();
				fs.open(f, FileMode.WRITE);
				fs.writeBytes($ba);
				fs.close();
			}
			catch (e:Error)
			{
				Out.e('FileCache.saveSync - ERROR:', $sourceUrl, e.message);
				return false;
			}

			Out.v('FileCache.saveSync', $ba.length, $sourceUrl);
			return true;
		}
		
		public function save($sourceUrl:String, $ba:ByteArray):void
		{
			if (_currentSaveVo && _currentSaveVo.url == $sourceUrl) {
				Out.w('FileCache.save - already writing');
				return;
			}
			
			for each (var v:Vo in _saveQueue) {
				if (v.url == $sourceUrl) {
					Out.w('FileCache.save - already in queue');
					return;
				}
			}
			
			//
			
			var vo:Vo = new Vo($sourceUrl, $ba);
			_saveQueue.push(vo);
			
			if (! _currentSaveVo) saveNext();
		}
		
		private function saveNext():void
		{
			// end condition:
			if (_saveQueue.length == 0) {
				Out.v('FileCache - save done.');
				return;
			}
			
			_currentSaveVo = _saveQueue.shift();
			
			var id:String = getIdFromString(_currentSaveVo.url);
			var f:File = new File(_basePath + id);
			
			try
			{
				_fsSave.openAsync(f, FileMode.WRITE);
				_fsSave.writeBytes(_currentSaveVo.byteArray);
				_fsSave.close();
			}
			catch (e:Error)
			{
				Out.e('FileCache.save - ERROR:', _currentSaveVo.url, e.message);
				return;
			}
		}
		
		private function onSaveError($e:IOErrorEvent):void
		{
			Out.e('FileCache.onSaveError - ERROR:', $e.text);
			// TODO
		}
		
		private function onSaveClose($e:Event):void
		{
			Out.v('FileCache.onSaveClose', _currentSaveVo.url);
			_currentSaveVo.clear();
			_currentSaveVo = null;
			
			saveNext();
		}
		
		public function load($url:String):ByteArray
		{
			if (_currentSaveVo && _currentSaveVo.url == $url) {
				Out.w('FileCache.load - file is still being saved');
				return null;
			}

			var id:String = getIdFromString($url);
			var f:File = new File(_basePath + id);
			if (! f.exists) return null;

			var ba:ByteArray = new ByteArray();
			var now:int = getTimer();

			try 
			{
				// Synchronous
				var fs:FileStream = new FileStream();
				fs.open(f, FileMode.READ);
				fs.readBytes(ba);
				fs.close();
			}
			catch (e:Error)
			{
				Out.e('FileCache.load - ERROR:', $url, e.message);
				return null;
			}
			
			Out.v('FileCache.load', (getTimer()-now)+"ms", ba.length+"bytes", $url);
			return ba;
		}
		
		// Returns full hashed path IF file exists
		//
		public function getLocalPathOf($url:String):String
		{
			var id:String = getIdFromString($url);
			var f:File = new File(_basePath + id);
			if (! f.exists) return null;
			return (_basePath + id);
		}
		
		public function clearCache():void
		{
			Out.i("FileCache.clearCache()", _basePath);
			AirUtil.deleteFilesInDirectoryUrl(new File(_basePath).url);
		}

		// for debugging
		//
		public function printDirectoryContents():void
		{
			var dir:File = new File(_basePath);
			if (dir.exists) {
				var a:Array = dir.getDirectoryListing();
				for each (var f:File in a) {
					Out.i('-', f.nativePath);
					f.deleteFile();
				}
			}
		}

		private function getIdFromString($s:String):String
		{
			return MD5.hash($s);
			// TODO: Add logic to use just filename itself when filename is known to be a hashed string
		}

		
		// untested; not yet using
		//
		private function getFileSuffix($s:String):String
		{
			var slash:int = $s.lastIndexOf(_separator);
			var dot:int = $s.lastIndexOf(".");
			if (dot > -1  &&  dot > slash  &&  dot < $s.length-1) 
				return "." + $s.substr(dot+1);
			else
				return "";
		}
	}
}

// ---

import flash.utils.ByteArray;

internal class Vo
{
	public var url:String;
	public var byteArray:ByteArray;	

	function Vo($url:String, $ba:ByteArray) 
	{
		url = $url;
		byteArray = $ba;
	}
	
	public function clear():void
	{
		url = null;
		byteArray = null;
	}
}
