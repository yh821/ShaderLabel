// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


Shader "Lean/GaussianBlur"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_BlurRadius ("BlurRadius", Range(1, 20)) = 5
		_TextureSize ("TextureSize", Float) = 256
		[KeywordEnum(None, Gauss, Simple)] _BlurType ("BlurType", Float) = 0
	}
	SubShader
	{
		// No culling or depth
		//Cull Off ZWrite Off ZTest Always
		Blend SrcAlpha OneMinusSrcAlpha

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile _BLURTYPE_NONE _BLURTYPE_GAUSS _BLURTYPE_SIMPLE

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}
			
			sampler2D _MainTex;
			int _BlurRadius;
			float _TextureSize;
			float _BlurType;

			//这一步其实可以用计算出来的常量来替代，不需要在循环中每一步计算
			float GetGaussWeight(float x, float y, float sigma)
			{
				float sigma2 = pow(sigma, 2.0f);
				float left = 1 / (2 * sigma2 * 3.1415926f);
				float right = exp(-(x*x+y*y)/(2*sigma2));
				return left * right;
			}

			//高斯模糊
			fixed4 GaussBlur(float2 uv)
			{
				//因为高斯函数中3σ以外的点的权重已经很小了，因此σ取半径r/3的值
				float sigma = (float)_BlurRadius / 3.0f;
				float4 col = float4(0, 0, 0, 0);
				for (int x = - _BlurRadius; x <= _BlurRadius; ++x)
				{
					for (int y = - _BlurRadius; y <= _BlurRadius; ++y)
					{
						//获取周围像素的颜色
						//因为uv是0-1的一个值，而像素坐标是整形，我们要取材质对应位置上的颜色，需要将整形的像素坐标
						//转为uv上的坐标值
						float4 color = tex2D(_MainTex, uv + float2(x / _TextureSize, y / _TextureSize));
						//获取此像素的权重
						float weight = GetGaussWeight(x, y, sigma);
						//计算此点的最终颜色
						col += color * weight;
						
					}
				}
				return col;
			}

			//简单模糊
			fixed4 SimpleBlur(float2 uv)
			{
				float4 col = float4(0, 0, 0, 0);
				for (int x = - _BlurRadius; x <= _BlurRadius; ++x)
				{
					for (int y = - _BlurRadius; y <= _BlurRadius; ++y)
					{
						float4 color = tex2D(_MainTex, uv + float2(x / _TextureSize, y / _TextureSize));
						//简单的进行颜色累加
						col += color;
					}
				}
				//取平均数，所取像素为边长为(半径*2+1)的矩阵
				col = col / pow(_BlurRadius * 2 + 1, 2.0f);
				return col;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				float4 col;
				#if _BLURTYPE_GAUSS
				col = GaussBlur(i.uv);
				#elif _BLURTYPE_SIMPLE
				col = SimpleBlur(i.uv);
				#else
				col = tex2D(_MainTex, i.uv);
				#endif
				return col;
			}
			ENDCG
		}
	}
}