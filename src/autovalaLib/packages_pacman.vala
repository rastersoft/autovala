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
						ElementBase.globalData.addWarning(_("Can't find a package for the file %s").printf(element));
						continue;
					}
					if (ls_status != 0) {
						ElementBase.globalData.addWarning(_("Error %d when launching pacman for the file %s").printf(ls_status,element));
						ElementBase.globalData.addWarning(_("Can't find a package for the file %s").printf(element));
						continue;
					}
				} catch (SpawnError e) {
					ElementBase.globalData.addWarning(_("Exception '%s' when launching pacman for the file %s").printf(e.message,element));
					ElementBase.globalData.addWarning(_("Can't find a package for the file %s").printf(element));
					continue;
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

		private void print_key(DataOutputStream of,Gee.Map<string,string> keylist,string key,string val) {

			if (!keylist.has_key(key)) {
				if (-1 == val.index_of_char('\n')) {
					of.put_string("%s=%s\n".printf(key,val));
				} else {
					of.put_string("%s=\"%s\"\n".printf(key,val));
				}
			} else {
				if (-1 == keylist.get(key).index_of_char('\n')) {
					of.put_string("%s=%s\n".printf(key,keylist.get(key)));
				} else {
					of.put_string("%s=\"%s\"\n".printf(key,keylist.get(key)));
				}
			}
		}

		private string? get_md5sum(string name) {

			string[] spawn_args = {"curl", "-L", "--fail", name};
			string[] spawn_env = Environ.get ();
			Pid child_pid;
			int exit_status = 0;

			int standard_output;

			if (!Process.spawn_async_with_pipes ("/",spawn_args, spawn_env, SpawnFlags.SEARCH_PATH | SpawnFlags.DO_NOT_REAP_CHILD, null, out child_pid,	null, out standard_output, null)) {
				return null;
			}

			MainLoop loop = new MainLoop ();

			ChildWatch.add (child_pid, (pid, status) => {
				Process.close_pid (pid);
				exit_status = status;
				loop.quit();
			});

			ssize_t size;
			uint8 buffer[65536];

			var md5 = new GLib.Checksum(ChecksumType.MD5);
			while ((size = Posix.read(standard_output,buffer,65536)) != 0) {
				md5.update(buffer,size);
			}

			loop.run();

			if (exit_status != 0) {
				return null;
			} else {
				return md5.get_string();
			}
		}

		public bool contains_string(string[] haystack, string needle) {
			foreach (var line in haystack) {
				if (line == needle) {
					return true;
				}
			}
			return false;
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
			var has_sources = false;

			string[] invalid_keys = {"pkgver","pkgrel"};

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
							if (!this.contains_string(invalid_keys,multiline_key)) {
								element_keys.set(multiline_key,"\""+multiline_data.strip()+"\"");
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
						if (!this.contains_string(invalid_keys,key)) {
							element_keys.set(key,data.strip());
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

				this.print_key(of,element_keys,"pkgname",this.config.globalData.projectName);
				of.put_string("pkgver=%s\n".printf(this.version));
				of.put_string("pkgrel=1\n");
				this.print_key(of,element_keys,"pkgdesc",this.description.replace("\"",""));
				this.print_key(of,element_keys,"arch","('i686' 'x86_64')");

				if (element_keys.has_key("source")) {
					var sources = element_keys.get("source").replace("(","").replace(")","").split("'");
					string[] l_sources = {};
					string[] l_mdsums  = {};
					foreach (var source in sources) {
						source = source.strip();
						if (source == "") {
							continue;
						}
						var md5sum = this.get_md5sum(source);
						if (md5sum != null) {
							l_sources += source;
							l_mdsums += md5sum;
						} else {
							ElementBase.globalData.addWarning(_("Failed to download %s").printf(source));
						}
					}
					if (l_sources.length != 0) {
						of.put_string("source=(");
						foreach (var source in l_sources) {
							of.put_string(" '%s' ".printf(source));
						}
						of.put_string(")\nmd5sums=(");
						foreach (var sum in l_mdsums) {
							of.put_string(" '%s' ".printf(sum));
						}
						of.put_string(")\n");
						has_sources = true;
					}
				}

				foreach (var key in element_keys.keys) {
					if ((key != "depends") && (key != "makedepends") && (key != "pkgname") && (key != "pkgver") && (key != "pkgrel") && (key != "pkgdesc") && (key != "arch") && (key != "source") && (key != "md5sums")) {
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

				if (has_sources) {
					of.put_string("build() {\n");
					of.put_string("\tcd $srcdir\n");
					of.put_string("\tTMP1=`find | grep -F \"%s\"` \n".printf(GLib.Path.get_basename(this.config.globalData.configFile)));
					of.put_string("\tcd `dirname $TMP1`\n");
					of.put_string("\trm -rf install\n");
					of.put_string("\tmkdir install\n");
					of.put_string("\tcd install\n");
					of.put_string("\tcmake .. -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_INSTALL_LIBDIR=/lib\n");
					of.put_string("\tmake\n");
					of.put_string("}\n\n");
					of.put_string("package() {\n");
					of.put_string("\tcd $srcdir\n");
					of.put_string("\tTMP1=`find | grep -F \"%s\"` \n".printf(GLib.Path.get_basename(this.config.globalData.configFile)));
					of.put_string("\tcd `dirname $TMP1`\n");
					of.put_string("\tcd install\n");
					of.put_string("\tmake DESTDIR=\"$pkgdir/\" install\n");
					of.put_string("}\n\n");
				} else {
					of.put_string("build() {\n");
					of.put_string("\trm -rf ${startdir}/install\n");
					of.put_string("\tmkdir ${startdir}/install\n");
					of.put_string("\tcd ${startdir}/install\n");
					of.put_string("\tcmake .. -DCMAKE_INSTALL_PREFIX=/usr\n");
					of.put_string("\tmake\n}\n\n");
					of.put_string("package() {\n\tcd ${startdir}/install\n\tmake DESTDIR=\"$pkgdir/\" install\n}\n");
				}

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
