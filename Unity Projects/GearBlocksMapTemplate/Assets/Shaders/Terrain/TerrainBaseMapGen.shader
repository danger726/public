// Copyright (C) 2017 - 2023 SmashHammer Games Inc. - All Rights Reserved.

Shader "Hidden/GearBlocks/Terrain/Terrain BaseMapGen"
{
	Properties
	{
		[HideInInspector] _DstBlend( "DstBlend", Float ) = 0.0
	}
	
	SubShader
	{
		CGINCLUDE

		#include "UnityCG.cginc"

		#pragma multi_compile_local __ _NORMALMAP
		#pragma multi_compile_local __ _MASKMAP

		#define TERRAIN_BLEND_HEIGHT
		#include "TerrainSplatmapCommon.cginc"

		struct appdata_t
		{
			float4 vertex : POSITION;
			float2 texcoord : TEXCOORD0;
		};

		struct v2f
		{
			float4 vertex : SV_POSITION;
			float2 texcoord : TEXCOORD0;
		};

		v2f vert( appdata_t v )
		{
			v2f o;

			o.vertex = UnityObjectToClipPos( v.vertex );
			o.texcoord = v.texcoord;

			return o;
		}

		ENDCG

		Pass
		{
			Tags
			{
				"Name" = "_MainTex"
				"Format" = "RGBA32"
				"Size" = "1"
			}

			ZTest Always Cull Off ZWrite Off
			Blend One [_DstBlend]

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			float4 frag( v2f i ) : SV_Target
			{
				half3 albedo, normal;
				half metallic, smoothness, occlusion, alpha;
				SplatmapSurf( i.texcoord, albedo, normal, metallic, smoothness, occlusion, alpha );

				return half4( albedo, smoothness );
			}

			ENDCG
		}

		Pass
		{
			// _NormalMap pass will get ignored by terrain basemap generation code. Put here so that the VTC can use it to generate cache for normal maps.
			Tags
			{
				"Name" = "_NormalMap"
				"Format" = "A2R10G10B10"
				"Size" = "1"
			}

			ZTest Always Cull Off ZWrite Off
			Blend One [_DstBlend]
			
			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			float4 frag( v2f i ) : SV_Target
			{
				half3 albedo, normal;
				half metallic, smoothness, occlusion, alpha;
				SplatmapSurf( i.texcoord, albedo, normal, metallic, smoothness, occlusion, alpha );

				return float4( normal.xyz * 0.5f + 0.5f, 1.0f );
			}
			
			ENDCG
		}

		Pass
		{
			Tags
			{
				"Name" = "_MetallicTex"
				"Format" = "R8"
				"Size" = "1/4"
			}

			ZTest Always Cull Off ZWrite Off
			Blend One [_DstBlend]
			
			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			float4 frag( v2f i ) : SV_Target
			{
				half3 albedo, normal;
				half metallic, smoothness, occlusion, alpha;
				SplatmapSurf( i.texcoord, albedo, normal, metallic, smoothness, occlusion, alpha );

				return metallic;
			}
			
			ENDCG
		}
	}

	Fallback "Hidden/TerrainEngine/Splatmap/Standard-BaseGen"
}
