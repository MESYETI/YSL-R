module yslr.modules.process;

import std.array;
import std.stdio;
import std.process;
import std.exception;
import ydlib.sortedMap;
import yslr.util;
import yslr.environment;

static Variable GetEnv(string[] args, Environment env) {
	return environment.get(args[0], "").StringToIntArray();
}

static Variable SetEnv(string[] args, Environment env) {
	environment[args[0]] = args[1];
	return [];
}

static Variable Shell(string[] args, Environment env) {
	spawnProcess(["/bin/sh", "-c", args[0]]).wait();
	return [];
}

Module Module_Process() {
	Module ret;
	ret["get_env"] = Function.CreateBuiltIn(true, [ArgType.Other], &GetEnv);
	ret["set_env"] = Function.CreateBuiltIn(true, [ArgType.Other, ArgType.Other], &SetEnv);
	ret["shell"]   = Function.CreateBuiltIn(true, [ArgType.Other], &Shell);
	return ret;
}
