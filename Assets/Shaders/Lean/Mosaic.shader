// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'
//马赛克
Shader "Lean/Mosaic"
{
	Properties {
		_MainTex ("Base(RGB)", 2D) = "white" {}
		_MosaicSize("MosaicSize", int)=5
	}
	
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 100
		
		Blend One OneMinusSrcAlpha

		Pass {  
			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
			
				
				#include "UnityCG.cginc"
	
				struct appdata_t {
					float4 vertex : POSITION;//三维坐标
					float2 texcoord : TEXCOORD0;//纹理坐标
				};
	
				struct v2f {
					float4 vertex : SV_POSITION;
					half2 texcoord : TEXCOORD0;
				};
	
				sampler2D _MainTex;
				float4 _MainTex_ST;
				//内置四元数变量_MainTex_TexelSize，这个变量的从字面意思是主贴图_MainTex的像素尺寸大小，是一个四元数，它的值为 Vector4(1 / width, 1 / height, width, height)
				half4 _MainTex_TexelSize;
				int _MosaicSize;
				v2f vert (appdata_t v)
				{
					v2f o;
					o.vertex = UnityObjectToClipPos(v.vertex);//三维坐标转裁剪坐标
					o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);//纹理偏移后的坐标
					return o;
				}
				
				fixed4 frag (v2f i) : SV_Target
				{
					float2 uv = (i.texcoord*_MainTex_TexelSize.zw) ;//将纹理坐标映射到分辨率的坐标
					uv = floor(uv/_MosaicSize)*_MosaicSize;//根据马赛克块大小进行取整，使得纹理坐标都使用该区域的左下角的uv
					i.texcoord =uv*_MainTex_TexelSize.xy;//把坐标重新映射回0,1的范围之内
					fixed4 col = tex2D(_MainTex, i.texcoord);
				
					return col;
				}
			ENDCG
		}
	}
}