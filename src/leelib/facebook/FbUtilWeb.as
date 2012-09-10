package leelib.facebook
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.errors.IOError;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.external.ExternalInterface;
	import flash.geom.Matrix;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.net.navigateToURL;
	import flash.system.LoaderContext;
	import flash.system.SecurityDomain;
	import flash.utils.setTimeout;
	
	import leelib.ExtendedEvent;
	import leelib.util.Out;
	import leelib.util.Service;
	
	/**
	 * USAGE:
	 * 
	 * 	[1] Call FbUtil.init(...) to populate the necessary values.
	 * 
	 * 	[2] Then call authorize(), and listen for FbUtilEvent.EVENT
	 *
	 * 
	 *	SETUP: 
	 * 
	 * 		An external HTML page with some Javascript, which is the callback url coming from the Facebook login popup.
	 * 		It parses the querystring for the value of "code" and passes it back to the parent window.
	 * 
	 * 		The parent window (the one with the Flash) needs a Javascript function which receives the value passed 
	 * 		to it by the callback page, which then passes that value to FbUtil.onAuthorize()
	 * 
	 * 		See "FbUtil.txt" included in this package directory for sample code.
	 * 
	 * 
	 * 	In parent page:
	 *
	 *	<script>        
	 *		function setCode($s)
	 *		{
	 *			var flash = document.getElementById("flash"); 
	 *			flash.onAuthorize($s);
	 *		}
	 *	</script>
     *
	 *	... where "flash" is the id of the SWF object
	 *  
     *
	 *	 In the popup callback page:
     *		
	 *	    <script>
	 *	        var a = location.href.split("?");
	 *	        var s = a[a.length-1];
	 *	        var a2 = s.split("code=");
	 *	        var s2 = a2[a2.length-1];
	 *	        opener.setCode(s2); 
	 *	        self.close();
	 *	    </script>
     *
     *
	 * 
	 * 
	 * 
	 * TO DO:
	 * 
	 * 		Logic involving "_authorizeMessage" not fully ironed out for general request() calls after authorize sequence.
	 * 
	 */
	public class FbUtilWeb extends EventDispatcher
	{
		public static const REQUESTTYPE_INFO:String 		= "REQUESTTYPE_Info";
		public static const REQUESTTYPE_LIKES:String		= "REQUESTTYPE_Likes";
		public static const REQUESTTYPE_FRIENDS:String 		= "REQUESTTYPE_Friends";
		public static const REQUESTTYPE_ALBUMLIST:String 	= "REQUESTTYPE_Albums";
		public static const REQUESTTYPE_IMAGELIST:String 	= "REQUESTTYPE_ImageList";
		public static const REQUESTTYPE_FEED:String			= "REQUESTTYPE_Feed";
				
		private static const DEFAULT_FACEBOOK_LOGIN_POPUP:XML = <script><![CDATA[
				function ($url){
					var vars = 'resizable=yes,location=no,directories=no,status=no,menubar=no,scrollbars=no,toolbar=no,left=100,top=100,width=1000,height=550';
					window.open($url, "Facebook", vars);
				}
			]]></script>;		

		[Embed(source="fbDefaultThumb.gif")] // (note, is in source directory)
		public static const ClsFbDefaultThumb:Class;
		
		private static var _instance:FbUtilWeb;

		private var _clientId:String;
		private var _clientSecret:String;
		private var _redirectUri:String; 
		private var _fbAuthUrl:String;
		private var _fbGetTokenurl:String;
		private var _graphUrl:String; 
		private var _scope:String;
		private var _popupFunction:*;
		
		private var _code:String;
		private var _token:String;
		
		private var _errorMessages:String;
		
		private var _service:Service;
		private var _urlLoader:URLLoader;
		private var _loader:Loader;

		private var _requestCallback:Function;
		private var _postCallback:Function;
		private var _loadImageCallback:Function;
		private var _loadImagesCallback:Function
		private var _queuedImageVos:Array;
		
		private var _user:FbUserVo;
		
		
		public function FbUtilWeb($enforcer:SingletonEnforcer)
		{
			_user = new FbUserVo();
			_service = new Service();
			_loader = new Loader();
		}

		public static function getInstance():FbUtilWeb 
		{
			if (_instance == null) _instance = new FbUtilWeb(new SingletonEnforcer());
			return _instance;
		}
		
		/**
		 * @param $clientId
		 * @param $secret
		 * @param $redirectUri
		 * @param $javascriptFacebookLoginPopupFunction		The name of the Javascript popup function (or the actual function itself). Should take one argument, which is the url. If nothing is passed, default popup function will be used.
		 * @param $facebookScope
		 * @param $facebookGraphUrl
		 * @param $facebookAuthUrl
		 * @param $facebookGetTokenUrl
		 * 
		 */
		public function init(
			$clientId:String, 
			$secret:String, 
			$redirectUri:String,
			$javascriptFacebookLoginPopupFunction:* = null,
			$facebookScope:String = "read_stream,user_photos",
			$facebookGraphUrl:String = "https://graph.facebook.com/", 
			$facebookAuthUrl:String = "https://graph.facebook.com/oauth/authorize", 
			$facebookGetTokenUrl:String = "https://graph.facebook.com/oauth/access_token" 
			)
		:void
		{
			_clientId = $clientId;
			_clientSecret = $secret;
			_redirectUri = $redirectUri;
			
			_popupFunction = $javascriptFacebookLoginPopupFunction;
			if (! _popupFunction) _popupFunction = DEFAULT_FACEBOOK_LOGIN_POPUP;
			
			_scope = $facebookScope;
			_graphUrl= $facebookGraphUrl; 
			_fbAuthUrl = $facebookAuthUrl;
			_fbGetTokenurl = $facebookGetTokenUrl;
		}
		
		public function get user():FbUserVo
		{
			return _user;
		}
		
		public function get isLoggedIn():Boolean
		{
			return Boolean(_user.id);
		}
		
		public function authorizePretend():void
		{
			
			
			var b:BitmapData = Bitmap(new ClsFbDefaultThumb()).bitmapData;
			var m:Matrix = new Matrix();
			b.draw(b, m);
			_user.profileImageSquare = b;
			
			// make own friends
			var a:Array = ["Master Thomas Hariot", "Master Acton", "Master Edward Stafford", "Thomas Luddington", "Master Maruyn", "Master Gardyner", "Captain Vaughan", "Master Kendall", "Master Prideox", "Robert Holecroft", "Rise Courtenay", "Master Hugh Rogers", "Thomas Foxe", "Edward Nugen", "Darby Glande", "Edward Kelle", "Iohn Gostigo", "Erasmus Clefs", "Edward Ketcheman", "Iohn Linsey", "Thomas Rottenbury", "Roger Deane", "Iohn Harris ", "Frauncis Norris", "Mathewe Lyne", "Edward Kettell", "Thomas Wisse", "Robert Biscombe", "William Backhouse", "William White", "Henry Potkin", "Dennis Barnes", "Ioseph Borges", "Doughan Gannes (Joachim Gans)", "William Tenche", "Randall Latham", "Thomas Hulme", "Walter Myll", "Richard Gilbert", "Steuen Pomarie", "Iohn Brocke", "Bennet Harrye", "Iames Stevenson", "Charles Stevenson", "Christopher Lowde", "Ieremie Man", "Iames Mason", "Dauvid Salter", "Richard Ireland", "Thomas Bookener", "William Philippes", "Randall Mayne", "Master Thomas Harvye", "Master Snelling", "Master Anthony Russe", "Master Allyne", "Master Michel Polyson", "Iohn Cage", "Thomas Parre", "William Randes", "Geffery Churchman", "William Farthowe", "Iohn Taylor", "Philppe Robyns", "Thomas Phillippes", "Valentine Beale", "Iames Skinner", "George Eseuen", "John Chaundeler", "Philip Blunt", "Richard Poore", "Robert Yong", "Marmaduke Constable", "Thomas Hesket", "William Wasse", "Iohn Feuer", "Daniel", "Thomas Taylor", "Richard Humfrey", "Iohn Wright", "Gabriell North", "Bennet Chappell", "Richard Sare", "Iames Lasie", "Smolkin", "Thomas Smart", "Robert", "Iohn Evans", "Roger Large", "Humfrey Garden", "Frauncis Whitton", "Rowland Griffyn", "William Millard", "Iohn Twyt (John White?)", "Edwarde Seklemore", "Iohn Anwike", "Christopher Marshall", "Dauid Williams", "Nicholas Swabber", "Edward Chipping", "Syluester Beching", "Vincent Cheyne", "Haunce Walters", "Edward Barecombe", "Thomas Skeuelabs", "William Walters"];
			_user.friends = [];
			for (var i:int = 0; i < a.length; i++)
			{
				var name:String = a[i];
				var id:String = int(Math.random()*99999999).toString();
				var vo:FbFriendVo = new FbFriendVo(id,name);
				_user.friends.push(vo);
			}
			
			// force async
			setTimeout(this.dispatchEvent, 1, new FbUtilEvent(true, "")); 
		}
		
		// =============================================
		// START OF AUTH CHAIN OF FUNCTIONS ...

		public function authorize():void
		{
			_errorMessages = "";
			clearAuthListeners();

			// Show authorize popup
			
			var url:String = _fbAuthUrl + "?client_id=" + _clientId + "&redirect_uri=" + _redirectUri;			
			if (_scope) url += "&scope=" + _scope;
			url = encodeURI(url);

			ExternalInterface.addCallback("onAuthorize", setCode);
			ExternalInterface.call(_popupFunction, url);
		}
		
		private function setCode($code:String):void
		{
			// User has logged in if necessary
			// FB has redirected to auth.html
			// auth.html has sent back the code to the parent page and closed itself 
			// Parent page has called this function with the token (code).
			
			Out.i('FbUtil.onAuthorize()', $code);
			
			if ($code.indexOf("error_reason") > -1) 
			{
				// eg, "error_reason=user_denied"
				_errorMessages += "Authorize error\r"
				finishAuth();
				return;
			}
			
			_code = $code;
			
			// Global.getInstance().showPinwheel();
			
			getToken();
		}
		
		private function getToken():void
		{
			// Get token from Facebook
			
			_service.addEventListener(IOErrorEvent.IO_ERROR, onGetTokenError);
			_service.addEventListener(Event.COMPLETE, onGetToken);

			var url:String = _fbGetTokenurl + "?client_id=" + _clientId + "&redirect_uri=" + _redirectUri + "&client_secret=" + _clientSecret + "&code=" + _code;
			_service.request(url,null,"GET",Service.RETURNTYPE_STRING );
		}
		
		private function onGetTokenError($e:IOErrorEvent):void
		{
			Out.e('FbUtil.onGetTokenError() -' + $e.text);

			_errorMessages += "Error getting token\r";
			finishAuth();
		}
		
		private function onGetToken($e:ExtendedEvent):void
		{
			_service.removeEventListener(IOErrorEvent.IO_ERROR, onGetTokenError);
			_service.removeEventListener(Event.COMPLETE, onGetToken);
			// Global.getInstance().hidePinwheel();

			var s:String = $e.object as String;

			if (!s) {
				_errorMessages += "Error getting token (blank response)\r";
				finishAuth();
				return;
			}
			
			var a:Array = s.split("&");
			var s2:String = a[0];
			if (s2.indexOf("access_token=") == -1) {
				_errorMessages += "Error getting token (bad response data)\r";
				finishAuth();
				return;
			}
			var a2:Array = s2.split("=");
			_token = a2[1]
			
			Out.i('FbUtil.onGetToken() - token:', _token);
			
			// get user info
			request("", REQUESTTYPE_INFO, onRequestInfo);
		}
		
		private function onRequestInfo($o:Object):void
		{
			_user.parseUserInfo($o);
			
			if (! _user.id || _user.id.length == 0) {
				_errorMessages += "No user ID found\r";
			}
			
			// get friends
			request(_user.id, REQUESTTYPE_FRIENDS, onRequestFriends);
		}
		
		private function onRequestFriends($o:Object):void
		{
			_user.parseFriends($o);
			
			finishAuth();
		}
		
		private function finishAuth():void
		{
			//Global.getInstance().hidePinwheel();
			clearAuthListeners();
			
			var success:Boolean = (_errorMessages.length == 0);
			this.dispatchEvent(new FbUtilEvent(success, _errorMessages));
		}

		private function clearAuthListeners():void
		{
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
				trace('FbUtil.onRequestImageList - No albums.');
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
				_service.request(_graphUrl + "me", { "access_token":_token } );
			}
			else {
				_service.request(_graphUrl + $id + "/" + s, { "access_token":_token } );
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
			// Global.getInstance().hidePinwheel();
			
			Out.e('FbUtil.onRequestError() - fail gracefully', $e.text);
			
			_errorMessages += "IOError on get\r"
			
			
			var fn:Function = _requestCallback;
			_requestCallback = null;
			fn(null);
		}

		//
		
		public function makeImageUrl($id:String, $type:String="large"):String
		{
			var url:String = _graphUrl + $id + "/picture" + "&" + "type=" + $type+ "&" + "access_token=" + _token;
			return url;
		}
		
		//

		public function loadImage($id:String, $callback:Function, $type:String="large"):void // small | normal | large | square
		{
			_loadImageCallback = $callback;
			
			//Global.getInstance().showPinwheel();
			
			_loader = new Loader();
			var lc:LoaderContext = new LoaderContext();
			lc.checkPolicyFile = true;
			lc.securityDomain = SecurityDomain.currentDomain;
			
			var url:String = _graphUrl + $id + "/picture" + "&" + "type=" + $type+ "&" + "access_token=" + _token;
			Out.i('FbUtil.loadImage()', url);
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

			if (!$b) Out.e('FbUtil.onLoadAlbumImage() - NO BITMAP');

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
			urlVars["access_token"] = _token;

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
	}
}

class SingletonEnforcer {}
