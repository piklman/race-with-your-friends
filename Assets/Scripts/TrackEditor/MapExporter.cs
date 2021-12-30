using System;
using System.Collections;
using System.Collections.Generic;

using UnityEngine;
using UnityEngine.Tilemaps;

public class MapExporter : MonoBehaviour
{
	private Tilemap tilemap;

	private void Start()
	{
		tilemap = gameObject.GetComponent<Tilemap>();
		Export();
	}

	public void Export()
	{
		BoundsInt bounds = tilemap.cellBounds;

		// 1-D array of all of the tiles in the tilemap.
		TileBase[] tiles = tilemap.GetTilesBlock(bounds);
		TileBase[,] orderedTiles = new TileBase[bounds.size.x, bounds.size.y];

		for (int x = 0; x < bounds.size.x; x++)
		{
			for (int y = 0; y < bounds.size.y; y++)
			{
				// Expands the 1-D array into a 2-D one.
				TileBase tile = tiles[x + y * bounds.size.x];
				orderedTiles[x, y] = tile;
			}
		}

		print(JsonUtility.ToJson(orderedTiles));
	}
}
