Shader "Custom/UI/UINoiseEffect"
{
    Properties{
		[PerRendererData]_MainTex("Sprite Texture", 2D) = "white" {}
        _NoiseTex("Noise Texture", 2D) = "white" {}
		_Color("Tint", Color) = (1,1,1,1)

		_StencilComp("Stencil Comparison", Float) = 8
		_Stencil("Stencil ID", Float) = 0
		_StencilOp("Stencil Operation", Float) = 0
		_StencilWriteMask("Stencil Write Mask", Float) = 255
		_StencilReadMask("Stencil Read Mask", Float) = 255
		_ColorMask("Color Mask", Float) = 15

        _Intensity("强度", Range(0,10)) = 3
        _Speed("Speed", Vector) = (0.5,0.5,0.5,0.5)
    }
    SubShader{
		Tags{
			"Queue" = "Transparent"
			"IgnoreProjector" = "True"
			"RenderType" = "Transparent"
			"PreviewType" = "Plane"
			"CanUseSpriteAtlas" = "True"
		}

		Stencil{
			Ref[_Stencil]
			Comp[_StencilComp]
			Pass[_StencilOp]
			ReadMask[_StencilReadMask]
			WriteMask[_StencilWriteMask]
		}
		ColorMask[_ColorMask]

		Cull Off
		Lighting Off
		ZWrite Off
		ZTest[unity_GUIZTestMode]
		Blend SrcAlpha OneMinusSrcAlpha

        Pass{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			struct appdata_t
			{
				float4 vertex : POSITION;
				fixed4 color : COLOR;
				half2 texcoord : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				fixed4 color : COLOR;
				half2 texcoord : TEXCOORD0;
                half2 noiseuv : TEXCOORD1;
			};

			sampler2D _MainTex;
            sampler2D _NoiseTex;
            float4 _NoiseTex_ST;
			fixed4 _Color;
            Vector _Speed;
            float _Intensity;

			v2f vert(appdata_t i)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(i.vertex);
				o.texcoord = i.texcoord;
                o.noiseuv = TRANSFORM_TEX(i.texcoord, _NoiseTex);
#ifdef UNITY_HALF_TEXEL_OFFSET
				o.vertex.xy += (_ScreenParams.zw - 1.0)*float2(-1,1);
#endif
				o.color = i.color * _Color;
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
                float2 uv = i.noiseuv + _Speed.xy * _Time.y;
                uv = frac(uv);
                fixed4 noise = tex2D(_NoiseTex, uv);
                noise = (noise*2-1) * 0.01;
                i.texcoord += frac(_Time.y * _Speed.zw);
                i.texcoord = frac(i.texcoord);
                i.texcoord += noise * _Intensity;

				half4 color = tex2D(_MainTex, i.texcoord) * i.color;
				clip(color.a - 0.01);
				return color;
			}

            ENDCG
        }
    }
}