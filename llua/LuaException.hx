package llua;

import llua.State;
import llua.Lua;
import haxe.Exception;

class LuaException extends Exception {

public var error_code:Int = 0;

public function new(?message:String, ?previous:Exception, ?code:Int = 0, ?luaState:State) {

	error_code = code;

	if (message == null) {

		message = switch(code) {

			case Lua.LUA_ERRRUN:
				if(luaState == null) {
					"Lua Runtime Error";
				} else {
					var err = Lua.tostring(luaState, -1);
					err == null ? "Lua Runtime Error" : err;
				}

			case Lua.LUA_ERRMEM:
				"Lua VM ran out of memory";

			case Lua.LUA_ERRERR:
				"Lua Error while handling another error";

			default:
				"Lua Error: " + code;
		};
	}

	super(message, previous);
}

public static function ifErrorThrow(l:State, status:Int) {

	if (status == Lua.LUA_OK)
		return;

	throw new LuaException(null, null, status, l);
}

}
