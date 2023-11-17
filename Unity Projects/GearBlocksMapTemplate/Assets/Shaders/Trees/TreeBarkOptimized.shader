// Copyright (C) 2017 - 2023 SmashHammer Games Inc. - All Rights Reserved.

Shader "Hidden/GearBlocks/Trees/Tree Bark Optimized"
{
	Properties
	{
		_Color( "Main Color", Color ) = (1.0, 1.0, 1.0, 1.0)
		_MainTex( "Albedo", 2D ) = "white" {}
		_BumpSpecMap( "Normalmap (GA) Spec (R)", 2D ) = "bump" {}
		_TranslucencyMap( "Translucency (B) Gloss (A)", 2D ) = "white" {}
		
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
		
		#pragma multi_compile __ BILLBOARD_FACE_CAMERA_POS
		
		#include "TreeOptimized.cginc"
		
		ENDCG
	}
	
	Dependency "BillboardShader" = "Hidden/GearBlocks/Trees/Tree Bark Rendertex"
}
