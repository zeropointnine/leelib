package leelib.screens
{
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.StageOrientation;
	import flash.errors.IllegalOperationError;
	import flash.events.Event;
	import flash.events.StageOrientationEvent;
	
	import leelib.graphics.GrUtil;
	import leelib.loadUtil.LoadUtilEvent;
	import leelib.ui.Component;
	import leelib.util.Out;
	import leelib.GlobalApp;
	import leelib.managers.NavManager;





	// Screen 'life cycle' is managed by NavManager.
	// 
	// Note, subclasses typically shouldn't bother implementing size() because the app 
	// never changes the size of the screens after initialization, and data changes are 
	//
	public class AcScreen extends Component
	{
		public static const EVENT_READY:String = "AcScreen.eventReady";
		
		protected var _numLoaders:uint; 	// Should be set to the total number of AcLoaders (loading local files) used by subclass on instantiation.
										// When _numLoaded count reaches this value, this fires EVENT_READY.
		protected var _numLoaded:uint;
		
		protected var _isTabBaseScreen:Boolean = false;
		// ? ... 
		
		protected var _navOnCreateKillHistory:Boolean = false;
		// when shown, clear history and kill its screens 

		protected var _navOnPushKillInstance:Boolean = false;
		// when pushed on stack (ie, hidden), kill the instance but keep as part of stack history
		
		protected var _navOnPopKill:Boolean = true;
		// when popped from stack (back button), kills instance rather than putting it in the pool
		
		protected var _titleBarBoldTitle:String = "";
		protected var _titleBarThinTitle:String;
		protected var _titleBarSettingsButtonVisible:Boolean = true;
		protected var _titleBarBackButtonAsDone:Boolean = false;
		protected var _titleBarVisible:Boolean = false;
		protected var _titleBarBackNeverVisible:Boolean = false;
		protected var _bottomBarVisible:Boolean = true;
		protected var _navTransition : String = NavManager.TRANSITION_SLIDE; // TODO: May not use; if not, remove me
		
		protected var _data:Object;


		public function AcScreen()
		{
			super();
			
			//this.addEventListener(AcLoader.EVENT_COMPLETE, onAcLoaderComplete, false,0,true);
		}

		public override function show():void
		{
			throw new IllegalOperationError("AcScreen subclasses should use navShow and navShowComplete");
		}
		public override function hide():void
		{
			throw new IllegalOperationError("AcScreen subclasses should use navHide and navHideComplete");
		}
		
		public function get isTabBaseScreen():Boolean
		{
			return _isTabBaseScreen;
		}
		public function get navOnCreateKillHistory():Boolean
		{
			// When true, when pushed on the stack by nav manager, kills instance and history
			return _navOnCreateKillHistory;
		}
		public function get navOnPushKillInstance():Boolean
		{
			// When true, when pushed on the stack by nav manager, kills actual instance but not history
			// (so when user goes back to that screen, it gets reinstantiated)
			return _navOnPushKillInstance;
		}
		public function get navOnPopKill():Boolean
		{
			// When popped, nav mgr either kills instance or stores it in screen pool
			return _navOnPopKill;
		}
		
		public function get navTransition():String
		{
			return _navTransition;
		}
		public function get titleBarVisible():Boolean
		{
			// Read on instantiation. When false, Screen sized to full area of Stage.
			return _titleBarVisible;
		}
		public function get titleBarTitleBold():String
		{
			return _titleBarBoldTitle;
		}
		public function get titleBarTitleThin():String
		{
			return _titleBarThinTitle;
		}
		public function get titleBarSettingsButtonVisible():Boolean
		{
			return _titleBarSettingsButtonVisible;
		}
		public function get titleBarBackButtonAsDone():Boolean
		{
			return _titleBarBackButtonAsDone;
		}
		public function get bottomBarVisible():Boolean
		{
			return _bottomBarVisible;
		}
		public function get backNeverVisible():Boolean
		{
			return _titleBarBackNeverVisible;
		}
		
		public function get numLoaders():uint
		{
			return _numLoaders;
		}

		
		// These methods get used in lieu of Component's "show()/hide()"
		//
		// BTW, subclass can assume that onNavHideStart+Complete will get called 
		// before kill().
		
		public function onNavShowStart():void
		{
		}
		public function onNavShowComplete():void
		{
		}
		public function onNavHideStart():void
		{
		}
		public function onNavHideComplete():void
		{
		}
		
		protected function onAcLoaderComplete(e:*):void
		{
			_numLoaded++;
			
			if (_numLoaded >= _numLoaders) 
			{
				//this.removeEventListener(AcLoader.EVENT_COMPLETE, onAcLoaderComplete);
				this.dispatchEvent(new Event(EVENT_READY));
			}
		}
		public function get isReady():Boolean
		{
			return (_numLoaded >= _numLoaders);
		}
		
		public function get data():Object
		{
			return _data;
		}
		public function set data($o:Object):void
		{
			_data = $o;
			onSetData();
		}
		protected function onSetData():void
		{
			// Update screen subviews based on data here.
			throw new Error("onSetData must be overridden!");
		}

		public function onStageOrientationChanging($e:StageOrientationEvent):void
		{
			// Default behavior is to cancel any orientation change
			if ($e.afterOrientation != StageOrientation.DEFAULT) { 
				$e.preventDefault();
			}
		}
		public function onStageOrientationChange($e:StageOrientationEvent):void
		{
		}
		
		public function onAppActivate():void
		{
		}
		public function onAppDeactivate():void
		{
		}

		/*
		protected function eventDataCheck():void
		{
			if (M.m.events) {
				onEventDataSuccess();
				return;
			}

			G.g.appLoadUtil.addEventListener("eventdata", onEventDataResponse);
			G.g.appLoadUtil.load(G.EVENTS_URL, "eventdata", "string", false, true, true, true);
		}
		private function onEventDataResponse($e:LoadUtilEvent):void
		{
			if ($e.data == null) {
				onEventDataFail();
				return;
			}

			var s:String = $e.data as String;
			if (! s || s.length == 0) onEventDataFail();
			var o:Object;
			try {
				o = JSON.parse(s);
			}
			catch (e:Error) {
				Out.e("AcScreen.onEventDataResponse - " + e.message);
				onEventDataFail();
				return;
			}
			if (! o["events"]) {
				onEventDataFail();
				return;
			}
			
			M.m.parseEventsJsonObject(o);
			onEventDataSuccess();
		}
		private function onEventDataFail():void
		{
			G.g.ane.showDialog("Error", "Could not load event info. You must be connected to the internet to continue", "Retry");
		}
		protected function onEventDataSuccess():void
		{
			// override
		}
		*/
	}
}
