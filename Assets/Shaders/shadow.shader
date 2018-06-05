Shader "Example/ShadowColor" 
{
    Properties 
    {
        _MainColor("MainColor",color) = (0.5,0.5,0.5,1)
        _ShadowColor("ShadowColor",color) = (1,1,0,1)
    }
    SubShader 
    {
        Tags {"RenderType"="Opaque"}
        Pass 
        {
                Tags {"LightMode" = "ForwardBase"}
                
            CGPROGRAM
            #pragma multi_compile_fwdbase
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            
            #pragma vertex vertexMain
            #pragma fragment fragmentMain
            
            fixed4 _MainColor;
            fixed4 _ShadowColor;

            struct VertexToFragment 
            {
                float4 pos         : SV_POSITION;
                half4 uv          : TEXCOORD0;
                SHADOW_COORDS(1)
            };
            
            VertexToFragment vertexMain (appdata_full v) 
            {
                VertexToFragment result = (VertexToFragment)0;
                result.pos = mul(UNITY_MATRIX_MVP, v.vertex);
                result.uv.xy =  v.texcoord.xy;
                TRANSFER_SHADOW(result)
                return result;
            }
            
            fixed4 fragmentMain (VertexToFragment i) : COLOR0 
            {
                float attenuation = SHADOW_ATTENUATION(i);
                return lerp(_MainColor*_ShadowColor,_MainColor,attenuation);
            }

            ENDCG
        }
        
        Pass
        {
            Name "ShadowCollector"
            Tags { "LightMode" = "ShadowCollector" }
            
            Fog {Mode Off}
            ZWrite On ZTest LEqual

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_shadowcollector

            #define SHADOW_COLLECTOR_PASS
            #include "UnityCG.cginc"

            struct appdata { float4 vertex : POSITION;};
            struct v2f { V2F_SHADOW_COLLECTOR;};

            v2f vert (appdata v)
            {
                v2f o;
                TRANSFER_SHADOW_COLLECTOR(o)
                return o;
            }

            fixed4 frag (v2f i) : SV_Target { SHADOW_COLLECTOR_FRAGMENT(i)}
            ENDCG
        }
   
    } 

}