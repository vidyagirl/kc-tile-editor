package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxColor;
import haxe.Json;
import openfl.net.FileReference;
import openfl.utils.Assets;
import sys.FileSystem;

using StringTools;

typedef EventDef = {
	var name:String;
	var ?values:Array<Dynamic>;
}

typedef TileDef = {
	var x:Float;
	var y:Float;
	var angle:Float;
	var alpha:Float;
	var color:String; // String for JSON
	var ?collidable:Bool;
	var ?immovable:Bool;
	var ?layer:String;
	var ?event:EventDef;
	var ?graphicPath:String;
}

class Tile extends FlxSprite {
	public var collidable:Bool;
	public var event:EventDef;
	public var layer:String;
	public var graphicPath:FlxGraphicAsset;
	public var tileDef:TileDef;

	public function new(x:Float = 0, y:Float = 0, ?tileDef:TileDef) {
		super(x, y);
		if (tileDef != null) {
			this.tileDef = loadFromTileDef(tileDef);
		}
		else {
			this.tileDef = loadFromTileDef(emptyTile());
		}
	}

	public override function loadGraphic(Graphic:FlxGraphicAsset, Animated:Bool = false, Width:Int = 0, Height:Int = 0, Unique:Bool = false,
			?Key:String):FlxSprite {
		graphicPath = Graphic;
		if (graphicPath == null || new String(graphicPath).toLowerCase() == 'solid_color') {
			return makeGraphic(32, 32, this.color);
		}
		return super.loadGraphic(Graphic, Animated, Width, Height, Unique, Key);
	}

	public function loadFromTileDef(tileDef:TileDef) {
		this.x = tileDef.x;
		this.y = tileDef.y;
		this.angle = tileDef.angle;
		this.alpha = tileDef.alpha;
		if (tileDef.color.length >= 6) {
			this.color = Std.parseInt('0xFF' + tileDef.color);
		}
		else {
			this.color = FlxColor.WHITE;
		}
		this.collidable = tileDef.collidable;
		this.immovable = tileDef.immovable;
		this.layer = tileDef.layer;
		this.graphicPath = tileDef.graphicPath;
		this.event = tileDef.event;

		if (this.layer == null) {
			this.layer = 'background';
		}

		// cuz FlxGraphicAsset doesnt fucking have a toLowerCase func
		if (graphicPath == null || new String(graphicPath).toLowerCase() == 'solid_color') {
			makeGraphic(32, 32, this.color);
		}
		else {
			if (FileSystem.exists(graphicPath)) {
				loadGraphic(graphicPath);
			}
			else {
				FlxG.log.warn('File $graphicPath not found!');
			}
		}

		return tileDef;
	}

	private inline function emptyTile():TileDef {
		return {
			x: this.x,
			y: this.y,
			angle: this.angle,
			alpha: this.alpha,
			color: StringTools.hex(this.color),
			collidable: false,
			immovable: true,
			layer: "background",
			graphicPath: "SOLID_COLOR",
		}
	}
}
