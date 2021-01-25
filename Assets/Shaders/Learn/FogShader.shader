Shader "Learn/FogShader"
{
	//只有不透明shader才会被写入ZBuffer
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_FogColor("Fog Color", Color) = (1,1,1,1)
	}
		SubShader
	{
		Tags { "RenderType" = "Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
			sampler2D _CameraDepthTexture;

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float4 scrPos : TEXCOORD1;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float4 _FogColor;
			float _depthSlope;
			float _depthStart;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.scrPos = ComputeScreenPos(o.vertex); //齐次坐标下的屏幕坐标， 范围(0,w)    
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				float depthValue = UNITY_SAMPLE_DEPTH(tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.scrPos)));
				float depth = saturate(Linear01Depth(depthValue) * _depthSlope + _depthStart);

				//fog的效果 越近越呈现自己的原色，越远越接近fogColor
				fixed4 selfColor = tex2Dproj(_MainTex, i.scrPos);
				fixed4 fogColor = _FogColor * depth;
				return lerp(selfColor, fogColor, depth);//返回深度纹理 uv映射后的颜色
			}
			ENDCG
		}
	}
}