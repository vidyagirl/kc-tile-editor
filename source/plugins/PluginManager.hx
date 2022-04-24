package plugins;

import sys.FileSystem;

class PluginManager {
	public static var plugins:Array<Plugin>;

	public static var enabledPlugins(get, never):Array<Plugin>;

	public static var disabledPlugins(get, never):Array<Plugin>;

	static function get_enabledPlugins() {
		return [for (i in plugins) if (i.active) i];
	}

	static function get_disabledPlugins() {
		return [for (i in plugins) if (!i.active) i];
	}

	public static function init() {
		if (plugins == null)
			plugins = new Array<Plugin>();
		return plugins;
	}

	public static function removePlugin(name:String) {
		for (i in plugins) {
			if (i.name == name) {
				plugins.remove(i);
				return i;
			}
		}

		return null;
	}

	public static function addPlugin(scriptPath:String) {
		if (FileSystem.exists('plugins/$scriptPath.hx')) {
			var newPlugin = new Plugin('plugins/$scriptPath.hx');
			return newPlugin;
		}
		trace('Plugin file not found!');
		return null;
	}

	public static function disablePlugin(name:String) {
		for (i in plugins) {
			if (i.name == name) {
				i.active = false;
				return i;
			}
		}

		return null;
	}

	public static function enablePlugin(name:String) {
		for (i in plugins) {
			if (i.name == name) {
				i.active = true;
				return i;
			}
		}

		return null;
	}
}
