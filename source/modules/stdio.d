module yslr.modules.stdio;

import std.conv;
import std.array;
import std.stdio;
import std.algorithm;
import core.stdc.stdio : getchar;
import yslr.util;
import yslr.environment;

private File[int] files;

static Variable Println(string[] args, Environment env) {
	writeln(args.join(" "));
	return [];
}

static Variable Print(string[] args, Environment env) {
	write(args.join(" "));
	return [];
}

static Variable Getch(string[] args, Environment env) {
	return [getchar()];
}

static Variable Input(string[] args, Environment env) {
	return StringToIntArray(readln()[0 .. $ - 1]);
}

static Variable PrintArray(string[] args, Environment env) {
	Variable* var = env.GetVariable(args[0]);

	writeln(*var);
	return [];
}

static Variable FileOpen(string[] args, Environment env) {
	int file = files.keys.length > 0? files.keys().maxElement() + 1 : 0;

	try {
		files[file] = File(args[0], args[1]);
	}
	catch (Exception e) {
		stderr.writefln("Error: file_open: %s", e.msg);
		throw new YSLError();
	}

	return [file];
}

static Variable FileWrite(string[] args, Environment env) {
	int file = parse!int(args[0]);

	if (file !in files) {
		stderr.writefln("Error: file_write: File '%d' doesn't exist", file);
		throw new YSLError();
	}

	try {
		files[file].write(args[1]);
	}
	catch (Exception e) {
		stderr.writefln("Error: file_write: %s", e.msg);
		throw new YSLError();
	}
	files[file].flush();
	return [];
}

static Variable FileRead(string[] args, Environment env) {
	int file = parse!int(args[0]);

	if (file !in files) {
		stderr.writefln("Error: file_write: File '%d' doesn't exist", file);
		throw new YSLError();
	}

	auto res = new ubyte[parse!int(args[1])];

	try {
		files[file].rawRead(res);
	}
	catch (Exception e) {
		stderr.writefln("Error: file_write: %s", e.msg);
		throw new YSLError();
	}

	Variable ret;
	foreach (ref b ; res) {
		ret ~= cast(int) b;
	}
	return ret;
}

static Variable FileTell(string[] args, Environment e) {
	int file = parse!int(args[0]);

	if (file !in files) {
		stderr.writefln("Error: file_write: File '%d' doesn't exist", file);
		throw new YSLError();
	}

	return [cast(int) files[file].tell];
}

static Variable FileSeekSet(string[] args, Environment e) {
	int file = parse!int(args[0]);

	if (file !in files) {
		stderr.writefln("Error: file_seek_set: File '%d' doesn't exist", file);
		throw new YSLError();
	}

	files[file].seek(parse!int(args[1]), SEEK_SET);
	return [];
}

static Variable FileSeekEnd(string[] args, Environment e) {
	int file = parse!int(args[0]);

	if (file !in files) {
		stderr.writefln("Error: file_seek_end: File '%d' doesn't exist", file);
		throw new YSLError();
	}

	files[file].seek(parse!int(args[1]), SEEK_END);
	return [];
}

static Variable FileSeekCur(string[] args, Environment e) {
	int file = parse!int(args[0]);

	if (file !in files) {
		stderr.writefln("Error: file_seek_cur: File '%d' doesn't exist", file);
		throw new YSLError();
	}

	files[file].seek(parse!int(args[1]), SEEK_CUR);
	return [];
}

static Variable FileClose(string[] args, Environment e) {
	int file = parse!int(args[0]);

	if (file !in files) {
		stderr.writefln("Error: file_seek_cur: File '%d' doesn't exist", file);
		throw new YSLError();
	}

	files[file].close();
	files.remove(file);
	return [];
}

Module Module_Stdio() {
	Module ret;
	ret["println"]    = Function.CreateBuiltIn(false, [], &Println);
	ret["print"]      = Function.CreateBuiltIn(false, [], &Print);
	ret["getch"]      = Function.CreateBuiltIn(false, [], &Getch);
	ret["input"]      = Function.CreateBuiltIn(false, [], &Input);
	ret["print_arr"]  = Function.CreateBuiltIn(true, [ArgType.Variable], &PrintArray);
	ret["file_open"]  = Function.CreateBuiltIn(true, [ArgType.Other, ArgType.Other], &FileOpen);
	ret["file_write"] = Function.CreateBuiltIn(true, [ArgType.Numerical, ArgType.Other], &FileWrite);
	ret["file_read"]  = Function.CreateBuiltIn(true, [ArgType.Numerical, ArgType.Numerical], &FileRead);
	ret["file_tell"]  = Function.CreateBuiltIn(true, [ArgType.Numerical], &FileTell);
	ret["file_seek_set"] =
		Function.CreateBuiltIn(true, [ArgType.Numerical, ArgType.Numerical], &FileSeekSet);
	ret["file_seek_end"] = 
		Function.CreateBuiltIn(true, [ArgType.Numerical, ArgType.Numerical], &FileSeekEnd);
	ret["file_seek_cur"] =
		Function.CreateBuiltIn(true, [ArgType.Numerical, ArgType.Numerical], &FileSeekCur);
	ret["file_close"] = Function.CreateBuiltIn(true, [ArgType.Numerical], &FileClose);
	return ret;
}
