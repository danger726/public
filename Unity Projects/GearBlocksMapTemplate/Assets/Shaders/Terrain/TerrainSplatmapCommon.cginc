// Copyright (C) 2017 - 2023 SmashHammer Games Inc. - All Rights Reserved.

#ifndef TERRAIN_SPLATMAP_COMMON_CGINC
#define TERRAIN_SPLATMAP_COMMON_CGINC

// Since 2018.3 we changed from _TERRAIN_NORMAL_MAP to _NORMALMAP to save 1 keyword.
// Since 2019.2 terrain keywords are changed to  local keywords so it doesn't really matter. You can use both.
#if defined(_NORMALMAP) && !defined(_TERRAIN_NORMAL_MAP)
	#define _TERRAIN_NORMAL_MAP
#elif !defined(_NORMALMAP) && defined(_TERRAIN_NORMAL_MAP)
	#define _NORMALMAP
#endif

#if defined(SHADER_API_GLCORE) || defined(SHADER_API_GLES3) || defined(SHADER_API_GLES)
	// GL doesn't support sperating the samplers from the texture object
	#undef TERRAIN_USE_SEPARATE_VERTEX_SAMPLER
#else
	#define TERRAIN_USE_SEPARATE_VERTEX_SAMPLER
#endif

struct Input
{
	float4 tc;
	#ifndef TERRAIN_BASE_PASS
		UNITY_FOG_COORDS( 0 ) // needed because finalcolor oppresses fog code generation.
	#endif
	#ifdef ENABLE_CUSTOMCLIPPLANE
		float3 worldPos;
	#endif
};

sampler2D _Control;
float4 _Control_ST;
float4 _Control_TexelSize;
sampler2D _Splat0, _Splat1, _Splat2, _Splat3;
float4 _Splat0_ST, _Splat1_ST, _Splat2_ST, _Splat3_ST;

half _Metallic0, _Metallic1, _Metallic2, _Metallic3;
half _Smoothness0, _Smoothness1, _Smoothness2, _Smoothness3;
half4 _DiffuseRemapScale0, _DiffuseRemapScale1, _DiffuseRemapScale2, _DiffuseRemapScale3;
half4 _MaskMapRemapOffset0, _MaskMapRemapOffset1, _MaskMapRemapOffset2, _MaskMapRemapOffset3;
half4 _MaskMapRemapScale0, _MaskMapRemapScale1, _MaskMapRemapScale2, _MaskMapRemapScale3;
half _LayerHasMask0, _LayerHasMask1, _LayerHasMask2, _LayerHasMask3;

half _HeightTransition;

#if defined(UNITY_INSTANCING_ENABLED) && !defined(SHADER_API_D3D11_9X)
	// Some drivers have undefined behaviors when samplers are used from the vertex shader
	// with anisotropic filtering enabled. This causes some artifacts on some devices. To be
	// sure to avoid this we use the vertex_linear_clamp_sampler sampler to sample terrain
	// maps from the VS when we can.
	#if defined(TERRAIN_USE_SEPARATE_VERTEX_SAMPLER)
		UNITY_DECLARE_TEX2D( _TerrainHeightmapTexture );
		UNITY_DECLARE_TEX2D( _TerrainNormalmapTexture );
		SamplerState sampler__TerrainNormalmapTexture;
		SamplerState vertex_linear_clamp_sampler;
	#else
		sampler2D _TerrainHeightmapTexture;
		sampler2D _TerrainNormalmapTexture;
	#endif
	
	float4 _TerrainHeightmapRecipSize;   // float4( 1.0 / width, 1.0 / height, 1.0 / (width - 1.0), 1.0 / (height - 1.0) )
	float4 _TerrainHeightmapScale;       // float4( hmScale.x, hmScale.y / (float)(kMaxHeight), hmScale.z, 0.0 )
#endif

UNITY_INSTANCING_BUFFER_START(Terrain)
	UNITY_DEFINE_INSTANCED_PROP( float4, _TerrainPatchInstanceData ) // float4( xBase, yBase, skipScale, ~ )
UNITY_INSTANCING_BUFFER_END(Terrain)

#ifdef _NORMALMAP
	sampler2D _Normal0, _Normal1, _Normal2, _Normal3;
	float _NormalScale0, _NormalScale1, _NormalScale2, _NormalScale3;
#endif

#ifdef _MASKMAP
	UNITY_DECLARE_TEX2D( _Mask0 );
	UNITY_DECLARE_TEX2D_NOSAMPLER( _Mask1 );
	UNITY_DECLARE_TEX2D_NOSAMPLER( _Mask2 );
	UNITY_DECLARE_TEX2D_NOSAMPLER( _Mask3 );
#endif

#ifdef _ALPHATEST_ON
	sampler2D _TerrainHolesTexture;
	
	void ClipHoles( float2 uv )
	{
		float hole = tex2D( _TerrainHolesTexture, uv ).r;
		clip( hole == 0.0f ? -1 : 1 );
	}
#endif

#if defined(TERRAIN_BASE_PASS) && defined(UNITY_PASS_META)
	// When we render albedo for GI baking, we actually need to take the ST
	float4 _MainTex_ST;
#endif

void SplatmapVert( inout appdata_full v, out Input data )
{
	UNITY_INITIALIZE_OUTPUT( Input, data );
	
#if defined(UNITY_INSTANCING_ENABLED) && !defined(SHADER_API_D3D11_9X)
	float2 patchVertex = v.vertex.xy;
	float4 instanceData = UNITY_ACCESS_INSTANCED_PROP( Terrain, _TerrainPatchInstanceData );
	
	float4 uvscale = instanceData.z * _TerrainHeightmapRecipSize;
	float4 uvoffset = instanceData.xyxy * uvscale;
	uvoffset.xy += 0.5 * _TerrainHeightmapRecipSize.xy;
	float2 sampleCoords = (patchVertex.xy * uvscale.xy + uvoffset.xy);
	
	#if defined(TERRAIN_USE_SEPARATE_VERTEX_SAMPLER)
		float hm = UnpackHeightmap( _TerrainHeightmapTexture.SampleLevel( vertex_linear_clamp_sampler, sampleCoords, 0 ) );
	#else
		float hm = UnpackHeightmap( tex2Dlod( _TerrainHeightmapTexture, float4( sampleCoords, 0.0, 0.0 ) ) );
	#endif
	
	v.vertex.xz = (patchVertex.xy + instanceData.xy) * _TerrainHeightmapScale.xz * instanceData.z;  //(x + xBase) * hmScale.x * skipScale;
	v.vertex.y = hm * _TerrainHeightmapScale.y;
	v.vertex.w = 1.0f;
	
	v.texcoord.xy = (patchVertex.xy * uvscale.zw + uvoffset.zw);
	v.texcoord3 = v.texcoord2 = v.texcoord1 = v.texcoord;
	
	#ifdef TERRAIN_INSTANCED_PERPIXEL_NORMAL
		v.normal = float3( 0.0, 1.0, 0.0 ); // TODO: reconstruct the tangent space in the pixel shader. Seems to be hard with surface shader especially when other attributes are packed together with tSpace.
		data.tc.zw = sampleCoords;
	#else
		#if defined(TERRAIN_USE_SEPARATE_VERTEX_SAMPLER)
			float3 nor = _TerrainNormalmapTexture.SampleLevel( vertex_linear_clamp_sampler, sampleCoords, 0 ).xyz;
		#else
			float3 nor = tex2Dlod( _TerrainNormalmapTexture, float4( sampleCoords, 0.0, 0.0 ) ).xyz;
		#endif
		v.normal = 2.0 * nor - 1.0;
	#endif
#endif
	
	v.tangent.xyz = cross( v.normal, float3( 0.0, 0.0, 1.0 ) );
	v.tangent.w = -1.0;
	
	data.tc.xy = v.texcoord.xy;
#ifdef TERRAIN_BASE_PASS
	#ifdef UNITY_PASS_META
		data.tc.xy = TRANSFORM_TEX( v.texcoord.xy, _MainTex );
	#endif
#else
	float4 pos = UnityObjectToClipPos( v.vertex );
	UNITY_TRANSFER_FOG( data, pos );
#endif
}

#ifndef TERRAIN_BASE_PASS

void ComputeMasks( out half4 masks[4], half4 hasMask, float4 uvSplat01, float4 uvSplat23 )
{
	masks[0] = 0.5h;
	masks[1] = 0.5h;
	masks[2] = 0.5h;
	masks[3] = 0.5h;
	
#ifdef _MASKMAP
	masks[0] = lerp( masks[0], UNITY_SAMPLE_TEX2D( _Mask0, uvSplat01.xy ), hasMask.x );
	masks[1] = lerp( masks[1], UNITY_SAMPLE_TEX2D_SAMPLER( _Mask1, _Mask0, uvSplat01.zw ), hasMask.y );
	masks[2] = lerp( masks[2], UNITY_SAMPLE_TEX2D_SAMPLER( _Mask2, _Mask0, uvSplat23.xy ), hasMask.z );
	masks[3] = lerp( masks[3], UNITY_SAMPLE_TEX2D_SAMPLER( _Mask3, _Mask0, uvSplat23.zw ), hasMask.w );
#endif
	
	masks[0] *= _MaskMapRemapScale0.rgba;
	masks[0] += _MaskMapRemapOffset0.rgba;
	masks[1] *= _MaskMapRemapScale1.rgba;
	masks[1] += _MaskMapRemapOffset1.rgba;
	masks[2] *= _MaskMapRemapScale2.rgba;
	masks[2] += _MaskMapRemapOffset2.rgba;
	masks[3] *= _MaskMapRemapScale3.rgba;
	masks[3] += _MaskMapRemapOffset3.rgba;
}

#ifdef TERRAIN_BLEND_HEIGHT
	void HeightBasedSplatModify( inout half4 splatControl, in half4 maskHeight )
	{
		// Multiply by the splat control weights to get combined height.
		half4 splatHeight = maskHeight * splatControl;
		half maxHeight = max( splatHeight.r, max( splatHeight.g, max( splatHeight.b, splatHeight.a ) ) );
		
		// Ensure that the transition height is not zero.
		half transition = max( _HeightTransition, 1e-4 );
		
		// This sets the highest splat to "transition", and everything else to a lower value relative to that, clamping to zero.
		half4 weightedHeights = splatHeight + transition - maxHeight;
		weightedHeights = max( 0.0h, weightedHeights );
//		// Alternative method, using smoothstep instead, seems to give almost identical results.	
//		half4 weightedHeights = smoothstep( maxHeight - transition, maxHeight, splatHeight );
		
		// We need to add an epsilon here for active layers (hence the blendMask again) so that at least a layer shows up if everything's too low.
		weightedHeights = (weightedHeights + 1e-6) * splatControl;
		
		// Normalize (and clamp to epsilon to keep from dividing by zero).
		half sumHeight = max( dot( weightedHeights, 1.0h ), 1e-6 );
		splatControl = weightedHeights / sumHeight;
	}
#endif

void SplatmapMix( float4 uvSplat01, float4 uvSplat23, inout half4 splatControl, in half4 maskHeight, out half weight, out half3 mixedDiffuse, out half4 defaultSmoothness, out half3 mixedNormal )
{
	half4 diffAlbedo[4];
	
	diffAlbedo[0] = tex2D( _Splat0, uvSplat01.xy );
	diffAlbedo[1] = tex2D( _Splat1, uvSplat01.zw );
	diffAlbedo[2] = tex2D( _Splat2, uvSplat23.xy );
	diffAlbedo[3] = tex2D( _Splat3, uvSplat23.zw );
	
	// This might be a bit of a gamble -- the assumption here is that if the diffuseMap has no
	// alpha channel, then diffAlbedo[n].a = 1.0 (and _DiffuseHasAlphaN = 0.0)
	// Prior to coming in, _SmoothnessN is actually set to max(_DiffuseHasAlphaN, _SmoothnessN)
	// This means that if we have an alpha channel, _SmoothnessN is locked to 1.0 and
	// otherwise, the true slider value is passed down and diffAlbedo[n].a == 1.0.
	defaultSmoothness = half4( diffAlbedo[0].a, diffAlbedo[1].a, diffAlbedo[2].a, diffAlbedo[3].a );
	defaultSmoothness *= half4( _Smoothness0, _Smoothness1, _Smoothness2, _Smoothness3 );
	
	weight = dot( splatControl, 1.0h );
	
#if !defined(SHADER_API_MOBILE) && defined(TERRAIN_SPLAT_ADDPASS)
	clip( weight <= 0.005h ? -1.0h : 1.0h );
#endif
	
	// Normalize weights before lighting and restore weights in final modifier functions so that the overall
	// lighting result can be correctly weighted.
	splatControl /= (weight + 1e-3);
	
#ifdef TERRAIN_BLEND_HEIGHT
	HeightBasedSplatModify( splatControl, maskHeight );
#endif
	
	mixedDiffuse = 0.0h;
	mixedDiffuse += diffAlbedo[0] * half4( _DiffuseRemapScale0.rgb * splatControl.r, 1.0h );
	mixedDiffuse += diffAlbedo[1] * half4( _DiffuseRemapScale1.rgb * splatControl.g, 1.0h );
	mixedDiffuse += diffAlbedo[2] * half4( _DiffuseRemapScale2.rgb * splatControl.b, 1.0h );
	mixedDiffuse += diffAlbedo[3] * half4( _DiffuseRemapScale3.rgb * splatControl.a, 1.0h );
	
	mixedNormal = half3( 0.0h, 0.0h, 1.0h );
#ifdef _NORMALMAP
	mixedNormal  = UnpackNormalWithScale( tex2D( _Normal0, uvSplat01.xy ), _NormalScale0 ) * splatControl.r;
	mixedNormal += UnpackNormalWithScale( tex2D( _Normal1, uvSplat01.zw ), _NormalScale1 ) * splatControl.g;
	mixedNormal += UnpackNormalWithScale( tex2D( _Normal2, uvSplat23.xy ), _NormalScale2 ) * splatControl.b;
	mixedNormal += UnpackNormalWithScale( tex2D( _Normal3, uvSplat23.zw ), _NormalScale3 ) * splatControl.a;
	#if defined(SHADER_API_SWITCH)
		mixedNormal.z += UNITY_HALF_MIN; // to avoid nan after normalizing
	#else
		mixedNormal.z += 1e-5f; // to avoid nan after normalizing
	#endif
#endif
}

void SplatmapSurf( float2 uv, out half3 albedo, out half3 normal, out half metallic, out half smoothness, out half occlusion, out half alpha )
{
	float4 uvSplat01, uvSplat23;
	uvSplat01.xy = TRANSFORM_TEX( uv, _Splat0 );
	uvSplat01.zw = TRANSFORM_TEX( uv, _Splat1 );
	uvSplat23.xy = TRANSFORM_TEX( uv, _Splat2 );
	uvSplat23.zw = TRANSFORM_TEX( uv, _Splat3 );
	
	half4 hasMask = half4( _LayerHasMask0, _LayerHasMask1, _LayerHasMask2, _LayerHasMask3 );
	half4 masks[4];
	ComputeMasks( masks, hasMask, uvSplat01, uvSplat23 );
	
	half4 maskMetallic = half4( masks[0].r, masks[1].r, masks[2].r, masks[3].r );
	half4 maskOcclusion = half4( masks[0].g, masks[1].g, masks[2].g, masks[3].g );
	half4 maskHeight = half4( masks[0].b, masks[1].b, masks[2].b, masks[3].b );
	half4 maskSmoothness = half4( masks[0].a, masks[1].a, masks[2].a, masks[3].a );
	
	// adjust splatUVs so the edges of the terrain tile lie on pixel centers
	float2 splatUV = (uv * (_Control_TexelSize.zw - 1.0f) + 0.5f) * _Control_TexelSize.xy;
	half4 splatControl = tex2D( _Control, splatUV );
	
	half4 defaultSmoothness;
	SplatmapMix( uvSplat01, uvSplat23, splatControl, maskHeight, alpha, albedo, defaultSmoothness, normal );
	
	half4 defaultMetallic = half4( _Metallic0, _Metallic1, _Metallic2, _Metallic3 );
	half4 defaultOcclusion = half4( _MaskMapRemapScale0.g, _MaskMapRemapScale1.g, _MaskMapRemapScale2.g, _MaskMapRemapScale3.g ) +
							 half4( _MaskMapRemapOffset0.g, _MaskMapRemapOffset1.g, _MaskMapRemapOffset2.g, _MaskMapRemapOffset3.g );
	
	defaultMetallic = lerp( defaultMetallic, maskMetallic, hasMask );
	defaultSmoothness = lerp( defaultSmoothness, maskSmoothness, hasMask );
	defaultOcclusion = lerp( defaultOcclusion, maskOcclusion, hasMask );
	
	metallic = dot( splatControl, defaultMetallic );
	smoothness = dot( splatControl, defaultSmoothness );
	occlusion = dot( splatControl, defaultOcclusion );
}

#ifndef TERRAIN_SURFACE_OUTPUT
	#include "Lighting.cginc"
	#define TERRAIN_SURFACE_OUTPUT SurfaceOutput
#endif

void SplatmapFinalColor( Input IN, TERRAIN_SURFACE_OUTPUT o, inout fixed4 color )
{
	color *= o.Alpha;
#ifdef TERRAIN_SPLAT_ADDPASS
	UNITY_APPLY_FOG_COLOR( IN.fogCoord, color, fixed4( 0.0, 0.0, 0.0, 0.0 ) );
#else
	UNITY_APPLY_FOG( IN.fogCoord, color );
#endif
}

void SplatmapFinalPrepass( Input IN, TERRAIN_SURFACE_OUTPUT o, inout fixed4 normalSpec )
{
	normalSpec *= o.Alpha;
}

void SplatmapFinalGBuffer( Input IN, TERRAIN_SURFACE_OUTPUT o, inout half4 outGBuffer0, inout half4 outGBuffer1, inout half4 outGBuffer2, inout half4 emission )
{
	UnityStandardDataApplyWeightToGbuffer( outGBuffer0, outGBuffer1, outGBuffer2, o.Alpha );
	emission *= o.Alpha;
}

#endif // TERRAIN_BASE_PASS

#endif // TERRAIN_SPLATMAP_COMMON_CGINC
