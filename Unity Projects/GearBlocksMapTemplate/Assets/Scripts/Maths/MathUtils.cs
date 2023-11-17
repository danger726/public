// <copyright company="SmashHammer Games Inc.">Copyright (C) 2017 - 2023 SmashHammer Games Inc. - All Rights Reserved.</copyright>

using UnityEngine;
using System;

namespace SmashHammer.Maths
{
	public static class MathUtils
	{
#region Serialized data
#endregion // Serialized data

#region Public data
		public enum Axis : byte
		{
			X_Axis,
			Y_Axis,
			Z_Axis
		}

		[Flags]
		public enum AxisFlags : byte
		{
			X_Axis = 0x01,
			Y_Axis = 0x02,
			Z_Axis = 0x04
		}

		public const float					oneOverTwoPI = 1.0f / (2.0f * Mathf.PI);
		public const float					twoPI = 2.0f * Mathf.PI;
		public const float					fourThirdsPI = (4.0f / 3.0f) * Mathf.PI;

		public static readonly Quaternion	rotX90 = Quaternion.Euler( 90.0f, 0.0f, 0.0f );
		public static readonly Quaternion	rotX180 = Quaternion.Euler( 180.0f, 0.0f, 0.0f );
		public static readonly Quaternion	rotX270 = Quaternion.Euler( 270.0f, 0.0f, 0.0f );
		public static readonly Quaternion	rotY90 = Quaternion.Euler( 0.0f, 90.0f, 0.0f );
		public static readonly Quaternion	rotY180 = Quaternion.Euler( 0.0f, 180.0f, 0.0f );
		public static readonly Quaternion	rotY270 = Quaternion.Euler( 0.0f, 270.0f, 0.0f );
		public static readonly Quaternion	rotZ90 = Quaternion.Euler( 0.0f, 0.0f, 90.0f );
		public static readonly Quaternion	rotZ180 = Quaternion.Euler( 0.0f, 0.0f, 180.0f );
		public static readonly Quaternion	rotZ270 = Quaternion.Euler( 0.0f, 0.0f, 270.0f );

		//
		// Unit box vertex ordering:
		//
		// 1_______________0
		// |\              |\
		// | \             | \
		// |  \            |  \
		// |   2___________|___\3
		// |   |           |   |       y
		// |   |           |   |    z  |
		// 5___|___________4   |     \ |
		//  \  |            \  |      \|_____ x
		//   \ |             \ |
		//    \|______________\|
		//     6               7
		//
		public static readonly Vector3[]	unitBoxVertices =
		{
			new Vector3( 1.0f, 1.0f, 1.0f ),
			new Vector3( -1.0f, 1.0f, 1.0f ),
			new Vector3( -1.0f, 1.0f, -1.0f ),
			new Vector3( 1.0f, 1.0f, -1.0f ),
			new Vector3( 1.0f, -1.0f, 1.0f ),
			new Vector3( -1.0f, -1.0f, 1.0f ),
			new Vector3( -1.0f, -1.0f, -1.0f ),
			new Vector3( 1.0f, -1.0f, -1.0f )
		};
#endregion // Public data

#region Private data
#endregion // Private data

#region Constructors
#endregion // Constructors

#region Unity messages
#endregion // Unity messages

#region Interface methods
#endregion // Interface methods

#region Public methods
		public static AxisFlags GetAxisFlag( Axis axis )
		{
			return (AxisFlags)(1 << (byte)axis);
		}

		public static Vector3Int GetAxisMask( AxisFlags axisFlags )
		{
			Vector3Int mask = Vector3Int.zero;
			for( int i = 0; i < 3; ++i )
			{
				if( (axisFlags & (AxisFlags)(1 << i)) != 0 )
				{
					mask[i] = 1;
				}
			}

			return mask;
		}

		public static byte RotateLeft( this byte value, int shift )
		{
			int numBits = sizeof(byte) * 8;
			return (byte)((value << shift) | (value >> (numBits - shift)));
		}

		public static byte RotateRight( this byte value, int shift )
		{
			int numBits = sizeof(byte) * 8;
			return (byte)((value >> shift) | (value << (numBits - shift)));
		}

		public static int Round( int val, int roundTo )
		{
			if( Mathf.Abs( roundTo ) > 0 )
			{
				return (val / roundTo) * roundTo;
			}

			return val;
		}

		public static int Round( int val, int roundTo, int offset )
		{
			return Round( val - offset, roundTo ) + offset;
		}

		public static int Lerp( int from, int to, float t )
		{
			t = Mathf.Clamp01( t );
			return (int)((1.0f - t) * from + t * to);
		}

		public static Vector3Int Min( Vector3Int a, Vector3Int b )
		{
			a.x = Mathf.Min( a.x, b.x );
			a.y = Mathf.Min( a.y, b.y );
			a.z = Mathf.Min( a.z, b.z );

			return a;
		}

		public static Vector3Int Max( Vector3Int a, Vector3Int b )
		{
			a.x = Mathf.Max( a.x, b.x );
			a.y = Mathf.Max( a.y, b.y );
			a.z = Mathf.Max( a.z, b.z );

			return a;
		}

		public static float LerpRepeat( float from, float to, float t, float length )
		{
			float diff = to - from;
			if( Mathf.Abs( diff ) > 0.5f * length )	// If diff is large enough, assume one of the values has wrapped relative to the other...
			{
				from += length * Mathf.Sign( diff );
			}
			return Mathf.Lerp( from, to, t );
		}

		public static float Remap01( float val, float zeroAt, float oneAt )
		{
			float denom = oneAt - zeroAt;

			if( Mathf.Abs( denom ) >= 1e-06f )
			{
				// Construct a line equation (y = mx + b) where:
				//     x = zeroAt => y = 0
				//     x = oneAt => y = 1
				float m = 1.0f / denom;
				float b = -zeroAt / denom;

				// Evaluate (and clamp to 0 to 1 range).
				return Mathf.Clamp01( m * val + b );
			}
			else if( val <= zeroAt )
			{
				return 0.0f;
			}
			else
			{
				return 1.0f;
			}
		}

		public static bool NearlyEqual( float a, float b, float threshold )
		{
			return Mathf.Abs( a - b ) < threshold;
		}

		public static bool NearlyEqual( float a, float b, float minThreshold, float maxThreshold )
		{
			float delta = a - b;
			return (minThreshold < delta) && (delta < maxThreshold);
		}

		public static float ClampAngle( float angle, float minAngle, float maxAngle )
		{
			if( (angle > maxAngle) && (angle < 180.0f) )
			{
				angle = maxAngle;
			}
			else if( (angle < 360.0f + minAngle) && (angle > 180.0f) )
			{
				angle = 360.0f + minAngle;
			}

			return angle;
		}

		public static float Round( float val, float roundTo )
		{
			if( Mathf.Abs( roundTo ) > 0.0f )
			{
				return Mathf.Round( val / roundTo ) * roundTo;
			}

			return val;
		}

		public static float Round( float val, float roundTo, float offset )
		{
			return Round( val - offset, roundTo ) + offset;
		}

		public static float Ceil( float val, float ceilTo )
		{
			if( Mathf.Abs( ceilTo ) > 0.0f )
			{
				return Mathf.Ceil( val / ceilTo ) * ceilTo;
			}

			return val;
		}

		public static float Ceil( float val, float ceilTo, float offset )
		{
			return Ceil( val - offset, ceilTo ) + offset;
		}

		public static float Floor( float val, float floorTo )
		{
			if( Mathf.Abs( floorTo ) > 0.0f )
			{
				return Mathf.Floor( val / floorTo ) * floorTo;
			}

			return val;
		}

		public static float Floor( float val, float floorTo, float offset )
		{
			return Floor( val - offset, floorTo ) + offset;
		}

		public static float Wrap( float val, float wrapTo )
		{
			float twoWrapTo = 2.0f * wrapTo;

			// First ensure value is in +/- (2 * wrapTo) range.
			val %= twoWrapTo;

			// Now put value into +/- wrapTo range.
			if( val > wrapTo )
			{
				val -= twoWrapTo;
			}
			else if( val < -wrapTo )
			{
				val += twoWrapTo;
			}

			return val;
		}

		public static float PerlinFractal( float x, float y, int octaves = 8, float amplitude = 0.5f, float persistence = 0.5f, float frequency = 1.0f )
		{
			float total = 0.0f;

			for( int i = 0; i < octaves; i++ )
			{
				total += Mathf.PerlinNoise( x * frequency, y * frequency ) * amplitude;

				amplitude *= persistence;
				frequency *= 2.0f;
			}

			return total;
		}

		public static float PerlinFractalNormalized( float x, float y, int octaves = 8, float persistence = 0.5f, float frequency = 1.0f )
		{
			float total = 0.0f;
			float amplitude = 1.0f;
			float maxValue = 0.0f;  // Used for normalizing result to 0.0 - 1.0

			for( int i = 0; i < octaves; i++ )
			{
				total += Mathf.PerlinNoise( x * frequency, y * frequency ) * amplitude;

				maxValue += amplitude;

				amplitude *= persistence;
				frequency *= 2.0f;
			}

			return total / maxValue;
		}

		public static float ComputeBoxVolume( Vector3 size )
		{
			return size.x * size.y * size.z;
		}

		public static float ComputeSphereVolume( float innerRadius, float outerRadius )
		{
			return fourThirdsPI * (outerRadius * outerRadius * outerRadius - innerRadius * innerRadius * innerRadius);
		}

		public static float ComputeCylinderVolume( float innerRadius, float outerRadius, float length )
		{
			return Mathf.PI * (outerRadius * outerRadius - innerRadius * innerRadius) * length;
		}

		public static float ComputeCapsuleVolume( float radius, float length )
		{
			return ComputeSphereVolume( 0.0f, radius ) + ComputeCylinderVolume( 0.0f, radius, length );
		}

		public static float ComputeEllipsoidVolume( Vector3 extents )
		{
			return fourThirdsPI * extents.x * extents.y * extents.z;
		}

		public static int GetNumEdgesAroundCircle( float radius, float edgeLength )
		{
			int numSides = (int)(twoPI * radius / edgeLength);
			numSides = Mathf.Clamp( numSides, 5, 64 );

			return numSides;
		}

		public static float GetCircleEdgeLength( float radius, int numEdges )
		{
			return twoPI * radius / numEdges;
		}

		public static void FindFraction( float value, out int numerator, out int denominator )
		{
			if( value < 1.0f )
			{
				value = 1.0f / value;
				numerator = 1;
				float total = value;
				float remainder = Mathf.Abs( total % 1.0f );
				while( (1e-06f < remainder) && (remainder < (1.0f - 1e-06f)) )
				{
					++numerator;
					total += value;
					remainder = Mathf.Abs( total % 1.0f );
				}
				denominator = Mathf.RoundToInt( total );
			}
			else if( value > 1.0f )
			{
				denominator = 1;
				float total = value;
				float remainder = Mathf.Abs( total % 1.0f );
				while( (1e-06f < remainder) && (remainder < (1.0f - 1e-06f)) )
				{
					++denominator;
					total += value;
					remainder = Mathf.Abs( total % 1.0f );
				}
				numerator = Mathf.RoundToInt( total );
			}
			else
			{
				numerator = 1;
				denominator = 1;
			}
		}
#endregion // Public methods

#region Private methods
#endregion // Private methods

#region Remote methods
#endregion // Remote methods
	}
}
