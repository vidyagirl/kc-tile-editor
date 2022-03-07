package;

import Tile;
import haxe.Json;
import openfl.net.FileReference;

class Writer
{
	public static function writeTilesToJSON(tileArr:Array<Tile>)
	{
		var tileDefArr:Array<TileDef> = [for (i in tileArr) i.tileDef];

		return Json.stringify({tiles: tileDefArr});
	}
}
