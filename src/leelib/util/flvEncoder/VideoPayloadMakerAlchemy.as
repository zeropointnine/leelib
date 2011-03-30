package leelib.util.flvEncoder
{
	import cmodule.flvEncodeHelper.CLibInit;
	
	import flash.display.BitmapData;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import flash.utils.Endian;

	/**
	 * Technique for Alchemy memory allocation/access comes from Bernard Visscher:
	 * http://blog.debit.nl/2009/03/using-bytearrays-in-actionscript-and-alchemy/
	 */	
	public class VideoPayloadMakerAlchemy implements IVideoPayload
	{
		private static var _alchemyLoader:CLibInit;

		private var _width:int;
		private var _height:int;
		
		private var _helper:Object;
		private var _alchemyBufferPos:uint;
		private var _baBuffer:ByteArray;
		
		public function VideoPayloadMakerAlchemy()
		{
			
			if (!_alchemyLoader) _alchemyLoader = new CLibInit();

			_helper = _alchemyLoader.init();
			if (! _helper) throw new Error("Bad Alchemy build?");
		}
		
		public function init($width:int, $height:int):void
		{
			_width = $width;
			_height = $height;

			_alchemyBufferPos = _helper.initBuffer($width, $height);
			var ns:Namespace = new Namespace("cmodule.flvEncodeHelper");
			_baBuffer = (ns::gstate).ds;
		}
		
		public function make($bitmapData:BitmapData):ByteArray
		{
			var w:int = $bitmapData.width;
			var h:int = $bitmapData.height;

			var baResult:ByteArray = new ByteArray();

			// VIDEODATA 'header' - frametype (1) + codecid (3)
			baResult.writeByte(0x13); 
			
			// SCREENVIDEOPACKET 'header' 
			FlvEncoder.writeUI4_12(baResult, int(FlvEncoder.BLOCK_WIDTH/16) - 1,  w); // blockwidth/16-1 (4bits) + imagewidth (12bits)
			FlvEncoder.writeUI4_12(baResult, int(FlvEncoder.BLOCK_HEIGHT/16) - 1, h);	// blockheight/16-1 (4bits) + imageheight (12bits)			
			
			// IMAGEBLOCKS
			
			// Make byteArray of bitmapData
			var baBitmap:ByteArray = $bitmapData.getPixels(new Rectangle(0,0,$bitmapData.width,$bitmapData.height));

			// Write byteArray to alchemy buffer
			_baBuffer.position = _alchemyBufferPos;
			_baBuffer.writeBytes(baBitmap);
			
			baBitmap.position = 0;
			baBitmap = null;

			// Process data in alchemy
			var baImg:ByteArray = new ByteArray();
			var baIdx:ByteArray = new ByteArray();
			
			_helper.makeImageBlocks(baImg, baIdx);
			
			// Parse data and write to byteArray
			writeAlchemyDataTo(baResult, baImg, baIdx);

			baImg.position = 0;
			baImg = null;
			baIdx.position = 0;
			baIdx = null;
			
			return baResult;
		}
		
		public function kill():void
		{
			_helper.clear();
		}		
		
		/**
		 * @param $baVideo		ByteArray being added to 
		 * @param $baAlchemy	The processed but still uncompressed video frame data coming out of the Alchemy routine
		 * @param $baIndices	Indices (unsigned shorts) of byteArray positions of each chunk in the $baAlchemy ByteArray. 
		 */		
		private function writeAlchemyDataTo($baVideo:ByteArray, $baAlchemy:ByteArray, $baIndices:ByteArray):void
		{
			$baAlchemy.position = 0;
			var cursor:int = 0;
			
			$baIndices.endian = Endian.BIG_ENDIAN;
			$baIndices.position = 0;
			
			var block:ByteArray = new ByteArray();
			
			while ($baIndices.position < $baIndices.length-1)
			{
				var numBytes:int = $baIndices.readUnsignedShort();
				block.length = 0;
				block.writeBytes($baAlchemy, cursor, numBytes);
				block.compress();
				
				FlvEncoder.writeUI16($baVideo, block.length); 	// write block length (UI16)
				$baVideo.writeBytes( block ); 					// write block
				
				cursor += numBytes;
			}
		}
	}
}
