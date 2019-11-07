// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// UI渐变
Shader "Learn/UI/UIDissolve"
{
	Properties
	{
        [PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1,1)

        //调节溶解像素范围
        _Step("Step", Range(0,1)) = 0.5
        //不规则纹理
        _dissolveTex ("Dissolve (RGB)", 2D) = "white" {}
        //调节边缘颜色区域
        _Value("边缘颜色区域", Range(0,1)) = 0.5
        //边缘颜色强度
        _Inde("边缘颜色强度", Range(0,1)) = 0.05

        _Duration("边缘颜色强度", Range(0,1)) = 0.05

		_StencilComp("Stencil Comparison", Float) = 8
		_Stencil("Stencil ID", Float) = 0
		_StencilOp("Stencil Operation", Float) = 0
		_StencilWriteMask("Stencil Write Mask", Float) = 255
		_StencilReadMask("Stencil Read Mask", Float) = 255
		_ColorMask("Color Mask", Float) = 15
	}

	SubShader
	{
		Tags
		{
			"Queue" = "Transparent"
			"IgnoreProjector" = "True"
			"RenderType" = "Transparent"
			"PreviewType" = "Plane"
			"CanUseSpriteAtlas" = "True"
		}

		Stencil
		{
			Ref[_Stencil]
			Comp[_StencilComp]
			Pass[_StencilOp]
			ReadMask[_StencilReadMask]
			WriteMask[_StencilWriteMask]
		}

		Cull Off
		Lighting Off
		ZWrite Off
		ZTest[unity_GUIZTestMode]
		Blend SrcAlpha OneMinusSrcAlpha
		ColorMask[_ColorMask]

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			struct appdata_t
			{
				float4 vertex   : POSITION;
				fixed4 color    : COLOR;
				half2 texcoord : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex   : SV_POSITION;
				fixed4 color : COLOR;
				half2 texcoord  : TEXCOORD0;
			};
            
            fixed4 _Color;
            sampler2D _MainTex;
            sampler2D _dissolveTex;
            float _Step;
            float _Value;
            float _Inde;

			v2f vert(appdata_t IN)
			{
				v2f OUT;
				OUT.vertex = UnityObjectToClipPos(IN.vertex);
				OUT.texcoord = IN.texcoord;
#ifdef UNITY_HALF_TEXEL_OFFSET
				OUT.vertex.xy += (_ScreenParams.zw - 1.0)*float2(-1,1);
#endif
				OUT.color = IN.color * _Color;
				return OUT;
			}

			fixed4 frag(v2f IN) : SV_Target
			{
                fixed4 c = tex2D (_MainTex, IN.texcoord);

                //采样噪音
                fixed4 d = tex2D (_dissolveTex, IN.texcoord);

                //变量保存噪音 减去0 - 1 范围结果
                float mask = d.r - frac(_Time.y);

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
                
				return c;
			}
			ENDCG
		}
	}
}