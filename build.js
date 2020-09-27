// ================================================
// * Gimmick Build
// *
// * Robert Borghese
// *
// * Used to quickly and easily build Gimmick mighty fast.
// * Ramen noodles. Tatsy and delicious.
// * Roasted. Toasted. Boiled. Edible.
// * Consume it.
// *
// ================================================
// * Examples:
// *
// *
// * `node build.js hl run -- --src:source --out:output`
// *
// * Builds and runs the hashlink version.
// * Of course, requires hashlink binaries on path.
// *
// *
// * `node build.js node run -- --src:source --out:output`
// *
// * Does the example same thing, but with
// * the NodeJS export. Honestly, I don't know why
// * I wrote "Examples" at the top, they're all
// * pretty much the same except for the platform
// * argument part. There's probably a better way.
// ================================================

// ================================================
// * Build Script Variables
// ================================================

let BuildObj = null;
let ShouldBuild = true;
let ShouldRun = false;

const BuildArgs = [];

const GimmickArgs = [];

const { exec } = require("child_process");

// ================================================
// * Load Arguments
// ================================================

function LoadArgs() {
	const args = process.argv;
	if(args.length >= 3) {
		let ConsumingGimmickArgs = false;
		for(let i = 2; i < args.length; i++) {
			const arg = args[i];
			if(ConsumingGimmickArgs) {
				GimmickArgs.push(arg);
			} else {
				ConsumingGimmickArgs = ProcessArgument(arg);
			}
		}
	}
};

// ================================================
// * Process Argument
// ================================================

function ProcessArgument(arg) {
	switch(arg.toLowerCase()) {
		case "javascript":
		case "js":
			BuildObj = new BuildJs();
			break;
		case "nodejs":
		case "node":
			BuildObj = new BuildNode();
			break;
		case "hashlink":
		case "hl":
			BuildObj = new BuildHl();
			break;
		case "runonly":
			ShouldBuild = false;
		case "run":
			ShouldRun = true;
		case "build":
			break;
		case "--":
			return true;
	}
	return false;
};

// ================================================
// * Print Line
// ================================================

function PrintLine() {
	console.log("========================================");
};

// ================================================
// * Format Arguments
// ================================================

function FormatArguments(args) {
	return args.map(arg => "\"" + arg.replace(/"/g,"\\\"") + "\"").join(" ");
};

// ================================================
// * Run
// ================================================

function Run() {
	const ArgList = FormatArguments(GimmickArgs);
	if(BuildObj) {
		BuildObj.run(ArgList);
	}
};

function OnRunComplete(err, stdout, stderr) {
	if(stdout) {
		console.log(stdout);
	}
	if(stderr) {
		console.log(stderr);
	}
};

// ================================================
// * Build
// ================================================

function Build() {
	const ArgList = BuildArgs.map(arg => `"${arg}"`).join(" ");
	if(BuildObj) {
		BuildObj.build(ArgList);
	}
};

function OnBuildComplete(err, stdout, stderr) {
	OnRunComplete(err, stdout, stderr);
	if(ShouldRun) {
		if(stdout && stderr) {
			PrintLine();
		}
		Run();
	}
};

// ================================================
// * Main
// ================================================

function Main() {
	LoadArgs();
	if(ShouldBuild) {
		Build();
	} else if(ShouldRun) {
		Run();
	}
};

// ================================================
// * Build Classes
// ================================================

class BuildBase {
	build(args) {
	}

	run(args) {
	}
}

class BuildJs extends BuildBase {
	build(args) {
		exec(`haxe builds/build.js.hxml ${args}`, OnBuildComplete);
	}

	run(args) {
		console.warn("The `js` build cannot be run automatically.");
	}
}

class BuildNode extends BuildBase {
	build(args) {
		exec(`haxe builds/build.node.hxml ${args}`, OnBuildComplete);
	}

	run(args) {
		exec(`node bin/node/Gimmick.js ${args}`, OnRunComplete);
	}
}

class BuildHl extends BuildBase {
	build(args) {
		exec(`haxe builds/build.hl.hxml ${args}`, OnBuildComplete);
	}

	run(args) {
		exec(`hl bin/hl/Gimmick.hl ${args}`, OnRunComplete);
	}
}

// ================================================
// * Run Main
// ================================================

Main();
