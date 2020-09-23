
let BuildType = 0;
let ShouldBuild = true;
let ShouldRun = false;

const KotlinFiles = [];

const BuildArgs = [];

const GimmickArgs = [];

const Colors = {
	Reset: "\x1b[0m",
	Red: "\x1b[31m"
};

const { exec } = require("child_process");

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

function ProcessArgument(arg) {
	switch(arg.toLowerCase()) {
		case "native":
			BuildType = 0;
			break;
		case "java":
		case "jvm":
			BuildType = 1;
			break;
		case "javascript":
		case "js":
			BuildType = 2;
			break;
		case "runonly":
			ShouldBuild = false;
		case "run":
			ShouldRun = true;
		case "build":
			break;
		case "nowarn":
			BuildArgs.push("-nowarn");
			break;
		case "--":
			return true;
	}
	return false;
};

function LoadKotlinFiles() {
	const fs = require("fs");
	const path = require("path");

	function Walk(dir) {
		const list = fs.readdirSync(dir);
		for(let i = 0; i < list.length; i++) {
			const location = path.join(dir, list[i]);
			const stat = fs.statSync(location);
			if(stat && stat.isDirectory()) {
				Walk(location);
			} else {
				const platform = GetFilePlatformType(location);
				if(platform === -1 || platform === BuildType) {
					KotlinFiles.push(location);
				}
			}
		}
	};

	Walk(path.join(__dirname, "src"));
};

function PrintLine() {
	console.log("--------------------------");
};

function GetFilePlatformType(location) {
	const types = location.split('.').slice(1);
	if(types.length >= 2) {
		switch(types[types.length - 2]) {
			case "native": return 0;
			case "jvm": return 1;
			case "js": return 2;
		}
	}
	return types.length === 0 || types[types.length - 1] !== "kt" ? -2 : -1;
};

function OnRunComplete(err, stdout, stderr) {
	if(stdout) {
		console.log(stdout);
	}
	if(stderr) {
		console.log(stderr);
	}
};

function Run() {
	const ArgList = GimmickArgs.join(" ");
	const path = require("path");
	switch(BuildType) {
		case 0:
			exec("\"" + path.join(__dirname, "bin/Gimmick.exe") + "\" " + ArgList, OnRunComplete);
			break;
		case 1:
			exec("java -jar \"" + path.join(__dirname, "bin/Gimmick-Java.jar") + "\" " + ArgList, OnRunComplete);
			break;
		case 2:
			exec("node " + path.join(__dirname, "bin/JSOutput/Main.js") + " " + ArgList, OnRunComplete);
			break;
	}
};

function OnBuildComplete(err, stdout, stderr) {
	OnRunComplete(err, stdout, stderr);
	if(ShouldRun) {
		PrintLine();
		Run();
	}
};

function Build() {
	const FileList = KotlinFiles.join(" ");
	const ArgList = BuildArgs.join(" ");
	const path = require("path");
	switch(BuildType) {
		case 0:
			exec("kotlinc-native " + FileList + " -o " + path.join(__dirname, "bin/Gimmick.exe") + " " + ArgList, OnBuildComplete);
			break;
		case 1:
			exec("kotlinc-jvm -include-runtime " + FileList + " -d " + path.join(__dirname, "bin/Gimmick-Java.jar") + " " + ArgList, OnBuildComplete);
			break;
		case 2:
			exec("kotlinc-js " + FileList + " -output " + path.join(__dirname, "bin/JSOutput/Gimmick.js") + " " + ArgList, OnBuildComplete);
			break;
	}
};

function Main() {
	LoadArgs();
	if(ShouldBuild) {
		LoadKotlinFiles();
		Build();
	} else if(ShouldRun) {
		Run();
	}
};

Main();
