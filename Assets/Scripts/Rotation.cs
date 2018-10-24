using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Rotation : MonoBehaviour 
{
	public float speed = 5f;
	public Vector3 axis = Vector3.right;
	public int angleMod = 360;

	float angle=50;

	// Use this for initialization
	void Start () {
		
	}
	
	// Update is called once per frame
	void Update () {
		angle += Time.deltaTime*speed;
		angle = angle%angleMod;
		transform.rotation = Quaternion.AngleAxis (angle,axis);
	}
}
