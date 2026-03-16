package llua;

import llua.State;
import llua.Convert;

@:keep
class LuaCallback {

    /** The Lua environment the function is bound to **/
    private var l:State;

    /** Pointer to Lua function reserved for temporary use */
    public var ref(default, null):Int;

    public function new(lua:State, ref:Int) {
        this.l = lua;
        this.ref = ref;
    }

    /** Runs this Lua function once, with the given arguments. */
    public function call(args:Array<Dynamic> = null):Void {
        Lua.rawgeti(l, Lua.LUA_REGISTRYINDEX, ref);

        if (!Lua.isfunction(l, -1)) {
            Lua.pop(l, 1);
            return;
        }

        if (args == null) args = [];
        for (arg in args) Convert.toLua(l, arg);

        var status:Int = Lua.pcall(l, args.length, 0, 0);

        if (status != Lua.LUA_OK) {
            var err:String = null;
            if (!Lua.isnil(l, -1)) err = Lua.tostring(l, -1);
            Lua.pop(l, 1);

            if (err == null || err == "") {
                switch(status) {
                    case Lua.LUA_ERRRUN: err = "Runtime Error";
                    case Lua.LUA_ERRMEM: err = "Memory Allocation Error";
                    case Lua.LUA_ERRERR: err = "Critical Error";
                    default: err = "Unknown Error";
                }
            }

            trace("Error on callback: " + err);
        }
    }

    /** Removes the reference to this Lua function */
    public function dispose():Void {
        if (ref != null) {
            LuaL.unref(l, Lua.LUA_REGISTRYINDEX, ref);
            ref = null;
        }
    }
}
