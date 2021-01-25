using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode, ImageEffectAllowedInSceneView]
public class FogEffect : MonoBehaviour
{
	public Shader fogShader;
	public Color fogColor;
	public float depthStart = 0;
	public float depthSlope = 1;
	private Material mat;

	private void Start ()
	{
		mat = new Material (fogShader);
		GetComponent<Camera> ().depthTextureMode = DepthTextureMode.Depth;
	}

	private void OnRenderImage (RenderTexture source, RenderTexture destination)
	{
		mat.SetColor ("_FogColor", fogColor);
		mat.SetFloat ("_depthStart", depthStart);
		mat.SetFloat ("_depthSlope", depthSlope);
		Graphics.Blit (source, destination, mat);
	}
}