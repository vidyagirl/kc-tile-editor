package;

import Tile.EventDef;
import Tile.TileDef;
import Util.Program;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.ui.FlxButtonPlus;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIColorSwatch;
import flixel.addons.ui.FlxUIColorSwatchSelecter;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUISlider;
import flixel.addons.ui.SwatchData;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.input.FlxInput;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import haxe.Json;
import haxe.ds.StringMap;
import openfl.events.Event;
import openfl.net.FileFilter;
import openfl.net.FileReference;
import openfl.utils.Assets;
import sys.FileSystem;

using StringTools;

typedef TileStringDef = {
	var name:String;
	var path:String;
}

class MainState extends FlxState {
	// * "make it work with haxeflixel"
	// * -ninjamuffin99, 2022
	public var background:FlxTypedGroup<Tile>;
	public var midground:FlxTypedGroup<Tile>;
	public var foreground:FlxTypedGroup<Tile>;
	public var tilesArray:Array<Tile>;
	public var uiGroup:FlxTypedGroup<FlxSprite>;

	public var mouseX:Float;
	public var mouseY:Float;

	public var gridMouseX:Float;
	public var gridMouseY:Float;

	public final GRID_SIZE:Int = 32;

	public var curLayer:String = 'background';
	public var curGraphicPath:String = 'SOLID_COLOR';
	public var isCollidable:Bool = false;
	public var isImmovable:Bool = true;
	public var curAngle:Float = 0;
	public var curColor:Int = 0xFFFFFFFF;
	public var curAlpha:Float = 1;
	public var curEvent:String = "none";
	public var curEventValues:Array<Dynamic> = [];

	public var curGrp:String = '';
	public var curSpriteMap:StringMap<Array<String>> = null;

	public var focusedOnText(get, never):Bool;

	public var allowTileOverlapping:Bool = false;

	function get_focusedOnText() {
		if (eventInputText != null && eventArgsInputText != null && colorInputText != null)
			return eventInputText.hasFocus || eventArgsInputText.hasFocus || colorInputText.hasFocus;
		return false;
	}

	public var camFollow:FlxObject;

	public static var instance:MainState;

	public function new() {
		super();
		instance = this;
	}

	override public function create() {
		background = new FlxTypedGroup<Tile>();
		midground = new FlxTypedGroup<Tile>();
		foreground = new FlxTypedGroup<Tile>();
		tilesArray = new Array<Tile>();
		uiGroup = new FlxTypedGroup<FlxSprite>();
		add(background);
		add(midground);
		add(foreground);
		add(uiGroup);

		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);

		FlxG.camera.follow(camFollow, LOCKON, 1);

		uiGroup.memberAdded.add(function(spr:FlxSprite) {
			spr.scrollFactor.set();
		});

		setCallbacks(background, function(tile:Tile) {
			tilesArray.push(tile);
		}, function(tile:Tile) {
			tilesArray.remove(tile);
		});

		setCallbacks(midground, function(tile:Tile) {
			tilesArray.push(tile);
		}, function(tile:Tile) {
			tilesArray.remove(tile);
		});

		setCallbacks(foreground, function(tile:Tile) {
			tilesArray.push(tile);
		}, function(tile:Tile) {
			tilesArray.remove(tile);
		});

		generateUI();

		super.create();
	}

	inline function setCallbacks(grp:FlxTypedGroup<Tile>, memberAdded:Tile->Void, memberRemoved:Tile->Void) {
		grp.memberAdded.add(memberAdded);
		grp.memberRemoved.add(memberRemoved);
	}

	public var isOverlappingSmth:Bool = false;
	public var overlappedTile:Tile;

	// * unused function since addTile()'s tiledef comparing is broken for some reason
	function mouseInput() {
		if (FlxG.mouse.pressed && !FlxG.mouse.overlaps(uiGroup)) {
			addTile();
		}

		if (FlxG.mouse.pressedRight && !FlxG.mouse.overlaps(uiGroup)) {
			for (i in getLayerFromStr(curLayer).members) {
				if (FlxG.mouse.overlaps(i))
					removeTile(i);
			}
		}
	}

	override public function update(elapsed:Float) {
		mouseX = FlxG.mouse.x;
		mouseY = FlxG.mouse.y;

		gridMouseX = Math.floor(mouseX / GRID_SIZE) * GRID_SIZE;
		gridMouseY = Math.floor(mouseY / GRID_SIZE) * GRID_SIZE;

		if (FlxG.mouse.justPressed && !FlxG.mouse.overlaps(uiGroup)) {
			addTile();
		}
		if (FlxG.mouse.justPressedRight && !FlxG.mouse.overlaps(uiGroup)) {
			for (i in getLayerFromStr(curLayer).members) {
				if (FlxG.mouse.overlaps(i))
					removeTile(i);
			}
		}
		// mouseInput();
		updateUI();

		camFollowMovement();

		if (!focusedOnText && !isInDropdown) {
			keybinds();
		}

		super.update(elapsed);
	}

	var resetTmr:FlxTimer;

	function keybinds() {
		var ctrl = FlxG.keys.pressed.CONTROL;
		if (ctrl) {
			if (FlxG.keys.justPressed.S) {
				saveBtn.onClickCallback();
			}
			else if (FlxG.keys.justPressed.L) {
				load();
			}
			else if (FlxG.keys.justPressed.R) {
				// FlxG.resetState();
				// loadTiles();
			}
		}
	}

	function camFollowMovement() {
		if (!focusedOnText) {
			if (FlxG.keys.anyPressed([UP, W])) {
				camFollow.velocity.y = -200;
			}
			else if (FlxG.keys.anyPressed([DOWN, S])) {
				camFollow.velocity.y = 200;
			}
			else if (FlxG.keys.anyPressed([UP, W]) && FlxG.keys.anyPressed([DOWN, S])) {
				camFollow.velocity.y = 0;
			}
			else {
				camFollow.velocity.y = 0;
			}

			if (FlxG.keys.anyPressed([LEFT, A])) {
				camFollow.velocity.x = -200;
			}
			else if (FlxG.keys.anyPressed([RIGHT, D])) {
				camFollow.velocity.x = 200;
			}
			else if (FlxG.keys.anyPressed([LEFT, A]) && FlxG.keys.anyPressed([RIGHT, D])) {
				camFollow.velocity.x = 0;
			}
			else {
				camFollow.velocity.x = 0;
			}
		}
	}

	function getColor() {
		if (colorInputText.text.length > 0)
			return curColor = Std.parseInt('0x' + colorInputText.text);
		else
			return curColor = FlxColor.WHITE;
	}

	function addTile() {
		#if debug
		trace('adding tile @ layer $curLayer');
		#end

		var tileDef:TileDef = {
			x: gridMouseX,
			y: gridMouseY,
			alpha: curAlpha,
			angle: curAngle,
			color: Std.string(curColor),
			collidable: isCollidable,
			immovable: isImmovable,
			layer: curLayer,
			graphicPath: curGraphicPath,
			event: getEventItems()
		}

		var tile = new Tile(tileDef);
		if (getColor() != 0)
			tile.color = getColor();
		else
			tile.color = FlxColor.WHITE;

		trace(getColor());

		isOverlappingSmth = FlxG.mouse.overlaps(getLayerFromStr(curLayer));
		overlappedTile = getOverlappedTile();

		if (isOverlappingSmth && overlappedTile != null && !allowTileOverlapping) {
			removeTile(overlappedTile);
		}

		switch (curLayer) {
			case 'background':
				trace('added tile to background');
				background.add(tile);
			case 'midground':
				trace('added tile to midground');
				midground.add(tile);
			case 'foreground':
				trace('added tile to foreground');
				foreground.add(tile);
		}
	}

	function arrayFromDef(def:TileDef):Array<Dynamic> {
		return [

			def.x, def.y, def.alpha, def.angle, def.color, def.collidable, def.immovable, def.layer, def.graphicPath, def.event

		];
	}

	function removeTile(tile:Tile) {
		#if debug
		trace('removin tile @ $curLayer');
		#end
		switch (curLayer) {
			case 'background':
				if (tile.layer == 'background')
					background.remove(tile, true);
			case 'midground':
				if (tile.layer == 'midground')
					midground.remove(tile, true);
			case 'foreground':
				if (tile.layer == 'foreground')
					foreground.remove(tile, true);
		}

		tilesArray.remove(tile);
	}

	public inline function getEventItems():EventDef {
		return {
			name: eventInputText.text,
			values: eventArgsInputText.text.replace(' ', '').split(',')
		};
	}

	inline function getOverlappedTile() {
		var _overlappedTile:Tile = null;

		switch (curLayer) {
			case 'background':
				for (i in background.members) {
					if (FlxG.mouse.overlaps(i)) {
						_overlappedTile = i;
					}
				}
			case 'midground':
				for (i in midground.members) {
					if (FlxG.mouse.overlaps(i)) {
						_overlappedTile = i;
					}
				}
			case 'foreground':
				for (i in foreground.members) {
					if (FlxG.mouse.overlaps(i)) {
						_overlappedTile = i;
					}
				}
		}

		return _overlappedTile;
	}

	function getLayerFromStr(str:String) {
		switch (str.toLowerCase()) {
			case 'background':
				return background;
			case 'midground':
				return midground;
			case 'foreground':
				return foreground;
			default:
				return background;
		}
	}

	public function getData() {
		var tGroups:Array<String> = [];
		if (FileSystem.exists('assets/data/tiles/list.json')) {
			var parse:Array<String> = Json.parse(Assets.getText('assets/data/tiles/list.json')).list;
			trace(parse);
			if (parse != null)
				for (i in 0...parse.length)
					tGroups.push(parse[i]);
		}

		var sprMap:StringMap<Array<TileStringDef>> = new StringMap<Array<TileStringDef>>();

		trace(tGroups);

		for (i in tGroups) {
			if (FileSystem.exists('assets/data/tiles/$i.json')) {
				var jsonStuff:Array<TileStringDef> = Json.parse(Assets.getText('assets/data/tiles/$i.json')).tiles;
				var theTiles:Array<TileStringDef> = [];
				for (x in 0...jsonStuff.length) {
					trace('$i/' + jsonStuff[x].path);
					theTiles.push({name: jsonStuff[x].name, path: jsonStuff[x].path});
				}
				sprMap.set(i, theTiles);
			}
		}

		trace("tGroups" + tGroups + "\n" + "sprMap" + sprMap);

		return {t: tGroups, s: sprMap};
	}

	public inline function clearTiles() {
		background.clear();
		midground.clear();
		foreground.clear();

		tilesArray = [];
	}

	public var verticalUIBar:FlxSprite;
	public var horizontalUIBar:FlxSprite;
	public var tileGroupSelect:FlxUIDropDownMenu;
	public var tileSpriteSelect:FlxUIDropDownMenu;
	public var isCollidableCheckbox:FlxUICheckBox;
	public var isImmovableCheckbox:FlxUICheckBox;
	public var colorInputText:FlxInputText;
	public var eventInputText:FlxInputText;
	public var eventArgsInputText:FlxInputText;
	public var layerSelect:FlxUIDropDownMenu;
	public var loadBtn:FlxButtonPlus;
	public var clearBtn:FlxButtonPlus;
	public var saveBtn:FlxButtonPlus;
	public var curTileStuff:Array<TileDef> = [];
	public var alphaDisplayText:FlxText;
	public var alphaSlider:FlxUISlider;
	public var alphaInputText:FlxInputText;
	public var allowTileOverlappingCheckbox:FlxUICheckBox;

	public function generateUI() {
		var coolData = getData();
		var groupCool:Array<String> = coolData.t;
		var sprMapCool:StringMap<Array<TileStringDef>> = coolData.s;

		curGrp = groupCool[0];

		verticalUIBar = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width / 4), FlxG.height, FlxColor.GRAY);

		// horizontalUIBar = new FlxSprite(0, 0).makeGraphic(FlxG.width, Std.int(FlxG.height / 4), FlxColor.GRAY);
		// horizontalUIBar.y = FlxG.height - horizontalUIBar.height;

		uiGroup.add(verticalUIBar);
		// uiGroup.add(horizontalUIBar);

		isImmovableCheckbox = new FlxUICheckBox(0, 0, null, null, 'Immovable?');
		isCollidableCheckbox = new FlxUICheckBox(0, 0, null, null, 'Collidable?');
		isImmovableCheckbox.checked = true;
		isCollidableCheckbox.checked = false;

		uiGroup.add(isImmovableCheckbox);
		uiGroup.add(isCollidableCheckbox);

		var colorDisplayText:FlxText = new FlxText(0, 0, 0, "Color (hex)", 12);
		colorInputText = new FlxInputText(0, 0, Std.int(FlxG.width / 4 - 40), "", 12);
		var eventDisplayText:FlxText = new FlxText(0, 0, 0, "Event", 12);
		eventInputText = new FlxInputText(0, 0, Std.int(FlxG.width / 4 - 40), "", 12);
		var eventArgsDisplayText = new FlxText(0, 0, 0, "Event Params", 12);
		eventArgsInputText = new FlxInputText(0, 0, Std.int(FlxG.width / 4) - 40, "", 12);

		uiGroup.add(colorDisplayText);
		uiGroup.add(colorInputText);
		uiGroup.add(eventDisplayText);
		uiGroup.add(eventInputText);
		uiGroup.add(eventArgsDisplayText);
		uiGroup.add(eventArgsInputText);

		volProofInputText(colorInputText);
		volProofInputText(eventInputText);
		volProofInputText(eventArgsInputText);

		tileGroupSelect = new FlxUIDropDownMenu(10, 40, FlxUIDropDownMenu.makeStrIdLabelArray(groupCool, true), function(grp:String) {
			if (curGrp != groupCool[Std.parseInt(grp)]) {
				curGrp = groupCool[Std.parseInt(grp)];
				if (tileSpriteSelect != null) {
					var listThingy = [];
					for (i in sprMapCool.get(curGrp)) {
						listThingy.push(i.name);
					}
					tileSpriteSelect.setData(FlxUIDropDownMenu.makeStrIdLabelArray(listThingy));
				}
			}
		});

		var someList = [for (i in sprMapCool.get(curGrp)) i.name];

		tileSpriteSelect = new FlxUIDropDownMenu(tileGroupSelect.x + tileGroupSelect.width + 10, tileGroupSelect.y,
			FlxUIDropDownMenu.makeStrIdLabelArray(someList, true), function(spr:String) {
				curGraphicPath = sprMapCool.get(curGrp)[Std.parseInt(spr)].path;
				trace(curGraphicPath);
		});

		uiGroup.add(tileGroupSelect);
		uiGroup.add(tileSpriteSelect);

		isImmovableCheckbox.setPosition(tileGroupSelect.x, tileGroupSelect.y + 60);
		isCollidableCheckbox.setPosition(tileSpriteSelect.x, isImmovableCheckbox.y);

		colorDisplayText.setPosition(10, isImmovableCheckbox.y + 30);
		colorInputText.setPosition(10, colorDisplayText.y + 20);

		eventDisplayText.setPosition(10, colorInputText.y + 30);
		eventInputText.setPosition(10, eventDisplayText.y + 20);

		eventArgsDisplayText.setPosition(10, eventInputText.y + 30);
		eventArgsInputText.setPosition(10, eventArgsDisplayText.y + 20);

		isImmovableCheckbox.callback = function() {
			isImmovable = !isImmovable;
			isImmovableCheckbox.checked = isImmovable;
		}

		isCollidableCheckbox.callback = function() {
			isCollidable = !isCollidable;
			isCollidableCheckbox.checked = isCollidable;
		}

		layerSelect = new FlxUIDropDownMenu(10, eventArgsInputText.y + 40,
			FlxUIDropDownMenu.makeStrIdLabelArray(['background', 'midground', 'foreground', 'events']), function(str:String) {
				curLayer = str;
		});

		alphaSlider = new FlxUISlider(this, "curAlpha", 10, layerSelect.y + 50, 0, 1, Std.int(verticalUIBar.width - 30), 15, 5, FlxColor.WHITE,
			FlxColor.BLACK);
		alphaSlider.valueLabel.color = FlxColor.WHITE;
		alphaSlider.setTexts("Alpha", true, "0", "1", 14);
		alphaSlider.hoverAlpha = 1;

		uiGroup.add(layerSelect);
		uiGroup.add(alphaSlider);

		allowTileOverlappingCheckbox = new FlxUICheckBox(10, alphaSlider.y + 65, null, null, "Allow Tile Overlapping");
		allowTileOverlappingCheckbox.callback = function() {
			allowTileOverlapping = !allowTileOverlapping;
			allowTileOverlappingCheckbox.checked = allowTileOverlapping;
		}

		uiGroup.add(allowTileOverlappingCheckbox);

		saveBtn = new FlxButtonPlus(alphaSlider.x, allowTileOverlappingCheckbox.y + 30, function() {
			var fr:FileReference = new FileReference();
			fr.save(Writer.writeTilesToJSON(tilesArray), "level.json");

			Program.title = 'kc level editor - ' + fr.name;
		}, "Save");

		loadBtn = new FlxButtonPlus(saveBtn.x + saveBtn.width + 10, saveBtn.y, function() {
			load();
		}, "Load");

		uiGroup.add(saveBtn);
		uiGroup.add(loadBtn);
	}

	var isInDropdown:Bool = false;

	public function updateUI() {
		if (tileSpriteSelect.list[0].visible) {
			isImmovableCheckbox.active = false;
			isCollidableCheckbox.active = false;
			colorInputText.active = false;
			eventInputText.active = false;
			eventArgsInputText.active = false;
			layerSelect.active = false;
			alphaSlider.active = false;
			allowTileOverlappingCheckbox.active = false;
			isInDropdown = true;
		}
		else if (tileGroupSelect.list[0].visible) {
			isImmovableCheckbox.active = true;
			isCollidableCheckbox.active = false;
			colorInputText.active = false;
			eventInputText.active = false;
			eventArgsInputText.active = false;
			layerSelect.active = false;
			alphaSlider.active = false;
			allowTileOverlappingCheckbox.active = false;
			isInDropdown = true;
		}
		else {
			isImmovableCheckbox.active = true;
			isCollidableCheckbox.active = true;
			colorInputText.active = true;
			eventInputText.active = true;
			eventArgsInputText.active = true;
			layerSelect.active = true;
			alphaSlider.active = true;
			allowTileOverlappingCheckbox.active = true;
			isInDropdown = false;
		}
	}

	inline function volProofInputText(inputText:FlxInputText) {
		inputText.focusGained = function() {
			FlxG.sound.volumeUpKeys = null;
			FlxG.sound.volumeDownKeys = null;
			FlxG.sound.muteKeys = null;
		}

		inputText.focusLost = function() {
			FlxG.sound.volumeUpKeys = [PLUS, NUMPADPLUS];
			FlxG.sound.volumeDownKeys = [MINUS, NUMPADMINUS];
			FlxG.sound.muteKeys = [ZERO, NUMPADZERO];
		}
	}

	/*
	 * load code made by:
	 * Vascofr & GeoKureli
	 * Demo I took the code from: https://haxeflixel.com/demos/FileBrowse/
	 * Demo's github link: https://github.com/HaxeFlixel/flixel-demos/tree/dev/UserInterface/FileBrowse/source
	 */
	public function load() {
		clearTiles();
		var fr:FileReference = new FileReference();
		fr.addEventListener(Event.SELECT, onSelect);
		fr.addEventListener(Event.CANCEL, onCancel);
		fr.browse([new FileFilter("JSON files", "*.json")]);
	}

	public function loadTiles(tileArray:Array<TileDef>) {
		for (i in tileArray) {
			switch (i.layer.toLowerCase()) {
				case 'background':
					var tile = new Tile(i);
					background.add(tile);
					tilesArray.push(tile);
				case 'midground':
					var tile = new Tile(i);
					midground.add(tile);
					tilesArray.push(tile);
				case 'foreground':
					var tile = new Tile(i);
					foreground.add(tile);
					tilesArray.push(tile);
				// todo: load event tiles
				default:
					var tile = new Tile(i);
					background.add(tile);
					tilesArray.push(tile);
			}
		}
	}

	public function onSelect(e:Event) {
		trace('hi');
		var fr:FileReference = cast(e.target, FileReference);
		fr.addEventListener(Event.COMPLETE, onLoad, false, 0, true);
		fr.load();
	}

	public function onLoad(e:Event) {
		trace('bbbbbbbbbfds');
		var fr:FileReference = cast(e.target, FileReference);
		fr.removeEventListener(Event.COMPLETE, onLoad);
		trace(fr.name);
		trace(fr.data.toString());
		var theJson = Json.parse(fr.data.toString());
		if (theJson.tiles != null) {
			loadTiles(theJson.tiles);
			Program.title = 'kc level editor - ' + fr.name;
		}
	}

	public function onCancel(e:Event) {}
}
