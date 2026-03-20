#include <hxcpp.h>
#include <hx/CFFI.h>
#include <cstring>
#include "./linc_lua.h"
#include "../lib/lua/src/lua.hpp"

namespace linc {

namespace lua {

::String version(){
    return ::String(LUA_VERSION);
}

::String versionJIT(){
    return ::String(LUAJIT_VERSION);
}

::String tostring(lua_State *l, int v){
    if(!l) return ::String("");
    const char* s = lua_tostring(l, v);
    return s ? ::String(s) : ::String("");
}

::String tolstring(lua_State *l, int v, size_t *len){
    if(!l) return ::String("");
    const char* s = lua_tolstring(l, v, len);
    return s ? ::String(s) : ::String("");
}

::cpp::Function<int(lua_State*)> tocfunction(lua_State* l, int i) {
    if(!l) return null();
    return (::cpp::Function<int(lua_State*)>) lua_tocfunction(l, i);
}

void pushcclosure(lua_State* l, ::cpp::Function<int(lua_State*)> fn, int n) {
    if(l && fn != null()) lua_pushcclosure(l, (lua_CFunction)fn, n);
}

void pushcfunction(lua_State* l, ::cpp::Function<int(lua_State*)> fn) {
    if(l && fn != null()) lua_pushcfunction(l, (lua_CFunction)fn);
}

::String _typename(lua_State *l, int v){
    if(!l) return ::String("");
    const char* s = lua_typename(l, v);
    return s ? ::String(s) : ::String("");
}

int getstack(lua_State *L, int level, Dynamic ar){
    if(!L || ar == null()) return 0;
    lua_Debug dbg;
    int ret = lua_getstack(L, level, &dbg);
    ar->__FieldRef(HX_CSTRING("i_ci")) = (int)dbg.i_ci;
    return ret;
}

int getinfo(lua_State *L, const char *what, Dynamic ar){
    if(!L || !what || ar == null()) return 0;
    lua_Debug dbg;
    dbg.i_ci = ar->__FieldRef(HX_CSTRING("i_ci"));
    int ret = lua_getinfo(L, what, &dbg);
    if (strchr(what, 'S')){
        if (dbg.source)
            ar->__FieldRef(HX_CSTRING("source")) = ::String(dbg.source);
        if (dbg.short_src[0] != '\0')
            ar->__FieldRef(HX_CSTRING("short_src")) = ::String(dbg.short_src);
        if (dbg.linedefined != 0)
            ar->__FieldRef(HX_CSTRING("linedefined")) = (int)dbg.linedefined;
        if (dbg.lastlinedefined != 0)
            ar->__FieldRef(HX_CSTRING("lastlinedefined")) = (int)dbg.lastlinedefined;
        if (dbg.what)
            ar->__FieldRef(HX_CSTRING("what")) = ::String(dbg.what);
    }
    if (strchr(what, 'n')){
        if (dbg.name)
            ar->__FieldRef(HX_CSTRING("name")) = ::String(dbg.name);
        if (dbg.namewhat)
            ar->__FieldRef(HX_CSTRING("namewhat")) = ::String(dbg.namewhat);
    }
    if (strchr(what, 'l')){
        if (dbg.currentline != 0)
            ar->__FieldRef(HX_CSTRING("currentline")) = (int)dbg.currentline;
    }
    if (strchr(what, 'u')){
        if (dbg.nups != 0)
            ar->__FieldRef(HX_CSTRING("nups")) = (int)dbg.nups;
    }
    return ret;
}

}

namespace lual {

::String checklstring(lua_State *l, int numArg, size_t *len){
    if(!l) return ::String("");
    const char* s = luaL_checklstring(l, numArg, len);
    return s ? ::String(s) : ::String("");
}

::String optlstring(lua_State *l, int numArg, const char *def, size_t *len){
    if(!l) return ::String("");
    const char* s = luaL_optlstring(l, numArg, def, len);
    return s ? ::String(s) : ::String("");
}

::String prepbuffer(luaL_Buffer *B){
    if(!B) return ::String("");
    return ::String(luaL_prepbuffer(B));
}

::String gsub(lua_State *l, const char *s, const char *p, const char *r){
    if(!l || !s || !p || !r) return ::String("");
    return ::String(luaL_gsub(l, s, p, r));
}

::String findtable(lua_State *L, int idx, const char *fname, int szhint){
    if(!L || !fname) return ::String("");
    return ::String(luaL_findtable(L, idx, fname, szhint));
}

::String checkstring(lua_State *L, int n){
    if(!L) return ::String("");
    const char* s = luaL_checkstring(L, n);
    return s ? ::String(s) : ::String("");
}

::String optstring(lua_State *L, int n, const char *d){
    if(!L) return ::String("");
    const char* s = luaL_optstring(L, n, d);
    return s ? ::String(s) : ::String("");
}

void error(lua_State *L, const char* fmt) {
    if(L && fmt) luaL_error(L, fmt, "");
}

::String ltypename(lua_State *L, int idx){
    if(!L) return ::String("");
    const char* s = luaL_typename(L, idx);
    return s ? ::String(s) : ::String("");
}

}

namespace helpers {

static int onError(lua_State *L) {
    if(!L) return 0;
    const char *msg = lua_tostring(L, 1);
    if (msg)
        luaL_traceback(L, L, msg, 1);
    else if (!lua_isnoneornil(L, 1)){
        if (!luaL_callmeta(L, 1, "__tostring"))
            lua_pushliteral(L, "(no error message)");
    }
    return 1;
}

int setErrorHandler(lua_State *L){
    if(!L) return 0;
    lua_pushcfunction(L, onError);
    return 1;
}

static HxTraceFN print_fn = 0;

static int hx_trace(lua_State* L){
    if(!L) return 0;
    std::stringstream buffer;
    int n = lua_gettop(L);
    lua_getglobal(L,"tostring");
    for (int i = 1; i <= n; ++i){
        lua_pushvalue(L,-1);
        lua_pushvalue(L,i);
        lua_call(L,1,1);
        size_t len = 0;
        const char* s = lua_tolstring(L,-1,&len);
        if (!s)
            return luaL_error(L,"tostring must return a string");
        if (i > 1)
            buffer << "\t";
        buffer << s;
        lua_pop(L,1);
    }
    if (print_fn != null())
        print_fn(::String(buffer.str().c_str()));
    return 0;
}

static const struct luaL_Reg printlib [] = {
    {"print", hx_trace},
    {NULL, NULL}
};

void register_hxtrace_func(HxTraceFN fn){
    print_fn = fn;
}

void register_hxtrace_lib(lua_State* L){
    if(!L) return;
    lua_getglobal(L, "_G");
    luaL_register(L, NULL, printlib);
    lua_pop(L, 1);
}

}

namespace callbacks {

static luaCallbackFN event_fn = 0;

static int luaCallback(lua_State *L){
    if(!L || event_fn == null()) return 0;
    const char* str = lua_tostring(L, lua_upvalueindex(1));
    return event_fn(L, ::String(str ? str : ""));
}

void set_callbacks_function(luaCallbackFN fn){
    event_fn = fn;
}

void add_callback_function(lua_State *L, const char *name){
    if(!L || !name) return;
    lua_pushstring(L, name);
    lua_pushcclosure(L, luaCallback, 1);
    lua_setglobal(L, name);
}

void remove_callback_function(lua_State *L, const char *name){
    if(!L || !name) return;
    lua_pushnil(L);
    lua_setglobal(L, name);
}

}

}
