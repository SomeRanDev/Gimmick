external val process: dynamic;

@Suppress("UNUSED_PARAMETER")
fun main(args: Array<String>) {
	GimmickMain(process.argv.splice(2));
}
