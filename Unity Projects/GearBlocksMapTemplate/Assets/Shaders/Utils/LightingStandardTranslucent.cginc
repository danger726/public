// Copyright (C) 2017 - 2023 SmashHammer Games Inc. - All Rights Reserved.

#ifndef LIGHTINGSTANDARDTRANSLUCENT_CGINC
#define LIGHTINGSTANDARDTRANSLUCENT_CGINC

#include "UnityPBSLighting.cginc"

struct SurfaceOutputStandardTranslucent
{
	fixed3 Albedo;      // base (diffuse or specular) color
	float3 Normal;      // tangent space normal, if written
	half3 Emission;
	half Metallic;      // 0=non-metal, 1=metal
	half Smoothness;    // 0=rough, 1=smooth
	half Occlusion;     // occlusion (default 1)
	fixed3 Translucency;
	fixed Alpha;        // alpha for transparencies
};

float _TranslucencyDistortion;
float _TranslucencyPower;
float _TranslucencyScale;

half TranslucencyIntensity( half3 L, float3 V, float3 N )
{
	float3 H = normalize( L + N * _TranslucencyDistortion );

	return pow( saturate( dot( V, -H ) ), _TranslucencyPower ) * _TranslucencyScale;
}

inline half4 LightingStandardTranslucent( SurfaceOutputStandardTranslucent s, float3 viewDir, UnityGI gi )
{
	SurfaceOutputStandard s1;

	s1.Albedo = s.Albedo;
	s1.Normal = s.Normal;
	s1.Emission = s.Emission;
	s1.Metallic = s.Metallic;
	s1.Smoothness = s.Smoothness;
	s1.Occlusion = s.Occlusion;
	s1.Alpha = s.Alpha;

	half4 c = LightingStandard( s1, viewDir, gi );

	half intensity = TranslucencyIntensity( gi.light.dir, viewDir, s.Normal );

	c.rgb += gi.light.color * s.Translucency * intensity;

	return c;
}

inline void LightingStandardTranslucent_GI( SurfaceOutputStandardTranslucent s, UnityGIInput data, inout UnityGI gi )
{
	SurfaceOutputStandard s1;

	s1.Albedo = s.Albedo;
	s1.Normal = s.Normal;
	s1.Emission = s.Emission;
	s1.Metallic = s.Metallic;
	s1.Smoothness = s.Smoothness;
	s1.Occlusion = s.Occlusion;
	s1.Alpha = s.Alpha;

	LightingStandard_GI( s1, data, gi );
}

#endif // LIGHTINGSTANDARDTRANSLUCENT_CGINC
