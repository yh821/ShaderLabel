Shader "Unlit/NewUnlitShader1"
{
	Properties{
		_MainTex("Main Texture",2D) = ""{}
		_BlendTex("Blend Texture",2D) = ""{}
		// _Color("Color", Color) = (1,1,1,1)
		// _AmbientColor("Ambient Color", Color) = (0,1,0,1)
		// _Cutoff("Cutoff",float) = 0.5
	}
	SubShader
	{
		//AlphaTest GEqual [_Cutoff]
		GrabPass{"_GrabTex"}
		Pass
		{
			// Material{
				// Diffuse (1,1,1,1)
				// Ambient (1,1,1,1)
				// diffuse[_Color] 
				// ambient[_AmbientColor]
			// }
			SetTexture[_GrabTex]{
				ConstantColor (0,1,0,1)
				Combine constant * texture
				Combine one - texture
			}
			SetTexture[_GrabTex]{
				Combine one - previous
			}
			//Color(1,1,0,0)
			// Offset 1,1
			// Lighting on
			// Cull front
			// SetTexture[_BlendTex]{
			// 	Combine constant lerp(texture) previous
			// }
			// SetTexture[_MainTex]{
			// 	Combine previous * texture
			// }
		}
	}
}
