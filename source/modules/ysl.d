module yslr.modules.ysl;

import std.conv;
import std.array;
import std.stdio;
import std.string;
import yslr.util;
import yslr.environment;

static Variable Reset(string[] args, Environment env) {
	Function[string] noFunctions;
	Module[string]   noModules;
	Scope            noScope; // 420

	env.globals     = noScope; // 420
	env.locals      = cast(Scope[])    [];
	env.returnStack = cast(Variable[]) [];
	env.callStack   = cast(int[])      [];
	env.passStack   = cast(Variable[]) [];
	return [];
}

static Variable GetLine(string[] args, Environment env) {
	int line = parse!int(args[0]);

	if (line !in env.code) {
		stderr.writefln("Error: get_line: Line %d doesn't exist", line);
		throw new YSLError();
	}

	env.returnStack ~= StringToIntArray(env.code[line]);
	return [];
}

static Variable GetLines(string[] args, Environment env) {
	int[] ret;

	int from = -1;
	int to   = -1;

	if (args.length != 0) {
		if (args.length != 2) {
			stderr.writefln("Error: get_lines: Must have either 0 or 2 parameters");
			throw new YSLError();
		}
		if (!args[0].isNumeric() || !args[1].isNumeric()) {
			stderr.writefln("Error: get_lines: Parameters must be numeric");
			throw new YSLError();
		}

		from = parse!int(args[0]);
		to   = parse!int(args[1]);
	}

	foreach (key, ref value ; env.code) {
		if (((from >= 0) && (key < from)) ||((to >= 0) && (key > to))) {
			continue;
		}

		ret ~= key;
	}

	return ret;
}

static Variable AllocLine(string[] args, Environment env) {
	int max;

	foreach (key, ref value ; env.code) {
		if (key > max) max = key;
	}

	env.code[max + 10] = "";
	return [max];
}

static Variable RunYSL(string[] args, Environment env) {
	try {
		env.Interpret(-1, args[0]);
	}
	catch (YSLError) {
		return [0];
	}
	catch (Exception e) {
		stderr.writefln("Exception from %s:%d: %s", e.file, e.line, e.msg);
		stderr.writeln(e.info);
		throw new YSLExit(1);
	}

	return [1];
}

static Variable Pop(string[] args, Environment env) {
	void CheckStack(T)(T[] stack) {
		if (stack.empty()) {
			stderr.writefln("Error: pop: Stack underflow");
			throw new YSLError();
		}
	}

	switch (args[0]) {
		case "return": {
			CheckStack(env.returnStack);
			env.returnStack = env.returnStack[0 .. $ - 1];
			break;
		}
		case "call": {
			CheckStack(env.callStack);
			env.callStack = env.callStack[0 .. $ - 1];
			break;
		}
		case "pass": {
			CheckStack(env.passStack);
			env.passStack = env.passStack[0 .. $ - 1];
			break;
		}
		default: {
			stderr.writefln("Error: pop: Unknown stack '%s'", args[0]);
			throw new YSLError();
		}
	}

	return [];
}

private void PushVariableStack(ref Variable[] stack, string[] args, string name) {
	if (args.length == 1) {
		if (args[0].isNumeric()) {
			stack ~= [parse!int(args[0])];
		}
		else {
			stack ~= args[0].StringToIntArray();
		}
	}
	else {
		Variable res;

		foreach (ref arg ; args) {
			if (!arg.isNumeric()) {
				stderr.writefln("Error: %s: Contents must be numeric", name);
				throw new YSLError();
			}

			res ~= parse!int(arg);
		}

		stack ~= res;
	}
}

static Variable PushReturn(string[] args, Environment env) {
	PushVariableStack(env.returnStack, args, "push_return");
	return [];
}

static Variable PushPass(string[] args, Environment env) {
	PushVariableStack(env.passStack, args, "push_pass");
	return [];
}

static Variable PushCall(string[] args, Environment env) {
	env.callStack ~= parse!int(args[0]);
	return [];
}

static Variable GetIP(string[] args, Environment env) {
	return [env.ip.value.key];
}

Module Module_Ysl() {
	Module ret;
	ret["reset"]       = Function.CreateBuiltIn(true, [], &Reset);
	ret["get_line"]    = Function.CreateBuiltIn(true, [ArgType.Numerical], &GetLine);
	ret["get_lines"]   = Function.CreateBuiltIn(false, [], &GetLines);
	ret["alloc_line"]  = Function.CreateBuiltIn(true, [], &AllocLine);
	ret["run_ysl"]     = Function.CreateBuiltIn(true, [ArgType.Other], &RunYSL);
	ret["pop"]         = Function.CreateBuiltIn(true, [ArgType.Other], &Pop);
	ret["push_return"] = Function.CreateBuiltIn(false, [], &PushReturn);
	ret["push_pass"]   = Function.CreateBuiltIn(false, [], &PushPass);
	ret["push_call"]   = Function.CreateBuiltIn(true, [ArgType.Numerical], &PushCall);
	ret["get_ip"]      = Function.CreateBuiltIn(true, [], &GetIP);
	return ret;
}
