package;

import Tile.TileDef;
import Tile;
import haxe.Json;
import openfl.utils.Assets;

class Reader
{
	public static inline function getTilesFromJSON(path:String):{tiles:Array<TileDef>}
	{
		return {tiles: cast Json.parse(Assets.getText(path)).tiles};
	}
}
