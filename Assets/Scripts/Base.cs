using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Base
{
    public class Vectors
    {
        public bool VectorEqualsApprox(Vector2 v1, Vector2 v2)
        {
            return (Mathf.Approximately(v1.x, v2.x) && Mathf.Approximately(v1.y, v2.y));
        }

/*        public bool VectorLT(Vector2 v1, Vector2 v2)
        {
            return v1.x < v2.x && v1.y < v2.y;
        }

        public bool VectorLTE(Vector2 v1, Vector2 v2)
        {
            return v1.x <= v2.x && v1.y <= v2.y;
        }

        public bool VectorGT(Vector2 v1, Vector2 v2)
        {
            return v1.x > v2.x && v1.y > v2.y;
        }

        public bool VectorGTE(Vector2 v1, Vector2 v2)
        {
            return v1.x >= v2.x && v1.y >= v2.y;
        }*/

        public Vector2 Vector3To2(Vector3 v3)
        {
            return new Vector2(v3.x, v3.y);
        }
    }

    [System.Serializable]
    public struct Stats
    {
        ///public float hp; // Vehicle durability
        public float spd; // Max speed
        public float acc; // Acceleration
        public float handling; // Handling
        ///public float offroad; // Offroad
        ///public float braking; // Braking strength
        ///public float luck; // Item drops / strength
    }
}
