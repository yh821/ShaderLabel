using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DrawOutline : MonoBehaviour
{
	public Camera additionalCamera;

	public Material material;
	public Shader outlineShader;

	public Material occMaterial;
	public Shader occShader;

	public Color outlineColor;

	public int outlineWidth;

	public int iterations;

	private Camera camera;

	private void Awake ()
	{
		additionalCamera.CopyFrom (camera);
		additionalCamera.clearFlags = CameraClearFlags.Color;
		additionalCamera.backgroundColor = Color.black;
		additionalCamera.cullingMask = 1 << LayerMask.NameToLayer ("Outline");       // 只渲染"Outline"层的物体
	}

	private void Start ()
	{
		camera = GetComponent<Camera> ();
		//camera.depthTextureMode = DepthTextureMode.Depth;
	}

	private void OnRenderImage (RenderTexture source, RenderTexture destination)
	{
		if (material != null && occShader != null && additionalCamera != null) {
			RenderTexture TempRT = RenderTexture.GetTemporary (source.width, source.height, 0);
			TempRT.Create ();
			
			material.SetTexture ("_SceneTex", source);
			material.SetColor ("_Color", outlineColor);
			material.SetInt ("_Width", outlineWidth);
			material.SetInt ("_Iterations", iterations);
			additionalCamera.targetTexture = TempRT;
			// 额外相机中使用shader，绘制出物体所占面积
			additionalCamera.RenderWithShader (occShader, "");
			Graphics.Blit (TempRT, destination);
			TempRT.Release ();
		} else
			Graphics.Blit (source, destination);
	}
}
