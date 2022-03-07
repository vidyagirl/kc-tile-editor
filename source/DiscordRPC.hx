package;

#if DISCORD_RPC
import discord_rpc.DiscordRpc;
#end

class DiscordRPC
{
	public static inline function start()
	{
		DiscordRpc.start({
			clientID: "950168593482514503",
			onReady: () ->
			{
				onReady();
			},
			onError: (code:Int, message:String) ->
			{
				trace(onError(code, message));
			},
			onDisconnected: (code:Int, message:String) ->
			{
				trace(onDisconnected(code, message));
			}
		});
	}

	public static inline function shutdown()
	{
		DiscordRpc.shutdown();
	}

	public static function changePresence(details:String, state:String, ?largeImageKey:String, ?largeImageText:String, ?smallImageKey:String,
			?smallImageText:String)
	{
		return DiscordRpc.presence({
			details: details,
			state: state,
			largeImageKey: largeImageKey,
			largeImageText: largeImageText
		});
	}

	private static function onReady()
	{
		trace('DiscordRPC Ready!');
		changePresence("In the Menus", "Menu", null, "Mentomukatte", null, "Editting: ");
	}

	private static function onError(code:Int, message:String)
	{
		return "Error!\nCode: " + code + "\nMessage: " + message;
	}

	private static function onDisconnected(code:Int, message:String)
	{
		return "Disconnected!\nCode: " + code + "\nMessage: " + message;
	}
}
