using UnityEngine;
using UnityEngine.UI;

public class UIScrollImage : MonoBehaviour {
	void Start () {
		var image = GetComponent<Image> ();
		if (image != null) {
			Vector4 uvRect = UnityEngine.Sprites.DataUtility.GetOuterUV(image.overrideSprite);
			var mater = new Material (Shader.Find("Custom/UI/UIScrollUV"));
			mater.SetVector("_UvRect", uvRect);
			image.material = mater;
		}
	}
}
