package leelib.appropriated
{
	import flash.errors.IllegalOperationError;
	import flash.system.System;

    // Original: http://adiinteractive.blogspot.com/2006/05/generating-guid-globally-unique.html
	// Lee: Small edits
    
    public class Guid 
    {
        private static var counter:Number = 0;
        
        public function Guid(){
			throw new IllegalOperationError("Use static function Guid.create()");
        }
        
        public static function create():String {
            var id1:String = new Date().getTime().toString();
            var id2:String = (Math.random()*Number.MAX_VALUE).toString(); 
			var id3:String = (Math.random()*Number.MAX_VALUE).toString(); // System.capabilities.serverString;
            return calculate(id1+id2+counter++).toUpperCase();
        }

        private static function calculate(src:String):String 
		{
            var s:String = hex_sha1(src);
			return [s.substr(0, 8), s.substr(8, 4), s.substr(12, 4), s.substr(16, 4), s.substr(20, 12)].join("-")
        }

        private static function hex_sha1(src:String):String {
                return binb2hex(core_sha1(str2binb(src), src.length*8));
        }
            
        private static function core_sha1(x:Array, len:Number):Array {
            x[len >> 5] |= 0x80 << (24-len%32);
            x[((len+64 >> 9) << 4)+15] = len;
            var w:Array = new Array(80), a:Number = 1732584193;
            var b:Number = -271733879, c:Number = -1732584194;
            var d:Number = 271733878, e:Number = -1009589776;
            for (var i:Number = 0; i<x.length; i += 16) {
                var olda:Number = a, oldb:Number = b;
                var oldc:Number = c, oldd:Number = d, olde:Number = e;
                for (var j:Number = 0; j<80; j++) {
                    if (j<16) w[j] = x[i+j];
                    else w[j] = rol(w[j-3] ^ w[j-8] ^ w[j-14] ^ w[j-16], 1);
                    var t:Number = safe_add(safe_add(rol(a, 5), sha1_ft(j, b, c, d)), safe_add(safe_add(e, w[j]), sha1_kt(j)));
                    e = d; d = c;
                    c = rol(b, 30);
                    b = a; a = t;
                }
                a = safe_add(a, olda);
                b = safe_add(b, oldb);
                c = safe_add(c, oldc);
                d = safe_add(d, oldd);
                e = safe_add(e, olde);
            }
            return new Array(a, b, c, d, e);
        }

        private static function sha1_ft(t:Number, b:Number, c:Number, d:Number):Number {
            if (t<20) return (b & c) | ((~b) & d);
            if (t<40) return b ^ c ^ d;
            if (t<60) return (b & c) | (b & d) | (c & d);
            return b ^ c ^ d;
        }

        private static function sha1_kt(t:Number):Number {
            return (t<20) ? 1518500249 : (t<40) ? 1859775393 : (t<60) ? -1894007588 : -899497514;
        }

        private static function safe_add(x:Number, y:Number):Number {
            var lsw:Number = (x & 0xFFFF)+(y & 0xFFFF);
            var msw:Number = (x >> 16)+(y >> 16)+(lsw >> 16);
            return (msw << 16) | (lsw & 0xFFFF);
        }

        private static function rol(num:Number, cnt:Number):Number {
            return (num << cnt) | (num >>> (32-cnt));
        }

        private static function str2binb(str:String):Array {
            var bin:Array = new Array();
            var mask:Number = (1 << 8)-1;
            for (var i:Number = 0; i<str.length*8; i += 8) {
                bin[i >> 5] |= (str.charCodeAt(i/8) & mask) << (24-i%32);
            }
            return bin;
        }

        private static function binb2hex(binarray:Array):String {
            var str:String = new String("");
            var tab:String = new String("0123456789abcdef");
            for (var i:Number = 0; i<binarray.length*4; i++) {
                str += tab.charAt((binarray[i >> 2] >> ((3-i%4)*8+4)) & 0xF) + tab.charAt((binarray[i >> 2] >> ((3-i%4)*8)) & 0xF);
            }
            return str;
        }
    }
}
