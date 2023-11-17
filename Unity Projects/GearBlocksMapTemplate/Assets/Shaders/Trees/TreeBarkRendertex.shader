// Copyright (C) 2017 - 2023 SmashHammer Games Inc. - All Rights Reserved.

Shader "Hidden/GearBlocks/Trees/Tree Bark Rendertex"
{
	Properties
	{
		_MainTex( "Albedo", 2D ) = "white" {}
		_BumpSpecMap( "Normalmap (GA) Spec (R)", 2D ) = "bump" {}
		_TranslucencyMap( "Translucency (B) Gloss(A)", 2D ) = "white" {}
		
		// These are here only to provide default values
		_SpecColor( "Specular Color", Color ) = (0.5, 0.5, 0.5, 1.0)
	}
	
	SubShader
	{
		Pass
		{
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			
			#include "TreeRendertex.cginc"
			
			ENDCG
		}
	}
	
	FallBack Off
}
