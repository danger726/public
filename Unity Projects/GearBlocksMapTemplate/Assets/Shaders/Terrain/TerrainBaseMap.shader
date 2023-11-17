// Copyright (C) 2017 - 2023 SmashHammer Games Inc. - All Rights Reserved.

Shader "Hidden/GearBlocks/Terrain/Terrain BaseMap"
{
	Properties
	{
		_MainTex( "Base (RGB) Smoothness (A)", 2D ) = "white" {}
		_MetallicTex( "Metallic (R)", 2D ) = "white" {}

		// used in fallback on old cards
		_Color( "Main Color", Color ) = (1.0, 1.0, 1.0, 1.0)
		
		[HideInInspector] _TerrainHolesTexture( "Holes Map (RGB)", 2D ) = "white" {}
	}

	SubShader
	{
		Tags
		{
			"Queue" = "Geometry-100"
			"RenderType" = "Opaque"
		}

		LOD 200

		CGPROGRAM

		#pragma surface surf Standard vertex:SplatmapVert addshadow fullforwardshadows
		#pragma instancing_options assumeuniformscaling nomatrices nolightprobe nolightmap forwardadd
		#pragma target 3.0
		#pragma multi_compile_local_fragment __ _ALPHATEST_ON

		#define TERRAIN_BASE_PASS
		#define TERRAIN_INSTANCED_PERPIXEL_NORMAL
		#include "TerrainSplatmapCommon.cginc"
		#include "UnityPBSLighting.cginc"

		#pragma multi_compile _ ENABLE_CUSTOMCLIPPLANE

		#include "Assets/Shaders/Utils/CustomClipPlane.cginc"

		sampler2D _MainTex;
		sampler2D _MetallicTex;

		void surf( Input IN, inout SurfaceOutputStandard o )
		{
			CUSTOM_CLIP_PLANE( IN.worldPos );

			#ifdef _ALPHATEST_ON
				ClipHoles( IN.tc.xy );
			#endif

			half4 albedoGloss = tex2D( _MainTex, IN.tc.xy );
			
			o.Albedo = albedoGloss.rgb;
			o.Alpha = 1.0;
			o.Smoothness = albedoGloss.a;
			o.Metallic = tex2D( _MetallicTex, IN.tc.xy ).r;

			#if defined(INSTANCING_ON) && defined(SHADER_TARGET_SURFACE_ANALYSIS) && defined(TERRAIN_INSTANCED_PERPIXEL_NORMAL)
				o.Normal = float3( 0.0, 0.0, 1.0 ); // make sure that surface shader compiler realizes we write to normal, as UNITY_INSTANCING_ENABLED is not defined for SHADER_TARGET_SURFACE_ANALYSIS.
			#endif

			#if defined(UNITY_INSTANCING_ENABLED) && !defined(SHADER_API_D3D11_9X) && defined(TERRAIN_INSTANCED_PERPIXEL_NORMAL)
				#if defined(TERRAIN_USE_SEPARATE_VERTEX_SAMPLER)
					o.Normal = normalize( _TerrainNormalmapTexture.Sample( sampler__TerrainNormalmapTexture, IN.tc.zw ).xyz * 2.0 - 1.0 ).xzy;
				#else
					o.Normal = normalize( tex2D( _TerrainNormalmapTexture, IN.tc.zw ).xyz * 2.0 - 1.0 ).xzy;
				#endif
			#endif
		}

		ENDCG

		UsePass "Hidden/Nature/Terrain/Utilities/PICKING"
		UsePass "Hidden/Nature/Terrain/Utilities/SELECTION"
	}

	FallBack "Hidden/TerrainEngine/Splatmap/Standard-Base"
}
