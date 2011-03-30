package leelibExamples.flvEncoder.basic
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.net.FileReference;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.utils.ByteArray;
	import flash.utils.getTimer;
	
	import leelib.util.flvEncoder.ByteArrayFlvEncoder;
	import leelib.util.flvEncoder.FlvEncoder;
	

	/**
	 * Example of using ByteArrayFlvEncoder to create an FLV whose source   
	 * audio is static (eg, a music soundtrack).
	 * 
	 * Resulting video is 8 seconds of a red bouncing ball on a gray-scale perlin  
	 * noise background, with the beginning of the song "Hello" by Capsule. 
	 */
	
	[SWF(width="340", height="290", frameRate="30")]
	public class StaticAudioExampleApp extends Sprite
	{
		[Embed(source="./assets/hello.mp3")]
		private static const Soundtrack:Class;
		
		private const OUTPUT_WIDTH:Number = 320;
		private const OUTPUT_HEIGHT:Number = 240;
		private const FLV_FRAMERATE:int = 30;
		
		private var _videoOutput:Sprite;
		private var _ball:Sprite;
		private var _vx:Number = 12;
		private var _vy:Number = 6;
		
		private var _sound:Sound;
		private var _soundChannel:SoundChannel;
		
		private var _bitmaps:Array;
		
		private var _baFlvEncoder:ByteArrayFlvEncoder;
		

		public function StaticAudioExampleApp()
		{
			init();
			generateFrames();
			save();
		}
		
		private function init():void
		{
			_videoOutput = new Sprite();
			
			var bmd:BitmapData = new BitmapData(OUTPUT_WIDTH,OUTPUT_HEIGHT,false);
			bmd.perlinNoise(OUTPUT_WIDTH/2,OUTPUT_HEIGHT/2, 3, 666, false,false, 7, true);
			_videoOutput.addChild(new Bitmap(bmd));
			
			this.addChild(_videoOutput);
			
			_ball = new Sprite();
			_ball.graphics.beginFill(0xff0000);
			_ball.graphics.drawCircle(0,0,10);
			_ball.graphics.endFill();
			_videoOutput.addChild(_ball);
			
			_bitmaps = new Array();
			
			_sound = new Soundtrack();
		}
		
		private function generateFrames():void
		{
			for (var i:int = 0; i < FLV_FRAMERATE*8; i++)
			{
				updateDisplay();
				
				var b:BitmapData = new BitmapData(OUTPUT_WIDTH,OUTPUT_HEIGHT,false,0x0);
				b.draw(_videoOutput);
				_bitmaps.push(b);
			}
		}
		
		private function onEnterFrame(e:*):void
		{
			updateDisplay();
			
			var b:BitmapData = new BitmapData(OUTPUT_WIDTH,OUTPUT_HEIGHT,false,0x0);
			b.draw(_videoOutput);
			_bitmaps.push(b);
			
			//
			
			if (_bitmaps.length / FLV_FRAMERATE >= 5.0) 
			{
				this.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
				_sound.close();
				save();
			}
		}
		
		private function updateDisplay():void
		{
			_ball.x += _vx;
			_ball.y += _vy;
			
			if (_ball.x > 310) {
				_ball.x = 310;
				_vx = - Math.abs(_vx);
			}
			if (_ball.x < 10) {
				_ball.x = 10;
				_vx = + Math.abs(_vx);
			}
			
			if (_ball.y > 230) {
				_ball.y = 230;
				_vy = - Math.abs(_vy);
			}
			if (_ball.y < 10) {
				_ball.y = 10;
				_vy = + Math.abs(_vy);
			}
		}
		
		private function save():void
		{
			// Prepare the audio data
			
			var baAudio:ByteArray = new ByteArray();
			var seconds:Number = _bitmaps.length / FLV_FRAMERATE;
			_sound.extract(baAudio, seconds * 44000 + 1000); 
			
			// Make FlvEncoder object
			
			_baFlvEncoder = new ByteArrayFlvEncoder(FLV_FRAMERATE);
			_baFlvEncoder.setVideoProperties(OUTPUT_WIDTH, OUTPUT_HEIGHT);
			_baFlvEncoder.setAudioProperties(FlvEncoder.SAMPLERATE_44KHZ, true,true, true);
			_baFlvEncoder.start();
			
			// Make FLV:
			
			for (var i:int = 0; i < _bitmaps.length; i++) 
			{
				var audioChunk:ByteArray = new ByteArray();
				audioChunk.writeBytes(baAudio, i * _baFlvEncoder.audioFrameSize, _baFlvEncoder.audioFrameSize);

				_baFlvEncoder.addFrame(_bitmaps[i], audioChunk);

				_bitmaps[i].dispose();
			}
			_baFlvEncoder.updateDurationMetadata();
			
			var tf:TextField = new TextField();
			tf.autoSize = TextFieldAutoSize.LEFT;
			tf.defaultTextFormat = new TextFormat("_sans", 18, 0x888888, true);
			tf.text = "Click to save.";
			this.addChild(tf);
			this.addEventListener(MouseEvent.CLICK, onClick);
		}
		
		private function onClick(e:*):void
		{
			this.removeEventListener(MouseEvent.CLICK, onClick);

			// Save FLV file via FileReference
			var fileRef:FileReference = new FileReference();
			fileRef.save(_baFlvEncoder.byteArray, "test.flv");			
			
			// cleanup
			_baFlvEncoder.kill();
		}
	}
}
