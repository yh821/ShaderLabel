// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Lean/Distort"
{
	Properties
	{
		_DistortStrength("DistortStrength", Range(0,1)) = 0.2
		_DistortTimeFactor("DistortTimeFactor", Range(0,1)) = 1
		_NoiseTex("NoiseTexture", 2D) = "white" {}
	}
	SubShader
	{
		//ZWrite Off
		//ZTest Always
		Cull Off
		//GrabPass
		GrabPass
		{
			//此处给出一个抓屏贴图的名称，抓屏的贴图就可以通过这张贴图来获取，而且每一帧不管有多个物体使用了该shader，只会有一个进行抓屏操作
			//如果此处为空，则默认抓屏到_GrabTexture中，但是据说每个用了这个shader的都会进行一次抓屏！
			"_GrabTempTex"
		}
 
		Pass
		{
			Tags
			{ 
				"RenderType" = "Transparent"
				"Queue" = "Transparent + 100"
			}
 
			CGPROGRAM
			sampler2D _GrabTempTex;
			float4 _GrabTempTex_ST;
			sampler2D _NoiseTex;
			float4 _NoiseTex_ST;
			float _DistortStrength;
			float _DistortTimeFactor;
			#include "UnityCG.cginc"
			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float4 grabPos : TEXCOORD1;
			};
 
			v2f vert(appdata_base v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.grabPos = ComputeGrabScreenPos(o.pos);
				o.uv = TRANSFORM_TEX(v.texcoord, _NoiseTex);
				return o;
			}
 
			fixed4 frag(v2f i) : SV_Target
			{
				//首先采样噪声图，采样的uv值随着时间连续变换，而输出一个噪声图中的随机值，乘以一个扭曲快慢系数
				float4 offset = tex2D(_NoiseTex, i.uv - _Time.xy * _DistortTimeFactor);
				//用采样的噪声图输出作为下次采样Grab图的偏移值，此处乘以一个扭曲力度的系数
				i.grabPos.xy -= offset.xy * _DistortStrength;
				//uv偏移后去采样贴图即可得到扭曲的效果
				fixed4 color = tex2Dproj(_GrabTempTex, i.grabPos);
				return color;
			}
 
			#pragma vertex vert
			#pragma fragment frag
			ENDCG
		}
	}
}