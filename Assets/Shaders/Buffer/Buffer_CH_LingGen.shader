Shader "Custom/Buffer/CH_LingGen"
{
	Properties
	{
		_MainTex("Ö÷ÌùÍ¼", 2D) = "white" {}
		_bufColor("Color", Color) = (0.5,0.5,0.5,0.5)
		_bufAlpha("Alpha", Range(0.0, 1.0)) = 4.0
		_grayPower("Gray", Range(0.0, 1.0)) = 0.2
	}
	SubShader
	{
		Tags { "Queue" = "Transparent" }

		CGPROGRAM
		#pragma surface surf Lambert alpha
		struct Input 
		{
			float3 viewDir;
			float2 uv_MainTex;
			INTERNAL_DATA
		};
		uniform sampler2D _MainTex;
		float4 _bufColor;
		float _bufAlpha;
		float _grayPower;

		void surf(Input IN, inout SurfaceOutput o)
		{
			half4 color = tex2D(_MainTex, IN.uv_MainTex);
			half4 gray = dot(color.rgb, float3(_grayPower, _grayPower, _grayPower)) + (1 - _grayPower);
			o.Emission = _bufColor.rgb*gray;
			o.Alpha = _bufAlpha;
		}
		ENDCG
	}
	Fallback "VertexLit"
}