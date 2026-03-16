package llua;

import llua.State;
import llua.Convert;

class LuaCallback {

    private var l:State;
    public var ref(default, null):Int;

    public function new(lua:State, ref:Int) {
        this.l = lua;
        this.ref = ref;
    }

    public function call(args:Array<Dynamic> = null) {

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
            if (!Lua.isNilBool(l, -1)) err = Lua.tostring(l, -1);
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

    public function dispose() {
        LuaL.unref(l, Lua.LUA_REGISTRYINDEX, ref);
    }
}
