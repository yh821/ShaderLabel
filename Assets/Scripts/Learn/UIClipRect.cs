using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class UIClipRect : UnityEngine.EventSystems.UIBehaviour, UnityEngine.UI.IClipper
{
    private const string CLIP_RECT = "_ClipRect";

    private RectTransform m_RectTransform;
    public RectTransform rectTransform
    {
        get { return m_RectTransform ?? (m_RectTransform = GetComponent<RectTransform>()); }
    }

    private readonly Vector3[] m_worldCorners = new Vector3[4];
    public Rect worldRect
    {
        get
        {
            rectTransform.GetWorldCorners(m_worldCorners);
            return new Rect(m_worldCorners[0].x, m_worldCorners[0].y, m_worldCorners[2].x - m_worldCorners[0].x, m_worldCorners[2].y - m_worldCorners[0].y);
        }
    }

    private Rect m_LastRect;
    
    protected override void OnEnable()
    {
        base.OnEnable();
        UnityEngine.UI.ClipperRegistry.Register(this);

        m_LastRect = worldRect;
        ModifyMaterial(m_LastRect);
    }

    protected override void OnDisable()
    {
        base.OnDisable();
        UnityEngine.UI.ClipperRegistry.Unregister(this);

        m_LastRect = Rect.zero;
        ModifyMaterial(m_LastRect);
    }

    private void ModifyMaterial(Rect rect)
    {
        ParticleSystem[] particles = gameObject.GetComponentsInChildren<ParticleSystem>();
        foreach (ParticleSystem particle in particles)
        {
            {
                Material m = particle.GetComponent<Renderer>().material;
                m.SetVector(CLIP_RECT, new Vector4(rect.xMin, rect.yMin, rect.xMax, rect.yMax));              
            }
        }
    }

    public virtual void PerformClipping()
    {
        Rect rect = worldRect;
        if (rect != m_LastRect)
        {            
            m_LastRect = rect;
            ModifyMaterial(m_LastRect);
        }
    }

}