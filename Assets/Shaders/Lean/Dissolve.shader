Shader "Learn/Dissolve" {
    Properties {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}

        //调节溶解像素范围
        _Step("Step", Range(0,1)) = 0.5
        //不规则纹理
        _dissolveTex ("Dissolve (RGB)", 2D) = "white" {}
        //调节边缘颜色区域
        _Value("边缘颜色区域", Range(0,1)) = 0.5
        //边缘颜色强度
        _Inde("边缘颜色强度", Range(0,1)) = 0.05

        _Glossiness ("光泽度", Range(0,1)) = 0.5
        _Metallic ("金属度", Range(0,1)) = 0.0
    }

    SubShader {
        Tags { "RenderType"="Opaque" }
        LOD 200
        
        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;
        sampler2D _dissolveTex;
        float _Step;
        float _Value;
        float _Inde;

        struct Input {
            float2 uv_MainTex;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

        void surf (Input IN, inout SurfaceOutputStandard o) {

            fixed4 c = tex2D (_MainTex, IN.uv_MainTex);

            //采样噪音
            fixed4 d = tex2D (_dissolveTex, IN.uv_MainTex);

            //变量保存噪音 减去0 - 1 范围结果
            float mask = d.r - _Step;

            //边缘颜色 渐变就是 边缘为0，因为小于0的clip去掉像素了，所以边缘到其他 会增长直到1
            //所以根据mask值作为渐变强度来计算
            //先判断哪个范围 需要边缘颜色
            if(mask < _Value){
                //溶解后剩余整体颜色
                c = c * _Color;
                // c = c * 1.0 / mask;
                c = c * _Inde / mask;
            }

            //clip函数 完成丢弃像素过程,小于0就会丢弃像素，造成镂空溶解的样子，白色就会>多少，颜色越深就会镂空
            clip(mask);

            o.Albedo = c.rgb;
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}