// Copyright (C) 2017 - 2023 SmashHammer Games Inc. - All Rights Reserved.

Shader "GearBlocks/Trees/Tree Bark"
{
	Properties
	{
		_Color( "Main Color", Color ) = (1.0, 1.0, 1.0, 1.0)
		_MainTex( "Albedo", 2D ) = "white" {}
		_BumpMap( "Normalmap", 2D ) = "bump" {}
		_GlossMap( "Gloss", 2D ) = "black" {}
		
		// These are here only to provide default values
		[HideInInspector] _TreeInstanceColor( "TreeInstanceColor", Vector ) = (1.0, 1.0, 1.0, 1.0)
		[HideInInspector] _TreeInstanceScale( "TreeInstanceScale", Vector ) = (1.0, 1.0, 1.0, 1.0)
		[HideInInspector] _SquashAmount( "Squash", Float ) = 1.0
	}
	
	SubShader
	{
		Tags
		{
			"IgnoreProjector" = "True"
			"RenderType" = "TreeBark"
		}
		
		LOD 300
		
		CGPROGRAM
		
		#pragma surface surf Standard vertex:TreeVertBark addshadow nolightmap
		
		#include "UnityBuiltin3xTreeLibrary.cginc"
		
		sampler2D _MainTex;
		sampler2D _BumpMap;
		sampler2D _GlossMap;
		
		struct Input
		{
			float2 uv_MainTex;
			fixed4 color : COLOR; // color.a = AO
		};
		
		void surf( Input IN, inout SurfaceOutputStandard o )
		{
			fixed4 c = tex2D( _MainTex, IN.uv_MainTex );
			
			half2 metallicGloss = tex2D( _GlossMap, IN.uv_MainTex ).ra;
			
			o.Albedo = c.rgb * IN.color.rgb;
			o.Normal = UnpackNormal( tex2D( _BumpMap, IN.uv_MainTex ) );
			o.Metallic = metallicGloss.x;
			o.Smoothness = metallicGloss.y;
			o.Occlusion = IN.color.a;
			o.Alpha = c.a;
		}
		
		ENDCG
	}
	
	Dependency "OptimizedShader" = "Hidden/GearBlocks/Trees/Tree Bark Optimized"
	FallBack "Diffuse"
}
