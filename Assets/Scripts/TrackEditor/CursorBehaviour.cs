using System.Collections;
using System.Collections.Generic;
using UnityEngine;

using Base;

public class CursorBehaviour : MonoBehaviour
{
    // Base Classes
    private Vectors vectors = new Vectors();

    [SerializeField] private Camera cam;

    private enum DrawMode
    {
        ERASE = 0,
        PAINT = 1
    }
    private DrawMode drawMode;
    private DrawMode storedDrawMode;

	private void Start()
	{
        drawMode = DrawMode.PAINT;
	}

	Vector2 RoundVector(Vector2 vector, float toNearest)
    {
        var modVector = new Vector2(vector.x % toNearest, vector.y % toNearest);
        var pos = vectors.Vector3To2(transform.position);

        if (vectors.VectorEqualsApprox(modVector, Vector2.zero))
        {
            return vector;
        }

        if (vector.x > pos.x + toNearest)
        {
            // x in a square higher
            pos.x += toNearest;
        }
        else if (vector.x < pos.x)
        {
            // x in a square lower
            pos.x -= toNearest;
        }

        if (vector.y > pos.y + toNearest)
        {
            // y in a square higher
            pos.y += toNearest;
        }
        else if (vector.y < pos.y)
        {
            // y in a square lower
            pos.y -= toNearest;
        }

        return pos;
    }

    void HandleClicks()
    {
        if (Input.GetMouseButtonDown(1))
        {
            storedDrawMode = drawMode;
            drawMode = DrawMode.ERASE;
        }

        if (Input.GetMouseButtonUp(1))
        {
            drawMode = storedDrawMode;
        }

        if (Input.GetMouseButton(0) || Input.GetMouseButton(1))
        {

        }
    }

	// Update is called once per frame
	void Update()
    {
        transform.position = RoundVector(cam.ScreenToWorldPoint(Input.mousePosition), 1f);
        HandleClicks();
    }
}
