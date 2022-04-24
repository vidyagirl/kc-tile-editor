package plugins;

import flixel.FlxG;
import hscript.Expr;
import hscript.Interp;
import hscript.Parser;
import sys.FileSystem;

class Plugin {
	var script:Expr;
	var parser:Parser;
	var interp:Interp;

	public var active:Bool = true;
	public var name:String = '';

	public function new(scriptPath:String) {
		if (FileSystem.exists(scriptPath)) {
			script = parser.parseString(scriptPath);
			PluginManager.plugins.push(this);
			if (MainState != null) {
				if (interp.variables.get("init") != null)
					init();
			}
			else {
				trace("MainState instance not found!");
			}
		}
		else {
			var msg = 'Error! Script "$scriptPath" not found';
			trace(msg);
			FlxG.log.error(msg);
		}
	}

	function setVars() {
		var ins:MainState = MainState.instance;
		var set:String->Dynamic->Void = interp.variables.set;

		set("background", ins.background);
		set("midground", ins.midground);
		set("foreground", ins.foreground);
		set("uiGroup", ins.uiGroup);
		set("name", name);
	}

	public function init() {
		var _init = interp.variables.get("init");
		_init();
	}

	public function create() {
		var _create = interp.variables.get("create");
		_create();
	}

	public function update(elapsed:Float) {
		var _update = interp.variables.get("update");
		_update(elapsed);
	}
}
