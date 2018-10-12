// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/UI/UVSprite"
{
	Properties
	{
		_MainTex("MainTex", 2D) = "white" {}
		_Color("Color", color) = (1,1,1,1)
		_UV("UV", Vector) = (0,0,0)
		[Space(10)]
		_HorizontalAmount("HorizontalAmount", int) = 3
		_VerticalAmount("VerticalAmount", int) = 3
		_ShowMode ("显示模式", int) = 0
	}

	SubShader
	{
		Tags{ "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" }

		Pass
		{
			Tags{ "LightMode" = "ForwardBase" }

			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#pragma vertex vert  
			#pragma fragment frag

			#include "UnityCG.cginc"

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float2 _UV;
			int _HorizontalAmount;
			int _VerticalAmount;
			int _ShowMode;
			fixed4 _Color;

			struct a2v {
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
				fixed4 color : COLOR;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				fixed4 color : COLOR;
			};

			v2f vert(a2v v) {
				v2f o;
				//将顶点坐标转换到裁剪空间坐标系并且
				o.pos = UnityObjectToClipPos(v.vertex);
				//将纹理坐标映射到顶点上以及zw偏移
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.color = v.color;
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				half2 uv = i.uv + half2(_UV.x, _UV.y);

				if (_ShowMode == 0) 
				{
					uv.x /= _HorizontalAmount;
					uv.y /= _VerticalAmount;
				}
				else if (_ShowMode == 1)
				{
					uv = frac(uv);
				}

				//纹理采样
				fixed4 c = tex2D(_MainTex, uv) * _Color;

				return c;
			}

			ENDCG
		}
	}
	//FallBack "Transparent/VertexLit"
}