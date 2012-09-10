package leelib.screens
{
	import leelib.interfaces.*;
	import leelib.ui.ListView;
	import flash.errors.IllegalOperationError;

	public class ListAcScreen extends AcScreen implements IListScreen
	{
		public function ListAcScreen()
		{
			super();
		}
		
		public function set listView(value:ListView):void
		{
			throw new IllegalOperationError("ListAcScreen subclasses should override set listView");
		}
		
		public function get listView():ListView
		{
			throw new IllegalOperationError("ListAcScreen subclasses should override get listView");
		}
		
	}
}
