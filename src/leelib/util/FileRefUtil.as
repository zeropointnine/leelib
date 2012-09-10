package leelib.util
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.FileReference;
	import flash.utils.ByteArray;

	
	public class FileRefUtil extends EventDispatcher
	{
		private var _saveFileRef:FileReference;
		private var _saveErrorHandler:Function;
		private var _saveCancelHandler:Function;
		private var _saveCompleteHandler:Function;
		
		private var _loadFileRef:FileReference;
		private var _loadErrorHandler:Function;
		private var _loadCancelHandler:Function;
		private var _loadCompleteHandler:Function;
		
		
		public function FileRefUtil()
		{
		}
		
		// Rem, Flash 10 or greater
		public function save($ba:ByteArray, $defaultFileName:String, $errorHandler:Function, $cancelHandler:Function, $completeHandler:Function):void 
		{
			_saveFileRef = new FileReference();
			_saveFileRef.addEventListener(Event.CANCEL, onSaveCancel);
			_saveFileRef.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_saveFileRef.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSaveError);
			_saveFileRef.addEventListener(Event.COMPLETE, onSaveComplete);

			_saveErrorHandler = $errorHandler;
			_saveCancelHandler = $cancelHandler;
			_saveCompleteHandler = $completeHandler;
			
			_saveFileRef.save($ba, $defaultFileName);
		}
		
		private function saveClear():void 
		{
			if(_saveFileRef) {
				_saveFileRef.removeEventListener(Event.CANCEL, onSaveCancel);
				_saveFileRef.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
				_saveFileRef.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onSaveError);
				_saveFileRef = null;
			}
			_saveErrorHandler = null;
			_saveCancelHandler = null;
			_saveCompleteHandler = null;
		}
		
		private function onSaveCancel($e:Event):void 
		{
			var f:Function = _saveCancelHandler;
			saveClear();
			if (f != null) f($e);
		}
		
		private function onSaveError($e:IOErrorEvent):void {
			var f:Function = _saveErrorHandler;
			saveClear();
			if (f != null) f($e);
		}

		private function onSaveComplete($e:Event):void {
			var f:Function = _saveCompleteHandler;
			saveClear();
			if (f != null) f($e);
		}		
		
		// 
		
		public function browseAndLoad($loadCompleteHandler:Function, $browseCancelHandler:Function, $anyErrorHandler:Function, $typeFilter:Array):void
		{
			_loadFileRef = new FileReference();
			_loadFileRef.addEventListener(Event.CANCEL, onLoadCancel);
			_loadFileRef.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
			_loadFileRef.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onLoadError);
			_loadFileRef.addEventListener(Event.SELECT, onLoadSelect);
			
			_loadCompleteHandler = $loadCompleteHandler;
			_loadErrorHandler = $anyErrorHandler;
			_loadCancelHandler = $browseCancelHandler;
			
			_loadFileRef.browse($typeFilter);
		}
		
		private function loadClear():void 
		{
			if(_loadFileRef) {
				_loadFileRef.removeEventListener(Event.CANCEL, onLoadCancel);
				_loadFileRef.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
				_loadFileRef.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onLoadError);
				_loadFileRef = null;
			}
			_loadErrorHandler = null;
			_loadCancelHandler = null;
		}
		
		private function onLoadCancel($e:Event):void 
		{
			var f:Function = _loadCancelHandler;
			loadClear();
			if (f != null) f($e);
		}
		
		private function onLoadError($e:Event):void {
			var f:Function = _loadErrorHandler;
			loadClear();
			if (f != null) f($e);
		}
		
		private function onLoadSelect($e:Event):void {
			_loadFileRef.addEventListener(Event.COMPLETE, onLoadComplete);
			_loadFileRef.load();
		}
		
		private function onLoadComplete($e:Event):void
		{
			var f:Function = _loadCompleteHandler;
			loadClear();
			if (f != null) f($e);
		}
		
	}
}
