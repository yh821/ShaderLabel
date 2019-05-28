// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/Scene/Water_Distort"  //带alpha 贴图和扰动纹理的水,表现水流等
{
	Properties 
	{
		_NormalMap("波纹法线图", 2D) = "bump" {}
		_BumpDirection("Bump Direction & Speed", Vector) = (8.0, 8.0, 0, 0)
		_BumpTiling("Bump Tiling", Vector) = (10.0, 8.0, 0, 0)

		_ReflectionMap("反射图",2D) = "white"{}
		_ReflectionDistortion("反射扰动", float) = 0.5
		_ReflectionAlpha("反射Alpha", Range(0, 1)) = 1.0


		_MainColor ("基础颜色", Color) = (0.1137,0.4,0.31,1)
		_MainTex("_MainTex", 2D) = "white" {}

		_TintColor("扰动颜色", Color) = (0.5,0.5,0.5,0.5)
		_NoiseTex("扰动纹理", 2D) = "white" {}
		_HeatTime("扰动纹理扰动速度", Vector) = (0.2, 0.03, 0.5, 0.5)

		_AplhaTex("Aplha贴图", 2D) = "white" {}
		_SpecularColor("镜面高光颜色", Color) = (1, 0, 0, 1)

		_SpecularShininess("镜面高光强度", Range (0.001, 2)) = 1
		_NormalScale("Normal Scale", Range (1, 32)) = 8
		_SpecularLightDir("太阳光位置",Vector) = (50,-15,1,0)
	}

	SubShader 
	{
		Tags { "Queue"="Transparent" "RenderType"="Transparent" }
		Pass
		{
			Blend SrcAlpha OneMinusSrcAlpha
			ZTest LEqual
			ZWrite Off

			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#pragma fragmentoption ARB_precision_hint_fastest 
				#include "UnityCG.cginc"

				sampler2D _NormalMap;
				sampler2D _ReflectionMap;
				half4 _ReflectionMap_ST;

				fixed4 _MainColor;

				half _ReflectionDistortion;
				half _ReflectionAlpha;

				half4 _BumpDirection;
				half4 _BumpTiling;


				fixed4 _SpecularColor;
				fixed  _SpecularShininess;
				fixed  _NormalScale;
				half4 _SpecularLightDir;

				struct v2f_full
				{
					half4 pos : SV_POSITION;
					half2 uv : TEXCOORD0;
					half4 bumpCoords : TEXCOORD1;
					half3 viewDir :TEXCOORD2;
					half4 color : Color;
				};
			
				v2f_full vert (appdata_full v) 
				{
					v2f_full o;
					o.pos = UnityObjectToClipPos (v.vertex);
					o.bumpCoords.xyzw = v.texcoord.xyxy * _BumpTiling + frac(_Time.xxxx * _BumpDirection) ;
					o.uv = TRANSFORM_TEX(v.texcoord, _ReflectionMap);
					o.viewDir = normalize(mul(unity_ObjectToWorld, v.vertex).xyz - _WorldSpaceCameraPos);
					o.color = v.color;
					return o; 
				}
				
				fixed4 frag (v2f_full i) : COLOR0
				{	
			

					// normal 
					fixed4 temp = tex2D(_NormalMap, i.bumpCoords.xy);

					fixed4 normal_1 = fixed4(UnpackNormal(temp),temp.w);
					temp = tex2D(_NormalMap, i.bumpCoords.zw);
					fixed4 normal_2 =  fixed4(UnpackNormal(temp),temp.w);
					fixed4 bump = normal_1 + normal_2; // [0,1]->[0,2]
	//#if (defined(SHADER_API_GLES) || defined(SHADER_API_GLES3)) && defined(SHADER_API_MOBILE)  
					fixed3 normal = fixed3(bump.x-1.0, 1, bump.z-1.0); // [0,2]->[-1,1]
	//#else
	//				fixed3 normal = fixed3(bump.w-1.0, 1, bump.y-1.0); // [0,2]->[-1,1]
	//#endif
					normal *= _NormalScale;
					// reflection
					fixed4 offset = (normal_1 - 0.5) * _ReflectionDistortion;
					fixed4 reflection = tex2D(_ReflectionMap, i.uv + offset.xy);
					
					// specular
					fixed3 h	= normalize (_SpecularLightDir.xyz + i.viewDir);
					fixed nh 	= max (0, dot (normal, h));
					fixed spec	= pow (nh, _SpecularShininess);

					// final color
					fixed4 baseColor = _MainColor + (reflection * _ReflectionAlpha)  + spec * _SpecularColor;
					baseColor.a =  _MainColor.a;
					baseColor = baseColor*i.color;
					return baseColor;
				}	
			ENDCG
		}	

		Pass 
		{
			Blend SrcAlpha One
			Cull Off Lighting Off ZWrite Off Fog { Color (0,0,0,0) }

			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#pragma fragmentoption ARB_precision_hint_fastest
				#pragma multi_compile_particles
				#include "UnityCG.cginc"

				struct appdata_t 
				{
					fixed4 vertex : POSITION;
					fixed4 color : COLOR;
					fixed2 texcoord: TEXCOORD0;
				};

				struct v2f 
				{
					fixed4 vertex : POSITION;
					fixed4 color : COLOR;
					fixed2 uvmain : TEXCOORD1;
					fixed2 uvAlpha : TEXCOORD2;
				};

				fixed4 _TintColor;
				fixed4 _HeatTime;
				float4 _MainTex_ST;
				float4 _NoiseTex_ST;
				float4 _AplhaTex_ST;
				sampler2D _NoiseTex;
				sampler2D _MainTex;
				sampler2D _AplhaTex;


				v2f vert (appdata_t v)
				{
					v2f o;
					o.vertex = UnityObjectToClipPos(v.vertex);
					o.color = v.color;
					o.uvmain = TRANSFORM_TEX(v.texcoord, _MainTex);
					o.uvAlpha = TRANSFORM_TEX(v.texcoord, _AplhaTex);
					return o;
				}

				fixed4 frag(v2f i) : COLOR
				{
					fixed4 offsetColor1 = tex2D(_NoiseTex, i.uvmain + frac(_Time.y * _HeatTime.xy));
					fixed4 offsetColor2 = tex2D(_NoiseTex, i.uvmain + frac(_Time.y * _HeatTime.yx));
			
					i.uvmain.x += ((offsetColor1.r + offsetColor2.r) - 1) * _HeatTime.z;
					i.uvmain.y += ((offsetColor1.r + offsetColor2.r) - 1) * _HeatTime.w;
					return 2.0f * i.color * _TintColor * tex2D( _MainTex, i.uvmain)  * tex2D(_AplhaTex, i.uvAlpha);
				}
			ENDCG
		}
	}
}
