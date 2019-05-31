// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Lean/UI/UIClipRect"
{
	Properties {
		_MainTex ("Particle Texture", 2D) = "white" {}
		_InvFade ("Soft Particles Factor", Range(0.01,3.0)) = 1.0
		_ClipRect("ClipRect",Vector) = (0,0,0,0) // Clip
		[Enum(Enable, 1, Disable, 0)] _ClipStatus("ClipStatus", float) = 1.0 // Clip
	}

	Category {
		Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "PreviewType"="Plane" }
		Blend One OneMinusSrcAlpha
		ColorMask RGB
		Cull Off Lighting Off ZWrite Off

		SubShader {
			Pass {
				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#pragma target 2.0
				#pragma multi_compile_particles

				#include "UnityCG.cginc"
				#include "UnityUI.cginc" // Clip

				sampler2D _MainTex;
				fixed4 _TintColor;
				float4 _ClipRect; // Clip
				float _ClipStatus; // Clip

				struct appdata_t {
					float4 vertex : POSITION;
					fixed4 color : COLOR;
					float2 texcoord : TEXCOORD0;
					UNITY_VERTEX_INPUT_INSTANCE_ID
				};

				struct v2f {
					float4 vertex : SV_POSITION;
					fixed4 color : COLOR;
					float2 texcoord : TEXCOORD0;
					#ifdef SOFTPARTICLES_ON
					float4 projPos : TEXCOORD1;
					#endif
					float3 worldPosition : TEXCOORD2; // Clip
					UNITY_VERTEX_OUTPUT_STEREO
				};

				float4 _MainTex_ST;

				v2f vert (appdata_t v)
				{
					v2f o;
					// o.worldPosition = v.vertex 这么写好像也没问题
					o.worldPosition = mul(unity_ObjectToWorld, v.vertex); // Clip
					UNITY_SETUP_INSTANCE_ID(v);
					UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
					o.vertex = UnityObjectToClipPos(v.vertex);
					#ifdef SOFTPARTICLES_ON
					o.projPos = ComputeScreenPos (o.vertex);
					COMPUTE_EYEDEPTH(o.projPos.z);
					#endif
					o.color = v.color;
					o.texcoord = TRANSFORM_TEX(v.texcoord,_MainTex);
					return o;
				}

				UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);
				float _InvFade;

				fixed4 frag (v2f i) : SV_Target
				{
					#ifdef SOFTPARTICLES_ON
					float sceneZ = LinearEyeDepth (SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos)));
					float partZ = i.projPos.z;
					float fade = saturate (_InvFade * (sceneZ-partZ));
					i.color.a *= fade;
					#endif

					if (_ClipStatus == 0)
					{
						return i.color * tex2D(_MainTex, i.texcoord) * i.color.a;
					}
					else
					{
						// clip
						fixed4 col = i.color * tex2D(_MainTex, i.texcoord) * i.color.a;
						if (UnityGet2DClipping(i.worldPosition.xy, _ClipRect) == 0)
						{
							col = 0;
						}
						return col;
					}
				}
				ENDCG
			}
		}
	}
}