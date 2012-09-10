package leelib.ui
{
	import com.greensock.TweenLite;
	import com.greensock.easing.Cubic;
	import com.greensock.easing.Linear;
	
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.system.Capabilities;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	import leelib.GlobalApp;
	import leelib.interfaces.*;
	import leelib.events.AbstractListMouseEvent;
	import leelib.events.ListSelectEvent;
	import leelib.graphics.GrUtil;
	import leelib.loadUtil.LoadUtil;
	import leelib.loadUtil.LoadUtilEvent;
	import leelib.util.Out;
	
	
	/**
	 * Designed for mobile UI 'idiom'
	 * Rem, ListItems' select event (AbstractListItem.EVENT_SELECT) bubble.
	 * 
	 * Uses a solid graphics background (even if alpha is 0), so that clicks in the listView 
	 * (ie, not on a list item) can start vertical dragging
	 */
	public class ListView extends Component
	{
		protected var _data:Array;
		
		private static var DEBUG:Boolean = false;
		private static var _instanceCounter:int = -1;
		
		private static var _dragMinThresh:int; // amount of vertical travel allowed before a touch turns into a drag
		
		private var _backgroundIsWhiteNotClear:Boolean;
		private var _instanceLoadEventName:String;

		private var _assetLoader:LoadUtil;

		private var _dataImageUrlField:String;

		private var _stage:Stage;
		private var _mask:Sprite;
		private var _holder:Sprite;

		private var _pools:Dictionary; // key = Class; value = object-pool array
		
		private var _isDraggingThis:Boolean;
		private var _thisDragStartMouseY:Number;
		private var _thisDragStartHolderY:Number;
		private var _thisDragCurrentMouseY:Number;		
		private var _thisDragCurrentMouseTime:Number;
		
		
		private var _historyMouseY:Vector.<Number> = new Vector.<Number>();
		private var _historyMouseTime:Vector.<Number> = new Vector.<Number>();

		private var _velocity:Number;
		
		private var _thumbDragStartMouseY:Number;
		private var _thumbDragStartThumbY:Number;
		
		private var _offsets:Array;
		private var _totalHeight:Number;
		private var _lastY:Number = 0;
		private var _topIndex:int; // points to the the y value of the top-most visible element
		private var _bottomIndex:int; // points to the y value _below_ the bottom-most visible element
		
		private var _posY:Number;
		
		private var _usingCustomThumb:Boolean;
		private var _thumb:BoxSprite;
		private var _thumbRightMargin:Number = 5;
		private var _thumbVerticalMargin:Number = 5;
		private var _contentVerticalRange:Number;
		private var _thumbVerticalRange:Number;
		private var _isScrollingApplicable:Boolean;
		private var _tweenObject:Object;
		
		private var renderedDataFlag:Boolean = false;
		
		// items
		private var _item:Sprite;
		private var _tracker:Sprite;
		
		// tracking pos
		private var _userMouseDown	:Boolean;
		private var _initialMouseOffset: Number;
		private var _currentMousePos: Number;
		
		// animation props
		private var _trackerY:Number = 0;
		private var _distanceY:Number  = 0;
		private var _itemVelY: Number  = 0;
		private var _friction: Number = .6;
		private var _easing: Number = .2;
		
		//triggered after last visibile item is dispatched
		public static const LIST_RENDER_COMPLETE:String = "listRenderComplete";
		
		/**
		 * ListItem subclasses' data-classes must be unique.
		 * 
		 * If no $customThumb is passed, uses Apple-style thin oval thumb which sizes proportionally to height of content.
		 * 
		 * If two data-classes share the same type (eg, a POD like String or even Object),
		 * one must be wrapped in a custom class. 
		 * 
		 * Bad design decision, think about re-plumbing ListView, AbstractListItem, etc.
		 */
		public function ListView($assetLoader:LoadUtil=null, $backgroundIsWhiteNotClear:Boolean=true, $customThumb:BoxSprite=null)
		{
			super();
			
			_assetLoader = $assetLoader;
			_backgroundIsWhiteNotClear = $backgroundIsWhiteNotClear;

			// dictionary of listitem pools
			_pools = new Dictionary();
						
			_instanceLoadEventName = "listview" + (++_instanceCounter).toString(); 

			if (! _dragMinThresh) {
				_dragMinThresh = Math.round(0.03 * Capabilities.screenDPI);  
			}
			
			_holder = new Sprite();
			this.addChild(_holder);
			
			_mask = new Sprite();
			this.addChild(_mask);
			if (! DEBUG) _holder.mask = _mask;

			_usingCustomThumb = ($customThumb!=null);
			if (_usingCustomThumb) {
				_thumb = $customThumb;
				_thumb.buttonMode = true;
			}
			else {
				_thumb = new BoxSprite(); // gets drawn on size
				_thumb.mouseEnabled = false;
			}
			_thumb.alpha = 0;
			this.addChild(_thumb);
			
			// xxx check for dataClass uniqueness
			
			this.addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			addEventListener(ListSelectEvent.EVENT_SELECT, onListItemSelect); // (bubbles from list items)
			
			_tracker = new Sprite()
			_tracker.graphics.beginFill(0x00ffff, 2);
			_tracker.graphics.drawRect(0, 0, 20, 20);
			_tracker.graphics.endFill();
			addChild(_tracker);
			_tracker.visible = false;
			
		}
		
		/**
		 * Handles list item select events from item renderer AsyncListBaic
		 *  
		 * @param e
		 * 
		 */		
		private function onListItemSelect(e:ListSelectEvent):void
		{
			e.index = this._data.indexOf(e.data);
		}
		
		
		
		/**
		 * 
		 *  
		 * @param e
		 * 
		 */	
		private function onAddedToStage(e:*):void
		{
			this.removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			_stage = this.stage;
		}

		/**
		 * doInit() 
		 * activate lists when initialized 
		 * 
		 */		
		protected override function doInit():void
		{
			activate();
		}
		
		
		
		/**
		 * activate() called by nav manager, sets up scroll beahavior
		 * 
		 */		
		public function activate():void
		{
			if (_assetLoader) _assetLoader.addEventListener(_instanceLoadEventName, onAssetLoaded);
			updateIsScrollingApplicable();
		}
		
		
		
		/**
		 * deactivate() called by nav manager, sets up scroll beahavior
		 * 
		 */	
		public function deactivate():void
		{
			if (_assetLoader){
				_assetLoader.removeEventListener(_instanceLoadEventName, onAssetLoaded);
				_assetLoader.removeByEventName(_instanceLoadEventName, true);
			}
			
			this.removeEventListener(AbstractListMouseEvent.EVENT_MOUSE_DOWN, onThisDown);
			this.removeEventListener(MouseEvent.MOUSE_DOWN, onThisDown);
			this.removeEventListener(Event.ENTER_FRAME, onThisEnterFrame);
			_stage.removeEventListener(MouseEvent.MOUSE_MOVE, onThisDragMove2);
			_thumb.removeEventListener(MouseEvent.MOUSE_DOWN, onThumbDown);

			if (_stage) {
				_stage.removeEventListener(MouseEvent.MOUSE_MOVE, onThisDragMove1);
				_stage.removeEventListener(Event.ENTER_FRAME, onThumbDragPoll);
				_stage.removeEventListener(MouseEvent.MOUSE_UP, onThumbDragUp);
			}
			
			resetThisDragRelatedState();
		}
		
		/**
		 * removes all item renderers 
		 * 
		 */		
		public override function kill():void
		{
			deactivate();
			// pools
			
			replaceActiveItemsToPool();
			
			for (var key:Object in _pools)
			{
				var a:Array = _pools[key] as Array;
				for each (var listItem:AbstractListItem in a)
				{
					listItem.kill();
				}
				delete _pools[key];
			}
			_pools = null;
			
			// displayobjects

			_holder.mask = null;
			this.removeChild(_holder);
			_holder = null;
			
			this.removeChild(_mask);
			_mask = null;

			this.removeChild(_thumb);
			_thumb = null;
			
			_data = null;
		}
		
		public function get data():Array
		{
			return _data;
		}
		
		public function get assetLoader():LoadUtil
		{
			return _assetLoader;
		}

		/**
		 * must be an array of listItems 
		 * @param $a
		 * 
		 */

		public function set data($a:Array):void
		{			
			resetThisDragRelatedState();
			this.renderedDataFlag = true; //holds whether we dispatch an event after a render

			_data = $a;
			if (! _data) _data = [];
			//trace('ListView.data - num:', $a.length);
			
			replaceActiveItemsToPool();
			
			// calc offsets
			calcOffsets();
			
			updateIsScrollingApplicable();

			_thumb.visible = _isScrollingApplicable;
			sizeThumb();			

			if (DEBUG) {
				//_mask.addEventListener(MouseEvent.MOUSE_DOWN, onThisDown);
			}

			_thumb.alpha = 0;
			_topIndex = 0;
			_bottomIndex = 0;
			_posY = 0;
			moveHolderTo(0);
		}
		
		private function resetThisDragRelatedState():void
		{
			_velocity = 0;
			this.removeEventListener(Event.ENTER_FRAME, onThisEnterFrame);
			
			if (_stage) {
				_stage.removeEventListener(MouseEvent.MOUSE_MOVE, onThisDragMove1);
				_stage.removeEventListener(MouseEvent.MOUSE_MOVE, onThisDragMove2);
				_stage.removeEventListener(MouseEvent.MOUSE_UP, onThisDragUp);
			}
			_isDraggingThis = false;
		}

		/**
		 * ListItemVO impelements a method called calcHeightFor, for measuring each item renderer 
		 * 
		 */

		private function calcOffsets():void
		{
			// rem, offset elements are positive numbers starting from 0
			_offsets = []; 

			if (! _data) return;
			
			_offsets.push(0);
			var cum:Number = 0;

			var i:int = 0;
			for (i = 0; i < _data.length; i++)
			{
				var o:Object = _data[i];
				var o2:IListItemData = o as IListItemData;
				if (! o2) throw new Error("Data object must implement IListItemData");
				var calcHeightFunction:Function = o2.listItemSubclass["calcHeightFor"]; // xxx change this interface 
				if (calcHeightFunction == null) {
					throw new Error("ListView.calcOffsets() - CLASS MUST IMPLEMENT STATIC FUNCTION CALCHEIGHTFOR" + o);
				}
				var h:Number = calcHeightFunction(o, _sizeWidth);
				cum += h;
				_offsets[i+1] = cum;
			}
			_totalHeight = cum;
		}
	
		
		/**
		 * Size the list 
		 * 
		 */		
		public override function size():void
		{
			_mask.graphics.beginFill(0xff0000, (DEBUG ? 0.33 : 1.0));
			_mask.graphics.drawRect(0,0, _sizeWidth, _sizeHeight);
			_mask.graphics.endFill();
			
			if (_backgroundIsWhiteNotClear)
			{
				this.opaqueBackground = 0xffffff;
				GrUtil.replaceRect(this, _sizeWidth, _sizeHeight, 0xffffff, 1);
			}
			else
			{
				this.opaqueBackground = null;
				GrUtil.replaceRect(this, _sizeWidth, _sizeHeight, 0xffffff, 0.0);
			}
			
			sizeThumb();
		}

		public function scrollToItemByDataObject($dataObject:IListItemData, $tween:Boolean):Boolean
		{
			var index:int = _data.indexOf($dataObject); 
			if (index == -1) return false;

			resetThisDragRelatedState();

			var tweenStart:Number = _holder.y;
			var tweenEnd:Number = _offsets[index] * -1;
			var limit:Number = (_totalHeight - _sizeHeight) * -1; // clamp
			if (tweenEnd < limit) tweenEnd = limit;
			
			if ($tween) {
				_tweenObject = { value:tweenStart }
				TweenLite.to(_tweenObject, 0.66, { value:tweenEnd, ease:Linear.easeOut, onUpdate:scrollToItemTweenUpdate, onComplete:scrollToItemTweenComplete } );
			}
			else {
				moveHolderTo(tweenEnd);
			}
			return true;
		}
		
		/**
		 * Scrolls to a list position
		 * 
		 * @param index item-index is the position in the list we want to scroll to
		 * @param $tween whether we want to tween to the element
		 * 
		 */		
		public function scrollToIndex(index:int,$tween:Boolean = false):void
		{
			var tweenStart:Number = _holder.y;
			var tweenEnd:Number = _offsets[index] * -1;
			var limit:Number = (_totalHeight - _sizeHeight) * -1; // clamp
			if (tweenEnd < limit) tweenEnd = limit;
			
			if ($tween) {
				_tweenObject = { value:tweenStart }
				TweenLite.to(_tweenObject, 0.66, { value:tweenEnd, ease:Linear.easeOut, onUpdate:scrollToItemTweenUpdate, onComplete:scrollToItemTweenComplete } );
			}
			else {
				moveHolderTo(tweenEnd);
			}
		}
		
		
		private function scrollToItemTweenUpdate($dontUpdateThumb:Boolean=false):void
		{
			moveHolderTo(_tweenObject.value, $dontUpdateThumb);
		}
		
		private function scrollToItemTweenComplete():void
		{
		
		}
		
		/**
		 * Returns top item that is  > 50% visible
		 * 
		 * @return 
		 * 
		 */
		public function getTopItem():AbstractListItem
		{
			if (_data.length == 0) return null;
			if (_data.length == 1) return _data[0];
			
			var item0:AbstractListItem = _holder.getChildAt(0) as AbstractListItem;
			var item1:AbstractListItem = _holder.getChildAt(1) as AbstractListItem;
			if (! item0 || ! item1) {
				Out.w("ListView.getTopItemDataObject - SHOULDNT HAPPEN");
				return null;
			}
			
			var hy:Number = Math.abs(_holder.y);
			var item0MajorityVisible:Boolean = (hy - item0.y) < (item0.sizeHeight * 0.5);
			if (item0MajorityVisible)
				return item0;
			else
				return item1;
		}
		
		/**
		 *  Get the dataObject for the top visible renderer
		 *  
		 * @return 
		 * 
		 */		
		public function getTopItemDataObject():Object
		{
			var item:AbstractListItem = getTopItem();
			return item ? item.data : null;
		}
		
		public function get holder():Sprite
		{
			return _holder;
		}
		
		private function replaceActiveItemsToPool():void
		{
			while (_holder.numChildren > 0) {
				var item:AbstractListItem = _holder.removeChildAt(0) as AbstractListItem; // remove from holder
				var itemClass:Class = Object(item).constructor; // add item back to its object-pool
				_pools[itemClass].push(item); 
			}
		}
		
		
		/**
		 * Sizes Thumb, either android passed in thumb, or apple style thumb by default 
		 * 
		 */		
		private function sizeThumb():void
		{
			if (! _isScrollingApplicable) return;

			var thumbW:Number;
			var thumbH:Number;
			var thumbX:Number;
			
			if (! _usingCustomThumb)
			{
				// draw apple-style thumb

				thumbW = GlobalApp.pw(0.019);

				thumbH = (_sizeHeight / _totalHeight) * _sizeHeight;
				thumbH = Math.max(_sizeHeight * 0.08, thumbH);
				
				_thumb.graphics.clear();
				_thumb.graphics.beginFill(0x888888, 0.5);
				_thumb.graphics.drawRoundRect(0,0, thumbW,thumbH, thumbW,thumbW);
				_thumb.graphics.endFill();

				thumbX = _sizeWidth - thumbW - _thumbRightMargin; 
			}
			else
			{
				thumbW = _thumb.sizeWidth;
				thumbH = _thumb.sizeHeight;
				thumbX = _sizeWidth - thumbW;
			}
			
			_thumb.x = thumbX;
			_thumbVerticalRange = _sizeHeight - thumbH - _thumbVerticalMargin*2;
			_contentVerticalRange = _totalHeight - _sizeHeight;

			positionThumbY();
		}
		
		
		/**
		 * Hides are thumb after an animation 
		 * 
		 */		
		private function showThumb():void
		{
			if (_isScrollingApplicable) {
				TweenLite.killTweensOf(_thumb);
				TweenLite.to(_thumb, 0.20, { alpha:1.0, ease:Linear.easeNone } );
			}
		}
		
		
		/**
		 * Shows Thumb when an animation plays
		 * 
		 */	
		private function hideThumb():void
		{
			TweenLite.to(_thumb, 0.35, { alpha:0, ease:Linear.easeNone } );
		}
		
		
		/*
		private function onThisDown(e:*):void
		{
			_userMouseDown = true;
			_tracker.y  =  _currentMousePos = _stage.mouseY;
			
			if (e is AbstractListMouseEvent){
				_tracker.y  =  _currentMousePos = e.mouseEvent.stageY;
				
			} else
			{
				_tracker.y  =  _currentMousePos = e.stageY;
			}
			 
			_thisDragStartHolderY = _holder.y;
			_thisDragStartMouseY  = _trackerY;
			_thisDragCurrentMouseY = _trackerY;
			
			// add mouse tracking
			addEventListener(Event.ENTER_FRAME, handleEnterFrame);	
			stage.addEventListener(MouseEvent.MOUSE_MOVE, handleMouseMove);
			stage.addEventListener(MouseEvent.MOUSE_UP, handleMouseUp);		
		} */
		
		
		
		/**
		 *  Hanels mouse down event onThisDown on an item renderer
		 *  
		 * @param e
		 * 
		 */		
		private function onThisDown(e:*):void
		{
			_thisDragStartMouseY = _stage.mouseY;
			_thisDragCurrentMouseY = _thisDragStartMouseY;
			_thisDragStartHolderY = _holder.y;
			if (e is AbstractListMouseEvent)
			{
				_thisDragCurrentMouseY  =  _currentMousePos = e.mouseEvent.stageY;
				
			} else
			{
				_thisDragCurrentMouseY  =  _currentMousePos = e.stageY;
			}
			_isDraggingThis = true;
			_velocity = 0;
			_stage.addEventListener(MouseEvent.MOUSE_MOVE, onThisDragMove1);
			_stage.addEventListener(MouseEvent.MOUSE_UP, onThisDragUp);
		}
		
		
		/**
		 * Meausures time for scrolling for first mouse move event 
		 * @param e
		 * 
		 */		
		private function onThisDragMove1(e:*):void
		{
			
			if (Math.abs(_stage.mouseY - _thisDragStartMouseY) < _dragMinThresh) return;

			// at this point, we 'invalidate' any would-be click, and really start the vertical dragging:
			_stage.removeEventListener(MouseEvent.MOUSE_MOVE, onThisDragMove1);
			for (var i:int = 0; i < _holder.numChildren; i++) {
				AbstractListItem( _holder.getChildAt(i) ).cancelMouseDown();
			}
			//reset our stored position of our mouse calculations
			_historyMouseY.splice(0,_historyMouseY.length);
			_historyMouseTime.splice(0,_historyMouseTime.length);
			_historyMouseY[0] = _stage.mouseY;
			_historyMouseTime[0] =  getTimer() 
			this.addEventListener(Event.ENTER_FRAME, onThisEnterFrame);
			_stage.addEventListener(MouseEvent.MOUSE_MOVE, onThisDragMove2);
			showThumb();
		}
		
		/**
		 * Meausures time for scrolling for second mouse move event 
		 * @param e
		 * 
		 */	
		
		private function onThisDragMove2(e:*):void
		{
			// mousemove gets called more often than enterframe, which makes it 
			// better to use to track 'fling' gesture, especially when framerate sucks
			// maybe
			var mouseY:Number = _stage.mouseY;
			if (mouseY < 0 || mouseY > GlobalApp.ph(1.0)) 
			{
				mouseY = Math.floor( GlobalApp.ph(1.0)*.5);
			}
			
			_thisDragCurrentMouseY = mouseY
			_historyMouseY.unshift(_thisDragCurrentMouseY);
			if (_historyMouseY.length > 6) _historyMouseY.pop();
			
			_thisDragCurrentMouseTime = getTimer(); 
			_historyMouseTime.unshift(_thisDragCurrentMouseTime);
			if (_historyMouseTime.length > 6) _historyMouseTime.pop();
		}
		
		
		/**
		 *  handles onEnterFrame events for updating animation properties
		 * 
		 * @param $e
		 * 
		 */		
		private function onThisEnterFrame($e:Event):void
		{
			var newy:Number;

			if (_isDraggingThis)
			{
				// don't update if mousey hasn't changed 
				// if (_thisDragCurrentMouseY == _thisDragLastMouseY1) return;
				
				var delta:Number = _thisDragCurrentMouseY - _thisDragStartMouseY;
				newy = _thisDragStartHolderY + delta; // later: ensure step is less than itemheight
			}
			else // 'has-flung'
			{
				_velocity *= 0.95; // friction
				if (Math.abs(_velocity) < 1.0) { // stops
					_velocity = 0;
					hideThumb();
					this.removeEventListener(Event.ENTER_FRAME, onThisEnterFrame);
					this.removeEventListener(MouseEvent.MOUSE_MOVE, onThisDragMove2);
				}
				newy = _holder.y + _velocity;
			}
			moveHolderTo(newy);
		}
		
		private function onEnterFrameTween():void
		{
			
		}
		
		
		
		/**
		 * Handles mouse down event for thumb 
		 * 
		 * @param $e
		 * 
		 */		
		private function onThumbDown($e:MouseEvent):void
		{
			$e.stopImmediatePropagation();
			
			// Rem, this condition means:
			// - User is not dragging holder
			// - Probably has velocity, but not necessarily
			// - Thumb is visible, but may be fading out
			
			// Reset some stuff:
			
			TweenLite.killTweensOf(_thumb);
			_thumb.alpha = 1;
			
			resetThisDragRelatedState();

			_thumbDragStartMouseY = $e.stageY;
			_thumbDragStartThumbY = _thumb.y;
			
			_stage.addEventListener(Event.ENTER_FRAME, onThumbDragPoll);
			_stage.addEventListener(MouseEvent.MOUSE_UP, onThumbDragUp);
		}
		
		
		/**
		 * Handles mouse up event for thumb 
		 * 
		 * @param $e
		 * 
		 */		
		
		private function onThumbDragPoll($e:Event):void
		{
			var dif:Number = _stage.mouseY - _thumbDragStartMouseY;
			var ty:Number = _thumbDragStartThumbY + dif;
			if (ty < _thumbVerticalMargin) ty = _thumbVerticalMargin;
			if (ty > _thumbVerticalMargin + _thumbVerticalRange) ty = _thumbVerticalMargin + _thumbVerticalRange; 
			_thumb.y = ty;
			
			var ratio:Number = (_thumb.y - _thumbVerticalMargin) / _thumbVerticalRange;
			
			_tweenObject = { value:_holder.y };
			var tweenEnd:Number = ratio * _contentVerticalRange * -1;
			TweenLite.to(_tweenObject, 0.40, { value:tweenEnd, ease:Cubic.easeOut, onUpdate:scrollToItemTweenUpdate, onUpdateParams:[true], onComplete:scrollToItemTweenComplete } );
			
			// trace('huh?', ratio * _contentVerticalRange * -1);
			// moveHolderTo(ratio * _contentVerticalRange, true);
		}
		
		private function onThumbDragUp(e:*):void
		{
			_stage.removeEventListener(Event.ENTER_FRAME, onThumbDragPoll);
			_stage.removeEventListener(MouseEvent.MOUSE_UP, onThumbDragUp);
			hideThumb();
		}
		
		//
		
		public function get offset():Number
		{
			return Math.abs(_holder.y);
		}
		
		public function set offset($y:Number):void
		{
			moveHolderTo($y);
		}


		/**
		 * Moves the list holder
		 * 
		 * @param $y param should be negative
		 * @param $dontPositionThumb
		 * 
		 */		
		private function moveHolderTo($y:Number, $dontPositionThumb:Boolean=false):void
		{
			$y = int($y);
		
			var wasPosY:Number = _posY;
			_posY = - $y; // switch sign (easier to work with positive numbers)

			// clamp $y
			if (_posY <= 0) { 
				_posY = 0; 
				_velocity = 0; 
			}
			else if (_posY > _totalHeight - _sizeHeight) { 
				_posY = _totalHeight - _sizeHeight; 
				_velocity = 0; 
			}
			
			_holder.y = - _posY;
			var holderDirectionIsUpNotDown:Boolean = (_posY - wasPosY >= 0);
			updateIncremental(holderDirectionIsUpNotDown, _posY-wasPosY);
			
			if (! $dontPositionThumb) positionThumbY();
		}
		
		
		
		/**
		 * Positions the thumb 
		 * 
		 */		
		private function positionThumbY():void
		{
			_thumb.y = (_posY / _contentVerticalRange) * _thumbVerticalRange  +  _thumbVerticalMargin;
		}
		
		private function updateIncremental($holderDirectionIsUpNotDown:Boolean, $delta:Number):void
		{
			var orig:int;
			
			if ($holderDirectionIsUpNotDown)
			{
				// remove top elements that are no longer visible
				orig = _holder.numChildren;
				while (_offsets[_topIndex+1] < _posY)
				{
					
					if (_holder.numChildren == 0) // xxx I can remove this now yea?
					{
						trace('problem...', orig, $delta);
						_topIndex++
						continue;
					}
					
					var item1:AbstractListItem = _holder.removeChildAt(0) as AbstractListItem; // remove from holder
					var item1Class:Class = Object(item1).constructor; // add item back to its object-pool
					_pools[item1Class].push(item1); 
					_topIndex++;
				}

				// add elements to the bottom
				while (_offsets[_bottomIndex] < _posY + _sizeHeight)
				{
					// edge case
					if (_data.length == 0) break;
					
					addItem(_bottomIndex, false);
					_bottomIndex++;
					
					// edge case, happens when content height < sizeHeight:
					if (_bottomIndex == _offsets.length-1) break; 
				}
				
				if (this.renderedDataFlag)
				{
					renderedDataFlag = false;
					dispatchEvent(new Event(ListView.LIST_RENDER_COMPLETE,true));
				}
				
			}
			else // holder moved downwards
			{
				// remove bottom elements that are no longer visible
				orig = _holder.numChildren;
				while (_offsets[_bottomIndex-1] > _posY + _sizeHeight)
				{
					
					if (_holder.numChildren == 0)
					{
						trace('problem...', orig, $delta, _stage.mouseY);
						_bottomIndex--;
						continue;
					}
					
					var item2:AbstractListItem = _holder.removeChildAt(_holder.numChildren-1) as AbstractListItem;
					var item2Class:Class = Object(item2).constructor;
					_pools[item2Class].push(item2); 
					_bottomIndex--;
				}
				
				// add elements at the top
				while (_offsets[_topIndex] > _posY)
				{
					_topIndex--;
					addItem(_topIndex, true);
				}
				
			}	
			
		}

		
		/**
		 * Remove a ListItem instance from object pool and add it to the display.
		 * If no pool for that class exists yet, create it.
		 * 
		 * If pool is empty, instantiate a new item.
		 * 
		 * @param $index
		 * @param $toTopNotBottom
		 * 
		 */		
		private function addItem($index:int, $toTopNotBottom:Boolean):void
		{
			var o:IListItemData = _data[$index];
			
			// check out a ListItem from correct object pool
			var pool:Array = _pools[o.listItemSubclass];

			if (! pool)
			{
				// Out.i("ListView.addItem - creating pool for ", o.listItemSubclass);
				pool = [];
				_pools[o.listItemSubclass] = pool;
			}

			if (pool.length == 0)
			{
				// temp: debugging info...
				// var num:int = 0; 
				// for (var i:int = 0; i < _holder.numChildren; i++) {
				//	  if (_holder.getChildAt(i) is o.listItemSubclass) num++;
				// }
				// Out.i("ListView.addItem -", o.listItemSubclass, " Added new item. New total:", num+1);
				
				// make new listitem and add it to the pool 
				var item:AbstractListItem = new o.listItemSubclass();
				item.initialize(Component.ORIGIN_TL, new Rectangle(0, 0, _sizeWidth, 50)); // 50 is temporary/arbitrary  
				pool.push(item);
			}
			
			var listItem:AbstractListItem = pool.pop(); // xxx need logic for empty pool
			
			// initialize it
			listItem.data = o;
			listItem.sizeHeight = _offsets[$index+1] - _offsets[$index+0];
			
			// add it to the display
			listItem.y = _offsets[$index];
			if (! $toTopNotBottom)
				_holder.addChild(listItem);
			else
				_holder.addChildAt(listItem, 0);
			
			// load async-asset if applicable
		
			
			
			if (listItem is AbstractAsyncListItem && o is IAsyncAssetData)
			{
				var ao:IAsyncAssetData = o as IAsyncAssetData;	
				var url:String = ao.assetUrl;
				var ali:AbstractAsyncListItem = AbstractAsyncListItem( listItem );
				ali.setAsyncAssetToBlank();
				if (! _assetLoader) {
					Out.w("ListView.addItem - NO ASSET LOADER");
					ali.setAsyncAssetToBlank();
				}
				else if (! url) {
					ali.setAsyncAssetToBlank();
				}
				else {
					ali.setAsyncAssetToLoading();
					_assetLoader.addEventListener(LoadUtilEvent.COMPLETE,onAssetLoaded);
					_assetLoader.load(url, LoadUtilEvent.COMPLETE, ao.loadUtilAssetType, ao, true, false,false);
					
				}
			}
			
			// trace('index',$index, 'y', listItem.y, ' -', vo.listItemClass, vo.toString());
		}
		
		
		/**
		 *  Handles async loading of assets
		 * 
		 * @param $e
		 * 
		 */		
		private function onAssetLoaded($e:LoadUtilEvent):void
		{
			var hit:AbstractAsyncListItem;
			
			for (var i:int = 0; i < _holder.numChildren; i++) // lookup 
			{
				var ali:AbstractAsyncListItem = _holder.getChildAt(i) as AbstractAsyncListItem;
				if (! ali) continue;
				if (ali.data == $e.callbackData) {
					hit = ali;
					break;
				}
			}

			if (hit)
			{
				if ($e.errorText || ! $e.data) 
				{
					//trace('listview assetloaded ERROR', $e.errorText);
					hit.setAsyncAssetToError();
				}
				else 
				{
					hit.setAsyncAsset($e.data);
				}
			}
			else
			{
				// no match - cell must have already been scrolled out of view
			}
		}

		
		/**
		 * Handles the mouse onDragUp Position
		 *  
		 * @param $e
		 * 
		 */		
		private function onThisDragUp($e:Event):void
		{
			_isDraggingThis = false;
			_stage.removeEventListener(MouseEvent.MOUSE_UP, onThisDragUp);
			_stage.removeEventListener(MouseEvent.MOUSE_MOVE, onThisDragMove1);
			_stage.removeEventListener(MouseEvent.MOUSE_MOVE, onThisDragMove2);
			
			if (! _historyMouseY || _historyMouseY.length == 0) return; // .. will get treated as a click
			
			// 'fling' logic
			// currently not factoring for time. which is not really working well.
			// need bigger history, or maybe use setInterval rather than mouseMove
			var difY:Number = _thisDragCurrentMouseY - _historyMouseY[_historyMouseY.length-1];
			var difMs:Number = _thisDragCurrentMouseTime - _historyMouseTime[_historyMouseTime.length-1];
			var coef:Number = difY/difMs;
		
			

			// ensure simple press-up doesn't result in exaggerated movement; 1 ends up being a convenient cut-off point
			if (coef < 1.0) coef = Math.pow(coef, 3); 
			
			// var multiplier:Number = Math.log(Math.abs(coef)) // rem, log(10) = 2.3; log(100) = ~4.6; etc
			// if (multiplier < 1) multiplier = 1;
			
			_velocity = coef * 100; // magic #
			
			 //trace('fling difY', difY, 'difTime', difMs, 'coef', coef, 'vel', _velocity); 

			// speed limit
			var max:Number = _sizeHeight * .85; 
			if (_velocity > max) _velocity = max;
			if (_velocity < -max) _velocity = -max;
			
			if (_velocity == 0) {
				this.removeEventListener(Event.ENTER_FRAME, onThisEnterFrame);
				_stage.removeEventListener(MouseEvent.MOUSE_MOVE, onThisDragMove2);
				hideThumb();
			}
		}
		
		private function updateIsScrollingApplicable():void
		{
			_isScrollingApplicable = (_totalHeight > _sizeHeight);

			if (_isScrollingApplicable) {
				if (_usingCustomThumb) _thumb.addEventListener(MouseEvent.MOUSE_DOWN, onThumbDown); 
				this.addEventListener(AbstractListMouseEvent.EVENT_MOUSE_DOWN, onThisDown);
				this.addEventListener(MouseEvent.MOUSE_DOWN, onThisDown);
			}
			else {
				_thumb.removeEventListener(MouseEvent.MOUSE_DOWN, onThumbDown);
				this.removeEventListener(AbstractListMouseEvent.EVENT_MOUSE_DOWN, onThisDown);
				this.removeEventListener(MouseEvent.MOUSE_DOWN, onThisDown);
			}
		}
		
		//test animation not being used	
		private function handleEnterFrame(e:Event):void
		{
			var newY:Number  = 0;
			// calculate scroll distance
			_distanceY = _currentMousePos - _trackerY;
			// apply easing to tracker
			_trackerY += (_distanceY) * .1;
			// update velocity & apply friction		
			_itemVelY += (_distanceY) * _easing;	
			_itemVelY *= _friction;
			//trace ("distanceY",_distanceY,"_currentMousePos",_currentMousePos,"TrackerY",_trackerY,_itemVelY,_easing,_friction);
			// bound velocity to 0 if its too small
			if(_itemVelY < .3 && _itemVelY > -.3 ){
				_itemVelY = 0;
				
				if(!_userMouseDown) removeEventListener(Event.ENTER_FRAME, handleEnterFrame);
			}
			
			// update position 
			//	_item.y += _itemVelY;	
			newY += _itemVelY;	 
			moveHolderTo(newY);
		}
		
		//test animation not being used
		private function handleMouseDown(e:MouseEvent):void {
			_userMouseDown = true;
			_tracker.y = _currentMousePos = e.stageY;
			
			// add mouse tracking
			addEventListener(Event.ENTER_FRAME, handleEnterFrame);	
			stage.addEventListener(MouseEvent.MOUSE_MOVE, handleMouseMove);
			stage.addEventListener(MouseEvent.MOUSE_UP, handleMouseUp);
		}
		
		private function handleMouseMove(e:MouseEvent):void {
			// define current position
			_currentMousePos = e.stageY;
		}
		
		private function handleMouseUp(e:MouseEvent):void {
			_userMouseDown = false;
			
			if(_itemVelY == 0)
				removeEventListener(Event.ENTER_FRAME, handleEnterFrame);
			
			// remove mouse tracking			
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, handleMouseMove);
			stage.removeEventListener(MouseEvent.MOUSE_UP, handleMouseUp);
		}

		
		
		/*
		// works but unnecessary
		private function updateAll():void
		{
			trace('updateAll', _posY);
			
			// find topIndex 
			
			var i:int;
			for (i = 0; i < _offsets.length; i++) // xxx later start from topIndex-was and either increment or decrement
			{
				if (_offsets[i] > _posY) {
					_topIndex = i - 1;
					if (_topIndex == -1) _topIndex = 0;
					trace('topIndex is', _topIndex);
					break;
				}
			}
			
			// remove old items and replace them to their object-pools
			while (_holder.numChildren > 0) {
				var item:ListItem = _holder.removeChildAt(0) as ListItem; // remove from holder
				var itemClass:Class = Object(item).constructor; // add item back to its object-pool
				_pools[itemClass].push(item); 
			}
			
			// add items from _topIndex on:
			
			i = _topIndex;
			var bottom:Number = _posY + _sizeHeight;
			
			do
			{
				addItem(i, false);
				i++;
			}
			while (_offsets[i] < bottom && i < _data.length);
			
			_bottomIndex = i;
		}
		*/
	}
}

// xxx add clever logic to preload while queue is empty maybe
