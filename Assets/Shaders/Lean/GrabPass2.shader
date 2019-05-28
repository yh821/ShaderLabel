// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "ApcShader/GrabPass2"
{
	Properties
	{
		_NoiseTex("Noise Texture", 2D) = "white" {}
		_Color("Tint", Color) = (1,1,1,1)
		_Intensity("强度", Range(0,10)) = 3
        _Speed("Speed", Vector) = (0.5,0.5,0.5,0.5)
	}
	SubShader
	{
		//此处给出一个抓屏贴图的名称，抓屏的贴图就可以通过这张贴图来获取，而且每一帧不管有多个物体使用了该shader，
		//只会有一个进行抓屏操作
		//如果此处为空，则默认抓屏到_GrabTexture中，但是据说每个用了这个shader的都会进行一次抓屏！
		GrabPass
		{
			"_GrabTempTex"
		}

		//ZWrite Off

		Pass
		{
			Tags
			{
				"RenderType" = "Transparent"
				"Queue" = "Transparent+1"
			}

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			sampler2D _GrabTempTex;
			float4 _GrabTempTex_ST;
			sampler2D _NoiseTex;
            float4 _NoiseTex_ST;
			float _Intensity;
			Vector _Speed;

			struct v2f
			{
				float4 pos : SV_POSITION;
				float4 grabPos : TEXCOORD0;
				half2 noiseuv : TEXCOORD1;
			};

			v2f vert(appdata_base v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.noiseuv = TRANSFORM_TEX(v.texcoord, _NoiseTex);
				//计算抓屏的位置，其中主要是将坐标从(-1,1)转化到（0,1）空间并处理DX和GL纹理反向的问题
				o.grabPos = ComputeGrabScreenPos(o.pos);
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				float2 uv = i.noiseuv + _Speed.xy * _Time.y;
                uv = frac(uv);
                fixed4 noise = tex2D(_NoiseTex, uv);
                noise = (noise*2-1) * 0.01;
                i.grabPos.xy += frac(_Time.y * _Speed.zw);
                i.grabPos.xy = frac(i.grabPos.xy);
                i.grabPos.xy += noise * _Intensity;

				//根据抓屏位置采样Grab贴图,tex2Dproj等同于tex2D(grabPos.xy / grabPos.w)
				fixed4 color = tex2Dproj(_GrabTempTex, i.grabPos);
				return fixed4(color.r,color.r,color.r,1);//1 - color;
			}
			ENDCG
		}
	}
}