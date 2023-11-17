// Copyright (C) 2017 - 2023 SmashHammer Games Inc. - All Rights Reserved.

#ifndef TREE_OPTIMIZED_CGINC
#define TREE_OPTIMIZED_CGINC

#include "UnityBuiltin3xTreeLibrary.cginc"
#ifdef _TRANSLUCENCY
	#include "Assets/Shaders/Utils/LightingStandardTranslucent.cginc"
#endif

struct Input
{
	float2 uv_MainTex;
	fixed4 color : COLOR; // color.a = AO
#ifdef BILLBOARD_FACE_CAMERA_POS
	float4 screenPos;
#endif
#ifdef _TRANSLUCENCY
	half translucencyFade;
#endif
};
		
sampler2D _MainTex;
sampler2D _BumpSpecMap;
sampler2D _TranslucencyMap;
		
#ifdef _TRANSLUCENCY
	float _TranslucencyFarDist;
	float _TranslucencyFadeDist;
#endif
		
void vert( inout appdata_full v, out Input o )
{
	UNITY_INITIALIZE_OUTPUT( Input, o );
	
	TreeVertLeaf( v );
	
#ifdef _TRANSLUCENCY
	float3 viewPos = UnityObjectToViewPos( v.vertex );
	o.translucencyFade = saturate( (_TranslucencyFarDist - length( viewPos )) / _TranslucencyFadeDist );
#endif
}

#ifdef _TRANSLUCENCY
	#define SURFACE_OUTPUT SurfaceOutputStandardTranslucent
#else
	#define SURFACE_OUTPUT SurfaceOutputStandard
#endif
	
void surf( Input IN, inout SURFACE_OUTPUT o )
{
	fixed4 c = tex2D( _MainTex, IN.uv_MainTex );
	
	half4 normalSpec = tex2D( _BumpSpecMap, IN.uv_MainTex );
	fixed4 translucencyGloss = tex2D( _TranslucencyMap, IN.uv_MainTex );
	
	o.Albedo = c.rgb * IN.color.rgb;
	o.Normal = UnpackNormalDXT5nm( normalSpec );
	o.Metallic = 0.0;
	o.Smoothness = translucencyGloss.a;
	o.Occlusion = IN.color.a;
#ifdef _TRANSLUCENCY
	o.Translucency = _TranslucencyColor * translucencyGloss.b * IN.translucencyFade;
#endif
	o.Alpha = c.a;
#ifdef BILLBOARD_FACE_CAMERA_POS
	float coverage = 1.0;
	if( _TreeInstanceColor.a < 1.0 )
	{
		coverage = ComputeAlphaCoverage( IN.screenPos, _TreeInstanceColor.a );
	}
	o.Alpha *= coverage;
#endif
}

#endif // TREE_OPTIMIZED_CGINC
