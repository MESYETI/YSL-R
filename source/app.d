module yslr.app;

import std.stdio;
import std.range;
import std.string;
import std.exception;
import yslr.environment;

const string appHelp = "
Usage: %s [FILE] [FLAGS]

Flags:
	-h / --help : Shows this info
	-e / --edit : Loads editor module
";

int main(string[] args) {
	string inFile;
	bool   importEditor = false;

	auto env = new Environment();

	for (size_t i = 1; i < args.length; ++ i) {
		if (args[i][0] == '-') {
			switch (args[i]) {
				case "-h":
				case "--help": {
					writefln(appHelp.strip(), args[0]);
					return 0;
				}
				case "-e":
				case "--edit": {
					importEditor = true;
					break;
				}
				default: {
					stderr.writefln("Unknown flag %s", args[i]);
					return 1;
				}
			}
		}
		else {
			inFile = args[i];
		}
	}

	if (importEditor) {
		env.Import("editor", true);
		writeln("Imported editor");
	}

	if (inFile.empty()) {
		writeln("YSL repl");

		while (true) {
			write("> ");
			stdout.flush();
			string code = readln();

			if (code == "") {
				continue;
			}

			code = code[0 .. $ - 1];

			try {
				env.Interpret(-1, code);
			}
			catch (YSLError) {}
			catch (Exception e) {
				stderr.writefln("Exception from %s:%d: %s", e.file, e.line, e.msg);
				stderr.writeln(e.info);
			}
		}
	}
	else {
		try {
			env.LoadFile(inFile);
		}
		catch (ErrnoException e) {
			stderr.writefln("Failed to load file: %s", e.msg);
			return 1;
		}

		env.Run();
	}

	return 0;
}
