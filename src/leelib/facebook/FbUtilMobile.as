package leelib.facebook
{
	import flash.data.EncryptedLocalStore;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.Stage;
	import flash.errors.IOError;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.external.ExternalInterface;
	import flash.geom.Matrix;
	import flash.media.StageWebView;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.net.navigateToURL;
	import flash.system.LoaderContext;
	import flash.system.SecurityDomain;
	import flash.utils.ByteArray;
	import flash.utils.setTimeout;
	
	import leelib.ExtendedEvent;
	import leelib.MyEvents;
	import leelib.util.Out;
	import leelib.util.Service;
	import leelib.util.StringUtil;
	
	/**
	 * 'Forked' from FbUtil.as for mobile use.
	 * 
	 * USAGE:
	 * 
	 * 	[1] Call FbUtilMobile.init(...) to populate the necessary values.
	 * 	[2] Then call login(), and listen for return event.
	 * 
	 */
	public class FbUtilMobile extends EventDispatcher
	{
		public static const REQUESTTYPE_INFO:String 		= "REQUESTTYPE_Info";
		public static const REQUESTTYPE_LIKES:String		= "REQUESTTYPE_Likes";
		public static const REQUESTTYPE_FRIENDS:String 		= "REQUESTTYPE_Friends";
		public static const REQUESTTYPE_ALBUMLIST:String 	= "REQUESTTYPE_Albums";
		public static const REQUESTTYPE_IMAGELIST:String 	= "REQUESTTYPE_ImageList";
		public static const REQUESTTYPE_FEED:String			= "REQUESTTYPE_Feed";
		
		public static var EVENT_AUTHCHECK_RESULT:String = "FbUtilMobile.EventAuthCheck";
		public static var EVENT_LOGIN_RESULT:String = "FbUtilMobile.EventLoginResult";
		
		public static var RESULT_YES:String = "yes";
		public static var RESULT_NO:String = "no";
		public static var RESULT_ERROR:String = "error";
		
		[Embed(source="fbDefaultThumb.gif")] // (note how this file is in source directory)
		public static const ClsFbDefaultThumb:Class;
		
		private static var _instance:FbUtilMobile;
		
		private var _loginSwv:StageWebView;
		private var _stage:Stage;
		
		private var _fbAuthUrl:String;
		private var _fbGetTokenUrl:String;
		private var _graphUrl:String; 
		private var _deauthUrl:String;
		
		private var _clientId:String;
		private var _clientSecret:String;
		private var _loginRedirectUri:String; 
		private var _scope:String;
		private var _popupFunction:*;
		
		private var _postSwv:StageWebView;
		private var _postRedirectUri:String;
		
		private var _accessToken:String;
		
		private var _service:Service;
		private var _urlLoader:URLLoader;
		private var _loader:Loader;
		
		private var _requestCallback:Function;
		private var _postCallback:Function;
		private var _loadImageCallback:Function;
		private var _loadImagesCallback:Function
		private var _queuedImageVos:Array;
		
		private var _user:FbUserVo;
		
		private var _deauthSwv:StageWebView;
		private var _deauthCallbackUrl:String;
		
		
		public function FbUtilMobile($enforcer:SingletonEnforcer)
		{
			_user = new FbUserVo();
			_service = new Service();
			_loader = new Loader();
			
			_graphUrl= "https://graph.facebook.com/"; 
			_fbAuthUrl = "https://graph.facebook.com/oauth/authorize";
			_fbGetTokenUrl = "https://graph.facebook.com/oauth/access_token";
			_deauthUrl = "https://www.facebook.com/logout.php";
			
			var ba:ByteArray = EncryptedLocalStore.getItem("fbAccessToken")
			if (ba && ba.length > 0) {
				_accessToken = ba.readUTF();
			}
			Out.i("Fb token", _accessToken);
		}
		
		public static function getInstance():FbUtilMobile 
		{
			if (_instance == null) _instance = new FbUtilMobile(new SingletonEnforcer());
			return _instance;
		}
		
		public function get user():FbUserVo
		{
			return _user;
		}
		
		public function get isLoggedIn():Boolean
		{
			return Boolean(_user.id);
		}
		
		public function init($clientId:String, $secret:String, $scope:String):void
		{
			_clientId = $clientId;
			_clientSecret = $secret;
			_scope = $scope;
		}
		
		// TODO
		public function doAuthCheck():void
		{
			if (! _accessToken) {
				this.dispatchEvent(new ExtendedEvent(EVENT_AUTHCHECK_RESULT, RESULT_NO));
				return;
			}
			request("", REQUESTTYPE_INFO, onAuthCheckResult);			
		}
		
		private function onAuthCheckResult($o:Object):void
		{
			if (! $o) {
				this.dispatchEvent(new ExtendedEvent(EVENT_AUTHCHECK_RESULT, RESULT_NO));
				return;
			}
			
			var user:FbUserVo = new FbUserVo();
			user.parseUserInfo($o);
			if (! user.id) {
				this.dispatchEvent(new ExtendedEvent(EVENT_AUTHCHECK_RESULT, RESULT_NO));
			}
			else {
				this.dispatchEvent(new ExtendedEvent(EVENT_AUTHCHECK_RESULT, RESULT_YES));
			}
			user = null;
		}
		
		/**
		 * Starts chain of async functions, including getting user's info and friends.
		 * redirectUrl must match with that in the Facebook App settings.
		 * Sends back ExtendedEvent EVENT_LOGIN_RESULT with string value of AUTHRESULT_[OK | DENIED | ERROR]
		 * 
		 * Now how webview and pinwheel visibility does get managed here. 
		 */
		public function login($swv:StageWebView, $stage:Stage, $redirectUri:String):void
		{
			clearAuthListeners();
			
			_loginSwv = $swv;
			_stage = $stage;
			_loginSwv.stage = _stage;
			
			_loginRedirectUri = $redirectUri;
			
			// Show authorize webview
			
			var url:String = _fbAuthUrl + "?client_id=" + _clientId + "&redirect_uri=" + _loginRedirectUri;			
			if (_scope) url += "&scope="+ _scope;
			url = encodeURI(url);
			
			_loginSwv.addEventListener(Event.LOCATION_CHANGE, onLoginSwvLocationChange);
			_loginSwv.loadURL(url);
		}
		
		private function onLoginSwvLocationChange(event:Event):void
		{
			var url:String = event.currentTarget.location as String;
			if (url.indexOf(_loginRedirectUri) != 0) return;
			
			Out.d("onLocationChange", url);
			_loginSwv.removeEventListener(Event.LOCATION_CHANGE, onLoginSwvLocationChange);
			_loginSwv.stage = null;
			_loginSwv = null;
			
			// Get code from url...
			
			var o:Object = StringUtil.getQueryStringObject(url);
			if ( o["error"] || o["error_reason"] ) 
			{
				// eg, "error=invalid_scope"; "error_reason=user_denied"
				Out.e("FbUtilMobile.onLocationChange:", ( o["error"] || o["error_reason"] ) );
				this.dispatchEvent(new ExtendedEvent(EVENT_LOGIN_RESULT, RESULT_ERROR));
				return;
			}
			
			// TODO: look for user_denied
			
			var code:String = o["code"];
			if (! code) {
				Out.e("FbUtilMobile.onLocationChange - no code in qsp?");
				this.dispatchEvent(new ExtendedEvent(EVENT_LOGIN_RESULT, RESULT_ERROR));
				return;
			}
			
			_stage.dispatchEvent(new Event(MyEvents.EVENT_PINWHEELSHOW, true));
			getToken(code);
		}
		
		private function getToken($code:String):void
		{
			// Get token from Facebook
			
			_service.addEventListener(IOErrorEvent.IO_ERROR, onGetTokenError);
			_service.addEventListener(Event.COMPLETE, onGetToken);
			
			var url:String = _fbGetTokenUrl + "?client_id=" + _clientId + "&redirect_uri=" + _loginRedirectUri + "&client_secret=" + _clientSecret + "&code=" + $code;
			_service.request(url,null,"GET",Service.RETURNTYPE_STRING );
		}
		private function onGetTokenError($e:IOErrorEvent):void
		{
			Out.e('FbUtilMobile.onGetTokenError() -' + $e.text);
			clearAuthListeners();
			_stage.dispatchEvent(new Event(MyEvents.EVENT_PINWHEELHIDE, true));
			this.dispatchEvent(new ExtendedEvent(EVENT_LOGIN_RESULT, RESULT_ERROR));
		}
		private function onGetToken($e:ExtendedEvent):void
		{
			clearAuthListeners();
			
			var s:String = $e.object as String;
			if (! s) {
				Out.e('FbUtilMobile.onGetToken() - blank response');
				_stage.dispatchEvent(new Event(MyEvents.EVENT_PINWHEELHIDE, true));
				this.dispatchEvent(new ExtendedEvent(EVENT_LOGIN_RESULT, RESULT_ERROR));
				return;
			}
			
			var o:Object = StringUtil.getQueryStringObject(s);
			_accessToken = o["access_token"];
			if (! _accessToken)
			{
				Out.e('FbUtilMobile.onGetToken() - no token');
				_stage.dispatchEvent(new Event(MyEvents.EVENT_PINWHEELHIDE, true));
				this.dispatchEvent(new ExtendedEvent(EVENT_LOGIN_RESULT, RESULT_ERROR));
				return;
			}
			Out.d('FbUtilMobile - token:', _accessToken);
			
			// save the token			
			var ba:ByteArray = new ByteArray();
			ba.writeUTF(_accessToken);
			EncryptedLocalStore.setItem("fbAccessToken", ba);
			
			// get user info
			request("", REQUESTTYPE_INFO, onRequestInfo);
		}
		
		private function onRequestInfo($o:Object):void
		{
			_user.parseUserInfo($o);
			
			if (! _user.id || _user.id.length == 0) {
				Out.e('FbUtilMobile.onRequestInfo() - no user id');
				_stage.dispatchEvent(new Event(MyEvents.EVENT_PINWHEELHIDE, true));
				this.dispatchEvent(new ExtendedEvent(EVENT_LOGIN_RESULT, RESULT_ERROR));
			}
			
			// get friends
			request(_user.id, REQUESTTYPE_FRIENDS, onRequestFriends);
		}
		
		private function onRequestFriends($o:Object):void
		{
			_user.parseFriends($o);
			_stage.dispatchEvent(new Event(MyEvents.EVENT_PINWHEELHIDE, true));
			this.dispatchEvent(new ExtendedEvent(EVENT_LOGIN_RESULT, RESULT_YES));
		}
		
		public function clearAuthListeners():void
		{
			if (_loginSwv) _loginSwv.removeEventListener(Event.LOCATION_CHANGE, onLoginSwvLocationChange);
			_service.removeEventListener(IOErrorEvent.IO_ERROR, onGetTokenError);
			_service.removeEventListener(Event.COMPLETE, onGetToken);
			_service.removeEventListener(IOErrorEvent.IO_ERROR, onRequestError);
			_service.removeEventListener(Event.COMPLETE, onRequest);
		}
		
		// END OF AUTH SEQUENCE
		// =============================================
		
		/*
		
		private function loadProfileThumb():void
		{
		loadImage(_user.id, onLoadProfileThumb, "square");
		}
		private function onLoadProfileThumb($image:Bitmap):void
		{
		if ($image && $image.bitmapData) {
		_user.profileImageSquare = $image.bitmapData;
		}
		else {
		// Don't complain
		// _authErrorMessages += "Error getting profile image\n";
		}
		
		}
		
		finishAuth(); // ... done
		
		
		
		request(_user.id, REQUESTTYPE_LIKES, onRequestLikes);
		
		private function onRequestLikes($o:Object):void
		{
		_user.parseLikes($o);
		// ...
		}
		
		
		
		request(_user.id, REQUESTTYPE_FEED, onRequestWall);
		
		private function onRequestWall($o:Object):void
		{
		_user.parseFeedForFriendActivity($o);
		}
		
		
		
		request(_user.id, REQUESTTYPE_ALBUMLIST, onRequestAlbums);
		
		private function onRequestAlbums($o:Object):void
		{
		_user.parseAlbumList($o);
		
		// pick album with most items
		if (_user.getBiggestAlbum()) {
		request(_user.getBiggestAlbum().id, REQUESTTYPE_IMAGELIST, onRequestImageList);
		}
		else {
		loadImage(_user.id, onLoadProfileThumb);
		}
		}
		
		private function onRequestImageList($o:Object):void
		{
		if (! user.getBiggestAlbum()) {
		trace('FbUtilMobile.onRequestImageList - No albums.');
		loadProfileThumb();
		return;
		}
		
		//
		
		user.getBiggestAlbum().parsePhotos($o);
		loadImages( user.getBiggestAlbum().imageVos, loadProfileThumb );
		}
		
		private function loadProfileThumb():void
		{
		loadImage(_user.id, onLoadProfileThumb);
		}
		private function onLoadProfileThumb($image:Bitmap):void
		{
		if ($image && $image.bitmapData)
		_user.profilePic = $image.bitmapData;
		else
		_authorizeMessage += "Error getting profile image\n";
		
		//$image.width = 64;
		//$image.scaleY = $image.scaleX;
		//$image.x = $image.y = 10;
		//Global.getInstance().stage.addChild($image);
		
		_user.isDataPopulated = true;
		
		this.dispatchEvent(new ExtendedEvent(Event.COMPLETE, { message:_authorizeMessage } ) );
		}
		*/
		
		// END 
		// =============================================
		
		public function deauth($callbackUrl:String):void
		{
			if (! _accessToken) {
				Out.w("FbUtilMobile.deauth() - access token is null");
				return;				
			}
			
			if (! _deauthSwv) _deauthSwv = new StageWebView();
			_deauthCallbackUrl = $callbackUrl;
			_deauthSwv.addEventListener(Event.LOCATION_CHANGE, onDeauthLocationChange);
			var url:String = _deauthUrl + "?" + "next=" + $callbackUrl + "&" + "access_token=" + _accessToken; 
			url = encodeURI(url);
			_deauthSwv.loadURL(url);
		}
		private function onDeauthLocationChange($e:Event):void
		{
			var url:String = $e.currentTarget.location as String;
			if (url.indexOf(_deauthCallbackUrl) != 0) return;
			
			// Reaching here means deauth happened
			
			_deauthSwv.removeEventListener(Event.LOCATION_CHANGE, onDeauthLocationChange);
			_deauthSwv = null;
			
			_accessToken = null;
			EncryptedLocalStore.setItem("fbAccessToken", new ByteArray());
		}
		
		//
		
		public function request($id:String, $REQUESTTYPE:String, $callback:Function):void
		{
			_requestCallback = $callback;
			
			var s:String;
			switch($REQUESTTYPE) {
				case REQUESTTYPE_INFO:		s = ""; break; 
				case REQUESTTYPE_LIKES:		s = "likes"; break; 
				case REQUESTTYPE_FRIENDS:	s = "friends"; break;
				case REQUESTTYPE_ALBUMLIST:	s = "albums"; break;
				case REQUESTTYPE_IMAGELIST:	s = "photos"; break;
				case REQUESTTYPE_FEED:		s = "feed"; break;
			}
			
			_service.addEventListener(Event.COMPLETE, onRequest);
			_service.addEventListener(IOErrorEvent.IO_ERROR, onRequestError);
			
			if ($REQUESTTYPE == REQUESTTYPE_INFO) {
				_service.request(_graphUrl + "me", { "access_token":_accessToken } );
			}
			else {
				_service.request(_graphUrl + $id + "/" + s, { "access_token":_accessToken } );
			}
		}
		
		private function onRequest($e:ExtendedEvent):void
		{
			_service.removeEventListener(Event.COMPLETE, onRequest);
			_service.removeEventListener(IOErrorEvent.IO_ERROR, onRequestError);
			
			var fn:Function = _requestCallback;
			_requestCallback = null;
			fn($e.object);
		}
		
		private function onRequestError($e:IOErrorEvent):void
		{
			_service.removeEventListener(Event.COMPLETE, onRequest);
			_service.removeEventListener(IOErrorEvent.IO_ERROR, onRequestError);
			
			Out.e('FbUtilMobile.onRequestError() (fail gracefully)', $e.text);
			var fn:Function = _requestCallback;
			_requestCallback = null;
			fn(null);
		}
		
		//
		
		/**
		 * User icons don't need access token qsp
		 */
		public function makeImageUrl($id:String, $type:String="large", $withToken:Boolean=true):String
		{
			var url:String = _graphUrl + $id + "/picture" + "&" + "type=" + $type;
			if ($withToken) url += "&" + "access_token=" + _accessToken;
			return url;
		}
		
		//
		
		public function loadImage($id:String, $callback:Function, $type:String="large"):void // small | normal | large | square
		{
			_loadImageCallback = $callback;
			
			_loader = new Loader();
			var lc:LoaderContext = new LoaderContext();
			lc.checkPolicyFile = true;
			lc.securityDomain = SecurityDomain.currentDomain;
			
			var url:String = makeImageUrl($id, $type);
			Out.i('FbUtilMobile.loadImage()', url);
			_loader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onLoadImageSecurityError);
			_loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onLoadImageIoError);
			_loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoadImage);
			_loader.load( new URLRequest(url), lc );
		}
		
		private function onLoadImageSecurityError($e:SecurityErrorEvent):void
		{
			// this can happen, eg, when facebook returns the default user profile pic, which is on a different domain 
			
			_loader.contentLoaderInfo.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onLoadImageSecurityError);
			_loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onLoadImageIoError);
			_loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onLoadImage);
			
			Out.e('onLoadImageSecurityError()', $e.text);
			_loadImageCallback(null);
		}
		
		private function onLoadImageIoError($e:IOErrorEvent):void
		{
			_loader.contentLoaderInfo.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onLoadImageSecurityError);
			_loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onLoadImageIoError);
			_loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onLoadImage);
			
			Out.e('onLoadImageIoError()', $e.text);
			_loadImageCallback(null);
		}
		
		private function onLoadImage(e:Event):void
		{
			_loader.contentLoaderInfo.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onLoadImageSecurityError);
			_loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onLoadImageIoError);
			_loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onLoadImage);
			
			var b:Bitmap = e.target.content as Bitmap;
			_loadImageCallback(b); // * Callback takes image as argument
		}
		
		//
		
		public function loadImages($arrayOfImageVos:Array, $callback:Function, $max:int=5):void
		{
			_loadImagesCallback = $callback;
			
			_queuedImageVos = [];
			var num:int = Math.min($arrayOfImageVos.length, $max);
			if (num == 0) { 
				_loadImagesCallback();
				return;
			}
			
			//
			
			for (var i:int = 0; i < num; i++) { // 'clone' array
				_queuedImageVos[i] = $arrayOfImageVos[i];
			}
			
			loadImages_2();
		}
		private function loadImages_2():void
		{
			var vo:ImageVo = _queuedImageVos[0];
			loadImage(vo.id, loadImages_3, "normal");
		}
		private function loadImages_3($b:Bitmap):void
		{
			var vo:ImageVo = _queuedImageVos.shift();
			vo.bitmap = $b;
			
			if (!$b) Out.e('FbUtilMobile.onLoadAlbumImage() - NO BITMAP');
			
			if (_queuedImageVos.length > 0) { 
				loadImages_2();
			}
			else {
				_loadImagesCallback();
			}
		}
		
		
		/**
		 * Nothing special, basically just a regular POST
		 *  
		 * @param $id
		 * @param $params
		 * @param $callback
		 */		
		public function post($id:String, $params:Object, $callback:Function):void
		{
			// http://developers.facebook.com/docs/reference/api/post/
			
			_postCallback = $callback;
			
			var url:String = _graphUrl + $id + "/feed";
			
			var urlReq:URLRequest = new URLRequest(url);
			urlReq.method = URLRequestMethod.POST;
			
			var urlVars:URLVariables = new URLVariables();
			for ( var key:* in $params ) { 
				urlVars[key] = $params[key];
			}
			urlVars["access_token"] = _accessToken;
			
			// TEST - ACTIONS - THIS WORKS:
			// urlVars["actions"] = "{ 'name':'Action1', 'link':'http://www.yahoo.com' }";
			
			// TEST - PROPERTIES... NOT WORKING?
			// urlVars["properties"] = { "search engine:" : { "text" : "Text", "href" : "http://www.yahoo.com" } }
			
			urlReq.data = urlVars;
			
			var urlLoader:URLLoader = new URLLoader(urlReq);
			urlLoader.dataFormat = URLLoaderDataFormat.TEXT;
			
			urlLoader.addEventListener(Event.COMPLETE, onPostComplete); 
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, onPostError);
			
			urlLoader.load(urlReq); 
		}
		
		private function onPostError($e:IOErrorEvent):void
		{
			$e.target.removeEventListener(Event.COMPLETE, onPostComplete); 
			$e.target.removeEventListener(IOErrorEvent.IO_ERROR, onPostError);
			
			var fn:Function = _postCallback;
			_postCallback = null;
			fn( new FbUtilEvent(false, $e.text) );
		}
		
		private function onPostComplete($e:Event):void
		{
			$e.target.removeEventListener(Event.COMPLETE, onPostComplete); 
			$e.target.removeEventListener(IOErrorEvent.IO_ERROR, onPostError);
			
			var s:String = $e.target.data;
			
			// TODO: need to parse result for errors or whatevr
			
			Out.d('FBUtil - post result:\r' + s);
			
			var fn:Function = _postCallback;
			_postCallback = null;
			fn( new FbUtilEvent(true, null) );
		}
		
		//
		
		public function doPostToFeedDialog($swv:StageWebView, $stage:Stage, $redirectUri:String):void
		{
			/*
			http://www.facebook.com/dialog/feed?
			app_id=123050457758183&
			link=http://developers.facebook.com/docs/reference/dialogs/&
			picture=http://fbrell.com/f8.jpg&
			name=Facebook%20Dialogs&
			caption=Reference%20Documentation&
			description=Using%20Dialogs%20to%20interact%20with%20users.&
			redirect_uri=http://www.example.com/response			
			*/
			
			_postSwv = $swv;
			_stage = $stage;
			_postRedirectUri = $redirectUri;
			
			_postSwv.stage = _stage; 
			
			var url:String = "http://www.facebook.com/dialog/feed?app_id=" + _clientId + 
				"&link=http://clients.zeropointnine.com/uploadr/hello.gif" +
				"&picture=https://lh3.ggpht.com/AKM0Oadc6oTTBb1aB0Pb8GzDPfRt7i3Ha8gABaorfKeuUimkj-izEiPo0LyEjQPnDsfM=w609-h297" +
				"&name=My%20Caption" +
				"&caption=My%20Title" + 
				"&description=My%20description" +
				"&redirect_uri=" + _postRedirectUri + 
				"&display=touch";
			
			Out.i(url);
			
			_postSwv.addEventListener(Event.LOCATION_CHANGE, onPostDialogSwvLocationChange);
			_postSwv.loadURL(url);
		}
		private function onPostDialogSwvLocationChange(event:Event):void
		{
			var url:String = event.currentTarget.location as String;
			if (url.indexOf(_postRedirectUri) != 0) return;
			
			Out.d("onPostDialogSwvLocationChange", url);
			_postSwv.removeEventListener(Event.LOCATION_CHANGE, onPostDialogSwvLocationChange);
			_postSwv.stage = null;
			_postSwv = null;
			
		}
		
	}
}

class SingletonEnforcer {}
