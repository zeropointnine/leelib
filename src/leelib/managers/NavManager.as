package leelib.managers
{
	import com.greensock.TweenLite;
	import com.greensock.easing.Cubic;
	import com.greensock.easing.Linear;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.display.StageOrientation;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.system.System;
	import flash.utils.getDefinitionByName;
	import flash.utils.setTimeout;
	import flash.utils.clearTimeout;
	
	import leelib.GlobalApp;
	import leelib.graphics.GrUtil;
	import leelib.interfaces.IListScreen;
	import leelib.screens.AcScreen;
	import leelib.ui.Component;
	import leelib.ui.ListView;
	import leelib.util.Out;
	import leelib.vos.*;

	/**
	 * Screens that are recycled need to reset state on navShowStart.
	 * Or, need to store viewstate elsewhere. Etc.
	 */
	public class NavManager extends EventDispatcher
	{
		public static const EVENT_GOBACK:String = "NavManager.eventGoBack";
		public static const EVENT_TRANSITIONCOMPLETE:String = "NavManager.eventTransComplete";

		public static var TWEENTIME:Number = .66;
		public static var TWEENTIME_HALF:Number = TWEENTIME * .5;
		public static const TRANSITION_SLIDE:String = "slide";
		public static const TRANSITION_FADE:String = "fade";
		public static const TRANSITION_NONE:String = "none";

		public var flagUseTabTransition:Boolean;
		
		private var _stack:Vector.<NavVo>; 
		
		private var _pool:Vector.<AcScreen>;
		
		private var _inScreen:AcScreen; // in play during transition only
		private var _outScreen:AcScreen; // in play during transition only
		private var _isAnimating:Boolean;
		
		private var _popupBg:Sprite;
		
		private var _dialog:*;
		private var _buttonAlert:*;
		
		private var _outProxy:Bitmap;
		
		private var showTimeout:int;
		private var showGoTimeout:int;
		
		private var backTimeout:int;
		private var backGoTimeout:int;
	
		private static var _instance:NavManager;
		
		
		
		/**
		 * NavManager 
		 *  
		 * @param enforcer
		 * 
		 */		
		public function NavManager(enforcer:SingletonEnforcer)
		{
			_stack = new Vector.<NavVo>();
			_pool = new Vector.<AcScreen>();
			_outProxy = new Bitmap();
			GlobalApp.stage.addEventListener(NavManager.EVENT_GOBACK, onGoBack);
		}
		
		
		/**
		 *  
		 * @return NavManager
		 * 
		 */		
		public static function get instance():NavManager
		{
			if (NavManager._instance == null) 
				NavManager._instance = new NavManager(new SingletonEnforcer());
			return  NavManager._instance;
		}
		
		
		// readonly
		
		/**
		 *  
		 * @return AcScreen
		 * 
		 */		
		public function get currentScreen():AcScreen
		{
			if (_stack.length == 0) return null;
			return _stack[_stack.length-1].screenInstance;
		}
		
		/**
		 * 
		 * @return currentSkinClass
		 * 
		 */		
		public function get currentScreenClass():Class
		{
			if (_stack.length == 0) return null;
			return _stack[_stack.length-1].screenClass;
		}
		
		
		/**
		 * 
		 * @return 
		 * 
		 */		
		public function get currentNavVo():NavVo
		{
			if (_stack.length == 0) return null;
			return _stack[_stack.length-1];
		}
		
		
		/**
		 * 
		 * @return 
		 * 
		 */		
		public function get stack():Vector.<NavVo>
		{
			return _stack;
		}
		
		public function stackIncludes($class:Class):Boolean
		{
			for each (var nvo:NavVo in _stack)
			{
				if (nvo.screenInstance is $class || nvo.screenClass == $class) return true;
			}
			return false;
		}

		public function get isAnimating():Boolean
		{
			return _isAnimating;
		}
		
		public function showScreenByClassName($screenSubclassName:String, $data:Object=null):void
		{
			var screenType:Class = getDefinitionByName($screenSubclassName) as Class; // don't catch error
			showScreenByClass(screenType, $data);
		}

		
		
		/**
		 * Creates a class instance of a new screen
		 * 
		 * @param $screenSubclass
		 * @param $data
		 * 
		 */		
		public function showScreenByClass($screenSubclass:Class, $data:Object=null):void
		{
			var screen:AcScreen;
			// take a screen of type screenClass from the pool, if any
			for (var i:int = 0; i < _pool.length; i++) {
				if (_pool[i] is $screenSubclass) { 
					screen = _pool.splice(i, 1)[0];
					Out.i("NavManager.showScreenByClass - REUSING", screen); 
					break;
				}
			}
			if (! screen)  // no match - make new instance 
			{
				screen = new $screenSubclass(); // don't catch error
				screen.initialize( Component.ORIGIN_TL, getRectForScreen(screen) );
				Out.i("NavManager.showScreenByClass - INSTANTIATING", screen); 				
			}
			showScreen(screen, $data);
		}

		/**
		 * Creates an instance of showScreen
		 * 
		 * @param $screen 
		 * @param $data
		 * 
		 */		
		public function showScreen($screen:AcScreen, $data:Object=null):void
		{
			if (_isAnimating) {
				Out.w("NavManager.showScreen() - ALREADY ANIMATING. PROBLEM.");
				return;
			}

			_isAnimating = true;
			GlobalApp.globalApp.stage.mouseChildren = false;
			
			if (GlobalApp.globalApp.stage.orientation != StageOrientation.DEFAULT) {
				GlobalApp.globalApp.stage.setOrientation(StageOrientation.DEFAULT);
				showTimeout = setTimeout(onShowScreenOriented, 1000, $screen, $data);
			}
			else {
				onShowScreenOriented($screen, $data);
			}
		}
		
		/**
		 *
		 * 
		 *  
		 * @param $screen
		 * @param $data
		 * 
		 */		
		protected function onShowScreenOriented($screen:AcScreen, $data:Object):void
		{
			clearTimeout(showTimeout);
			_outScreen = currentScreen;
			_stack.push( new NavVo($screen) );
			_inScreen = currentScreen;
			
			if (_outScreen)
			{
				_outScreen.onNavHideStart();
			}
			_inScreen.data = $data;
			_inScreen.onNavShowStart();
			_inScreen.visible = false;
			GlobalApp.globalApp.rootComponent.addChildComponent(_inScreen, 0);
			
			updateTopBar();

			if ($screen is IListScreen) // this is a listview let's wait till we are rendered
			{
				_inScreen.addEventListener(ListView.LIST_RENDER_COMPLETE, onShowScreenReady,false,0,true);
				
			}else if (!_inScreen.isReady)
			{
				_inScreen.addEventListener(AcScreen.EVENT_READY, onShowScreenReady);
				
			}else
			{
				onShowScreenReady();
			}
		}
		
		
		/**
		 * Handles an event ready 
		 * 
		 * @param e
		 * 
		 */		
		protected function onShowScreenReady(e:*=null):void
		{
			_inScreen.removeEventListener(AcScreen.EVENT_READY, onShowScreenReady);
			_inScreen.removeEventListener(ListView.LIST_RENDER_COMPLETE, onShowScreenReady);
			
			var delay:int = 0; // 150 + _inScreen.numLoaders * 25;
			showGoTimeout = setTimeout(onShowGo, delay); 
		}
		
		
		
		
		/**
		 *  
		 * 
		 */		
		protected function onShowGo():void
		{
			clearTimeout(showGoTimeout);
			var easeFn:Function = Cubic.easeInOut;
			var index:int = 0;
			if (_outScreen)
			{
				if (flagUseTabTransition) // used when using navbar 
				{
					TweenLite.to(_outScreen, TWEENTIME*0.66, { alpha: 0, ease:easeFn } );
				}
				else 
				{
					_outProxy.bitmapData = new BitmapData(_outScreen.sizeWidth, _outScreen.sizeHeight, true, 0x0);
					_outProxy.bitmapData.draw(_outScreen);
					_outProxy.x = _outScreen.x;
					_outProxy.y = _outScreen.y;
					//index = GlobalApp.globalApp.rootComponent.getChildIndex(GlobalApp.globalApp.appRef.titleBar)-1;
					GlobalApp.globalApp.rootComponent.addChildAt(_outProxy, index);
					GlobalApp.globalApp.rootComponent.removeChildComponent(_outScreen);
					TweenLite.killTweensOf(_outProxy);
					TweenLite.to(_outProxy, TWEENTIME, { x: - GlobalApp.pw(1.0), ease:easeFn } );
				}
			}
			
			TweenLite.killTweensOf(_inScreen);
			if (! flagUseTabTransition) {
				_inScreen.x = GlobalApp.pw(1.0);
				_inScreen.alpha = 1;
				_inScreen.visible = true;
				TweenLite.to(_inScreen, TWEENTIME, { x: 0, ease:easeFn, onComplete:onShowComplete } );
			}
			else {
				_inScreen.visible = true;
				_inScreen.alpha = 0;
				_inScreen.x = 0;
				TweenLite.to(_inScreen, TWEENTIME*0.33, { alpha: 1, ease:easeFn, onComplete:onShowComplete } ); // used to be .15 (?)
			}
			
			if (flagUseTabTransition) flagUseTabTransition = false;
			
			updateBottomBarVisibility();

			// determine backbutton viz
			var finalStackLength:int = _stack.length;
			var bviz:Boolean = (finalStackLength > 1);
			if (_inScreen.navOnCreateKillHistory) bviz = false;
			if (_inScreen.backNeverVisible) bviz = false;
			//GlobalApp.globalApp.titleBar.setBackButtonVisibility(bviz, _inScreen.titleBarBackButtonAsDone);
		}
		
		
		
		/**
		 * 
		 * 
		 */		
		protected function onShowComplete():void
		{
			_isAnimating = false;
			GlobalApp.stage.mouseChildren = true;
			var nvo:NavVo;
			if (_outScreen) 
			{
				_outScreen.onNavHideComplete();
				if (GlobalApp.globalApp.rootComponent.contains(_outProxy)) GlobalApp.globalApp.rootComponent.removeChild(_outProxy);

				if (_outScreen.navOnPushKillInstance)
				{
					Out.i('NavManager.onShowComplete() KILLING outscreen (but NOT history)', _outScreen);
					
					// replace old nav-vo with an 'instance-less' one
					nvo = new NavVo(null, Object(_outScreen).constructor);
					_stack.splice(_stack.length-2, 1, nvo);
					_outScreen.kill();
				}

				if (_inScreen.isTabBaseScreen)
				{
					// kill and remove from history everything between homescreen and inscreen
					while (_stack.length > 2) 
					{
						nvo = _stack.splice(1,1)[0]; // remove screen #2
						Out.i('NavManager.onShowComplete() - KILLING AND REMOVING FROM HISTORY', nvo);
						var sc:AcScreen = nvo.screenInstance;
						sc.kill();
					}
				}
			}
			_outScreen = null;
			
			if (_outProxy && _outProxy.bitmapData) _outProxy.bitmapData.dispose();
			
			// special case
			if (_inScreen.navOnCreateKillHistory)
			{
				for (var i:int = _stack.length - 1; i > -1; i--) 
				{
					var nv:NavVo = _stack[i];
					if (nv.screenInstance && nv.screenInstance == _inScreen) continue; // drr
					
					if (nv.screenInstance) nv.screenInstance.kill(); 
					_stack.splice(i, 1); 
				}
			}
			
			// [b] in screen

			_inScreen.onNavShowComplete();
			_inScreen = null;

			Out.i('NavManager.onShowComplete() stack length is now:', _stack.length);
			
			GlobalApp.globalApp.stage.mouseChildren = true;
			this.dispatchEvent(new Event(EVENT_TRANSITIONCOMPLETE)); // xxx what is this good for
			
			// TODO: JUST FOR NOW
			System.gc();
			printStack();
		}
		
	
		
		
		/**
		 * Go back to a specific screen
		 * 
		 * @param $numberOfScreens
		 * @param $data
		 * 
		 */		
		public function back($numberOfScreens:int=1, $data:Object=null):void
		{
			if (_isAnimating) {
				Out.w("NavManager.back() - IS ALREADY TRANSITIONING. IGNORING.");
				return;
			}
			if (_stack.length < $numberOfScreens) {
				throw new Error("Logic error");
			}

			//MeVo.storeIfDirty(M.m.meVo, GlobalApp.meFilePath);
			//StorableObject.storeIfDirty(M.m.viewState, GlobalApp.viewStateFilePath);
			_isAnimating = true;
			GlobalApp.globalApp.stage.mouseChildren = false;

			if (GlobalApp.globalApp.stage.orientation != StageOrientation.DEFAULT) {
				GlobalApp.globalApp.stage.setOrientation(StageOrientation.DEFAULT);
				setTimeout(onBackOriented, 1000, $numberOfScreens, $data);
			}
			else {
				onBackOriented($numberOfScreens, $data);
			}
		}
		
		
		
		/**
		 * 
		 *  
		 * @param $numberOfScreens
		 * @param $data
		 * 
		 */		
		private function onBackOriented($numberOfScreens:int, $data:Object=null):void
		{
			// special sauce
			if ($numberOfScreens == 1) $numberOfScreens = numScreensBackOverrideLogic();
			
			_outScreen = currentScreen;
			_stack.pop();

			if ($numberOfScreens > 1)
			{
				// handle in-between screens
				for (var i:int = 0; i < $numberOfScreens-1; i++) 
				{
					// stack item can be either an instance or a class
					
					var nvo:NavVo = _stack.pop(); 

					if (nvo.screenInstance)
					{
						if (true || nvo.screenInstance.navOnPopKill) { // TODO: TEMP!!
							Out.i('NavManager.back_2() KILLING inbetween screen', nvo.screenInstance);
							nvo.screenInstance.kill();
						}
						else {
							Out.i('NavManager.back_2() REPLACING inbetween screen ', nvo.screenInstance);
							_pool.push(nvo.screenInstance);
						}					
					}
					else
					{
						// no cleanup needed
					}
				}
			}
			
			if (currentScreen) {
				_inScreen = currentScreen;
			}
			else {
				var screen:AcScreen = new currentScreenClass();
				screen.initialize( Component.ORIGIN_TL, getRectForScreen(screen) );
				_inScreen = currentNavVo.screenInstance = screen; // hah
				Out.i("NavManager.back_2() INSTANTIATED", _inScreen, "which was previously killed");
			}
			
			_outScreen.onNavHideStart();

			_inScreen.data = $data;
			_inScreen.onNavShowStart();
			_inScreen.visible = true;
			GlobalApp.globalApp.rootComponent.addChildComponent(_inScreen, 0);
			
			updateTopBar();

			if (! _inScreen.isReady) 
				_inScreen.addEventListener(AcScreen.EVENT_READY, onBackReady, false,0,true);
			else
				onBackReady();
		}
		
		private function onBackReady(e:*=null):void
		{
			_inScreen.removeEventListener(AcScreen.EVENT_READY, onBackReady);
			var delay:int = 0; // 150 + _inScreen.numLoaders * 25
			this.backGoTimeout  = setTimeout(onBackGo, delay);
		}
		
		private function onBackGo():void
		{
			clearTimeout (backGoTimeout);
			var easeFn:Function = Cubic.easeInOut;
			var index:int = 0;

			// outScreen
			_outProxy.x = _outScreen.x;
			_outProxy.y = _outScreen.y;
			_outProxy.bitmapData = new BitmapData(_outScreen.sizeWidth, _outScreen.sizeHeight, true, 0x0);
			_outProxy.bitmapData.draw(_outScreen);
			//var index:int = GlobalApp.globalApp.rootComponent.getChildIndex(GlobalApp.globalApp.appRef...)-1;
			
			GlobalApp.globalApp.rootComponent.addChildAt(_outProxy, index);
			
			GlobalApp.globalApp.rootComponent.removeChildComponent(_outScreen);

			TweenLite.killTweensOf(_outProxy);
			TweenLite.to(_outProxy, TWEENTIME, { x: + GlobalApp.pw(1.0), ease:easeFn, onComplete:onBackComplete } );
			
			// inScreen
			_inScreen.visible = true;
			_inScreen.x = - GlobalApp.pw(1.0);
			TweenLite.killTweensOf(_inScreen);
			TweenLite.to(_inScreen, TWEENTIME, { x: 0, ease:easeFn } );
			
			// determine backbutton viz
			var bviz:Boolean = (_stack.length > 1);
			if (_inScreen.backNeverVisible) bviz = false;
			//G.g.titleBar.setBackButtonVisibility(bviz, _inScreen.titleBarBackButtonAsDone);

			updateBottomBarVisibility();
		}
		
		private function onBackComplete():void
		{
			_isAnimating = false;
			GlobalApp.stage.mouseChildren = true;

			// outscreen
			
			if (GlobalApp.globalApp.rootComponent.contains(_outProxy)) GlobalApp.globalApp.rootComponent.removeChild(_outProxy);

			_outScreen.onNavHideComplete();

			if (_outScreen.navOnPopKill)
			{
				Out.i('NavManager.onBackComplete() - KILLING', _outScreen);
				_outScreen.kill();
			}
			else
			{
				Out.i('NavManager.onBackComplete() - REPLACING', _outScreen);
				_pool.push(_outScreen);
			}
			_outScreen = null;
			
			// inscreen

			_inScreen.onNavShowComplete();
			_inScreen = null;
			
			this.dispatchEvent(new Event(EVENT_TRANSITIONCOMPLETE));
			
			// TODO: FOR NOW
			System.gc();
			
			printStack();
		}

		private function numScreensBackOverrideLogic():int
		{
			/*
			var numBack:int;

			if (getTopmostClassIndexInStack(LoginScreen) > -1) return 1;
			
			var myc:int = getTopmostClassIndexInStack(MyConferenceScreen); 
			if (myc > -1) {
				numBack = (_stack.length-1) - myc;
				if (numBack > 1) {
					Out.i("NavManager.numScreensBackOverrideLogic() - MYCONF: OVERRIDING NUM-SCREENS-BACK TO ", numBack);
					return numBack;
				}
				else {
					return 1;
				}
			}
			
			var sch:int = getTopmostClassIndexInStack(ScheduleScreen);
			if (sch > -1) {
				if (sch > -1) {
					numBack = (_stack.length-1) - sch;
					if (numBack > 1) {
						Out.i("NavManager.numScreensBackOverrideLogic() - SCHEJ: OVERRIDING NUM-SCREENS-BACK TO ", numBack);
						return numBack;
					}
					else {
						return 1;
					}
				}
			}
			
			var ppl:int = getTopmostClassIndexInStack(PeopleScreen);
			if (ppl > -1) {
				if (ppl > -1) {
					numBack = (_stack.length-1) - ppl;
					if (numBack > 1) {
						Out.i("NavManager.numScreensBackOverrideLogic() - PEOPLE: OVERRIDING NUM-SCREENS-BACK TO ", numBack);
						return numBack;
					}
					else {
						return 1;
					}
				}
			}
			
			return 1; // default
	
		*/	
			return 0;
		}	
			
		
		
		// ==========================
		// POPUPS LOGIC
		
		public function showDialogByClassName($dialogSubclassName:String, $data:Object=null, $callback1:Function=null, $callback2:Function=null):void
		{
			//if (_dialog) { Out.w("showDialog - Already showing one. Ignoring."); return }
			
			// show darkener bg
			
			GrUtil.replaceRect(_popupBg, GlobalApp.globalApp.rootComponent.sizeWidth, GlobalApp.globalApp.rootComponent.sizeHeight, 0x0, 0.75);
			GlobalApp.globalApp.rootComponent.addChild(_popupBg); // to top
			_popupBg.visible = true;
			_popupBg.alpha = 0;
			_popupBg.addEventListener(MouseEvent.CLICK, onPopupBgClick);
			TweenLite.to(_popupBg, 0.25, { alpha:1, ease:Linear.easeNone } );

			// make dialog and show
			
			/*
			var dialogSubclass:Class = getDefinitionByName($dialogSubclassName) as Class; // don't catch error
			_dialog = new dialogSubclass(); // don't catch error
			GlobalApp.globalApp.rootComponent.addChildComponent(_dialog); // to top

			_dialog.initialize(Component.ORIGIN_TC, new Rectangle(0,G.pii(155), G.pw(1), _dialog.dialogRectHeight)); // dialog is expected to be full width by convention
			_dialog.setCallbacks($callback1, $callback2);
			_dialog.addEventListener(Component.EVENT_HIDECOMPLETE, onPopupHide);
			_dialog.data = $data;
			_dialog.show();
			*/
		}

		/**
		 * Treatment a little different from showDialog() oh well
	
		public function showButtonAlert($buttonAlert:ButtonAlert):void
		{
			if (_buttonAlert) { Out.w("showDialog - Already showing one. Ignoring."); return }
			
			_buttonAlert = $buttonAlert;
			
			// show darkener bg
			
			GrUtil.replaceRect(_popupBg, G.g.rootComponent.sizeWidth, G.g.rootComponent.sizeHeight, 0x0, 0.75);
			G.g.rootComponent.addChild(_popupBg); // to top
			_popupBg.visible = true;
			_popupBg.alpha = 0;
			_popupBg.addEventListener(MouseEvent.CLICK, onPopupBgClick);
			TweenLite.to(_popupBg, 0.25, { alpha:1, ease:Linear.easeNone } );
			
			// show alert
			
			_buttonAlert.x = int((G.g.rootComponent.sizeWidth - _buttonAlert.sizeWidth)/2);
			_buttonAlert.y = int((G.g.rootComponent.sizeHeight - _buttonAlert.sizeHeight)/2);
			G.g.rootComponent.addChild(_buttonAlert); // to top
			
			
			_buttonAlert.addEventListener(Component.EVENT_HIDECOMPLETE, onPopupHide);
			_buttonAlert.show();
		}	 */
		
		public function get isPopupShowing():Boolean
		{
			return Boolean(_dialog || _buttonAlert);
		}
		
		public function hidePopup():void
		{
			_popupBg.removeEventListener(MouseEvent.CLICK, onPopupBgClick);

			if (_dialog) _dialog.hide();
			if (_buttonAlert) _buttonAlert.hide();
		}
		
		private function onPopupBgClick(e:*):void
		{
			_popupBg.removeEventListener(MouseEvent.CLICK, onPopupBgClick);
			
			if (_dialog) _dialog.hide(); 
			if (_buttonAlert) _buttonAlert.hide();
			// ... results in onPopupHide, below, getting called
		}
		
		
		private function onPopupHide(e:*):void
		{
			TweenLite.to(_popupBg, 0.25, { alpha:0, ease:Linear.easeNone, onComplete:
				function():void{ if (GlobalApp.globalApp.rootComponent.contains(_popupBg)) GlobalApp.globalApp.rootComponent.removeChild(_popupBg); } } );
			
			if (_dialog)
			{
				GlobalApp.globalApp.rootComponent.removeChildComponent(_dialog);
				_dialog.removeEventListener(Component.EVENT_HIDECOMPLETE, onPopupHide);
				_dialog.kill();
				_dialog = null;
			}
			
			if (_buttonAlert)
			{
				GlobalApp.globalApp.rootComponent.removeChild(_buttonAlert);
				_buttonAlert.removeEventListener(Component.EVENT_HIDECOMPLETE, onPopupHide);
				_buttonAlert.kill();
				_buttonAlert= null;
			}
		}
		
		//
		// ==========================
		
		
		// Gets called by App
		//
		public function onAppActivate():void
		{
			if (currentScreen)
			{
				currentScreen.onAppActivate();
			}
		}
		
		public function onAppDeactivate():void
		{
			if (currentScreen)
			{
				currentScreen.onAppDeactivate();
			}
		}
		
		private function updateTopBar():void
		{
			return;
			if (currentScreen.titleBarVisible)
			{
				GlobalApp.globalApp.titleBar.show(); 
				
				// update titlebar contents
				
				GlobalApp.globalApp.titleBar.setTitle( currentScreen.titleBarTitleBold, currentScreen.titleBarTitleThin );
				
				var b:Boolean = currentScreen.titleBarSettingsButtonVisible; 
				if (b)
				{
					for each (var nvo:NavVo in _stack) 
					{
						
					}
				}
				GlobalApp.globalApp.titleBar.setSettingsButtonVisibility(b);
			}
			else
			{
				GlobalApp.globalApp.titleBar.hide(); 
			}
		}
		
		private function updateBottomBarVisibility():void
		{
			var showBottomBar:Boolean = currentScreen.bottomBarVisible;

			if (showBottomBar)
			{
				//GlobalApp.globalApp.bottomBar.updateSelectedState();
				//GlobalApp.globalApp.bottomBar.show();
			}
			else 
			{
				//GlobalApp.globalApp.bottomBar.hide();
			}
		}
		
		private function getRectForScreen($screen:AcScreen):Rectangle
		{
			var y:Number;
			var h:Number;
			
			var showBottomBar:Boolean = $screen.bottomBarVisible;
			
			if ($screen.titleBarVisible && showBottomBar) // both
			{
				y = GlobalApp.globalApp.appRef.titleBar.defaultY + GlobalApp.globalApp.titleBar.sizeHeight;
				h = GlobalApp.stage.stageHeight - y - GlobalApp.globalApp.bottomBar.sizeHeight;
			}
			else if (! $screen.titleBarVisible && ! showBottomBar) // neither
			{
				y = GlobalApp.globalApp.appRef.height;
				h = GlobalApp.stage.stageHeight - y;
			}
			else if ($screen.titleBarVisible && ! showBottomBar) // with titlebar, no bottombar
			{
				y = GlobalApp.globalApp.titleBar.height;
				h = GlobalApp.globalApp.stage.stageHeight - y
			}
			else // no titlebar, with bottombar 
			{ 
				y = 0;
				h = GlobalApp.stage.stageHeight;
				//h = GlobalApp.stage.stageHeight - GlobalApp.globalApp.appRef.bottomBar.sizeHeight - y;
			}
			return new Rectangle(0, y, GlobalApp.stage.stageWidth, h); 
		}
		

		
		private function printStack():void
		{
			for (var i:int = 0; i < _stack.length; i++)
			{
				Out.i("printStack", i, _stack[i].screenClass, _stack[i].screenInstance);
			}
		}

		private function onGoBack(e:*):void
		{
			back();
		}
		
		private function getTopmostClassIndexInStack($class:Class):int
		{
			for (var i:int = _stack.length-1; i > -1; i--)
			{
				if (_stack[i].screenClass == $class) return i;
			}
			return -1;
		}
	}
}
class SingletonEnforcer {}
