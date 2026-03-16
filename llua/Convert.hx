package llua;

import llua.State;
import llua.Lua;
import llua.LuaL;
import llua.LuaException;
import llua.Macro.*;
import haxe.DynamicAccess;
import haxe.ds.ObjectMap;

class Convert {

public static var enableUnsupportedTraces = false;
public static var allowFunctions = true;
public static var functionReferences:ObjectMap<Dynamic, Array<Dynamic>> = new ObjectMap<Dynamic, Array<Dynamic>>();
	
@:keep inline public static function cleanFunctionRefs() {
    functionReferences = new ObjectMap<Dynamic, Array<Dynamic>>();
}

public static function toLua(l:State, val:Any):Bool {

	switch (Type.typeof(val)) {

		case Type.ValueType.TNull:
			Lua.pushnil(l);

		case Type.ValueType.TBool:
			Lua.pushboolean(l, val);

		case Type.ValueType.TInt:
			Lua.pushinteger(l, cast(val, Int));

		case Type.ValueType.TFloat:
			Lua.pushnumber(l, val);

		case Type.ValueType.TClass(String):
			Lua.pushstring(l, cast(val, String));

		case Type.ValueType.TClass(Array):
			arrayToLua(l, val);

		case Type.ValueType.TClass(haxe.ds.StringMap) | Type.ValueType.TClass(haxe.ds.ObjectMap):
			mapToLua(l, val);

		case Type.ValueType.TObject:
			anonToLua(l, val);

		default:
			if(enableUnsupportedTraces)
				trace('Unsupported Haxe value: $val type ${Type.typeof(val)}');
			return false;
	}

	return true;
}

public static function callback_handler(cbf:Dynamic,l:State,?object:Dynamic):Int {

	try{

		final nparams:Int = Lua.gettop(l);

		if(cbf == null) return 0;

		final ret:Dynamic = Reflect.callMethod(object,cbf,[for (i in 0...nparams) fromLua(l, i + 1)]);

		if(ret != null){
			toLua(l, ret);
			return 1;
		}

	}catch(e){
		trace('$e');
		throw(e);
	}

	return 0;
}

@:keep public static inline function arrayToLua(l:State, arr:Array<Any>) {

	Lua.createtable(l, arr.length, 0);

	for (i => v in arr) {

		Lua.pushnumber(l, i + 1);
		toLua(l, v);
		Lua.settable(l, -3);

	}
}

@:keep static inline function mapToLua(l:State, res:Map<String,Dynamic>) {

	Lua.createtable(l, 0, 0);

	for (index => val in res){

		Lua.pushstring(l, Std.string(index));
		toLua(l, val);
		Lua.settable(l, -3);

	}
}

@:keep static inline function anonToLua(l:State, res:Any) {

	Lua.createtable(l, 0, 0);

	for (n in Reflect.fields(res)){

		Lua.pushstring(l, n);
		toLua(l, Reflect.field(res, n));
		Lua.settable(l, -3);

	}
}

@:keep public static inline function setGlobal(l:State, index:String, value:Dynamic) {

	toLua(l, value);
	Lua.setfield(l, Lua.LUA_GLOBALSINDEX, index);

}

public static function fromLua(l:State, v:Int):Any {

	final luaType = Lua.type(l, v);

	return switch(luaType) {

		case Lua.LUA_TNIL:
			null;

		case Lua.LUA_TBOOLEAN:
			Lua.toboolean(l, v);

		case Lua.LUA_TNUMBER:
			Lua.tonumber(l, v);

		case Lua.LUA_TSTRING:
			var s = Lua.tostring(l, v);
			s == null ? "" : s;

		case Lua.LUA_TTABLE:
			toHaxeObj(l, v);

		
		case Lua.LUA_TFUNCTION:
            Lua.pushvalue(l, v);
            new LuaCallback(cast l, LuaL.ref(l, Lua.LUA_REGISTRYINDEX));

		default:
			if(enableUnsupportedTraces)
				trace('Unsupported Lua return type $luaType');
			null;
	}
}

public static function toHaxeObj(l, i:Int):Any {

	var hasItems = false;
	var array = true;

	loopTable(l, i,{
		hasItems = true;

		if(Lua.type(l, -2) != Lua.LUA_TNUMBER)
			array = false;

		final index = Lua.tonumber(l, -2);

		if(index < 0 || Std.int(index) != index)
			array = false;

	});

	if(!hasItems) return {};

	if(array){

		final v:Array<Dynamic> = [];

		loopTable(l, i,{
			v[Std.int(Lua.tonumber(l, -2)) - 1] = fromLua(l, -1);
		});

		return cast v;

	}

	final v:DynamicAccess<Any> = {};

	loopTable(l, i,{

		switch Lua.type(l, -2){

			case t if(t == Lua.LUA_TSTRING):

				var key = Lua.tostring(l, -2);
				if(key != null) v.set(key, fromLua(l, -1));

			case t if(t == Lua.LUA_TNUMBER):

				v.set(Std.string(Lua.tonumber(l, -2)), fromLua(l, -1));

		}

	});

	return v;
}

public static function callLuaFunction(l, ?func:String, ?args:Array<Dynamic> = null, ?multipleReturns:Bool=false):Dynamic {

	if(func != null)
		Lua.getglobal(l, func);

	if(args != null)
		for(arg in args)
			Convert.toLua(l,arg);

	LuaException.ifErrorThrow(l, Lua.pcall(l, args == null ? 0 : args.length, multipleReturns ? Lua.LUA_MULTRET : 1, 0));

	if(!multipleReturns)
		return fromLua(l, -1);

	final returnArray = [];

	for(i in -(Lua.gettop(l)-1)...0)
		returnArray.push(fromLua(l,i));

	return returnArray;
}

public static function callLuaFuncNoReturns(l, func:String, ?args:Array<Dynamic> = null):Void {

	Lua.getglobal(l, func);

	if(args != null)
		for(arg in args)
			Convert.toLua(l,arg);

	LuaException.ifErrorThrow(l, Lua.pcall(l, args == null ? 0 : args.length, 0, 0));
}

}

@:include('hxcpp.h')
@:native('hx::Anon')
extern class Anon {

@:native('hx::Anon_obj::Create')
public static function create():Anon;

@:native('hx::Anon_obj::Add')
public function add(k:String, v:Any):Void;

}
