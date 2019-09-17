// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// UI渐变
Shader "Custom/UI/UIGradual"
{
	Properties
	{
		_Texture1("Texture1", 2D) = "white" {}
		_Texture2("Texture2", 2D) = "white" {}
		_Texture3("Texture3", 2D) = "white" {}
		_Color("Tint", Color) = (1,1,1,1)

		_StencilComp("Stencil Comparison", Float) = 8
		_Stencil("Stencil ID", Float) = 0
		_StencilOp("Stencil Operation", Float) = 0
		_StencilWriteMask("Stencil Write Mask", Float) = 255
		_StencilReadMask("Stencil Read Mask", Float) = 255
		_ColorMask("Color Mask", Float) = 15

		_Duration("Duration", Range(1,10)) = 3
		_Delay("Delay", Range(1,10)) = 3
	}

	SubShader
	{
		Tags
		{
			"Queue" = "Transparent"
			"IgnoreProjector" = "True"
			"RenderType" = "Transparent"
			"PreviewType" = "Plane"
			"CanUseSpriteAtlas" = "True"
		}

		Stencil
		{
			Ref[_Stencil]
			Comp[_StencilComp]
			Pass[_StencilOp]
			ReadMask[_StencilReadMask]
			WriteMask[_StencilWriteMask]
		}

		Cull Off
		Lighting Off
		ZWrite Off
		ZTest[unity_GUIZTestMode]
		Blend SrcAlpha OneMinusSrcAlpha
		ColorMask[_ColorMask]

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			struct appdata_t
			{
				float4 vertex   : POSITION;
				fixed4 color    : COLOR;
				half2 texcoord : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex   : SV_POSITION;
				fixed4 color : COLOR;
				half2 texcoord  : TEXCOORD0;
			};

			sampler2D _Texture1;
			sampler2D _Texture2;
			sampler2D _Texture3;
			fixed4 _Color;
			float _Duration;
			float _Delay;

			v2f vert(appdata_t IN)
			{
				v2f OUT;
				OUT.vertex = UnityObjectToClipPos(IN.vertex);
				OUT.texcoord = IN.texcoord;
#ifdef UNITY_HALF_TEXEL_OFFSET
				OUT.vertex.xy += (_ScreenParams.zw - 1.0)*float2(-1,1);
#endif
				OUT.color = IN.color * _Color;
				return OUT;
			}

			fixed4 frag(v2f IN) : SV_Target
			{
				float alltime = _Duration+_Delay;
				float time = fmod(_Time.y,alltime);
				float weight = saturate(time/_Duration);
				half4 mixcol;
				int select = fmod(_Time.y/alltime,3);
				if(select==0)
					mixcol = tex2D(_Texture1, IN.texcoord) * (1.0-weight) + tex2D(_Texture2, IN.texcoord) * weight;
				else if(select==1)
					mixcol = tex2D(_Texture2, IN.texcoord) * (1.0-weight) + tex2D(_Texture3, IN.texcoord) * weight;
				else
					mixcol = tex2D(_Texture3, IN.texcoord) * (1.0-weight) + tex2D(_Texture1, IN.texcoord) * weight;
				half4 color = mixcol * IN.color;
				clip(color.a - 0.01);
				return color;
			}
			ENDCG
		}
	}
}