// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Lean/Normal"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_BumpTex ("Normal Map", 2D) = "bump" {}
		_Color ("Color Tint", Color) = (1, 1, 1, 1)
		_Specular ("Specular", Color) = (1, 1, 1, 1)//高光反射颜色
		_Gloss ("Gloss", Range(0, 255)) = 20 //光泽度
		_BumpScale ("Bump Scale", Range(-10,10)) = 2.0
	}
	SubShader
	{
		Pass
		{
			Tags { "LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "Lighting.cginc"
 
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _BumpTex;
			float4 _BumpTex_ST;
			float _BumpScale;
			fixed4 _Color;
			fixed4 _Specular;
			float _Gloss;
 
			struct appdata
			{
				float4 vertex : POSITION;
				float4 uv : TEXCOORD0;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
			};
 
			struct v2f
			{
				float4 vertex : SV_POSITION;
				float4 uv : TEXCOORD0;
				float4 TtoW0 : TEXCOORD1;
				float4 TtoW1 : TEXCOORD2;
				float4 TtoW2 : TEXCOORD3;
			};
 
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);//从 模型坐标 到 裁剪坐标
 
				o.uv.xy = TRANSFORM_TEX(v.uv.xy, _MainTex);//纹理偏移
				o.uv.zw = TRANSFORM_TEX(v.uv.xy, _BumpTex);//法线纹理偏移
 
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;//世界空间坐标
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);//世界空间法线
				fixed3 worldTangent = UnityObjectToWorldDir(v.tangent);//世界空间切线
				fixed3 binormal = cross(worldNormal, worldTangent) * v.tangent.w;//垂直于法线和切线面的方向有两个，而w决定了我们选择哪一个方向
 
				o.TtoW0 = float4(worldTangent.x, binormal.x, worldNormal.x, worldPos.x);
				o.TtoW1 = float4(worldTangent.y, binormal.y, worldNormal.y, worldPos.y);
				o.TtoW2 = float4(worldTangent.z, binormal.z, worldNormal.z, worldPos.z);//这样可以使v2f少传递一个参数，优化计算
 
				return o;
			}
 
			fixed4 frag (v2f i) : SV_Target
			{
				float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
 
				fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));//获取光线方向
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));//获取视觉方向
 
				fixed4 bumpColor = tex2D(_BumpTex, i.uv.zw);//法线纹理颜色，后面要转换成方向
				fixed3 tangentNormal;

				//为了方便Unity对法线纹理的存储进行优化，我们通常会把法线纹理的纹理类型标识成Normal map（详见纹理属性篇），Unity会根据不同平台选择不同的压缩方法。
				//因为压缩方法的不同，_BumpMap的rgb分量就不再是切线空间下的xyz值了，那用上面的公式就错了。这时就用Unity内置函数UnpackNormal来得到正确的法线方向。
				//tangentNormal.xy = (bumpColor.xy * 2 - 1) * _BumpScale;
				tangentNormal = UnpackNormal(bumpColor);//法线值进行映射，将其从[0,1]区间转化到[-1,1]区间
				tangentNormal.xy *= _BumpScale;//法线强度
				tangentNormal.z = sqrt(1 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));//z可以直接由xy分量求得
 
 				//把切线空间的法线变换到世界空间，顶点着色器已经传过来了转换矩阵的三行数据，我们再组装成矩阵，左乘变换即可。
				float3x3 t2wMatrix = float3x3(i.TtoW0.xyz, i.TtoW1.xyz, i.TtoW2.xyz);
				tangentNormal = normalize(half3(mul(t2wMatrix, tangentNormal)));
 
				fixed4 col = tex2D(_MainTex, i.uv) * _Color;//材质颜色
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * col;//环境光
				fixed3 diffuse = _LightColor0.rgb * col * max(0, dot(tangentNormal, lightDir));//漫反射=光源颜色*材质颜色*max(0,dot(法线,光源方向))
				fixed3 halfDir = normalize(viewDir + lightDir);//合并方向=视角方向+光源方向
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(tangentNormal, halfDir)), _Gloss);//高光反射=光源颜色*高光反射颜色*pow(max(0,dot(法线,视角方向+光源方向)),光泽度)

				return fixed4(ambient + diffuse + specular, col.w);//输出颜色=环境光+漫反射+高光反射[+自发光]
			}
			ENDCG
		}
	}
	FallBack "Specular"
}