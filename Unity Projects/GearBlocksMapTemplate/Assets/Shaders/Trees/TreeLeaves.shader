// Copyright (C) 2017 - 2023 SmashHammer Games Inc. - All Rights Reserved.

Shader "GearBlocks/Trees/Tree Leaves"
{
	Properties
	{
		_Color( "Main Color", Color ) = (1.0, 1.0, 1.0, 1.0)
		_MainTex( "Albedo", 2D ) = "white" {}
		_BumpMap( "Normalmap", 2D ) = "bump" {}
		_GlossMap( "Metallic (RGB) Gloss (A)", 2D ) = "black" {}
		_TranslucencyMap( "Translucency (A)", 2D ) = "white" {}
		
		_TranslucencyDistortion( "Translucency Distortion", Range( 0.0, 2.0 ) ) = 0.5
		_TranslucencyPower( "Translucency Power", Range( 0.1, 10.0 ) ) = 2.0
		_TranslucencyScale( "Translucency Scale", Range( 0.0, 2.0 ) ) = 1.0
		
		// These are here only to provide default values
		_Cutoff( "Alpha cutoff", Range( 0.0, 1.0 ) ) = 0.3
		[HideInInspector] _TreeInstanceColor( "TreeInstanceColor", Vector ) = (1.0, 1.0, 1.0, 1.0)
		[HideInInspector] _TreeInstanceScale( "TreeInstanceScale", Vector ) = (1.0, 1.0, 1.0, 1.0)
		[HideInInspector] _SquashAmount( "Squash", Float ) = 1.0
	}
	
	SubShader
	{
		Tags
		{
			"IgnoreProjector" = "True"
			"RenderType" = "TreeLeaf"
		}
		
		LOD 300
		
		CGPROGRAM
		
		#pragma surface surf StandardTranslucent alphatest:_Cutoff vertex:TreeVertLeaf addshadow nolightmap
		
		#include "UnityBuiltin3xTreeLibrary.cginc"
		#include "Assets/Shaders/Utils/LightingStandardTranslucent.cginc"
		
		sampler2D _MainTex;
		sampler2D _BumpMap;
		sampler2D _GlossMap;
		sampler2D _TranslucencyMap;
		
		struct Input
		{
			float2 uv_MainTex;
			fixed4 color : COLOR; // color.a = AO
		};
		
		void surf( Input IN, inout SurfaceOutputStandardTranslucent o )
		{
			fixed4 c = tex2D( _MainTex, IN.uv_MainTex );
			
			half2 metallicGloss = tex2D( _GlossMap, IN.uv_MainTex ).ra;
			fixed3 translucency = tex2D( _TranslucencyMap, IN.uv_MainTex ).a;
			
			o.Albedo = c.rgb * IN.color.rgb;
			o.Normal = UnpackNormal( tex2D( _BumpMap, IN.uv_MainTex ) );
			o.Metallic = metallicGloss.x;
			o.Smoothness = metallicGloss.y;
			o.Occlusion = IN.color.a;
			o.Translucency = _TranslucencyColor * translucency;
			o.Alpha = c.a;
		}
		
		ENDCG
	}
	
	Dependency "OptimizedShader" = "Hidden/GearBlocks/Trees/Tree Leaves Optimized"
	FallBack "Diffuse"
}
