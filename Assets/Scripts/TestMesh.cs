using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TestMesh : MonoBehaviour
{
	public Vector3[] vertices;

	private MeshFilter m_Filter;
	private Mesh m_Mesh;

	// Use this for initialization
	void Start () {
		// 获取GameObject的Filter组件
		m_Filter = GetComponent<MeshFilter>();
		// 并新建一个mesh给它
		m_Mesh = new Mesh();
		m_Filter.mesh = m_Mesh;

		// 初始化网格
		InitMesh();
	}
		

	/// <summary>
	/// Inits the mesh.
	/// </summary>
	void InitMesh()
	{
		m_Mesh.name = "MyMesh";

		// 为网格创建顶点数组
		if (vertices == null || vertices.Length == 0) {
			vertices = new Vector3[4] {
				new Vector3 (1, 1, 0),
				new Vector3 (-1, 1, 0),
				new Vector3 (1, -1, 0),
				new Vector3 (-1, -1, 0)
			};
		}

		m_Mesh.vertices = vertices;

		// 通过顶点为网格创建三角形
		int[] triangles = new int[2 * 3]{
			0, 2, 1, 1, 2, 3
		};

		m_Mesh.triangles = triangles;

		// 为mesh设置纹理贴图坐标
		Vector2[] uv = new Vector2[4]{
			new Vector2(1, 1),
			new Vector2(0, 1),
			new Vector2(1, 0),
			new Vector2(0, 0)
		};

		m_Mesh.uv = uv;
	}
}
