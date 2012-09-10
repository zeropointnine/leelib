package leelib.interfaces
{
	import flash.display.BitmapData;
	
	import leelib.ui.ListView;

	public interface IListScreen
	{
		function set listView(listView:ListView):void
		function get listView():ListView;
	}
}
