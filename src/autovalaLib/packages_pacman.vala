/*
 Copyright 2013/2014 (C) Raster Software Vigo (Sergio Costas)

 This file is part of AutoVala

 AutoVala is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 3 of the License, or
 (at your option) any later version.

 AutoVala is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>. */

using GLib;
using Gee;
using Posix;

namespace AutoVala {

	private class packages_pacman : packages {

		private Gee.List<string> source_packages;
		private Gee.List<string> binary_packages;

		public bool create_pacman_package() {

			this.write_defaults();

			this.source_packages = new Gee.ArrayList<string>();
			this.binary_packages = new Gee.ArrayList<string>();

			this.fill_dependencies(this.source_dependencies,this.source_packages);
			this.fill_dependencies(this.extra_source_dependencies,this.source_packages);
			this.fill_dependencies(this.dependencies,this.binary_packages);
			this.fill_dependencies(this.extra_dependencies,this.binary_packages);

			if (this.create_pkgbuild(this.config.globalData.projectFolder)) {
				return true;
			}
			return false;
		}

		/**
		 * Uses pacman to discover to which package belongs each of the dependencies
		 * @param origin The list with the dependency files
		 * @param destination The list into which store the packages
		 */
		private void fill_dependencies(Gee.List<string> origin,Gee.List<string> destination) {
			foreach (var element in origin) {
				string[] spawn_args = {"pacman", "-Qo", element};
				string ls_stdout;
				int ls_status;

				try {
					if (!Process.spawn_sync (null,spawn_args,Environ.get(),SpawnFlags.SEARCH_PATH,null,out ls_stdout,null,out ls_status)) {
						ElementBase.globalData.addWarning(_("Failed to launch pacman for the file %s").printf(element));
						return;
					}
					if (ls_status != 0) {
						ElementBase.globalData.addWarning(_("Error %d when launching pacman for the file %s").printf(ls_status,element));
						return;
					}
				} catch (SpawnError e) {
					ElementBase.globalData.addWarning(_("Exception '%s' when launching pacman for the file %s").printf(e.message,element));
					return;
				}

				var pos = ls_stdout.index_of("is owned by");

				if (pos == -1) {
					ElementBase.globalData.addWarning(_("Can't find a package for the file %s").printf(element));
				} else {
					var package_name = ls_stdout.substring(pos+11).strip().split(" ")[0];
					if (!destination.contains(package_name)) {
						destination.add(package_name);
					}
				}
			}
		}

		/**
		 * Creates de PKGBUILD file
		 * @param path The project's path
		 * @return false if everything went OK; true if there was an error
		 */
		private bool create_pkgbuild(string path) {

			Gee.Map<string,string> element_keys = new Gee.HashMap<string,string>();

			var f_control_path = Path.build_filename(path,"PKGBUILD");
			var f_control_path_base = Path.build_filename(this.config.globalData.projectFolder,"packages","PKGBUILD.base");
			var f_control = File.new_for_path(f_control_path);
			var f_control_base = File.new_for_path(f_control_path_base);

			string[] valid_keys = {"pkgname","depends","makedepends","pkgdesc","arch","url","license","groups","provides","conflicts","replaces","backup","options","install","changelog"};

			if (f_control_base.query_exists()) {
				string ? multiline_key = null;
				string ? multiline_data = null;
				var dis = new DataInputStream (f_control_base.read ());
				string line;
				string? key = "";
				string data = "";
				while ((line = dis.read_line (null)) != null) {
					if (multiline_key != null) {
						multiline_data += line.replace("\"","") + "\n";
						if (line.index_of_char('"') != -1) {
							foreach (var l in valid_keys) {
								if (l == multiline_key) {
									element_keys.set(multiline_key,"\""+multiline_data.strip()+"\"");
									break;
								}
							}
							multiline_key = null;
							multiline_data = null;
						}
						continue;
					}
					if (line.strip() == "") {
						continue;
					}
					if (line[0] == '#') {
						continue;
					}
					var pos = line.index_of_char('=');
					if (pos != -1) {
						key = line.substring(0,pos).strip();
						data = line.substring(pos+1);
						if (data[0] == '"') {
							pos = data.index_of_char('"',1);
							if (pos == -1) { // multiline
								multiline_key = key;
								multiline_data = data.substring(1) + "\n";
								continue;
							}
							data = data.replace("\"","");
						}
						foreach (var l in valid_keys) {
							if (l == key) {
								element_keys.set(key,data.strip());
								break;
							}
						}
					}
				}
			}

			try {
				if (f_control.query_exists()) {
					f_control.delete();
				}
			} catch (Error e) {
				ElementBase.globalData.addWarning(_("Failed to delete PKGBUILD file (%s)").printf(e.message));
			}

			try {
				var dis = f_control.create_readwrite(GLib.FileCreateFlags.PRIVATE);
				var of = new DataOutputStream(dis.output_stream as FileOutputStream);
				bool not_first;

				of.put_string("pkgname=%s\n".printf(this.config.globalData.projectName));
				of.put_string("pkgver=%s\n".printf(this.version));
				of.put_string("pkgrel=1\n");
				if (!element_keys.has_key("pkgdesc")) {
					of.put_string("pkgdesc=\"%s\"\n".printf(this.description.replace("\"","")));
				}
				if (!element_keys.has_key("arch")) {
					of.put_string("arch=('i686' 'x86_64')\n");
				}

				foreach (var key in element_keys.keys) {
					if ((key != "depends") && (key != "makedepends")) {
						of.put_string("%s=%s\n".printf(key,element_keys.get(key)));
					}
				}

				var depends = new Gee.ArrayList<string>();
				var makedepends = new Gee.ArrayList<string>();
				if (element_keys.has_key("depends")) {
					var l = element_keys.get("depends").replace("'","").replace("(","").replace(")","").split(" ");
					foreach (var d2 in l) {
						var d = d2.strip();
						if ((d != "") && (!this.binary_packages.contains(d))){
							this.binary_packages.add(d);
						}
					}
				}
				if (element_keys.has_key("makedepends")) {
					var l = element_keys.get("makedepends").replace("'","").replace("(","").replace(")","").split(" ");
					foreach (var d in l) {
						if ((d != "") && (!this.source_packages.contains(d))){
							this.source_packages.add(d);
						}
					}
				}

				of.put_string("depends=(");
				foreach(var dep in this.binary_packages) {
					of.put_string(" '%s'".printf(dep));
				}
				of.put_string(" )\n");
				of.put_string("makedepends=(");
				foreach(var dep in this.source_packages) {
					of.put_string(" '%s'".printf(dep));
				}
				of.put_string(" )\n");

				of.put_string("source=()\n");
				of.put_string("noextract=()\n");
				of.put_string("md5sums=()\n");
				of.put_string("validpgpkeys=()\n\n");
				of.put_string("build() {\n\trm -rf ${startdir}/install\n\tmkdir ${startdir}/install\n\tcd ${startdir}/install\n\tcmake .. -DCMAKE_INSTALL_PREFIX=/usr\n\tmake\n}\n\n");
				of.put_string("package() {\n\tcd ${startdir}/install\n\tmake DESTDIR=\"$pkgdir/\" install\n}\n");

				dis.close();
				Posix.chmod(f_control_path,420); // 644 permissions)
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to write data to debian/control file (%s)").printf(e.message));
				return true;
			}
			return false;
		}
	}
}
