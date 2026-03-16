package llua;

import llua.State;
import haxe.Exception;

class LuaException extends Exception {
	public var error_code:Int = 0;
    
	public function new(message:String, ?previous:Exception, ?code:Int = 0) {
		error_code = code != null ? code : 0;
		super(message, previous);
	}
    
	public static function ifErrorThrow(l:State, status:Int) {
		if(status == 0) return;
        
		var errorMsg:String = switch(status) {
			case Lua.LUA_ERRRUN: (l == null ? "Lua Runtime Error: UNKNOWN ERROR?" : Lua.tostring(l, -1));
			case Lua.LUA_ERRMEM: "luavm ran out of memory";
			case Lua.LUA_ERRERR: "LUA_ERRERR";
			default: "Lua Error: " + status;
		};
        
		var exception = new LuaException(errorMsg, null, status);
        
		#if android
		trace("LUA EXCEPTION CAUGHT: " + exception.message);
		#else
		throw exception;
		#end
	}
}
