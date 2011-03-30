package leelib.util.flvEncoder 
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.SampleDataEvent;
	import flash.events.StatusEvent;
	import flash.media.Microphone;
	import flash.utils.ByteArray;
	import flash.utils.getTimer;
	
	
	/**
	 * Mostly duplicated from ByteArray's MicRecorder class
	 * http://www.bytearray.org/?p=1858
	 * 
	 * It couldn't be extended because is final. 
	 */
	public class MicRecorderUtil extends EventDispatcher
	{
		private var _startTime:uint;
		private var _microphone:Microphone;
		private var _byteArray:ByteArray = new ByteArray();
		
		private var _completeEvent:Event = new Event ( Event.COMPLETE );
		

		public function MicRecorderUtil(microphone:Microphone)
		{
			_microphone = microphone;
		}
		
		public function record():void
		{
			_startTime = getTimer();
			
			_byteArray.length = 0;

			_microphone.addEventListener(SampleDataEvent.SAMPLE_DATA, onSampleData);
			_microphone.addEventListener(StatusEvent.STATUS, onStatus); // (may never fire)
		}
		
		public function stop():void
		{
			_microphone.removeEventListener(SampleDataEvent.SAMPLE_DATA, onSampleData);
			_microphone.removeEventListener(StatusEvent.STATUS, onStatus);
			
			_byteArray.position = 0;
		}
		
		public function get microphone():Microphone
		{
			return _microphone;
		}
		
		public function get byteArray():ByteArray
		{
			return _byteArray;
		}
		
		/**
		 * Effectly removes the first $pos bytes from _byteArray.
		 * NB, creates a new instance of ByteArray; cursor ends up at the end.
		 */
		public function shift($pos:uint):void
		{
			var ba:ByteArray = new ByteArray();
			ba.writeBytes(_byteArray, $pos, _byteArray.length - $pos);
			_byteArray = ba;
		}

		//
		
		private function onStatus($e:StatusEvent):void
		{
			trace('Mic - onStatus', $e.code)		
			
			_startTime = getTimer();
		}
		
		private function onSampleData($e:SampleDataEvent):void
		{
			// ADD THIS LATER POSSIBLY
			// _recordingEvent.time = getTimer() - _startTime;
			
			while($e.data.bytesAvailable > 0) {
				_byteArray.writeFloat($e.data.readFloat());
			}
			
			// ADD THIS LATER POSSIBLY
			// private var _recordingEvent:RecordingEvent = new RecordingEvent( RecordingEvent.RECORDING, 0 );
			// this.dispatchEvent( _recordingEvent );
		}
	}
}
