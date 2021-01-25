Shader "Learn/InnerGlow"
{
	Properties
	{
		//_MainTex ("Texture", 2D) = "white" {}
		_Color ("Color", Color) = (0,0,0,1)
		_InSideRimColor ("InSideRimColor", Color)=(1,1,1,1)
		_InSideRimPower ("InSideRimPower", Range(0.0,5))=0
		_InSideRimIntensity ("InSideRimIntensity", Range(0,10))=5
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float4 normal: NORMAL;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				float4 normal: TEXCOORD1;
				float4 vertexWorld: TEXCOORD2;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float4 _Color;
			float4 _InSideRimColor;
			float _InSideRimPower;
			float _InSideRimIntensity;
			float _Point;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				o.normal = v.normal;//mul(unity_ObjectToWorld, v.normal);
				o.vertexWorld = mul(unity_ObjectToWorld, v.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				i.normal = normalize(i.normal);
				float3 worldViewDir = normalize(float3(0,0.5,0) - i.vertexWorld.xyz);
				half NdotV = max(0, dot(i.normal, worldViewDir));
				NdotV = 1.0 - NdotV;
				float fresnel = pow(NdotV,_InSideRimPower)*_InSideRimIntensity;
				float4 Emissive = _InSideRimColor*fresnel;
				return _Color+Emissive;
			}
			ENDCG
		}
	}
}
