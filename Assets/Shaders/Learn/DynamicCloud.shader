Shader "Learn/DynamicCloud"
{
	Properties
	{
		_Color("Color",Color) = (1,1,1,1)
		_MainTex("Texture", 2D) = "white" {}
		_CloudColor("cloud color",Color)=(1,1,1,1)
		_CloudSpeed("cloud speed",float)=2
		_CloudDensity("cloud density",range(0,1.1))=0.75
		_CloudNumber("cloud number",range(0,3))=1.0
	}
		SubShader
	{
		Tags{
		"Queue" = "Background"
		"RenderType" = "Background"
		"PreviewType" = "Skybox"
		}
		Zwrite Off
		Cull Off
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			struct a2v
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float3 view : TEXCOORD0;
			};

			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed4 _CloudColor;
			float _CloudSpeed;
			float _CloudDensity;
			float _CloudNumber;
			v2f vert(a2v v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.view = WorldSpaceViewDir(v.vertex);
				return o;
			}
			
			float noise(float2 uv)
			{
				return sin(1.5*uv.x)*sin(1.5*uv.y);
			}
			
			float fbm(float2 p,int n)
			{
				float2x2 m = float2x2(0.6,0.8,-0.8,0.6);
				float f = 0.0;
				float a = 0.5;
				for(int i=0;i<n;i++)
				{
					f += a * (_CloudDensity+0.5*noise(p));
					p = mul(p,m)*2.0;
					a *=0.5;
				}
				return f;
			}
			float cloud(float2 uv)
			{
				float _sin = sin(_CloudSpeed*0.05*_Time.x);
				float _cos = cos(_CloudSpeed*0.05*_Time.x);
				uv = float2((_cos*uv.x+_sin*uv.y),-_sin*uv.x+_cos*uv.y);
				float2 o = float2(fbm(uv,6),fbm(uv+1.2,6));				
				float ol = length(o);
				o += 0.05*float2((_CloudSpeed*1.35*_Time.x+ol),(_CloudSpeed*1.5*_Time.x+ol));
				o *= 2;
			    float2 n = float2(fbm(o+9,6),fbm(o+5,6));
				float f = fbm(2*(uv + n),4);
				f = f*0.5 + smoothstep(0,1,pow(f,3)*pow(n.x,2))*0.5 + smoothstep(0,1,pow(f,5)*pow(n.y,2))*0.5;
				return smoothstep(0,2,f);
			}
			fixed4 frag(v2f i) : SV_Target
			{
				float3 viewDir = normalize(i.view);
				float2 uv = float2((atan2(viewDir.x, viewDir.z) + UNITY_PI) / UNITY_TWO_PI,acos(viewDir.y) / UNITY_PI);
				uv = uv *_MainTex_ST.xy + _MainTex_ST.zw;
				fixed4 tex = tex2D(_MainTex, uv, float2(0.00001, 0.0), float2(0.0, 0.0));
				fixed4 col = tex * _Color;
				
				float y = min(viewDir.y+1.0,1.0);
				float s = 0.5*(1.0+0.4*tan(1.9+2.5*y));
				float th = uv.x * UNITY_PI * 2.0;
				float2 _uv = float2(sin(th)*0.5, cos(th)*0.5)*s*5*_CloudNumber + 0.5;
				float c = cloud(_uv*(s+1.0));
				c *= smoothstep(0.0,0.4,y)*smoothstep(0.0,0.15,1.0-y);
				return lerp(col,_CloudColor,c*_CloudColor.a);
			}
			ENDCG
		}
	}
}