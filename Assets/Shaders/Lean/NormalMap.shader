// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// 法线贴图
Shader "Lean/NormalMap" {
    Properties{
        _MainTex("Main Tex",2D) = "white"{}
        _NormalMap("Normal Map",2D) = "bump"{} //bump默认值的意思：若没有法线贴图，则使用顶点自带的
        _Color("Color",Color) = (1,1,1,1)
        _BumpScale("Bump Scale",Range(-30,30)) = 3
    }

    SubShader{

        Tags{ "Queue" = "Transparent" "IngnoreProjector" = "True" "RenderType" = "Transparent" }
        
        Pass{
        
            Tags {"LightMode" = "ForwardBase"}

            CGPROGRAM

            #include "Lighting.cginc"

            #pragma vertex vert
            #pragma fragment frag

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _NormalMap;
            float4 _NormalMap_ST;
            float _BumpScale;

            // application to vertex
            // 由应用程序传递给顶点函数
            struct a2v {
                float4 vertex:POSITION;
                float3 normal:NORMAL; // 切线空间的确定是通过(存储模型里的)法线和(存储模型里的)切线确定的，所以需要模型的法线
                float4 texcoord:TEXCOORD0; // 模型的纹理坐标
                float4 tangent:TANGENT;// 模型空间的切线
            };

            // vertex to fragment
            // 由顶点函数传递给片元函数
            struct v2f {
                float4 vertex:SV_POSITION;
                float4 uv:TEXCOORD0; // uv.xy 存储MainTex的纹理坐标,uv.zw 存储法线贴图的纹理坐标
                float3 lightDir : TEXCOORD1; // 切线空间下平行光的方向
            };

            v2f vert(a2v v) {
                v2f f;

                f.vertex = UnityObjectToClipPos(v.vertex);

                // 将MainTex纹理坐标赋值给v2f.uv.xy并赋值面板贴图的旋转缩放
                f.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                // 将法线贴图纹理坐标赋值给v2f.uv.zw并赋值面板贴图的旋转缩放
                f.uv.zw = v.texcoord.xy * _NormalMap_ST.xy + _NormalMap_ST.zw;

                // 调用这个宏之后，会得到一个矩阵 rotation
                // 这个矩阵用来把模型空间下的方向转换成切线空间下
                TANGENT_SPACE_ROTATION;

                //模型转切线矩阵 * 模型空间平行光方向
                f.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex));//切线空间平衡光方向
                    
                return f;
            }

            float4 frag(v2f f) : SV_Target{
                // tex2D 根据法线贴图的纹理坐标获取颜色值
                fixed4 normalColor = tex2D(_NormalMap,f.uv.zw);

                // 切线空间下的法线
                fixed3 tangentNormal = UnpackNormal(normalColor);
                tangentNormal.xy = tangentNormal.xy * _BumpScale;
                tangentNormal = normalize(tangentNormal);
                // 切线空间下的平行光方向
                fixed3 lightDir = normalize(f.lightDir);
                // tex2D 根据MainTex贴图的纹理坐标获取颜色值
                fixed4 texColor = tex2D(_MainTex,f.uv.xy) * _Color;
                // 环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * texColor.xyz; 
                // 漫反射 = 光源颜色*材质颜色*max(0,dot(法线,光源方向))
                fixed3 diffuse = _LightColor0.rgb * texColor.xyz * max(dot(tangentNormal, lightDir), 0);

                return fixed4(ambient+diffuse, 1.0);
            }

            ENDCG
        }
    }

    Fallback "VertexLit"
}