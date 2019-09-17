// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// 法线高光
Shader "Lean/NormalSpecular"
{
	Properties
    {
        _MainTex ("主贴图", 2D) = "white" {}
        _NormalTex ("法线贴图", 2D) = "white" {}
		_BumpScale("法线强度",Range(-10,10)) = 1
        _Specular ("高光颜色", Color) = (1, 1, 1, 1)
        _Gloss ("高光系数", Range(2, 255)) = 20
        //_RimColor ("边缘颜色", Color) = (1, 0, 0, 1)
        //_RimPower ("边缘颜色强度", Range(0.1, 1)) = 1
        //_MaskTex ("光遮罩图", 2D) = "white" {}
        //_MoveDir ("边缘光移动方向", Range(-1, 1)) = 1
    }
    SubShader
    {
        Tags { "LightMode" = "ForwardBase" }
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };
            struct v2f
            {           
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 lightDir : TEXCOORD1;
                float3 viewDir : TEXCOORD2;
            };
            sampler2D _NormalTex;
			float _BumpScale;
            fixed4 _Specular;
            float _Gloss;
            fixed4 _RimColor;
            half _RimPower;
            sampler2D _MaskTex;
            sampler2D _MainTex;
            fixed4 _MainTex_ST;
            fixed _MoveDir;



            // 方式一，切线空间下计算
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                TANGENT_SPACE_ROTATION;
                //rotation 是由 顶点法线和切线 计算除 副切线 后，组成的 切线空间的矩阵
                //转换 光源方向和观察方向 从 世界空间 到 模型空间（ObjSpaceLightDir） 再到 切线空间
                o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;
                o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex)).xyz;
                //不在这里归一化是为了会不影响 插值结果，所以在 frag 中归一化
                return o;
            }
            fixed4 frag (v2f i) : SV_Target
            {
                //切线空间光源方向
                fixed3 tangentLightDir = normalize(i.lightDir);
                //切线空间观察方向
                fixed3 tangentViewDir = normalize(i.viewDir);
                //采样 法线贴图，并转换 像素值 为 法线值 （normal = pixel * 2 -1）
                fixed4 normalColor = tex2D(_NormalTex, i.uv);
                //切线空间法线
                fixed3 tangentNormal = UnpackNormal(normalColor);
				tangentNormal.xy = tangentNormal.xy * _BumpScale;
                fixed4 tex = tex2D(_MainTex, i.uv);
                //环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * tex.rgb;
                //漫反射 = 光源颜色 * 材质色彩 * max(0, cos(光源方向和法线方向的夹角))
                fixed3 diffuse = _LightColor0.rgb * tex.rgb * saturate(dot(tangentNormal, tangentLightDir));
                //Blinn-Phong高光光照模型，相对于普通的Phong高光模型，会更加光
                fixed3 halfDir = normalize(tangentLightDir + tangentViewDir);//光源方向+观察方向
                //高光反射 = 光源颜色 * pow(max(0, dot(切线,高光光照模型)), 高光强度)
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(tangentNormal, halfDir)), _Gloss);
                //边缘颜色，对于法线和观察方向，只要在同一坐标系下即可
                //fixed dotProduct = 1 - saturate(dot(tangentNormal, tangentViewDir));
                //fixed3 rim = _RimColor.rgb * pow(dotProduct, 1 / _RimPower);
                //fixed4 maskCol = tex2D(_MaskTex, i.uv + float2(0, _Time.y * _MoveDir));
                //return fixed4(ambient + diffuse + specular + rim * maskCol.rgb, 1);
                return fixed4(ambient + diffuse + specular, 1);
            }



            // 方式二，世界空间下计算
            struct appdata2
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };
            struct v2f2
            {           
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 TtoW0 :TEXCOORD1;
                float4 TtoW1 :TEXCOORD2;
                float4 TtoW2 :TEXCOORD3;
                float3 lightDir : TEXCOORD4;
                float3 viewDir : TEXCOORD5;
            };
            v2f2 vert2 (appdata2 v)
            {
                v2f2 o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                float3 worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                o.lightDir = UnityWorldSpaceLightDir(worldPos);
                o.viewDir = UnityWorldSpaceViewDir(worldPos);
                // 构建 法线 从 切线空间 到 世界空间 的 变换矩阵（三个向量）
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);//法线
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);//切线
                //副法线 = 叉积(世界法线,世界切线)*模型切线.w
                fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;
                o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
                o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
                o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z); // 顺便把 世界坐标 也存在这里
                return o;
            }
            fixed4 frag2 (v2f2 i) : SV_Target
            {
                //获得世界空间中的坐标
                float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
                //计算光照和视角方向在世界坐标系中
                fixed3 worldLightDir = normalize(i.lightDir);
                fixed3 worldViewDir = normalize(i.viewDir);
                fixed4 packedNormal = tex2D(_NormalTex, i.uv);
                fixed4 tex = tex2D(_MainTex, i.uv);
                //法线图 解包 后 的 切线空间的法线向量
                fixed3 tangentNormal = UnpackNormal(packedNormal);
				tangentNormal.xy = tangentNormal.xy * _BumpScale;
                //转换 法线向量 从 切线空间 到 世界空间， 等价于 下面注释部分
                fixed3 worldNormal = normalize(half3(dot(i.TtoW0.xyz, tangentNormal), dot(i.TtoW1.xyz, tangentNormal), dot(i.TtoW2.xyz, tangentNormal)));
                //构建 转换矩阵
                //float3x3 worldNormalMatrix = float3x3(i.TtoW0.xyz, i.TtoW1.xyz, i.TtoW2.xyz);
                //fixed3 worldNormal = normalize(mul(worldNormalMatrix, tangentNormal));
                //环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * tex.rgb;
                //漫反射
                fixed3 diffuse = _LightColor0.rgb * tex.rgb * saturate(dot(worldNormal, worldLightDir));
                //Blinn-Phong高光光照模型，相对于普通的Phong高光模型，会更加光
                fixed3 halfDir = normalize(worldLightDir + worldViewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(worldNormal, halfDir)), _Gloss);
                //边缘颜色，对于法线和观察方向，只要在同一坐标系下即可
                //fixed dotProduct = 1 - saturate(dot(worldNormal, worldViewDir));
                //fixed3 rim = _RimColor.rgb * pow(dotProduct, 1 / _RimPower);
                //fixed4 maskCol = tex2D(_MaskTex, i.uv + float2(0, _Time.y * _MoveDir));
                //return fixed4(ambient + diffuse + specular + rim * maskCol.rgb, 1);
                return fixed4(ambient + diffuse + specular, 1);
            }
            ENDCG
        }
	}
	FallBack "Specular"
}