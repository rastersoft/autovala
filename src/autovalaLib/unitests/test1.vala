using GLib;

int main() {

	var t = new AutoVala.packages();
	t.init_all(null);

	foreach (var element in t.source_dependencies) {
		GLib.stdout.printf("Sdep: %s\n",element);
	}
	foreach (var element in t.dependencies) {
		GLib.stdout.printf("Dep: %s\n",element);
	}
	return 0;
}
