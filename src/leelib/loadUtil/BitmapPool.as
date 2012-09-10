package leelib.loadUtil
{
	import flash.display.BitmapData;

	/**
	 * Coded for mobile list components that use predictable image sizes.
	 */
	public class BitmapPool
	{
		private var _items:Array = [];
		private var _size:uint = 0; 
		private var _maxPx:uint;
		private var _counter:int = -1;
		private var _backCounter:int = -1;
		
		/**
		 * @param $numPixels 	Must be large enough to accomodate a few 'pages' worth of list items.
		 * 						Otherwise, more logic needed when bitmaps are disposed to check if they're currently in use.
		 */
		public function BitmapPool($numPixels:uint)
		{
			_maxPx = $numPixels;
		}

		public function add($key:String, $b:BitmapData):void
		{
			_counter++;

			var o:Object = { bitmap:$b, counter:_counter };
			_items[$key] = o;

			_size += $b.width * $b.height;
			
			// trace('cache add:', $key, 'capacity:', _size / _maxPx, 'counter:', _counter, 'backCounter:', _backCounter);

			while (_size > _maxPx)
			{
				_backCounter++;

				// O(n) lookup
				for (var key:String in _items)
				{
					var o2:Object = _items[key];
					if (o2.counter == _backCounter)
					{
						_size -= o2.bitmap.width * o2.bitmap.height;
						trace('BitmapPool - killing bitmap:', key);
						o2.bitmap.dispose();
						delete _items[key]
						break;
						// ... of course bitmapData should not be in use
						//	   otherwise, need more logic
					}
				}
			}
		}
		
		public function getBitmap($key:String):BitmapData
		{
			if (_items[$key])
			{
				// trace('cache hit:', $key);
				return _items[$key].bitmap;
			}
			return null;
		}
		
		public function clear():void
		{
			for each (var o:Object in _items)
			{
				o.bitmap.dispose();
			}
			_items = [];
			_counter = -1;
			_backCounter = -1;
		}
	}
}
