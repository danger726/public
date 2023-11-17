// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Hidden/TerrainEngine/Details/BillboardWavingDoublePass"
{
	Properties
	{
		_WavingTint( "Fade Color", Color ) = (0.7, 0.6, 0.5, 0.0)
		_MainTex( "Base (RGB) Alpha (A)", 2D ) = "white" {}
		_WaveAndDistance( "Wave and distance", Vector ) = (12.0, 3.6, 1.0, 1.0)
		_Cutoff( "Cutoff", float ) = 0.5
	}


	CGINCLUDE
	
	#include "UnityCG.cginc"
	#include "TerrainEngine.cginc"

	struct v2f
	{
		float4 pos : SV_POSITION;
		fixed4 color : COLOR;
		float4 uv : TEXCOORD0;
		UNITY_VERTEX_OUTPUT_STEREO
	};
	
	v2f BillboardVert( appdata_full v )
	{
		v2f o;
		
		UNITY_SETUP_INSTANCE_ID( v );
		UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );
		WavingGrassBillboardVert( v );
		
		o.color = v.color;

		o.color.rgb *= ShadeVertexLights( v.vertex, v.normal );

		o.pos = UnityObjectToClipPos( v.vertex );
		o.uv = v.texcoord;
		
		return o;
	}
	
	ENDCG


	SubShader
	{
		Tags
		{
			"Queue" = "Geometry+200"
			"IgnoreProjector" = "True"
			"RenderType" = "GrassBillboard"
			"DisableBatching" = "True"
		}
		
		Cull Off
		LOD 200

		CGPROGRAM
		
		#pragma surface surf Standard vertex:WavingGrassBillboardVert addshadow fullforwardshadows

		sampler2D _MainTex;
		fixed _Cutoff;

		struct Input
		{
			float2 uv_MainTex;
			fixed4 color : COLOR;
		};

		void surf( Input IN, inout SurfaceOutputStandard o )
		{
			fixed4 c = tex2D( _MainTex, IN.uv_MainTex ) * IN.color;
			o.Albedo = c.rgb;
			o.Metallic = 0.0;
			o.Smoothness = 0.0f;
			o.Alpha = c.a;
			clip( o.Alpha - _Cutoff );
			o.Alpha *= IN.color.a;
		}

		ENDCG
	}

	Fallback Off
}
