package leelib.util
{
	import flash.filesystem.File;
	import flash.net.URLRequest;
	import flash.system.Capabilities;

	public class AirUtil
	{
		public function AirUtil()
		{
		}
		
		public static function printDirectory($f:File, $recursive:Boolean=false):void
		{
			if (! $f.exists) { Out.i("AirUtil.printDirectory() - does not exist: ", $f.url); return; }
			if (! $f.isDirectory) { Out.i("AirUtil.printDirectory() - not a directory:", $f.url); return; }
			
			Out.i("");
			Out.i("------------------------------------------------------------------------------------");
			Out.i("AirUtil.printDirectory() - url:", $f.url);
			
			var a:Array = $f.getDirectoryListing();
			for (var i:int = 0; i < a.length; i++)
			{
				var f:File = a[i];
				var s:String = f.url + " " + f.size + " isDir:" + f.isDirectory;
				Out.i(s);
			}
			Out.i("------------------------------------------------------------------------------------");
			Out.i("");
		}
		public static function printDirectoryByUrl($url:String, $recursive:Boolean=false):void
		{
			var f:File = new File();
			try {
				f.url = $url;
			}
			catch (e:Error) {
				Out.e("AirUtil.printDirectoryByUrl() - BAD URL", $url);
				return;
			}
			
			printDirectory(f, $recursive);
		}
			

		// Delete the file contents of a directory
		//
		public static function deleteFilesInDirectoryUrl($fileUrl:String):void
		{
			var f:File = new File();
			try {
				f.url = $fileUrl;
			}
			catch (e:Error) {
				Out.w("AirUtil.deleteDirectoryFiles() - INVALID URL:", $fileUrl);
				return;
			}
			if (! f.exists) {
				Out.w("AirUtil.deleteDirectoryFiles() - DIRECTORY DOES NOT EXIST AT URL:", $fileUrl);
				return;
			}
			if (! f.isDirectory) {
				Out.w("AirUtil.deleteDirectoryFiles() - IS FILE, NOT DIRECTORY:", $fileUrl);
				return;
			}
			
			Out.i("");
			Out.i("------------------------------------------------------------------------------------");
			Out.i("AirUtil.deleteDirectoryFiles() - url:", f.url);
			var a:Array = f.getDirectoryListing();
			for each (var f2:File in a) {
				Out.d('- deleting', f.url);
				try {
					f2.deleteFile();
				}
				catch (e:Error) {
					Out.e("AirUtil.deleteDirectoryContents() - COULN'T DELETE FILE:", e.message);
				}
			}
			Out.i("------------------------------------------------------------------------------------");
			Out.i("");
		}
		
		public static function nativePathToUrl($path:String):String
		{
			return new File($path).url;
		}
		
		public static function nativePathToUrlRequest($path:String):URLRequest
		{
			return new URLRequest( new File($path).url );
		}
		
		//
		
		public static const APPTYPE_DEVICE_ANDROID:String = "androidDevice";
		public static const APPTYPE_DEVICE_IOS:String = "iosDevice";
		public static const APPTYPE_SIMULATOR:String = "simulator";

		public static function getAirAppType():String
		{
			// ios device test
			
			if (Capabilities.os.toLowerCase().indexOf("iphone") == 0) return APPTYPE_DEVICE_IOS; // this one's pretty sure
			
			// android device test
			
			// simulator could show "linux" too of course, but whatevr
			// simulator can show "and", of course
			// testing for cpu == ARM not great, since Android is on x86, too
			
			if (Capabilities.version.toLowerCase().indexOf("and") == 0 && Capabilities.os.toLowerCase().indexOf("linux") == 0) return APPTYPE_DEVICE_ANDROID;
			
			// by process of elimination. not ideal.
			
			return APPTYPE_SIMULATOR;
		}

	}
}
