// Copyright (C) 2017 - 2023 SmashHammer Games Inc. - All Rights Reserved.

Shader "Hidden/GearBlocks/Trees/Tree Leaves Optimized"
{
	Properties
	{
		_Color( "Main Color", Color ) = (1.0, 1.0, 1.0, 1.0)
		_MainTex( "Albedo", 2D ) = "white" {}
		_BumpSpecMap( "Normalmap (GA) Spec (R)", 2D ) = "bump" {}
		_TranslucencyMap( "Translucency (B) Gloss (A)", 2D ) = "white" {}
		
		_TranslucencyColor( "Translucency Color", Color ) = (0.73, 0.85, 0.41, 1.0)
		
		_TranslucencyDistortion( "Translucency Distortion", Range( 0.0, 2.0 ) ) = 0.5
		_TranslucencyPower( "Translucency Power", Range( 0.1, 10.0 ) ) = 2.0
		_TranslucencyScale( "Translucency Scale", Range( 0.0, 2.0 ) ) = 1.0
		
		_ShadowOffsetScale( "Shadow Bias", Float ) = 0.003
		
		// These are here only to provide default values
		_Cutoff( "Alpha cutoff", Range( 0.0, 1.0 ) ) = 0.3
		[HideInInspector] _TreeInstanceColor( "TreeInstanceColor", Vector ) = (1.0, 1.0, 1.0, 1.0)
		[HideInInspector] _TreeInstanceScale( "TreeInstanceScale", Vector ) = (1.0, 1.0, 1.0, 1.0)
		[HideInInspector] _SquashAmount( "Squash", Float ) = 1.0
		
		// Unused, here for compatibility with the tree editor
		[HideInInspector] _TranslucencyViewDependency( "View dependency", Range( 0.0, 1.0 ) ) = 0.7
		[HideInInspector] _ShadowStrength( "Shadow Strength", Range( 0.0, 1.0 ) ) = 0.8
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
		
		#pragma surface surf StandardTranslucent alphatest:_Cutoff vertex:vert nolightmap
		
		#pragma multi_compile __ BILLBOARD_FACE_CAMERA_POS
		
		#define _TRANSLUCENCY
		
		#include "TreeOptimized.cginc"
		
		ENDCG
		
		// Pass to render object as a shadow caster
		Pass
		{
			Name "ShadowCaster"
			Tags
			{
				"LightMode" = "ShadowCaster"
			}
			
			CGPROGRAM
			
			#pragma vertex vert_surf
			#pragma fragment frag_surf
			#pragma multi_compile_shadowcaster
			
			#include "HLSLSupport.cginc"
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			
			#define INTERNAL_DATA
			#define WorldReflectionVector( data, normal ) data.worldRefl
			
			#include "UnityBuiltin3xTreeLibrary.cginc"
			
			sampler2D _MainTex;
			float4 _MainTex_ST;
			
			float _ShadowOffsetScale;
			
			fixed _Cutoff;
			
			struct v2f_surf
			{
				V2F_SHADOW_CASTER;
				float2 hip_pack0 : TEXCOORD1;
				UNITY_VERTEX_OUTPUT_STEREO
			};
			
			v2f_surf vert_surf( appdata_full v )
			{
				v2f_surf o;
				
				UNITY_SETUP_INSTANCE_ID( v );
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );
				TreeVertLeaf( v );
				o.hip_pack0.xy = TRANSFORM_TEX( v.texcoord, _MainTex );
				TRANSFER_SHADOW_CASTER_NORMALOFFSET( o )
				
				// Apply additional linear bias to prevent leaves from self shadowing.
				o.pos.z -= _ShadowOffsetScale / o.pos.w;
				
				return o;
			}
			
			float4 frag_surf( v2f_surf IN ) : SV_Target
			{
				half alpha = tex2D( _MainTex, IN.hip_pack0.xy ).a;
				clip( alpha - _Cutoff );
				SHADOW_CASTER_FRAGMENT( IN )
			}
			
			ENDCG
		}
	}
	
	Dependency "BillboardShader" = "Hidden/GearBlocks/Trees/Tree Leaves Rendertex"
}
