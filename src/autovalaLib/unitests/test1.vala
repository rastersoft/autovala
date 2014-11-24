using GLib;

int main() {

	var t = new AutoVala.packages_deb();
	t.init_all(null);
	t.create_deb_package();
	t.show_errors();
	return 0;
}
