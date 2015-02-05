/**
 * TGADecoder.as
 * 
 * @see http://snippets.libspark.org/
 * @see http://snippets.libspark.org/trac/wiki/rch850/Metasequoia
 *
 * Copyright (c) 2008 rch850
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

package Utils{
	import flash.display.BitmapData;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	public class TGADecoder {
		//___________________________________________________________ const
		
		// constant value for _imageType
		private const TYPE_NONE:uint = 0x00;
		private const TYPE_INDEX_COLOR:uint = 0x01;
		private const TYPE_FULL_COLOR:uint = 0x02;
		private const TYPE_RLE_BIT:uint = 0x08;
		
		private const DIR_RIGHT_UP:int = 0;
		private const DIR_LEFT_UP:int = 1;
		private const DIR_RIGHT_DOWN:int = 2;
		private const DIR_LEFT_DOWN:int = 3;
		
		//___________________________________________________________ vars
		
		private var _bitmap:BitmapData;
		public function get bitmap():BitmapData {
			return _bitmap;
		}
		
		private var _idLength:int; // byte
		private var _colorMapType:int; // byte
		private var _imageType:int; // byte
		private var _colorMapIndex:int; // short
		private var _colorMapLength:int; // short
		private var _colorMapSize:int; // byte
		private var _originX:int; // short
		private var _originY:int; // short
		private var _width:int; // short
		public function get width():int {
			return _width;
		}
		private var _height:int; // short
		public function get height():int {
			return _height;
		}
		private var _bitDepth:int; // byte
		private var _descriptor:int; // byte
		public function get pixelDirection():int {
			// descriptor:
			//   4th bit: 0 = left to right, 1 = right to left
			//   5th bit: 0 = bottom up, 1 = top down
			return (_descriptor >> 4) & 3;
		}
		
		/**
		 * Construct TGA file from ByteArray.
		 */
		public function TGADecoder(bytes:ByteArray) {
			bytes.position = 0;
			bytes.endian = Endian.LITTLE_ENDIAN;
			
			_idLength = bytes.readByte();
			_colorMapType = bytes.readByte();
			_imageType = bytes.readByte();
			_colorMapIndex = bytes.readShort();
			_colorMapLength = bytes.readShort();
			_colorMapSize = bytes.readByte()
			_originX = bytes.readShort();
			_originY = bytes.readShort();
			_width = bytes.readShort();
			_height = bytes.readShort();
			_bitDepth = bytes.readByte();
			_descriptor = bytes.readByte();
			
			_bitmap = new BitmapData(_width, _height);
			
			// ignore unsupported formats.
			if ((_imageType & TYPE_FULL_COLOR) == 0
				|| (_imageType & TYPE_RLE_BIT) != 0) {
				throw new Error("Unsupported tga format.");
			}
			
			_bitmap.lock();
			try {
				if (_bitDepth == 32) {
					loadBitmap32(bytes);
				} else if (_bitDepth == 24) {
					loadBitmap24(bytes);
				}
			} finally {
				_bitmap.unlock();
			}
		}
		
		/**
		 * Load 32 bpp bitmap.
		 */
		private function loadBitmap32(bytes:ByteArray):void {
			var x:int, y:int;
			switch (pixelDirection) {
				case DIR_RIGHT_UP:
					for (y = _bitmap.height - 1; y >= 0; --y) {
						for (x = 0; x < _bitmap.width; ++x) {
							_bitmap.setPixel32(x, y, bytes.readUnsignedInt());
						}
					}
					break;
				case DIR_LEFT_UP:
					for (y = _bitmap.height - 1; y >= 0; --y) {
						for (x = _bitmap.width - 1; x >= 0; --x) {
							_bitmap.setPixel32(x, y, bytes.readUnsignedInt());
						}
					}
					break;
				case DIR_RIGHT_DOWN:
					for (y = 0; y < _bitmap.height; ++y) {
						for (x = 0; x < _bitmap.width; ++x) {
							_bitmap.setPixel32(x, y, bytes.readUnsignedInt());
						}
					}
					break;
				case DIR_LEFT_DOWN:
					for (y = 0; y < _bitmap.height; ++y) {
						for (x = _bitmap.width - 1; x >= 0; --x) {
							_bitmap.setPixel32(x, y, bytes.readUnsignedInt());
						}
					}
					break;
			}
		}
		
		/**
		 * Load 24 bpp bitmap.
		 */
		private function loadBitmap24(bytes:ByteArray):void {
			var x:int, y:int;
			var r:uint, g:uint, b:uint;
			switch (pixelDirection) {
				case DIR_RIGHT_UP:
					for (y = _bitmap.height - 1; y >= 0; --y) {
						for (x = 0; x < _bitmap.width; ++x) {
							b = bytes.readUnsignedByte();
							g = bytes.readUnsignedByte();
							r = bytes.readUnsignedByte();
							_bitmap.setPixel32(x, y, 0xFF000000 | (r << 16) | (g << 8) | b);
						}
					}
					break;
				case DIR_LEFT_UP:
					for (y = _bitmap.height - 1; y >= 0; --y) {
						for (x = _bitmap.width - 1; x >= 0; --x) {
							b = bytes.readUnsignedByte();
							g = bytes.readUnsignedByte();
							r = bytes.readUnsignedByte();
							_bitmap.setPixel32(x, y, 0xFF000000 | (r << 16) | (g << 8) | b);
						}
					}
					break;
				case DIR_RIGHT_DOWN:
					for (y = 0; y < _bitmap.height; ++y) {
						for (x = 0; x < _bitmap.width; ++x) {
							b = bytes.readUnsignedByte();
							g = bytes.readUnsignedByte();
							r = bytes.readUnsignedByte();
							_bitmap.setPixel32(x, y, 0xFF000000 | (r << 16) | (g << 8) | b);
						}
					}
					break;
				case DIR_LEFT_DOWN:
					for (y = 0; y < _bitmap.height; ++y) {
						for (x = _bitmap.width - 1; x >= 0; --x) {
							b = bytes.readUnsignedByte();
							g = bytes.readUnsignedByte();
							r = bytes.readUnsignedByte();
							_bitmap.setPixel32(x, y, 0xFF000000 | (r << 16) | (g << 8) | b);
						}
					}
					break;
			}
		}
	}
}
