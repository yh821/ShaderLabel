Shader "Unlit/GrabPass1"
{
	Properties{
		_MainTex("Main Texture",2D) = ""{}
	}
	SubShader
	{
        Lighting Off
		//GrabPass 是一种特殊的通道类型 - 捕获物体所在位置的屏幕的内容并写入到一个纹理中。
		GrabPass{"_GrabTex"}
		Pass
		{
			SetTexture[_GrabTex]{
				ConstantColor (0,1,0,1)
				Combine constant * texture
				Combine one - texture
			}
			SetTexture[_GrabTex]{
				Combine one - previous
			}
		}
	}
}
