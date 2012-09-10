package leelib.ui
{
	import flash.events.Event;
	

	// Note, updates own state.
	// Not currently designed to have num buttons change dynamically.
	//
	// For concrete use, best to make a static 'factory' method off a Button subclass,
	// that kind of thing.
	//
	public class ButtonBar extends Component
	{
		protected var _buttons:Vector.<MobileButton>;
		private var _margin:Number;
		private var _enabled:Boolean;
		private var _selectedIndex:int = -1;
		
		private var _flagSelectednessTransition:Boolean;
		
		/**
		 * Buttons expected to be already baked. 
		 * Their positions will be changed, but not their sizes.
		 */
		public function ButtonBar($buttons:Array, $margin:Number)
		{
			super();
			_buttons = Vector.<MobileButton>($buttons);
			_margin = $margin;
		}

		protected override function doInit():void
		{
			for (var i:int = 0; i < _buttons.length; i++) {
				_buttons[i].addEventListener(Event.SELECT, onButtonSelect);
				this.addChild(_buttons[i]);
			}

			// Overwrites sizeWidth/Height values:
			_sizeWidth = 0;
			for (i = 0; i < _buttons.length; i++)
			{
				var b:MobileButton = _buttons[i];
				_sizeWidth += b.width;
				if (i < _buttons.length-1) _sizeWidth += _margin;
			}
			_sizeHeight = _buttons[0].height;
			enabled = true;
		}
		
		public override function size():void
		{
			var x:Number = 0;
			for (var i:int = 0; i < _buttons.length; i++)
			{
				_buttons[i].x = x;
				x += _buttons[i].width + _margin;
			}
		}
		
		public function get enabled():Boolean
		{
			return _enabled;
		}
		public function set enabled($b:Boolean):void
		{
			_enabled = $b;
			
			this.mouseChildren = _enabled;
			this.alpha = (_enabled ? 1 : 0.5); // for now			
		}

		public function get buttons():Vector.<MobileButton>
		{
			return _buttons;
		}
		
		public function get selectedIndex():int
		{
			return _selectedIndex;
		}
		public function set selectedIndex($i:int):void
		{
			_selectedIndex = $i;
			updateButtonSelectedness();
		}
		
		//
		
		protected function updateButtonSelectedness():void
		{
			for (var i:int = 0; i < _buttons.length; i++)
			{
				_buttons[i].setSelected(i == _selectedIndex, _flagSelectednessTransition);
			}
			
			if (_flagSelectednessTransition) _flagSelectednessTransition = false;
		}
		
		protected function onButtonSelect($e:Event):void
		{
			_flagSelectednessTransition = true;
			selectedIndex = _buttons.indexOf($e.target);
			
			this.dispatchEvent(new Event(Event.SELECT));
		}
	}
}
