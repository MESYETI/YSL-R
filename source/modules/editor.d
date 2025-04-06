module yslr.modules.editor;

import std.conv;
import std.array;
import std.stdio;
import std.exception;
import ydlib.sortedMap;
import yslr.environment;

private SortedMap!(int, string)[int] buffers;

static Variable List(string[] args, Environment env) {
	foreach (key, ref value ; env.code) {
		writefln("  %.6d: %s", key, value);
	}
	
	return [];
}

static Variable Clear(string[] args, Environment env) {
	env.code = new SortedMap!(int, string);
	return [];
}

static Variable Load(string[] args, Environment env) {
	try {
		env.LoadFile(args[0]);
	}
	catch (ErrnoException e) {
		stderr.writefln("Error: load: Failed to load file: %s", e.msg);
		throw new YSLError();
	}

	return [];
}

static Variable Save(string[] args, Environment env) {
	auto file = File(args[0], "w");

	foreach (key, ref value ; env.code) {
		file.writeln(value);
	}
	return [];
}

static Variable Renum(string[] args, Environment env) {
	string[] lines;

	foreach (key, ref value ; env.code) {
		lines ~= value;
	}

	env.code = new SortedMap!(int, string);

	foreach (i, ref line ; lines) {
		env.code[cast(int) ((i + 1) * 10)] = line;
	}
	return [];
}

static Variable Store(string[] args, Environment env) {
	// create a copy
	auto copy = new SortedMap!(int, string);

	foreach (key, ref value ; env.code) {
		copy[key] = value.idup;
	}

	buffers[parse!int(args[0])] = copy;
	return [];
}

static Variable Restore(string[] args, Environment env) {
	// create a copy
	auto copy = new SortedMap!(int, string);

	foreach (key, ref value ; buffers[parse!int(args[0])]) {
		copy[key] = value.idup;
	}

	env.code = copy;
	return [];
}

Module Module_Editor() {
	Module ret;
	ret["list"]    = Function.CreateBuiltIn(false, [], &List);
	ret["clear"]   = Function.CreateBuiltIn(false, [], &Clear);
	ret["load"]    = Function.CreateBuiltIn(true, [ArgType.Other], &Load);
	ret["save"]    = Function.CreateBuiltIn(true, [ArgType.Other], &Save);
	ret["renum"]   = Function.CreateBuiltIn(true, [], &Renum);
	ret["store"]   = Function.CreateBuiltIn(true, [ArgType.Numerical], &Store);
	ret["restore"] = Function.CreateBuiltIn(true, [ArgType.Numerical], &Restore);
	return ret;
}
