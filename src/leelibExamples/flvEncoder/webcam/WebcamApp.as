package leelibExamples.flvEncoder.webcam
{
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.ActivityEvent;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.StatusEvent;
	import flash.media.Camera;
	import flash.media.Microphone;
	import flash.media.Video;
	import flash.net.FileReference;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.ByteArray;
	import flash.utils.clearTimeout;
	import flash.utils.getTimer;
	import flash.utils.setTimeout;
	
	import leelib.util.flvEncoder.MicRecorderUtil;
	import leelib.util.flvEncoder.ByteArrayFlvEncoder;
	import leelib.util.flvEncoder.FlvEncoder;
	
	import leelibExamples.flvEncoder.webcam.uiEtc.CheckBox;
	import leelibExamples.flvEncoder.webcam.uiEtc.RecordButton;
	import leelibExamples.flvEncoder.webcam.uiEtc.States;

	
	[SWF(width="340", height="290", frameRate="60")]
	public class WebcamApp extends Sprite
	{
		private const OUTPUT_WIDTH:Number = 320;
		private const OUTPUT_HEIGHT:Number = 240;
		
		private const FLV_FRAMERATE:int = 15;
		
		private var _output:Sprite;
		private var _btnRecord:RecordButton;
		private var _tfTime:TextField;
		private var _tfPrompt:TextField;
		private var _checkboxVideo:CheckBox;
		private var _checkboxAudio:CheckBox;

		private var _camera:Camera;
		private var _video:Video;
		private var _netConnection:NetConnection;
		private var _ns:NetStream;
		private var _micUtil:MicRecorderUtil;
		
		private var _baFlvEncoder:ByteArrayFlvEncoder;
		private var _encodeFrameNum:int;
		
		private var _bitmaps:Array;
		private var _audioData:ByteArray;

		private var _startTime:Number;
		private var _timeoutId:Number;
		private var _state:String;


		public function WebcamApp()
		{
			this.stage.align = StageAlign.TOP_LEFT;
			this.stage.scaleMode = StageScaleMode.NO_SCALE;
			
			this.graphics.beginFill(0xe5e5e5);
			this.graphics.drawRect(0,0, this.stage.stageWidth,this.stage.stageHeight);
			this.graphics.endFill();
			
			_output = new Sprite();
			_output.graphics.beginFill(0xe5e5e5);
			_output.graphics.drawRect(0,0, OUTPUT_WIDTH, OUTPUT_HEIGHT);
			_output.graphics.endFill();
			_output.x = 10;
			_output.y = 10;
			this.addChild(_output);
			
			_btnRecord = new RecordButton();
			_btnRecord.addEventListener(MouseEvent.CLICK, onBtnRecClick);
			_btnRecord.x = 10;
			_btnRecord.y = _output.y + _output.height + 10;
			this.addChild(_btnRecord);
			
			_checkboxVideo = new CheckBox("save video", false,false);
			_checkboxVideo.x = _btnRecord.x + _btnRecord.width + 10;
			_checkboxVideo.y = _btnRecord.y;
			_checkboxVideo.on = true;
			_checkboxVideo.addEventListener(MouseEvent.CLICK, onCkVideo);
			this.addChild(_checkboxVideo);
			
			_checkboxAudio = new CheckBox("save audio", false,false);
			_checkboxAudio.x = _checkboxVideo.x + _checkboxVideo.width + 5;
			_checkboxAudio.y = _btnRecord.y;
			_checkboxAudio.on = true;
			_checkboxAudio.addEventListener(MouseEvent.CLICK, onCkAudio);
			this.addChild(_checkboxAudio);
			
			_tfTime = new TextField();
			with (_tfTime)
			{
				defaultTextFormat = new TextFormat("_sans", 12, 0x0, null,null,null,null,null, "right");
				width = 100;
				height = 20;
				selectable = mouseEnabled = false;
				x = _output.x + _output.width - _tfTime.width;
				y = _btnRecord.y;
			}
			this.addChild(_tfTime);
			
			_tfPrompt = new TextField();
			with (_tfPrompt)
			{
				defaultTextFormat = new TextFormat("_sans", 36, 0x0, null,null,null,null,null, "center");
				width = _output.width;
				height = 100;
				text = " ";
				x = _output.x;
				y = _output.y + (_output.height - _tfPrompt.textHeight) / 2;
				selectable = mouseEnabled = false;
			}
			this.addChild(_tfPrompt);
			
			//

			_video = new Video();
			_output.addChild(_video);
			
			_netConnection = new NetConnection();
			_netConnection.connect(null);
			_ns = new NetStream(_netConnection);
			
			_camera = Camera.getCamera();
			_camera.setMode(320,240, 30);
			_camera.setQuality(0, 100);
			
			//
			
			var mic:Microphone = Microphone.getMicrophone();
			mic.setSilenceLevel(0, int.MAX_VALUE);
			mic.gain = 100;
			mic.rate = 44;
			_micUtil = new MicRecorderUtil(mic);			
			
			setState(States.WAITING_FOR_WEBCAM);
		}
		
		private function onCamStatus($e:StatusEvent):void
		{
			if ($e.code == "Camera.Unmuted") // rem: this event can't be relied upon 
			{
				_camera.removeEventListener(StatusEvent.STATUS, onCamStatus);
				_camera.removeEventListener(ActivityEvent.ACTIVITY, onCamActivity);
				setState(States.WAITING_FOR_RECORD);
			}			
		}
		private function onCamActivity($e:ActivityEvent):void
		{
			_camera.removeEventListener(StatusEvent.STATUS, onCamStatus);
			_camera.removeEventListener(ActivityEvent.ACTIVITY, onCamActivity);
			setState(States.WAITING_FOR_RECORD);
		}
		
		//

		private function startRecording():void
		{
			_bitmaps = new Array();
			
			_micUtil.record();
			
			_startTime = getTimer();
			captureFrame();
		}
		
		private function startEncoding():void
		{
			// Get just a little more Mic input!
			// (or enough time for last chunk of data to come in?)			
			setTimeout(startEncoding_2, 200);
		}

		private function startEncoding_2():void
		{
			_micUtil.stop();
			
			_audioData = _micUtil.byteArray;
			
			// Make FlvEncoder object
			_baFlvEncoder = new ByteArrayFlvEncoder(FLV_FRAMERATE);
			if (_checkboxVideo.on) 
			{
				_baFlvEncoder.setVideoProperties(OUTPUT_WIDTH,OUTPUT_HEIGHT);
				
				/*
				 	Replace the line above with the following to use the (much faster) Alchemy encoder.
				   	Requires Flash 10 and addition of of "leelib/util/flvEncoder/alchemy/"
					to the project library path.
				
				 	_baFlvEncoder.setVideoProperties(OUTPUT_WIDTH,OUTPUT_HEIGHT, VideoPayloadMakerAlchemy);
				*/
			}
			if (_checkboxAudio.on) 
			{
				_baFlvEncoder.setAudioProperties(FlvEncoder.SAMPLERATE_44KHZ, true, false, true);
			}
			_baFlvEncoder.start();

			_encodeFrameNum = -1;
			this.addEventListener(Event.ENTER_FRAME, onEnterFrameEncode);
			// ... encode FLV frames on an interval to keep UI from locking up
		}
		
		private function onEnterFrameEncode(e:*):void
		{
			// Encode 3 frames per iteration
			for (var i:int = 0; i < 3; i++)
			{
				_encodeFrameNum++;
				
				if (_encodeFrameNum < _bitmaps.length) {
					encodeNextFrame();
				}
				else {
					// done
					this.removeEventListener(Event.ENTER_FRAME, onEnterFrameEncode);
					_baFlvEncoder.updateDurationMetadata();
					setState(States.SAVING);
					return;
				}
			}
			
			_tfPrompt.text = "encoding\r" + (_encodeFrameNum+1) + " of " + _bitmaps.length;
		}
		
		private function encodeNextFrame():void
		{
			var baAudio:ByteArray;
			var bmdVideo:BitmapData;
			
			if (_checkboxAudio.on)
			{
				baAudio = new ByteArray();
				var pos:int = _encodeFrameNum * _baFlvEncoder.audioFrameSize;
				
				if (pos < 0 || pos + _baFlvEncoder.audioFrameSize > _audioData.length) {
					trace('out of bounds:', _encodeFrameNum, pos + _baFlvEncoder.audioFrameSize, 'versus', _audioData); 
					baAudio.length = _baFlvEncoder.audioFrameSize; // zero's
				}
				else {
					baAudio.writeBytes(_audioData, pos, _baFlvEncoder.audioFrameSize);
				}
			}
			
			if (_checkboxVideo.on) 
			{
				bmdVideo = _bitmaps[_encodeFrameNum];
			}

			_baFlvEncoder.addFrame(bmdVideo, baAudio);
			
			// Video frame has been encoded, so we can discard it now
			_bitmaps[_encodeFrameNum].dispose();
		}
		
		private function captureFrame():void
		{
			// capture frame
			var b:BitmapData = new BitmapData(OUTPUT_WIDTH,OUTPUT_HEIGHT,false,0x0);
			b.draw(_output);
			_bitmaps.push(b);

		 	var sec:int = int(_bitmaps.length / FLV_FRAMERATE);
			_tfTime.text = "0:"  +  ((sec < 10) ? ("0" + sec) : sec);
							
			// end condition:
			if (_bitmaps.length / FLV_FRAMERATE >= 10.0) {
				setState(States.ENCODING);
				return;
			}
			
			// schedule next captureFrame
			var elapsedMs:int = getTimer() - _startTime;
			var nextMs:int = (_bitmaps.length / FLV_FRAMERATE) * 1000;
			var deltaMs:int = nextMs - elapsedMs;
			if (deltaMs < 10) deltaMs = 10;
			_timeoutId = setTimeout(captureFrame, deltaMs);
		}

		private function onBtnRecClick(e:*):void
		{
			if (_state == States.WAITING_FOR_RECORD) 
				setState(States.RECORDING);
			else if (_state == States.RECORDING)
				setState(States.ENCODING);
		}
		
		private function onCkVideo(e:*):void
		{
			if (_checkboxVideo.on && ! _checkboxAudio.on) return;
			_checkboxVideo.on = ! _checkboxVideo.on;
		}

		private function onCkAudio(e:*):void
		{
			if (_checkboxAudio.on && ! _checkboxVideo.on) return;
			_checkboxAudio.on = ! _checkboxAudio.on;
		}
		
		private function onThisClickSave(e:*):void
		{
			var fileRef:FileReference = new FileReference();
			fileRef.save(_baFlvEncoder.byteArray, "no_server_required.flv");			
			
			setState(States.WAITING_FOR_RECORD);
		}
		
		//
		
		private function setState($state:String):void
		{
			_state = $state;
			
			switch (_state)
			{
				case States.WAITING_FOR_WEBCAM:
					_camera.addEventListener(StatusEvent.STATUS, onCamStatus);
					_camera.addEventListener(ActivityEvent.ACTIVITY, onCamActivity);
					_video.attachCamera(_camera);
					break;

				case States.WAITING_FOR_RECORD:
					_video.alpha = 1.0;
					_video.attachCamera(_camera);
					_btnRecord.visible = true;
					_btnRecord.showRecord();
					_tfTime.text = "";
					_tfPrompt.visible = false;
					_checkboxVideo.enabled = _checkboxAudio.enabled = true;
					break;
				
				case States.RECORDING:
					_btnRecord.showStop();
					_checkboxVideo.enabled = _checkboxAudio.enabled = false;
					startRecording();
					break;
				
				case States.ENCODING:
					clearTimeout(_timeoutId);
					_video.alpha = 0.5;
					_tfPrompt.text = "encoding";
					_tfPrompt.visible = true;
					_btnRecord.visible = false;
					startEncoding();
					break;
				
				case States.SAVING:
					_tfPrompt.text = "< click to save >";
					_tfPrompt.visible = true;
					this.addEventListener(MouseEvent.CLICK, onThisClickSave);
					break;
			}
		}
	}
}
