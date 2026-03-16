package llua;

import llua.State;
import llua.Convert;

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
    public function call(args:Array<Dynamic> = null) {

        // Push the function from registry onto the stack
        Lua.rawgeti(l, Lua.LUA_REGISTRYINDEX, ref);

        // Check if it's actually a function
        if (!Lua.isfunction(l, -1)) {
            Lua.pop(l, 1);
            return;
        }

        // Convert arguments to Lua
        if (args == null) args = [];
        for (arg in args) Convert.toLua(l, arg);

        // Call the function
        var status:Int = Lua.pcall(l, args.length, 0, 0);

        if (status != Lua.LUA_OK) {
            var err:String = null;

            // Only read error if stack top is not nil
            if (!Lua.isNilBool(l, -1)) err = Lua.tostring(l, -1);
            Lua.pop(l, 1);

            // Fallback error messages
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

    /** Deallocates the pointer reserved for this callback. */
    public function dispose() {
        LuaL.unref(l, Lua.LUA_REGISTRYINDEX, ref);
    }
}
