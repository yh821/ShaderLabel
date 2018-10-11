Shader "Custom/Effects/Line"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Color("Color", Color) = (1,1,1,1)
		_Speed("Speed", Range(-2,2)) = -0.5
	}
	SubShader
	{
		Tags { "Queue" = "Transparent+10" }
		Lighting Off
		ZWrite Off
		Blend SrcAlpha OneMinusSrcAlpha

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct a2v
			{
				float4 vertex : POSITION;
				fixed4 color : COLOR;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				fixed4 color : COLOR;
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed4 _Color;
			float _Speed;
			
			v2f vert (a2v v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				_MainTex_ST.z = frac(_Time.y * _Speed);
				o.uv = _MainTex_ST.xy*v.uv + _MainTex_ST.zw;
				o.color = v.color * _Color;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				return tex2D(_MainTex, i.uv) * i.color;
			}
			ENDCG
		}
	}
}
