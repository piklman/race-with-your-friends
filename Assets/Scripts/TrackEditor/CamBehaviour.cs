using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CamBehaviour : MonoBehaviour
{
    private Camera cam;

    // Start is called before the first frame update
    void Start()
    {
        cam = gameObject.GetComponent<Camera>();
    }

    // Update is called once per frame
    void Update()
    {
        var scrollDelta = -Input.mouseScrollDelta.y;
        if (cam.orthographicSize + scrollDelta > 0 && cam.orthographicSize + scrollDelta < 32)
        {
            cam.orthographicSize += scrollDelta;
        }
    }
}
