package;

import flixel.FlxG;

class Program {
	public static var title(get, set):String;

	static function set_title(value:String):String {
		return FlxG.stage.application.window.title = value;
	}

	static function get_title():String {
		return FlxG.stage.application.window.title;
	}
}
