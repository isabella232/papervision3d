/*
 * Copyright 2007 (c) Tim Knip, ascollada.org.
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */
 
package org.ascollada.core
{
	import org.ascollada.core.DaeEntity;
	
	/**
	 * 
	 */
	public class DaeAnimationCurve extends DaeEntity
	{
		public static const INTERPOLATION_STEP:uint = 0; //equivalent to no interpolation
		public static const INTERPOLATION_LINEAR:uint = 1;
		public static const INTERPOLATION_BEZIER:uint = 2;
		public static const INTERPOLATION_TCB:uint = 3;
		public static const INTERPOLATION_UNKNOWN:uint = 4;
		public static const INTERPOLATION_DEFAULT:uint = 0;
		
		public static const INFINITY_CONSTANT:uint = 0;
		public static const INFINITY_LINEAR:uint = 1;
		public static const INFINITY_CYCLE:uint = 2;
		public static const INFINITY_CYCLE_RELATIVE:uint = 3;
		public static const INFINITY_OSCILLATE:uint = 4;
		public static const INFINITY_UNKNOWN:uint = 5;
		public static const INFINITY_DEFAULT:uint = 0;
		
		public var keys:Array;
		public var keyValues:Array;
		
		public var interpolations:Array;
		
		public var inTangents:Array;
		
		public var outTangents:Array;
		
		public var tcbParameters:Array;
		
		public var easeInOuts:Array;
		
		public var preInfinity:uint = 0;
		
		public var postInfinity:uint = 0;
		
		public var interpolationType:uint = 1;
		
		/**
		 * 
		 * @param	keys
		 * @param	keyValues
		 */
		public function DaeAnimationCurve( keys:Array = null, keyValues:Array = null ):void
		{			
			this.keys = keys || new Array();
			this.keyValues = keyValues || new Array();
			this.interpolations = new Array();
		}
		
		/**
		 * main workhorse for the animation system.
		 * 
		 * @param	time
		 * 
		 * @return
		 */
		public function evaluate( input:Number ):Number
		{
			// Check for empty curves and poses (curves with 1 key).
			if( !this.keys.length ) return 0.0;
			if( this.keys.length == 1 ) return this.keyValues[0];
			
			var i:int;
			var outputStart:Number = this.keyValues[0];
			var outputEnd:Number = this.keyValues[this.keyValues.length-1];
			var inputStart:Number = this.keys[0];
			var inputEnd:Number = this.keys[this.keys.length-1];
			var inputSpan:Number = inputEnd - inputStart;
			var cycleCount:Number;
		
			// Account for pre-infinity mode
			var outputOffset:Number = 0.0;
			
			if( input <= inputStart )
			{
				switch( preInfinity )
				{
					case INFINITY_CONSTANT: return outputStart;
					case INFINITY_LINEAR: return outputStart + (input - inputStart) * (keyValues[1] - outputStart) / (keys[1] - inputStart);
					case INFINITY_CYCLE: { cycleCount = Math.ceil((inputStart - input) / inputSpan); input += cycleCount * inputSpan; break; }
					case INFINITY_CYCLE_RELATIVE: { cycleCount = Math.ceil((inputStart - input) / inputSpan); input += cycleCount * inputSpan; outputOffset -= cycleCount * (outputEnd - outputStart); break; }
					case INFINITY_OSCILLATE: { cycleCount = Math.ceil((inputStart - input) / (2.0 * inputSpan)); input += cycleCount * 2.0 * inputSpan; input = inputEnd - Math.abs(input - inputEnd); break; }
					case INFINITY_UNKNOWN: default: return outputStart;
				}
			}
			else if (input >= inputEnd)
			{
				// Account for post-infinity mode
				switch (postInfinity)
				{
					case INFINITY_CONSTANT: return outputEnd;
					case INFINITY_LINEAR: return outputEnd + (input - inputEnd) * (keyValues[keys.length - 2] - outputEnd) / (keys[keys.length - 2] - inputEnd);
					case INFINITY_CYCLE: { cycleCount = Math.ceil((input - inputEnd) / inputSpan); input -= cycleCount * inputSpan; break; }
					case INFINITY_CYCLE_RELATIVE: { cycleCount = Math.ceil((input - inputEnd) / inputSpan); input -= cycleCount * inputSpan; outputOffset += cycleCount * (outputEnd - outputStart); break; }
					case INFINITY_OSCILLATE: { cycleCount = Math.ceil((input - inputEnd) / (2.0 * inputSpan)); input -= cycleCount * 2.0 * inputSpan; input = inputStart + Math.abs(input - inputStart); break; }
					case INFINITY_UNKNOWN: default: return outputEnd;
				}
			}
			
			// Find the current interval
			var index:uint = 0;
			for( i = 0; i < this.keys.length; ++i, ++index )
				if( this.keys[i] > input ) break;
				
			// Get the keys and values for this interval
			var endKey:Number = this.keys[index];
			var startKey:Number = this.keys[index - 1];
			var endValue:Number = this.keyValues[index];
			var startValue:Number = this.keyValues[index - 1];
			var output:Number;
			
			switch( interpolationType )
			{
				case INTERPOLATION_LINEAR:
					output = (input - startKey) / (endKey - startKey) * (endValue - startValue) + startValue;
					break;
					
				case INTERPOLATION_STEP:
				default:
					output = startValue;
					break;
			}
			
			//Logger.debug( " => leaving DaeAnimationCurve#evaluate " + (outputOffset + output) ); 
			
			return outputOffset + output;
		}
	}
}