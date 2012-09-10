﻿
// ColorMatrix Class v2.1
//
// released under MIT License (X11)
// http://www.opensource.org/licenses/mit-license.php
//
// Author: Mario Klingemann
// http://www.quasimondo.com

/*
Copyright (c) 2008 Mario Klingemann

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
 */

// Changes in v1.1:
// Changed the RGB to luminance constants
// Added colorize() method

// Changes in v1.2:
// Added clone() 
// Added randomize() 
// Added blend() 
// Added "filter" property

// Changes in v1.3:
// Added invertAlpha()
// Added thresholdAlpha()

// Changes in v1.4:
// Added luminance2Alpha()

//Changes in v1.5
// Added rotateX();
// Added rotateY();
// Added rotateZ();
// Added shearZ();

//changes in v2.0
// AS3 optimizations
// Added setMultiplicators()
// Added clearChannels()
// Added rotateHue()
// Added transformVector()
// Added applyMatrix()
// Added rotateRed()
// Added rotateGreen()
// Added rotateBlue()
// Added shearRed()
// Added shearGreen()
// Added shearBlue()

//changes in v2.1
// Added applyColorDeficiency()

package leelib.graphics 
{
	import flash.filters.ColorMatrixFilter;

	public class ColorMatrix {

		public static const COLOR_DEFICIENCY_TYPES:Array = ['Protanopia',
															'Protanomaly',
															'Deuteranopia',
															'Deuteranomaly',
															'Tritanopia',
															'Tritanomaly',
															'Achromatopsia',
															'Achromatomaly'];
		// RGB to Luminance conversion constants as found on
		// Charles A. Poynton's colorspace-faq:
		// http://www.faqs.org/faqs/graphics/colorspace-faq/
		private static const LUMA_R:Number = 0.212671;
		private static const LUMA_G:Number = 0.71516;
		private static const LUMA_B:Number = 0.072169;
		// There seem different standards for converting RGB
		// values to Luminance. This is the one by Paul Haeberli:
		private static const LUMA_R2:Number = 0.3086;
		private static const LUMA_G2:Number = 0.6094;
		private static const LUMA_B2:Number = 0.0820;
		private static const ONETHIRD:Number = 1 / 3;
		private static const IDENTITY:Array = [1,0,0,0,0,
											 0,1,0,0,0,
											 0,0,1,0,0,
											 0,0,0,1,0];
		private static const RAD:Number = Math.PI / 180;
		public var matrix:Array;
		private var preHue:ColorMatrix;
		private var postHue:ColorMatrix;
		private var hueInitialized:Boolean;

		/*
		Function: ColorMatrix
	   
		Constructor

		Parameters:

		mat - if omitted matrix gets initialized with an
		identity matrix. Alternatively it can be 
		initialized with another ColorMatrix or 
		an array (there is currently no check 
		if the array is valid. A correct array 
		contains 20 elements.)
				
				
		 */
		public function ColorMatrix( mat:Object = null ) {
			
			if (mat is ColorMatrix ) {
				matrix = mat.matrix.concat();
			} else if (mat is Array ) {
				matrix = mat.concat();
			} else {
				reset();
			}
		}

		
		/*
		Function: reset

		resets the matrix to the neutral identity matrix. Applying this
		matrix to an image will not make any changes to it.

		Parameters:

		none
		  
		Returns:
		
		nothing
		 */
		public function reset():void {
			matrix = IDENTITY.concat();
		}

		
		public function clone():ColorMatrix {
			return new ColorMatrix(matrix);
		}

		
		public function invert():void {
			concat([-1 ,  0,  0, 0, 255,
					  0 , -1,  0, 0, 255,
					  0 ,  0, -1, 0, 255,
					  0,   0,  0, 1,   0]);
		}

		
		/*
		Function: adjustSaturation

		changes the saturation

		Parameters:

		s - typical values come in the range 0.0 ... 2.0 where
		0.0 means 0% Saturation
		0.5 means 50% Saturation
		1.0 is 100% Saturation (aka no change)
		2.0 is 200% Saturation
					 
		Other values outside of this range are possible
		-1.0 will invert the hue but keep the luminance
							
		  
		Returns:
		
		nothing
				
				
		 */
		public function adjustSaturation( s:Number ):void {
            
			var sInv:Number;
			var irlum:Number;
			var iglum:Number;
			var iblum:Number;
            
			sInv = (1 - s);
			irlum = (sInv * LUMA_R);
			iglum = (sInv * LUMA_G);
			iblum = (sInv * LUMA_B);
            
			concat([(irlum + s), iglum, iblum, 0, 0, 
            		irlum, (iglum + s), iblum, 0, 0, 
            		irlum, iglum, (iblum + s), 0, 0, 
            		0, 0, 0, 1, 0]);
		}

		
		/*
		Function: adjustContrast

		changes the contrast

		Parameters:

		s - typical values come in the range -1.0 ... 1.0 where
		-1.0 means no contrast (grey)
		0 means no change
		1.0 is high contrast
					
							
		  
		Returns:
		
		nothing
				
				
		 */
		public function adjustContrast( r:Number, g:Number = NaN, b:Number = NaN ):void {
			if (isNaN(g)) g = r;
			if (isNaN(b)) b = r;
			r += 1;
			g += 1;
			b += 1;
			
			concat([r, 0, 0, 0, (128 * (1 - r)), 
					0, g, 0, 0, (128 * (1 - g)), 
					0, 0, b, 0, (128 * (1 - b)), 
					0, 0, 0, 1, 0]);
		}

		
		public function adjustBrightness(r:Number, g:Number = NaN, b:Number = NaN):void {
			if (isNaN(g)) g = r;
			if (isNaN(b)) b = r;
			concat([1, 0, 0, 0, r, 
            		0, 1, 0, 0, g, 
            		0, 0, 1, 0, b, 
            		0, 0, 0, 1, 0]);
		}

		
		public function adjustHue( degrees:Number ):void {
			degrees *= RAD;
			var cos:Number = Math.cos(degrees);
			var sin:Number = Math.sin(degrees);
			concat([((LUMA_R + (cos * (1 - LUMA_R))) + (sin * -(LUMA_R))), ((LUMA_G + (cos * -(LUMA_G))) + (sin * -(LUMA_G))), ((LUMA_B + (cos * -(LUMA_B))) + (sin * (1 - LUMA_B))), 0, 0, 
            		((LUMA_R + (cos * -(LUMA_R))) + (sin * 0.143)), ((LUMA_G + (cos * (1 - LUMA_G))) + (sin * 0.14)), ((LUMA_B + (cos * -(LUMA_B))) + (sin * -0.283)), 0, 0, 
            		((LUMA_R + (cos * -(LUMA_R))) + (sin * -((1 - LUMA_R)))), ((LUMA_G + (cos * -(LUMA_G))) + (sin * LUMA_G)), ((LUMA_B + (cos * (1 - LUMA_B))) + (sin * LUMA_B)), 0, 0, 
            		0, 0, 0, 1, 0]);
		}

		
		public function rotateHue( degrees:Number ):void {
			initHue();
			
			concat(preHue.matrix);
			rotateBlue(degrees);
			concat(postHue.matrix);
		}

		
		public function luminance2Alpha():void {
			concat([0, 0, 0, 0, 255, 
            		0, 0, 0, 0, 255, 
            		0, 0, 0, 0, 255, 
            		LUMA_R, LUMA_G, LUMA_B, 0, 0]);
		}

		
		public function adjustAlphaContrast(amount:Number):void {
			amount += 1;
			concat([1, 0, 0, 0, 0, 
            		0, 1, 0, 0, 0, 
            		0, 0, 1, 0, 0, 
            		0, 0, 0, amount, (128 * (1 - amount))]);
		}

		
		public function colorize(rgb:int, amount:Number = 1):void {
			var r:Number;
			var g:Number;
			var b:Number;
			var inv_amount:Number;
            
			r = (((rgb >> 16) & 0xFF) / 0xFF);
			g = (((rgb >> 8) & 0xFF) / 0xFF);
			b = ((rgb & 0xFF) / 0xFF);
			inv_amount = (1 - amount);
            
			concat([(inv_amount + ((amount * r) * LUMA_R)), ((amount * r) * LUMA_G), ((amount * r) * LUMA_B), 0, 0, 
            		((amount * g) * LUMA_R), (inv_amount + ((amount * g) * LUMA_G)), ((amount * g) * LUMA_B), 0, 0, 
            		((amount * b) * LUMA_R), ((amount * b) * LUMA_G), (inv_amount + ((amount * b) * LUMA_B)), 0, 0, 
            		0, 0, 0, 1, 0]);
		}

		/*
		public function setChannels( r:int = 1, g:int = 2, b:int = 4, a:int = 8):void {
			var rf:Number = ((((((r & 1) == 1)) ? 1 : 0 + (((r & 2) == 2)) ? 1 : 0) + (((r & 4) == 4)) ? 1 : 0) + (((r & 8) == 8)) ? 1 : 0);
			if (rf > 0) {
				rf = (1 / rf);
			}
			;
			var gf:Number = ((((((g & 1) == 1)) ? 1 : 0 + (((g & 2) == 2)) ? 1 : 0) + (((g & 4) == 4)) ? 1 : 0) + (((g & 8) == 8)) ? 1 : 0);
			if (gf > 0) {
				gf = (1 / gf);
			}
			;
			var bf:Number = ((((((b & 1) == 1)) ? 1 : 0 + (((b & 2) == 2)) ? 1 : 0) + (((b & 4) == 4)) ? 1 : 0) + (((b & 8) == 8)) ? 1 : 0);
			if (bf > 0) {
				bf = (1 / bf);
			}
			;
			var af:Number = ((((((a & 1) == 1)) ? 1 : 0 + (((a & 2) == 2)) ? 1 : 0) + (((a & 4) == 4)) ? 1 : 0) + (((a & 8) == 8)) ? 1 : 0);
			if (af > 0) {
				af = (1 / af);
			}
			;
			concat([(((r & 1) == 1)) ? rf : 0, (((r & 2) == 2)) ? rf : 0, (((r & 4) == 4)) ? rf : 0, (((r & 8) == 8)) ? rf : 0, 0, (((g & 1) == 1)) ? gf : 0, (((g & 2) == 2)) ? gf : 0, (((g & 4) == 4)) ? gf : 0, (((g & 8) == 8)) ? gf : 0, 0, (((b & 1) == 1)) ? bf : 0, (((b & 2) == 2)) ? bf : 0, (((b & 4) == 4)) ? bf : 0, (((b & 8) == 8)) ? bf : 0, 0, (((a & 1) == 1)) ? af : 0, (((a & 2) == 2)) ? af : 0, (((a & 4) == 4)) ? af : 0, (((a & 8) == 8)) ? af : 0, 0]);
		}
		*/

		
		public function blend(mat:ColorMatrix, amount:Number):void {
			var inv_amount:Number = (1 - amount);
			var i:int = 0;
			while (i < 20) {
				matrix[i] = ((inv_amount * Number(matrix[i])) + (amount * Number(mat.matrix[i])));
				i++;
			}
			;
		}

		
		public function average( r:Number = ONETHIRD, g:Number = ONETHIRD, b:Number = ONETHIRD):void {
			concat([r, g, b, 0, 0, 
            		r, g, b, 0, 0, 
            		r, g, b, 0, 0, 
            		0, 0, 0, 1, 0]);
		}

		
		public function threshold(threshold:Number, factor:Number = 256):void {
			concat([(LUMA_R * factor), (LUMA_G * factor), (LUMA_B * factor), 0, (-(factor) * threshold), 
            		(LUMA_R * factor), (LUMA_G * factor), (LUMA_B * factor), 0, (-(factor) * threshold), 
            		(LUMA_R * factor), (LUMA_G * factor), (LUMA_B * factor), 0, (-(factor) * threshold), 
            		0, 0, 0, 1, 0]);
		}

		
		public function desaturate():void {
			concat([LUMA_R, LUMA_G, LUMA_B, 0, 0, 
            		LUMA_R, LUMA_G, LUMA_B, 0, 0, 
            		LUMA_R, LUMA_G, LUMA_B, 0, 0, 
            		0, 0, 0, 1, 0]);
		}

		
		public function randomize(amount:Number = 1):void {
			var inv_amount:Number = (1 - amount);
			var r1:Number = (inv_amount + (amount * (Math.random() - Math.random())));
			var g1:Number = (amount * (Math.random() - Math.random()));
			var b1:Number = (amount * (Math.random() - Math.random()));
			var o1:Number = ((amount * 0xFF) * (Math.random() - Math.random()));
			var r2:Number = (amount * (Math.random() - Math.random()));
			var g2:Number = (inv_amount + (amount * (Math.random() - Math.random())));
			var b2:Number = (amount * (Math.random() - Math.random()));
			var o2:Number = ((amount * 0xFF) * (Math.random() - Math.random()));
			var r3:Number = (amount * (Math.random() - Math.random()));
			var g3:Number = (amount * (Math.random() - Math.random()));
			var b3:Number = (inv_amount + (amount * (Math.random() - Math.random())));
			var o3:Number = ((amount * 0xFF) * (Math.random() - Math.random()));
           
			concat([r1, g1, b1, 0, o1, 
            		r2, g2, b2, 0, o2, 
            		r3, g3, b3, 0, o3, 
            		0, 0, 0, 1, 0]);
		}

		
		public function setMultiplicators( red:Number = 1, green:Number = 1, blue:Number = 1, alpha:Number = 1 ):void {
			var mat:Array = new Array(red, 0, 0, 0, 0, 0, green, 0, 0, 0, 0, 0, blue, 0, 0, 0, 0, 0, alpha, 0);
			
			concat(mat);
		}

		
		public function clearChannels( red:Boolean = false, green:Boolean = false, blue:Boolean = false, alpha:Boolean = false ):void {
			if ( red ) {
				matrix[0] = matrix[1] = matrix[2] = matrix[3] = matrix[4] = 0;
			}
			if ( green ) {
				matrix[5] = matrix[6] = matrix[7] = matrix[8] = matrix[9] = 0;
			}
			if ( blue ) {
				matrix[10] = matrix[11] = matrix[12] = matrix[13] = matrix[14] = 0;
			}
			if ( alpha ) {
				matrix[15] = matrix[16] = matrix[17] = matrix[18] = matrix[19] = 0;
			}
		}

		
		public function thresholdAlpha( threshold:Number, factor:Number = 256):void {
			concat([1, 0, 0, 0, 0, 
            		0, 1, 0, 0, 0, 
            		0, 0, 1, 0, 0, 
            		0, 0, 0, factor, (-factor * threshold)]);
		}

		
		public function averageRGB2Alpha():void {
			concat([0, 0, 0, 0, 255, 
            		0, 0, 0, 0, 255, 
            		0, 0, 0, 0, 255, 
            		ONETHIRD, ONETHIRD, ONETHIRD, 0, 0]);
		}

		
		public function invertAlpha():void {
			concat([1, 0, 0, 0, 0, 
            		0, 1, 0, 0, 0, 
            		0, 0, 1, 0, 0, 
            		0, 0, 0, -1, 255]);
		}

		
		public function rgb2Alpha( r:Number, g:Number, b:Number ):void {
			concat([0, 0, 0, 0, 255, 
            		0, 0, 0, 0, 255, 
            		0, 0, 0, 0, 255, 
            		r, g, b, 0, 0]);
		}

		
		public function setAlpha(alpha:Number):void {
			concat([1, 0, 0, 0, 0, 
            		0, 1, 0, 0, 0, 
            		0, 0, 1, 0, 0, 
            		0, 0, 0, alpha, 0]);
		}

		
		public function get filter():ColorMatrixFilter {
			return new ColorMatrixFilter(matrix);
		}

		
		public function concat( mat:Array ):void {
			
			var temp:Array = [];
			var i:int = 0;
			var x:int, y:int;
			for (y = 0;y < 4; y++ ) {
				
				for (x = 0;x < 5; x++ ) {
					temp[ int(i + x) ] = Number(mat[i  ]) * Number(matrix[x]) + Number(mat[int(i + 1)]) * Number(matrix[int(x + 5)]) + Number(mat[int(i + 2)]) * Number(matrix[int(x + 10)]) + Number(mat[int(i + 3)]) * Number(matrix[int(x + 15)]) + (x == 4 ? Number(mat[int(i + 4)]) : 0);
				}
				i += 5;
			}
			
			matrix = temp;
		}

		
		public function rotateRed( degrees:Number ):void {
			rotateColor(degrees, 2, 1); 
		}

		
		public function rotateGreen( degrees:Number ):void {
			rotateColor(degrees, 0, 2); 
		}

		
		public function rotateBlue( degrees:Number ):void {
			rotateColor(degrees, 1, 0); 
		}

		
		private function rotateColor( degrees:Number, x:int, y:int ):void {
			degrees *= RAD;
			var mat:Array = IDENTITY.concat();
			mat[ x + x * 5 ] = mat[ y + y * 5 ] = Math.cos(degrees);
			mat[ y + x * 5 ] = Math.sin(degrees);
			mat[ x + y * 5 ] = -Math.sin(degrees);
			concat(mat);
		}

		
		public function shearRed( green:Number, blue:Number ):void {
			shearColor(0, 1, green, 2, blue);
		}

		
		public function shearGreen( red:Number, blue:Number ):void {
			shearColor(1, 0, red, 2, blue);
		}

		
		public function shearBlue( red:Number, green:Number ):void {
			shearColor(2, 0, red, 1, green);
		}

		
		private function shearColor( x:int, y1:int, d1:Number, y2:int, d2:Number ):void {
			var mat:Array = IDENTITY.concat();
			mat[ y1 + x * 5 ] = d1;
			mat[ y2 + x * 5 ] = d2;
			concat(mat);
		}

		
		public function applyColorDeficiency( type:String ):void {
			// the values of this method are copied from http://www.nofunc.com/Color_Matrix_Library/ 
			switch ( type ) {
				case 'Protanopia':
					concat([0.567,0.433,0,0,0, 0.558,0.442,0,0,0, 0,0.242,0.758,0,0, 0,0,0,1,0]);
					break;
				case 'Protanomaly':
					concat([0.817,0.183,0,0,0, 0.333,0.667,0,0,0, 0,0.125,0.875,0,0, 0,0,0,1,0]);
					break;
				case 'Deuteranopia':
					concat([0.625,0.375,0,0,0, 0.7,0.3,0,0,0, 0,0.3,0.7,0,0, 0,0,0,1,0]);
					break;
				case 'Deuteranomaly':
					concat([0.8,0.2,0,0,0, 0.258,0.742,0,0,0, 0,0.142,0.858,0,0, 0,0,0,1,0]);
					break;
				case 'Tritanopia':
					concat([0.95,0.05,0,0,0, 0,0.433,0.567,0,0, 0,0.475,0.525,0,0, 0,0,0,1,0]);
					break;
				case 'Tritanomaly':
					concat([0.967,0.033,0,0,0, 0,0.733,0.267,0,0, 0,0.183,0.817,0,0, 0,0,0,1,0]);
					break;
				case 'Achromatopsia':
					concat([0.299,0.587,0.114,0,0, 0.299,0.587,0.114,0,0, 0.299,0.587,0.114,0,0, 0,0,0,1,0]);
					break;
				case 'Achromatomaly':
					concat([0.618,0.320,0.062,0,0, 0.163,0.775,0.062,0,0, 0.163,0.320,0.516,0,0, 0,0,0,1,0]);
					break;
			}
		}

		
		public function applyMatrix( rgba:uint ):uint {
			var a:Number = ( rgba >>> 24 ) & 0xff;
			var r:Number = ( rgba >>> 16 ) & 0xff;
			var g:Number = ( rgba >>> 8 ) & 0xff;
			var b:Number = rgba & 0xff;
       		
			var r2:int = 0.5 + r * matrix[0] + g * matrix[1] + b * matrix[2] + a * matrix[3] + matrix[4];
			var g2:int = 0.5 + r * matrix[5] + g * matrix[6] + b * matrix[7] + a * matrix[8] + matrix[9];
			var b2:int = 0.5 + r * matrix[10] + g * matrix[11] + b * matrix[12] + a * matrix[13] + matrix[14];
			var a2:int = 0.5 + r * matrix[15] + g * matrix[16] + b * matrix[17] + a * matrix[18] + matrix[19];
       		
			if ( a2 < 0 ) a2 = 0;
			if ( a2 > 255 ) a2 = 255;
			if ( r2 < 0 ) r2 = 0;
			if ( r2 > 255 ) r2 = 255;
			if ( g2 < 0 ) g2 = 0;
			if ( g2 > 255 ) g2 = 255;
			if ( b2 < 0 ) b2 = 0;
			if ( b2 > 255 ) b2 = 255;
       		
			return a2 << 24 | r2 << 16 | g2 << 8 | b2;
		}

		
		public function transformVector( values:Array ):void {
			if ( values.length != 4) return;
        	
			var r:Number = values[0] * matrix[0] + values[1] * matrix[1] + values[2] * matrix[2] + values[3] * matrix[3] + matrix[4];
			var g:Number = values[0] * matrix[5] + values[1] * matrix[6] + values[2] * matrix[7] + values[3] * matrix[8] + matrix[9];
			var b:Number = values[0] * matrix[10] + values[1] * matrix[11] + values[2] * matrix[12] + values[3] * matrix[13] + matrix[14];
			var a:Number = values[0] * matrix[15] + values[1] * matrix[16] + values[2] * matrix[17] + values[3] * matrix[18] + matrix[19];
       		
			values[0] = r;
			values[1] = g;
			values[2] = b;
			values[3] = a;
		}

		
		private function initHue():void {
			
			//var greenRotation:Number = 35.0;
			var greenRotation:Number = 39.182655;

			if (!hueInitialized) {
				hueInitialized = true;
				preHue = new ColorMatrix();
				preHue.rotateRed(45);
				preHue.rotateGreen(-greenRotation);
	
				var lum:Array = [LUMA_R2, LUMA_G2, LUMA_B2, 1.0];
	
				preHue.transformVector(lum);
	
				var red:Number = lum[0] / lum[2];
				var green:Number = lum[1] / lum[2];
	
				preHue.shearBlue(red, green);
	
				postHue = new ColorMatrix();
				postHue.shearBlue(-red, -green);
				postHue.rotateGreen(greenRotation);
				postHue.rotateRed(-45.0);
			}
		}
	}
}