package llua;

@:include('linc_lua.h')

@:native('lua_State')
extern class Lua_State {}

typedef State = cpp.RawPointer<Lua_State>;

typedef StatePointer = cpp.RawPointer<Lua_State>;
