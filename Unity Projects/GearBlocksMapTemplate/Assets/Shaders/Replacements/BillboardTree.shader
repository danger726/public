// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Hidden/TerrainEngine/BillboardTree"
{
	Properties
	{
		_MainTex( "Base (RGB) Alpha (A)", 2D ) = "white" {}
		
		_Cutoff( "Alpha cutoff", Range( 0.0, 1.0 ) ) = 0.3
	}
	
	SubShader
	{
		Tags
		{
			"IgnoreProjector" = "True"
			"RenderType" = "TreeBillboard"
		}
		
		
		CGINCLUDE
		
		#include "UnityCG.cginc"
		#include "TerrainEngine.cginc"
		
		fixed _Cutoff;
		
		struct v2f
		{
			float4 pos : SV_POSITION;
			fixed4 color : COLOR0;
			float2 uv : TEXCOORD0;
			UNITY_FOG_COORDS( 1 )
			UNITY_VERTEX_OUTPUT_STEREO
		};
		
		v2f vert( appdata_tree_billboard v )
		{
			v2f o;
			
			UNITY_SETUP_INSTANCE_ID( v );
			UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );
			TerrainBillboardTree( v.vertex, v.texcoord1.xy, v.texcoord.y );
			o.pos = UnityObjectToClipPos( v.vertex );
			o.uv.x = v.texcoord.x;
			o.uv.y = v.texcoord.y > 0;
			o.color = v.color;
			UNITY_TRANSFER_FOG( o, o.pos );
			
			return o;
		}
		
		sampler2D _MainTex;
		
		ENDCG
		
		
		Pass
		{
			Tags
			{
				"Queue" = "Transparent-100"
				"LightMode" = "ForwardBase"
			}
			
			ColorMask rgb
			Blend SrcAlpha OneMinusSrcAlpha
			ZWrite Off
			Cull Off
			
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase
			#pragma multi_compile_fog
			
			fixed4 frag( v2f input ) : SV_Target
			{
				fixed4 col = tex2D( _MainTex, input.uv );
				col.rgb *= input.color.rgb;
				clip( col.a - _Cutoff );
				UNITY_APPLY_FOG( input.fogCoord, col );
				
				return col;
			}
			
			ENDCG
		}
		
		Pass
		{
			Tags
			{
				"Queue" = "Geometry+200"
				"LightMode" = "Deferred"
			}
			
			ZWrite On
			Cull Off
			
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_prepassfinal
			#pragma multi_compile_fog
			#pragma exclude_renderers nomrt
			
			void frag( v2f input,
					   out half4 outGBuffer0: SV_Target0,	// albedo (rgb), occlusion (a)
					   out half4 outGBuffer1: SV_Target1,	// spec color (rgb), smoothness (a)
					   out half4 outGBuffer2: SV_Target2,	// normal (rgb)
					   out half4 outEmission: SV_Target3 )	// emission (rgb)
			{
				fixed4 col = tex2D( _MainTex, input.uv );
				col.rgb *= input.color.rgb;
				clip( col.a - _Cutoff );
				UNITY_APPLY_FOG( input.fogCoord, col );
				
				// We don't want any additional lighting to be applied, so output colour to emission target.
				outGBuffer0 = 0.0;
				outGBuffer1 = 0.0;
				outGBuffer2 = 0.0;
				outEmission = col;
			}
			
			ENDCG
		}
	}
	
	Fallback Off
}
