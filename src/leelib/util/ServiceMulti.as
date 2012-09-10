package leelib.util
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.utils.ByteArray;
	
	import leelib.ExtendedEvent;
	import leelib.appropriated.MultipartURLLoader;
	import leelib.appropriated.MultipartURLLoaderEvent;
	
	/**
	 * Uses Eugene Zatepyakin MultipartURLLoader class by composition 
	 */	
	public class ServiceMulti extends Service
	{
		private var _multi:MultipartURLLoader;
		
		
		public function ServiceMulti()
		{
		}
		

		public function requestMulti($url:String, $params:Object, $returnType:String, $file:ByteArray, $fileFieldName:String, $fileName:String="MyFile", $fileMimeType:String='application/octet-stream'):void
		{
			_returnType = $returnType;
			
			_multi = new MultipartURLLoader();
			_multi.dataFormat = URLLoaderDataFormat.TEXT;
			
			for (var key:String in $params)
			{
				_multi.addVariable(key, $params[key]);
			}
			
			_multi.addFile($file, $fileName, $fileFieldName, $fileMimeType);
			
			_multi.addEventListener(IOErrorEvent.IO_ERROR, onUploadIoError);
			_multi.addEventListener(MultipartURLLoaderEvent.DATA_PREPARE_COMPLETE, onUploadPrepComplete);
			_multi.addEventListener(MultipartURLLoaderEvent.DATA_PREPARE_PROGRESS, onUploadProgress);
			_multi.addEventListener(Event.COMPLETE, onUploadComplete);
			
			_multi.load($url);
		}
		
		private function onUploadIoError($e:IOErrorEvent):void
		{
			Out.e('ServiceMulti.onUploadIoError()', $e.text);
			clearEventHandlers();
			this.dispatchEvent($e);
		}
		private function onUploadPrepComplete(e:*):void
		{
			Out.i('ServiceMulti - MultipartURLLoaderEvent.DATA_PREPARE_COMPLETE');
		}
		private function onUploadProgress(e:MultipartURLLoaderEvent):void 
		{
			Out.i('ServiceMulti.onUploadProgress()' + e.bytesWritten + '/' + e.bytesTotal);
		}
		
		private function onUploadComplete($e:*):void
		{
			var loader:URLLoader = MultipartURLLoader($e.currentTarget).loader;
			var s:String = loader.data;
			var o:Object = castResponse(s);
			o = transform(o);
			this.dispatchEvent(new ExtendedEvent(Event.COMPLETE, o ));
		}
		
		private function clearEventHandlers():void
		{
			_multi.removeEventListener(IOErrorEvent.IO_ERROR, onUploadIoError);
			_multi.removeEventListener(MultipartURLLoaderEvent.DATA_PREPARE_COMPLETE, onUploadPrepComplete);
			_multi.removeEventListener(MultipartURLLoaderEvent.DATA_PREPARE_PROGRESS, onUploadProgress);
			_multi.removeEventListener(Event.COMPLETE, onUploadComplete);
		}
	}
}
