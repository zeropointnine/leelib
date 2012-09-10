package leelib
{
	import com.greensock.plugins.AutoAlphaPlugin;
	import com.greensock.plugins.TweenPlugin;
	
	import flash.display.BitmapData;
	import flash.display.Stage;
	import flash.events.EventDispatcher;
	import flash.filesystem.File;
	import flash.filters.BitmapFilter;
	import flash.filters.DropShadowFilter;
	import flash.net.URLRequest;
	import flash.net.registerClassAlias;
	import flash.system.Capabilities;
	import flash.text.Font;
	import flash.text.StyleSheet;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.ByteArray;
	
	import leelib.facebook.FbUtilMobile;
	import leelib.loadUtil.LoadUtil;
	import leelib.ui.Component;
	import leelib.util.AirUtil;
	import leelib.util.DateUtil;
	import leelib.util.IOutPrint;
	import leelib.util.Out;
	import leelib.util.TextFieldUtil;
	
	import leelib.managers.NavManager;
	
	


	/**
	 * GlobapApp is for globals
	 * Holds app settings and utilities, etc.
	 * 
	 * Also any app objects that need to persist between screens (eg, mySnaps)
	 */
	public class GlobalApp extends EventDispatcher
	{
		private static var _instance:GlobalApp;
		private static const FB_APP_ID:String = "157939031003411";
		private static const FB_SECRET:String = "fcc3668b87877ee691628847a707328c";
		private static const FB_SCOPE:String = "user_photos,publish_stream";

		private static const SERVICES_BASEPATH:String = "http://clients.zeropointnine.com/adcol/";

		private static var _appType:String;
		private static var _stage:Stage;
		
		// displayobjects
		public var appRef:*;
		public var titleBar:*;
		public var titleBarBd:BitmapData; // used by PhotoTake, too
		public var bottomBar:*;
		public var rootComponent:Component;
		public var debugTf:TextField;
		
		public var titleDropShadow:DropShadowFilter;
		
		// file paths
		public static var bakedDirPath:String;
		public static var photosCachePath:String;
		public static var iconsCachePath:String;
		public static var slotsCachePath:String;
		public static var appCachePath:String;
		public static var meFilePath:String;
		public static var viewStateFilePath:String;
		
		// util objects
		private var _fbUtil:FbUtilMobile;		
	
		private var _navMan:NavManager;
		
		public var appLoadUtil:LoadUtil;
		public var photosLoadUtil:LoadUtil;

		public var iconLoadUtil:LoadUtil;
		public static var strings:Object;
		
		// some state variables		
		public static var scaleI4:Number;
		public var isActivated:Boolean;
		public var activateTime:Number;
		
		// 'inter-screen' variables
		public var mySnapBitmaps:Vector.<BitmapData>;

		
		public function GlobalApp(enforcer:SingletonEnforcer)
		{
			initFirst();
		}
		
		public static function get globalApp():GlobalApp
		{
			if(GlobalApp._instance == null) 
				GlobalApp._instance = new GlobalApp(new SingletonEnforcer());
			return GlobalApp._instance;
		}
		
		public function initFirst():void
		{
			_appType = AirUtil.getAirAppType();

			// paths

			if (_appType == AirUtil.APPTYPE_DEVICE_IOS)
			{
				// For iOS, any cache-related files are going in [app]/Library/Caches/... (appstore guidelines)
				
				bakedDirPath 		= File.userDirectory.nativePath + "/Library/Caches/resized/";
				
				photosCachePath 	= File.userDirectory.nativePath + "/Library/Caches/photoscache/";
				iconsCachePath 		= File.userDirectory.nativePath + "/Library/Caches/iconcache/";
				slotsCachePath 		= File.userDirectory.nativePath + "/Library/Caches/slotscache/";
				appCachePath 		= File.userDirectory.nativePath + "/Library/Caches/appcache/";
				
				meFilePath 			= File.applicationStorageDirectory.nativePath + "/prefs.bin"
				viewStateFilePath 	= File.applicationStorageDirectory.nativePath + "/viewstate.bin";
			}
			else
			{
				// For Android, any cache-related files are going in /data/data/[app]/... to avoid sdcard dependencies
				
				bakedDirPath 		= File.applicationStorageDirectory.nativePath + "/resized/";
				
				photosCachePath		= File.applicationStorageDirectory.nativePath + "/photoscache/";
				iconsCachePath 		= File.applicationStorageDirectory.nativePath + "/iconcache/";
				slotsCachePath 		= File.applicationStorageDirectory.nativePath + "/slotscache/";
				appCachePath 		= File.applicationStorageDirectory.nativePath + "/appcache/";
				
				meFilePath 			= File.applicationStorageDirectory.nativePath + "/prefs.bin"
				viewStateFilePath 	= File.applicationStorageDirectory.nativePath + "/viewstate.bin";
			}
			

			
			Out.i("");
			Out.i("G.initFirst() - bakedDirUrl", bakedDirPath);
			Out.i("G.initFirst() - photosCachePath", photosCachePath);
			Out.i("G.initFirst() - iconsCachePath", iconsCachePath);
			Out.i("G.initFirst() - slotsCachePath", slotsCachePath);
			Out.i("G.initFirst() - appCachePath", appCachePath);
			Out.i("G.initFirst() - meFilePath", meFilePath);
			Out.i("G.initFirst() - viewStateFilePath", viewStateFilePath);
			Out.i("");
		}
		
		
		
		public function get stage():Stage
		{
			return _stage;
		}
		public function set stage($stage:Stage):void
		{
			_stage = $stage;
		}
		
		public static function get stage():Stage
		{
			return _stage;
		}
		public static function set stage($stage:Stage):void
		{
			_stage = $stage;
			GlobalApp.globalApp.stage = stage;
		}
		
		public function initPostStage():void
		{

		}
		

		
		// STATIC GETTERS

		/**
		 * Return percentage of stage width
		 */ 
		public static function pw($percent:Number):Number
		{
			return $percent * _stage.stageWidth;
		}
		
		/**
		 * Return percentage of stage height
		 * Should not be mixed and matched with pw() if you get my meaning
		 */
		public static function ph($percent:Number):Number
		{
			return $percent * _stage.stageHeight;
		}
		
		/**
		 * Convert pixels from iPhone4 to that of current device, based on device width
		 */
		public static function pi($iPhone4Pixels:Number):Number
		{
			return $iPhone4Pixels * scaleI4;
		}

		// Same, but rounded
		public static function pii($iPhone4Pixels:Number):int
		{
			return Math.round($iPhone4Pixels * scaleI4);
		}
		
		// GETTERS, SETTERS
		
		public static function get isIosDevice():Boolean
		{
			return (_appType == AirUtil.APPTYPE_DEVICE_IOS);
		}
		
		public static function get isAndroidDevice():Boolean
		{
			return (_appType == AirUtil.APPTYPE_DEVICE_ANDROID);
		}
		
		public static function get isSimulator():Boolean
		{
			return (_appType == AirUtil.APPTYPE_SIMULATOR);
		}
		
		public static function get isSystemSpanish():Boolean
		{
			return (Capabilities.language.toLowerCase().indexOf("es") == 0) 
		}

		public function get navManager():NavManager
		{
			return NavManager.instance;
		}
		
		public function get fbUtil():FbUtilMobile
		{
			return _fbUtil;
		}

		public static function sourceUrlRequest($filename:String):URLRequest
		{
			return new URLRequest(Constants.PACKAGEDIR_URL + $filename);
		}
		
		public function doLogout():void
		{
			// remove person details
		
		}
	}
}

class SingletonEnforcer {}
