package leelib.util.flvEncoder
{
	import flash.errors.IllegalOperationError;
	import flash.filesystem.File;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;

	
	public class ByteableFileStream extends FileStream implements IByteable
	{
		private var _file:File;
		
		
		public function ByteableFileStream($file:File)
		{
			_file = $file;
			super();
		}
		
		public function get pos():Number
		{
			return this.position;
		}
		public function set pos($pos:Number):void
		{
			this.position = uint($pos);
		}
		
		public function get len():Number
		{
			return _file.size;
		}
		
		public function kill():void
		{
		}
	}
}
