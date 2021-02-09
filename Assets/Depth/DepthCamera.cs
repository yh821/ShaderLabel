using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DepthCamera : MonoBehaviour
{
	public Shader shader;
	public Material material;
	public float force = 1;

	private Camera camera;

	// Use this for initialization
	void Start ()
	{
		camera = GetComponent<Camera> ();
		camera.depthTextureMode = DepthTextureMode.Depth;
	}

//	void OnRenderImage (RenderTexture source, RenderTexture destination)
//	{
//		if (material == null || material.shader != shader)
//			material = new Material (shader);
//
//		material.SetFloat ("_Force", force);
//		
//		Graphics.Blit (source, destination, material);
//	}
}
