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
            var f_control_path_base = Path.build_filename(path,"PKGBUILD.base");
			var f_control = File.new_for_path(f_control_path);
			var f_control_base = File.new_for_path(f_control_path_base);

            if (f_control.query_exists() && (!f_control_base.query_exists())) {
                f_control.copy(f_control_base,FileCopyFlags.NOFOLLOW_SYMLINKS);
            }

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
                            element_keys.set(multiline_key,multiline_data.strip());
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
						element_keys.set(key,data.strip());
					}
				}
			}

			try {
			    if (f_control.query_exists()) {
        			f_control.delete();
			    }
			} catch (Error e) {
				ElementBase.globalData.addWarning(_("Failed to delete PKGCONFIG file (%s)").printf(e.message));
			}

			try {
				var dis = f_control.create_readwrite(GLib.FileCreateFlags.PRIVATE);
				var of = new DataOutputStream(dis.output_stream as FileOutputStream);
				bool not_first;

                of.put_string("pkgname=%s\n".printf(this.config.globalData.projectName));
                of.put_string("pkgver=%s\n".printf(this.version));
                of.put_string("pkgrel=1\n");
                if (element_keys.has_key("pkgdesc")) {
                    of.put_string("pkgdesc=\"%s\"\n".printf(element_keys.get("pkgdesc")));
                } else {
                    of.put_string("pkgdesc=\"%s\"\n".printf(this.description.replace("\"","")));
                }
                if (element_keys.has_key("arch")) {
                    of.put_string("arch=%s\n".printf(element_keys.get("arch")));
                } else {
                    of.put_string("arch=('i686' 'x86_64')\n");
                }

                if (element_keys.has_key("url")) {
                    of.put_string("url=%s\n".printf(element_keys.get("url")));
                }
                if (element_keys.has_key("license")) {
                    of.put_string("license=%s\n".printf(element_keys.get("license")));
                }
                if (element_keys.has_key("groups")) {
                    of.put_string("groups=%s\n".printf(element_keys.get("groups")));
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

                if (element_keys.has_key("provides")) {
                    of.put_string("provides=%s\n".printf(element_keys.get("provides")));
                }
                if (element_keys.has_key("conflicts")) {
                    of.put_string("conflicts=%s\n".printf(element_keys.get("conflicts")));
                }
                if (element_keys.has_key("replaces")) {
                    of.put_string("replaces=%s\n".printf(element_keys.get("replaces")));
                }
                if (element_keys.has_key("backup")) {
                    of.put_string("backup=%s\n".printf(element_keys.get("backup")));
                }
                if (element_keys.has_key("options")) {
                    of.put_string("options=%s\n".printf(element_keys.get("options")));
                }
                if (element_keys.has_key("install")) {
                    of.put_string("install=%s\n".printf(element_keys.get("install")));
                }
                if (element_keys.has_key("changelog")) {
                    of.put_string("changelog=%s\n".printf(element_keys.get("changelog")));
                }
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
