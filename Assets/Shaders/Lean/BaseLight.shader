﻿Shader "Lean/Diffuse"
{
    //属性声明
    Properties{
        _MainTex ("Main Tex", 2D) = "white" {}
        _Color ("Color Tint", Color) = (1, 1, 1, 1)
        _Specular ("Specular", Color) = (1, 1, 1, 1)//高光颜色
        _Gloss ("Gloss", Range(8.0, 256)) = 20
        _DiffuseFactor("_DiffuseFactor", Range(0, 256)) = 1//漫反射
        _SpecularFactor("_SpecularFactor", Range(0, 256)) = 1//
    }
    //着色器
    SubShader{
        Pass{
            Tags { "LightMode"="ForwardBase" }

            CGPROGRAM

            //顶点着色器定义
            #pragma vertex vert
            //片元/像素着色器定义
            #pragma fragment frag

            #include "Lighting.cginc"

            //在CG代码中，需要定义一个与属性名称与类型都匹配的变量
            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Specular;
            float _Gloss;   
            float _DiffuseFactor;
            float _SpecularFactor;

            //通过结构体定义顶点着色器输入
            struct a2v{
                //POSTION语义：使用模型空间顶点坐标填充vertex变量
                float4 vertex : POSITION; 
                //NORMAL语义：使用模型空间法向量填充normal变量
                float3 normal : NORMAL; 
                //TEXCOORD0语义：使用模型第一套纹理坐标填充texcoord变量
                float4 texcoord : TEXCOORD0; 
            };

            struct v2f{
                //SV_POSTION语义：pos存储了裁剪空间中顶点位置信息
                float4 pos : SV_POSITION; 
                //TEXCOORD0语义：使用模型第一套纹理坐标填充worldNormal变量
                float3 worldNormal : TEXCOORD0;
                //TEXCOORD1语义：使用模型第二套纹理坐标填充worldPos变量
                float3 worldPos : TEXCOORD1;
                //TEXCOORD2语义：使用模型第三套纹理坐标填充uv变量
                float2 uv : TEXCOORD2;
            };


            //SV_POSITION语义：顶点着色器的输出作为裁剪空间顶点坐标
            v2f vert(a2v v){
                v2f o;
                //将坐标转换到裁剪空间，乘以MVP矩阵，模型空间-世界空间-观察空间-裁剪空间
                o.pos = UnityObjectToClipPos (v.vertex);
                //将模型空间法向量转换至世界法向量， ==normalize(mul(v.normal, (float3x3)unity_WorldToObject));
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                //将模型顶点转换至世界空间坐标
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                //获取纹理坐标 ==o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw; (xy为纹理缩放，zw为平移)
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

                return o;
            }

            //SV_Target语义：像素着色器的输出存储到一个渲染目标(RenderTarget)当中
            fixed4 frag(v2f i) : SV_Target{     
                //精度转换
                fixed3 worldNormal = normalize(i.worldNormal);
                //世界光照的方向
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));              
                //采样颜色值
                fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;
                //环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo; 
                //漫反射
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldNormal, worldLightDir));
                //世界空间观察方向（视角方向=相同位置-模型位置），内置函数：UnityWorldSpaceViewDir(i.worldPos)
                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);
                //光照模型
                return fixed4(ambient + diffuse  * _DiffuseFactor + specular * _SpecularFactor, 1.0);
            }
            ENDCG
        }
    }
}