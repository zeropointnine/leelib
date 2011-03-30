package leelib.util.flvEncoder
{
	import flash.filesystem.File;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;

	/**
	 * Encodes FLV's into a FileStream
	 */
	public class FileStreamFlvEncoder extends FlvEncoder
	{
		private var _file:File;
		private var _fileStream:ByteableFileStream;
		
		
		public function FileStreamFlvEncoder($file:File, $frameRate:Number)
		{
			_file = $file;
			super($frameRate);
		}
		
		public function get fileStream():FileStream
		{
			return _bytes as FileStream;
		}
		
		public function get file():File
		{
			return _file;
		}

		public override function kill():void
		{
			super.kill();
		}
		
		protected override function makeBytes():void
		{
			_bytes = new ByteableFileStream(_file);
			_fileStream = _bytes as ByteableFileStream;
		}
		
	}
}