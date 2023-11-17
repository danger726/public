// Copyright (C) 2017 - 2023 SmashHammer Games Inc. - All Rights Reserved.

#ifndef TREE_RENDERTEX_CGINC
#define TREE_RENDERTEX_CGINC

#include "UnityCG.cginc"
#ifdef EXPAND_BILLBOARD	
	#include "TerrainEngine.cginc"
#endif

struct v2f
{
	float4 pos : SV_POSITION;
	float2 uv : TEXCOORD0;
	fixed4 color : TEXCOORD1;
	float3 nl : TEXCOORD2;
	float3 nh : TEXCOORD3;
	UNITY_VERTEX_OUTPUT_STEREO
};
			
CBUFFER_START( UnityTerrainImposter )
	float3 _TerrainTreeLightDirections[4];
	float4 _TerrainTreeLightColors[4];
CBUFFER_END
			
sampler2D _MainTex;
sampler2D _TranslucencyMap;

fixed4 _SpecColor;
fixed _Cutoff;

void CalcLightingParams( float3 normal, float3 lightDir, float3 viewDir, out float nl, out float nh )
{
	nl = max( 0.0, dot( normal, lightDir ) );
	
	half3 h = normalize( lightDir + viewDir );
	nh = max( 0.0, dot( normal, h ) );
}

half3 ApplyLighting( half3 albedo, half gloss, half specular, half3 lightColor, half nl, half nh )
{
	half spec = pow( nh, specular ) * gloss;
	
	return (albedo * nl + _SpecColor.rgb * spec) * lightColor;
}

v2f vert( appdata_full v )
{
	v2f o;
	
	UNITY_SETUP_INSTANCE_ID( v );
	UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );
#ifdef EXPAND_BILLBOARD	
	ExpandBillboard( UNITY_MATRIX_IT_MV, v.vertex, v.normal, v.tangent );
#endif
	o.pos = UnityObjectToClipPos( v.vertex );
	o.uv = v.texcoord.xy;
	float3 viewDir = normalize( ObjSpaceViewDir( v.vertex ) );
	
	o.color.rgb = 1.0;
	o.color.a = v.color.a;
	
	CalcLightingParams( v.normal, _TerrainTreeLightDirections[0], viewDir, o.nl.x, o.nh.x );
	CalcLightingParams( v.normal, _TerrainTreeLightDirections[1], viewDir, o.nl.y, o.nh.y );
	CalcLightingParams( v.normal, _TerrainTreeLightDirections[2], viewDir, o.nl.z, o.nh.z );
	
	return o;
}

fixed4 frag( v2f i ) : SV_Target
{
	fixed4 c = tex2D( _MainTex, i.uv );
#ifdef ALPHATEST	
	clip( c.a - _Cutoff );
#endif
	
	fixed3 albedo = c.rgb * i.color;
	
	fixed4 translucencyGloss = tex2D( _TranslucencyMap, i.uv );
	
	c.rgb = UNITY_LIGHTMODEL_AMBIENT * albedo;
	
	c.rgb += ApplyLighting( albedo, translucencyGloss.a, 4.0, _TerrainTreeLightColors[0], i.nl.x, i.nh.x );
	c.rgb += ApplyLighting( albedo, translucencyGloss.a, 4.0, _TerrainTreeLightColors[1], i.nl.y, i.nh.y );
	c.rgb += ApplyLighting( albedo, translucencyGloss.a, 4.0, _TerrainTreeLightColors[2], i.nl.z, i.nh.z );
	
	c.a = 1.0;
	UNITY_OPAQUE_ALPHA( c.a );
	
	return c;
}

#endif // TREE_RENDERTEX_CGINC
