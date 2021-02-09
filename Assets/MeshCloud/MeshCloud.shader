Shader "Custom/MeshCloud"
{
    Properties
    {
        _TopColor("TopColor",Color) = (1,1,1,1)
        _BottomColor("BottomColor",Color) = (1,1,1,1)

        _NoiseTex("NoiseTex", 2D) = "white" {}
        _Height("Height",float) = 1
        _Speed("Speed",float) = 1
        _DepthBiasFactor("DepthBiasFactor",float) =1
//        _DcurvatureRadius("DcurvatureRadius",float) = 30

        _MaskTex("MaskTex", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType" = "Geometry" }
        LOD 100

        Cull Back
        Lighting Off
        ZWrite On
        ZTest On
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 CloudUV01 : TEXCOORD0;
                float2 CloudUV02 : TEXCOORD1;
                float4 worldPos : TEXCOORD2;
                float2 noisePos:TEXCOORD3;
                float4 screenPos : TEXCOORD4;
            };

            float4 _TopColor;
            float4 _BottomColor;
            sampler2D _NoiseTex;
            float4 _NoiseTex_ST;
            sampler2D _MaskTex;
            float _Height;
            float _Speed;
            float _DepthBiasFactor;
            sampler2D _CameraDepthTexture;
//            float _DcurvatureRadius;

            v2f vert (appdata v)
            {
                v2f o;
                //用两个方向获取噪波图的运动
                o.CloudUV01 = v.uv + _Time.x* _Speed;
                o.CloudUV02 = v.uv - _Time.x* _Speed;
                o.noisePos.x = tex2Dlod(_NoiseTex, float4(o.CloudUV01, 0, 0)).r;
                o.noisePos.y = tex2Dlod(_NoiseTex, float4(o.CloudUV02, 0, 0)).r;
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);

                o.vertex = UnityObjectToClipPos(v.vertex);
                //让云的Y轴扰动起来
                o.vertex.y += o.noisePos.x* o.noisePos.y * _Height ;
                //以中心开始 将圆变成一个碗的形状，因为边缘太低，可能会露出一些不必要的场景。
//                o.vertex.y += pow(distance(float2(0, 0), o.worldPos.xz) / _DcurvatureRadius, 2);

                o.screenPos = ComputeScreenPos(o.vertex);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float4 depthSample = SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, i.screenPos);
                float depth = LinearEyeDepth(depthSample);
                float borderLine = saturate((depth - i.screenPos.w) / 2 - _DepthBiasFactor);

                //获取遮罩图
                float mask = saturate(i.noisePos.x * i.noisePos.y);
                //利用噪波图来融合顶底两个颜色
                float4 col = (_TopColor * mask) + (_BottomColor * (1 - mask));
                //设置与物体交接的地方透明
                col.a = borderLine;

                return col;
            }
            ENDCG
        }
    }
}
