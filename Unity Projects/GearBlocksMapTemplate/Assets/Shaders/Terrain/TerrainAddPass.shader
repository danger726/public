// Copyright (C) 2017 - 2023 SmashHammer Games Inc. - All Rights Reserved.

Shader "Hidden/GearBlocks/Terrain/Terrain AddPass"
{
	Properties
	{
		[HideInInspector] _TerrainHolesTexture( "Holes Map (RGB)", 2D ) = "white" {}
	}
	
	SubShader
	{
		Tags
		{
			"Queue" = "Geometry-99"
			"RenderType" = "Opaque"
			"IgnoreProjector" = "True"
		}

		CGPROGRAM

		#pragma surface surf Standard decal:add vertex:SplatmapVert finalcolor:SplatmapFinalColor finalgbuffer:SplatmapFinalGBuffer fullforwardshadows nometa
		#pragma instancing_options assumeuniformscaling nomatrices nolightprobe nolightmap forwardadd
		#pragma multi_compile_fog
		#pragma target 3.0
		#include "UnityPBSLighting.cginc"

		#pragma multi_compile_local_fragment __ _ALPHATEST_ON
		#pragma multi_compile_local __ _NORMALMAP
		#pragma multi_compile_local __ _MASKMAP
		#pragma multi_compile _ ENABLE_CUSTOMCLIPPLANE

		#define TERRAIN_SPLAT_ADDPASS
		#define TERRAIN_BLEND_HEIGHT
		#define TERRAIN_INSTANCED_PERPIXEL_NORMAL
		#define TERRAIN_SURFACE_OUTPUT SurfaceOutputStandard
		#include "TerrainSplatmapCommon.cginc"
		#include "Assets/Shaders/Utils/CustomClipPlane.cginc"

		void surf( Input IN, inout SurfaceOutputStandard o )
		{
			CUSTOM_CLIP_PLANE( IN.worldPos );

		#ifdef _ALPHATEST_ON
			ClipHoles( IN.tc.xy );
		#endif

			SplatmapSurf( IN.tc.xy, o.Albedo, o.Normal, o.Metallic, o.Smoothness, o.Occlusion, o.Alpha );

		#if defined(INSTANCING_ON) && defined(SHADER_TARGET_SURFACE_ANALYSIS) && defined(TERRAIN_INSTANCED_PERPIXEL_NORMAL)
			o.Normal = half3( 0.0h, 0.0h, 1.0h ); // make sure that surface shader compiler realizes we write to normal, as UNITY_INSTANCING_ENABLED is not defined for SHADER_TARGET_SURFACE_ANALYSIS.
		#endif

		#if defined(UNITY_INSTANCING_ENABLED) && !defined(SHADER_API_D3D11_9X) && defined(TERRAIN_INSTANCED_PERPIXEL_NORMAL)
			float3 geomNormal = normalize( tex2D( _TerrainNormalmapTexture, IN.tc.zw ).xyz * 2.0 - 1.0 );
			#ifdef _NORMALMAP
				float3 geomTangent = normalize( cross( geomNormal, float3( 0.0, 0.0, 1.0 ) ) );
				float3 geomBitangent = normalize( cross( geomTangent, geomNormal ) );
				o.Normal = o.Normal.x * geomTangent + o.Normal.y * geomBitangent + o.Normal.z * geomNormal;
			#else
				o.Normal = geomNormal;
			#endif
			o.Normal = o.Normal.xzy;
		#endif
		}
		
		ENDCG
	}

	Fallback "Hidden/TerrainEngine/Splatmap/Standard-AddPass"
}
