Shader "Learn/GrabPass"
{
	SubShader
	{
		//GrabPass 是一种特殊的通道类型 - 捕获物体所在位置的屏幕的内容并写入到一个纹理中。
		GrabPass{"_GrabTex"}
		Pass
		{
			/*
			1.语法
			* SetTexture [TextureName] {Texture Block}
			2.Texture block combine 命令
			* combine src1 * src2 越乘越暗
			* combine src1 + src2 越加越亮
			* combine src1 lerp(src2) src3 插值运算使用src2的alpha值，注意如果alpha值为1，src1被使用；alpha值为0， src3被使用
			* src可以是 previous,constant,primary 或 texture 其中之一。
			* Previous 指前一个SetTexture的结果
			* Primary 指灯光计算的颜色
			* Texture 指在SetTexture中指定的TextureName的颜色
			* Constant 指ConstantColor指定的常量颜色值
			*/
			SetTexture[_GrabTex]{
				ConstantColor (0,1,0,1) //绿色通道(设置一个颜色)
				Combine constant * texture //绿色通道*屏幕颜色
				//Combine one - texture //1 - 屏幕颜色
			}
			// SetTexture[_GrabTex]{
			// 	Combine one - previous //1 - 上一个SetTexture结果
			// }
		}
	}
}
