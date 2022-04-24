package;

import flixel.FlxGame;
import openfl.display.FPS;
import openfl.display.Sprite;
import plugins.PluginManager;

class Main extends Sprite {
	public function new() {
		super();
		addChild(new FlxGame(0, 0, MainState));

		addChild(new FPS());

		PluginManager.init();
	}
}
