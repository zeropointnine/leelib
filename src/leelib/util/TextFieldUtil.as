package leelib.util
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.filters.ColorMatrixFilter;
	import flash.geom.ColorTransform;
	import flash.text.*;

	
	public class TextFieldUtil
	{ 
		private static var _defaultStyleSheet:StyleSheet;


		public static function getTextFormat(fontFamily:String,fontSize:int,fontColor:uint) :TextFormat
		{
			if (!findEmbeddedFont(fontFamily))
			{
				throw new Error("Font: "+fontFamily+" - Not Found in System to apply to textFormat");
			}
			
			var tf:TextFormat 	= new TextFormat(fontFamily, fontSize, fontColor, true);
			tf.letterSpacing 	= 0.45;
			return tf;
		}

		public static function set defaultStyleSheet($styleSheet:StyleSheet):void
		{
			if (_defaultStyleSheet) Out.w('TextFieldUtil.defaultStyleSheet already defined');
			_defaultStyleSheet = $styleSheet;
			
			// Out.i('TextFieldUtil._defaultStyleSheet = ' + _defaultStyleSheet);
		}
		
		public static function get defaultStyleSheet():StyleSheet
		{
			return _defaultStyleSheet;
		}
		
		private static function isSystemFont($textFormat:TextFormat):Boolean
		{
			return ($textFormat.font == "_sans" || $textFormat.font == "_serif"); // not good enough
		}
		
		public static function makeText( $text:String, $styleName:String, $forcedWidth:Number=NaN, $forcedHeight:Number=NaN, $stylesheet:StyleSheet=null): TextField 
		{
			if ($stylesheet == null) $stylesheet = _defaultStyleSheet;
			
			var tf:TextField = new TextField(); 
			var style:Object = $stylesheet.getStyle($styleName);

			tf.defaultTextFormat = $stylesheet.transform(style);
			tf.styleSheet = $stylesheet 
			tf.embedFonts = ! isSystemFont(tf.defaultTextFormat);
			
			tf.htmlText = $text;
			
			// My preferences:
			tf.antiAliasType = AntiAliasType.ADVANCED;
			tf.selectable = false;
			tf.mouseEnabled = false;
			tf.wordWrap = false;
			tf.multiline = true;
			
			//
			
			tf.autoSize = TextFieldAutoSize.LEFT;
			
			var w:Number = tf.width;
			var h:Number = tf.height;
			if ($forcedWidth || $forcedHeight) {
				tf.autoSize = TextFieldAutoSize.NONE;
				tf.width = ($forcedWidth || w);
				tf.height = ($forcedHeight || h);
			}
			
			//
			
			addValue(tf, style);

			return tf;
		}
		
		public static function makeTextWithFormat( $text:String, $textFormat:TextFormat, $forcedWidth:Number=NaN, $forcedHeight:Number=NaN): TextField
		{
			var tf:TextField = new TextField(); 
			tf.defaultTextFormat = $textFormat;
			tf.embedFonts = ! isSystemFont(tf.defaultTextFormat);
			tf.htmlText = $text;
			
			// My preferences:
			tf.antiAliasType = AntiAliasType.ADVANCED;
			tf.selectable = false;
			tf.mouseEnabled = false;
			tf.wordWrap = false;
			tf.multiline = true;
			
			//
			
			tf.autoSize = TextFieldAutoSize.LEFT;
			
			var w:Number = tf.width;
			var h:Number = tf.height;
			if ($forcedWidth || $forcedHeight) {
				tf.autoSize = TextFieldAutoSize.NONE;
				tf.width = ($forcedWidth || w);
				tf.height = ($forcedHeight || h);
			}
			
			return tf;
		}

		public static function makeTextQuick($text:String, $size:uint=12, $color:uint=0x0):TextField
		{
			var tf:TextField = new TextField();
			tf.defaultTextFormat = new TextFormat("_sans", $size, $color, true);
			tf.text = $text;
			tf.filters = [ new ColorMatrixFilter() ];
			tf.autoSize = TextFieldAutoSize.LEFT;
			tf.mouseEnabled= false;
			
			return tf;
		}
		
		public static function makeInput( $text:String , $width:Number, $styleName:String, $maxChars:int=-1, $stylesheet:StyleSheet=null): TextField // rework me 
		{
			if ($stylesheet == null) $stylesheet = _defaultStyleSheet;
			
			var tf:TextField = new TextField(); 
			var style:Object = $stylesheet.getStyle($styleName);
			
			tf.defaultTextFormat = $stylesheet.transform(style);
			tf.embedFonts = ! isSystemFont(tf.defaultTextFormat);
			tf.autoSize = TextFieldAutoSize.NONE;
			tf.selectable = true;
			tf.mouseEnabled = true;
			tf.antiAliasType = AntiAliasType.ADVANCED;
			tf.wordWrap = false;
			tf.multiline = false;
			tf.text = $text;
			
			tf.type = TextFieldType.INPUT;
			tf.width = $width;
			tf.height = tf.textHeight + 5;
			
			if ($maxChars > -1) tf.maxChars = $maxChars;
			
			addValue(tf, style);
			
			return tf;
		}

		
		/**
		 * If $styleName exists, html text is wrapped with a span tag
		 * If $width or $height is false, autoSize is set to LEFT
		 * 
		 * TODO: Do case where only $w or $h is set
		 */
		public static function makeHtmlText($text:String, $styleName:String=null, $width:Number=NaN, $height:Number=NaN, $stylesheet:StyleSheet=null):TextField
		{
			if ($stylesheet == null) $stylesheet = _defaultStyleSheet;

			var tf:TextField = new TextField();
			
			var style:Object;
			if ($styleName) {
				style = $stylesheet.getStyle($styleName);
				tf.defaultTextFormat = $stylesheet.transform(style);
			}

			tf.styleSheet = $stylesheet; 	
			tf.embedFonts = ! isSystemFont(tf.defaultTextFormat);
			if (tf.embedFonts) tf.antiAliasType = AntiAliasType.ADVANCED;
			if (!$width || !$height) {
				tf.autoSize = TextFieldAutoSize.LEFT;
			} else {
				tf.autoSize = TextFieldAutoSize.NONE;
				tf.width = $width;
				tf.height = $height;
			}
			tf.selectable = false;
			tf.mouseEnabled = true;
			tf.wordWrap = true; 
			tf.multiline = true;

			if (style) addValue(tf, style);

			tf.mouseWheelEnabled = false;  

			tf.width = $width;
			tf.height = $height;

			if ($styleName) $text = "<span class='" + $styleName + "'>" + $text + "</span>";
			tf.htmlText = $text;

			
			return tf; 
		}
		
		/**
		 * Makes TextField for HTML/multiline w/o stylesheet
		 */
		public static function makeHtmlText2($text:String, $width:Number, $height:Number, $textFormat:TextFormat):TextField
		{
			var tf:TextField = new TextField();
			tf.defaultTextFormat = $textFormat;
			tf.embedFonts = ! isSystemFont(tf.defaultTextFormat);
			if (tf.embedFonts) tf.antiAliasType = AntiAliasType.ADVANCED;
			tf.autoSize = TextFieldAutoSize.NONE;	
			tf.selectable = false;
			tf.mouseEnabled = false;
			tf.wordWrap = true; 
			tf.multiline = true;
			tf.mouseWheelEnabled = false;  
			
			tf.width = $width;
			tf.height = $height;
			
			tf.htmlText = $text;
			
			return tf; 
		}
		
		private static function addValue($tf:TextField, $style:Object):void
		{
			var n:Number = parseFloat($style.thickness);
			if (! isNaN(n)) $tf.thickness = n; 
			n = parseFloat($style.sharpness);
			if (! isNaN(n)) $tf.sharpness = n; 
			n = parseFloat($style.alpha);
			if (! isNaN(n)) $tf.alpha = n; 
			n = parseFloat($style.x);
			if (! isNaN(n)) $tf.x = n; 
			n = parseFloat($style.y);
			if (! isNaN(n)) $tf.y = n; 
		}
		

		public static function styleToTextFormat($styleName:String, $stylesheet:StyleSheet=null):TextFormat
		{
			if (! $stylesheet) $stylesheet = _defaultStyleSheet; 
			var style:Object = $stylesheet.getStyle($styleName);
			return $stylesheet.transform(style);  
		}

		/**
		 * Apply a style to a preexisting textfield.
		 */
		public static function applyAndMakeDefaultStyle($tf:TextField, $styleName:String, $stylesheet:StyleSheet=null):void  
		{
			if (! $stylesheet) $stylesheet = _defaultStyleSheet; 
			var style:Object = $stylesheet.getStyle($styleName);
			if ($tf.styleSheet) $tf.styleSheet = null;
			$tf.defaultTextFormat = $stylesheet.transform(style);  
			$tf.embedFonts = ! isSystemFont($tf.defaultTextFormat);
			$tf.setTextFormat(  $stylesheet.transform(style)  );
			$tf.antiAliasType = AntiAliasType.ADVANCED;
		} 
		
		public static function getColorFromStyle($styleName:String, $stylesheet:StyleSheet=null):uint
		{
			if (! $stylesheet) $stylesheet = _defaultStyleSheet; 
			var style:Object = $stylesheet.getStyle($styleName);
			var s:String = style["color"]; // .. assumes a string value in the format "#HHHHHH"
			if (s.indexOf("#") == 0) s = s.substr(1);
			return parseInt(s,16);
		}
		
		public static function createTextFormatFromStyleName($styleName:String, $stylesheet:StyleSheet=null):TextFormat
		{
			if (! $stylesheet) $stylesheet = _defaultStyleSheet; 
			var style:Object = $stylesheet.getStyle($styleName);
			return $stylesheet.transform(style);  
		}
		
		public static function getFontByName($fontName: String): Font 
		{
			var fontArray: Array = Font.enumerateFonts(false);
			for (var i: int = 0; i < fontArray.length; i++) {
				if (Font(fontArray[i]).fontName == $fontName) return fontArray[i];
			}
			return null;
		}
		
		public static function ellipsize($tf:TextField, $width:Number):void
		{
			// Assumes non-html-text
			
			if ($tf.textWidth <= $width || $tf.text.length <= 2) return;
			
			var s:String = $tf.text;
			do
			{
				s = s.substr(0, s.length - 1);
				$tf.text = s + "...";
			}
			while ($tf.textWidth > $width && $tf.text.length > 0)
		}
		
		//
		
		/**
		 * Sets the field's selection color and tries to handle changing the field's background, 
		 * border and text colors to maintain their initial values.
		 * 
		 * http://yourpalmark.com/2007/08/13/changing-selection-color-on-dynamic-textfields/
		 * 
		 * Not a perfect solution, but probably good enough
		 * 
		 * NOTE! borderColor is colortransformed, too, so if you set borderColor yourself, adjust accordingly! 
		 */
		public static function setSelectionColor( field:TextField, color:uint ):void
		{
			field.backgroundColor = invert( field.backgroundColor );
			field.borderColor = invert( field.borderColor );
			field.textColor = invert( field.textColor );
			
			var colorTrans:ColorTransform = new ColorTransform();
			colorTrans.color = color;
			colorTrans.redMultiplier = -1;
			colorTrans.greenMultiplier = -1;
			colorTrans.blueMultiplier = -1;
			field.transform.colorTransform = colorTrans;
		}
		private static function invert( color:uint ):uint
		{
			var colorTrans:ColorTransform = new ColorTransform();
			colorTrans.color = color;
			
			return invertColorTransform( colorTrans ).color;
		}
		private static function invertColorTransform( colorTrans:ColorTransform ):ColorTransform
		{
			with( colorTrans )
			{
				redMultiplier = -redMultiplier;
				greenMultiplier = -greenMultiplier;
				blueMultiplier = -blueMultiplier;
				redOffset = 255 - redOffset;
				greenOffset = 255 - greenOffset;
				blueOffset = 255 - blueOffset;
			}
			
			return colorTrans;
		}
		
		/**
		 * Scenario: Your stylesheet uses text sizes normalized for certain screen properties,
		 * but they need to be converted. 
		 * 
		 * $referenceValue and $yourValue should be of size unit, like DPI, or maybe screen width.
		 */
		public static function convertStyleSheetTextSizes($ss:StyleSheet, $referenceValue:Number, $yourValue:Number):void
		{
			var ratio:Number = $yourValue / $referenceValue;
			
			for (var i:int = 0; i < $ss.styleNames.length; i++)
			{
				var styleName:String = $ss.styleNames[i];
				var o:Object = $ss.getStyle(styleName);

				// TODO: do same thing for leading, letter-spacing
				
				var size:Number;
				if (o["fontSize"]) size = parseFloat(o["fontSize"]);
				if (size > 0) {
					size *= ratio;
					size = MathUtil.round(size, 0.5);
					o["fontSize"] = size.toString();
					$ss.setStyle(styleName, o); // apply modified style
				}
			}

			/*
			trace('sanity');
			for (var i:int = 0; i < $ss.styleNames.length; i++) {
				var styleName:String = $ss.styleNames[i];
				var o:Object = $ss.getStyle(styleName);
				for (var key:String in o) { trace(i, key, o[key], typeof o[key]); }
			}
			*/
		}
		
		public static function findEmbeddedFont(value:String):Boolean
		{
			var fonts:Array = Font.enumerateFonts();
			var font:Font;
			var hasFont:Boolean = false;
			for(var i:int; i<fonts.length;i++)
			{
				font = fonts[i];
				//trace("name : "+font.fontName);
				//trace("style : "+font.fontStyle);
				//trace("type : "+font.fontType);
				hasFont = Boolean(font.fontName);
			}
			return hasFont;
		}
	}
}
