/*
 * Copyright 2013/2014 (C) Raster Software Vigo (Sergio Costas)
 *
 * This file is part of AutoVala
 *
 * AutoVala is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * AutoVala is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>. */

using GLib;
using Gee;
using Posix;

namespace AutoVala {
	private class packages_deb : packages {
		private Gee.List<string> source_packages;
		private Gee.List<string> binary_packages;
		private string projectName;
		private int last_size;

		public bool create_deb_package() {
			// adjust project name to Debian conventions (only letters, numbers, '+', '-' and '.'
			this.projectName = "";
			for (int i = 0; i < this.config.globalData.projectName.length; i++) {
				var c = this.config.globalData.projectName.get_char(i);
				if (c.isspace()) {
					continue;
				}
				if ((c.isalnum()) || (c == '.') || (c == '+') || (c == '-')) {
					this.projectName += c.to_string();
					continue;
				}
				if ((c == ',') || (c == ':') || (c == ';')) {
					this.projectName += ".";
					continue;
				}
				this.projectName += "-";
			}

			this.write_defaults();

			this.source_packages = new Gee.ArrayList<string>();
			this.binary_packages = new Gee.ArrayList<string>();

			// These packages are always needed to build this package
			this.source_packages.add("build-essential");
			this.source_packages.add("po-debconf");

			var path  = Path.build_filename(this.config.globalData.projectFolder, "debian");
			var fpath = File.new_for_path(path);

			try {
				fpath.make_directory_with_parents();
			} catch (Error e) {
			}

			this.last_size = 0;
			this.fill_dependencies(this.source_dependencies, this.source_packages);
			this.fill_dependencies(this.extra_source_dependencies, this.source_packages);
			this.fill_dependencies(this.dependencies, this.binary_packages);
			this.fill_dependencies(this.extra_dependencies, this.binary_packages);

			this.source_packages = this.filter_dependencies(this.source_packages);
			this.binary_packages = this.filter_dependencies(this.binary_packages);
			print("\n");

			if (this.create_control(path)) {
				return true;
			}
			if (this.create_rules(path)) {
				return true;
			}
			if (this.create_preinst(path)) {
				return true;
			}
			if (this.create_prerm(path)) {
				return true;
			}
			if (this.create_postinst(path)) {
				return true;
			}
			if (this.create_postrm(path)) {
				return true;
			}
			if (this.create_compat(path)) {
				return true;
			}
			if (this.create_changelog(path)) {
				return true;
			}
			return false;
		}

		private void print_single_line(string line) {

			var output_str = line;
			var tmp_size = output_str.length;
			if (this.last_size != 0) {
				for (int i = tmp_size; i < last_size; i++) {
					output_str += " ";
				}
			}
			this.last_size = tmp_size;
			print(output_str + "\r");
		}

		/**
		 * Removes the packages that are already in the dependencies of other packages
		 * @param dependencies The list with the current dependencies
		 * @return a new list with the unneeded dependencies removed
		 */
		private Gee.List<string> filter_dependencies(Gee.List<string> dependencies) {
			var      out_dependencies     = new Gee.ArrayList<string>();
			var      current_dependencies = new Gee.ArrayList<string>();
			string[] current_environment  = {};
			foreach (var e in Environ.get()) {
				if (e.has_prefix("LANG=")) {
					current_environment += "LANG=en_US.UTF-8";
				} else {
					current_environment += e;
				}
			}

			foreach (var dep in dependencies) {
				this.print_single_line(_("Filtering %s").printf(dep));
				string[] spawn_args = { "apt", "depends", dep };
				string   ls_stdout;
				string   ls_stderr;
				int      ls_status;

				try {
					if (!Process.spawn_sync(null, spawn_args, current_environment, SpawnFlags.SEARCH_PATH, null, out ls_stdout, out ls_stderr, out ls_status)) {
						ElementBase.globalData.addWarning(_("Failed to launch apt for the file %s").printf(dep));
						continue;
					}
					if (ls_status != 0) {
						ElementBase.globalData.addWarning(_("Error %d when launching apt for the file %s").printf(ls_status, dep));
						continue;
					}
				} catch (SpawnError e) {
					ElementBase.globalData.addWarning(_("Exception '%s' when launching apt for the file %s").printf(e.message, dep));
					continue;
				}
				foreach (var line in ls_stdout.split("\n")) {
					var elements = line.split(":");
					if (elements.length < 2) {
						continue;
					}
					if (elements[0].strip() != "Depends") {
						continue;
					}
					var package = elements[1].strip().split(" ")[0];
					if (!current_dependencies.contains(package)) {
						current_dependencies.add(package);
					}
				}
			}
			// Now we have all the dependencies already resolved by these packages in current_dependencies,
			// so we can remove the original packages that already are dependencies for other packages
			foreach (var dep in dependencies) {
				if (current_dependencies.contains(dep)) {
					continue;
				}
				out_dependencies.add(dep);
			}
			return out_dependencies;
		}

		/**
		 * Uses dpkg to discover to which package belongs each of the dependencies
		 * @param origin The list with the dependency files
		 * @param destination The list into which store the packages
		 */
		private void fill_dependencies(Gee.List<string> origin, Gee.List<string> destination) {
			var current_environment = Environ.get();
			foreach (var element in origin) {
				this.print_single_line(_("Finding package for %s").printf(element));
				string[] spawn_args = { "dpkg", "-S", element };
				string   ls_stdout;
				int      ls_status;

				try {
					if (!Process.spawn_sync(null, spawn_args, current_environment, SpawnFlags.SEARCH_PATH, null, out ls_stdout, null, out ls_status)) {
						ElementBase.globalData.addWarning(_("Failed to launch dpkg for the file %s").printf(element));
						ElementBase.globalData.addWarning(_("Can't find a package for the file %s").printf(element));
						continue;
					}
					if (ls_status != 0) {
						ElementBase.globalData.addWarning(_("Error %d when launching dpkg for the file %s").printf(ls_status, element));
						ElementBase.globalData.addWarning(_("Can't find a package for the file %s").printf(element));
						continue;
					}
				} catch (SpawnError e) {
					ElementBase.globalData.addWarning(_("Exception '%s' when launching dpkg for the file %s").printf(e.message, element));
					ElementBase.globalData.addWarning(_("Can't find a package for the file %s").printf(element));
					continue;
				}
				var elements = ls_stdout.split(":");
				if (elements.length == 0) {
					ElementBase.globalData.addWarning(_("Can't find a package for the file %s").printf(element));
				} else if (!destination.contains(elements[0])) {
					destination.add(elements[0]);
				}
			}
		}

		private void print_key(DataOutputStream of, Gee.Map<string, string> keylist, string key, string val) throws GLib.IOError {
			if (!keylist.has_key(key)) {
				of.put_string("%s: %s\n".printf(key, val));
			} else {
				of.put_string("%s: %s\n".printf(key, keylist.get(key)));
			}
		}

		/**
		 * Creates de debian/control file
		 * @param path The 'debian' path
		 * @return false if everything went OK; true if there was an error
		 */
		private bool create_control(string path) {
			Gee.Map<string, string> source_keys = new Gee.HashMap<string, string>();
			Gee.Map<string, string> binary_keys = new Gee.HashMap<string, string>();

			var f_control_path = Path.build_filename(path, "control");
			var f_control      = File.new_for_path(f_control_path);

			try {
				if (f_control.query_exists()) {
					string[] not_valid_keys = { "Version", "Depends", "Build-Depends", "Maintainer" };
					bool     source         = true;
					var      dis            = new DataInputStream(f_control.read());
					string   line;
					string ? key = "";
					string data = "";
					while ((line = dis.read_line(null)) != null) {
						if (line == "") {
							source = false;
							key    = null;
							continue;
						}
						if (line[0] == '#') {
							continue;
						}
						if ((line[0] == ' ') || (line[0] == '\t')) {
							if (key == null) {
								continue;
							}
							bool found = false;
							foreach (var l in not_valid_keys) {
								if (l == key) {
									found = true;
									break;
								}
							}
							if (!found) {
								if (source) {
									data = source_keys.get(key);
								} else {
									data = binary_keys.get(key);
								}
								data += "\n" + line;
								if (source) {
									source_keys.set(key, data);
								} else {
									binary_keys.set(key, data);
								}
							}
							continue;
						}
						var pos = line.index_of_char(':');
						if (pos == -1) {
							continue;
						}
						key  = line.substring(0, pos).strip();
						data = line.substring(pos + 1).strip();
						bool found = false;
						foreach (var l in not_valid_keys) {
							if (l == key) {
								found = true;
								break;
							}
						}
						if (!found) {
							if (source) {
								source_keys.set(key, data);
							} else {
								binary_keys.set(key, data);
							}
						}
						continue;
					}
				}
			} catch (Error e) {
				ElementBase.globalData.addWarning(_("Failed to delete debian/control file (%s)").printf(e.message));
			}
			if (f_control.query_exists()) {
				try{
					f_control.delete();
				} catch (GLib.Error e) {
					ElementBase.globalData.addWarning(_("Failed to delete debian/control file (%s)").printf(e.message));
				}
			}
			try {
				var  dis = f_control.create_readwrite(GLib.FileCreateFlags.PRIVATE);
				var  of  = new DataOutputStream(dis.output_stream as FileOutputStream);
				bool not_first;

				this.print_key(of, source_keys, "Source", this.projectName);
				this.print_key(of, source_keys, "Maintainer", "%s <%s>".printf(this.author_package, this.email_package));
				this.print_key(of, source_keys, "Priority", "optional");
				this.print_key(of, source_keys, "Section", "misc");
				this.print_key(of, source_keys, "Standards-Version", "4.0.0");

				foreach (var key in source_keys.keys) {
					if ((key == "Source") || (key == "Maintainer") || (key == "Priority") || (key == "Section") || (key == "Build-Depends") || (key == "Standards-Version")) {
						continue;
					}
					of.put_string("%s: %s\n".printf(key, source_keys.get(key)));
				}

				of.put_string("Build-Depends: ");
				not_first = false;
				foreach (var element in this.source_packages) {
					if (not_first) {
						of.put_string(", ");
					}
					not_first = true;
					of.put_string(element);
					if (element == "valac") {
						of.put_string(" (>=%d.%d)".printf(this.config.globalData.valaVersionMajor, this.config.globalData.valaVersionMinor));
					}
				}
				of.put_string("\n\n");

				this.print_key(of, binary_keys, "Package", this.projectName);
				this.print_key(of, binary_keys, "Architecture", "any");
				of.put_string("Version: %s\n".printf(this.version));

				foreach (var key in binary_keys.keys) {
					if ((key == "Package") || (key == "Architecture") || (key == "Version") || (key == "Depends") || (key == "Description")) {
						continue;
					}
					of.put_string("%s: %s\n".printf(key, binary_keys.get(key)));
				}

				of.put_string("Depends: ");
				not_first = false;

				foreach (var element in this.binary_packages) {
					if (not_first) {
						of.put_string(", ");
					}
					not_first = true;
					of.put_string(element);
				}

				of.put_string("\n");
				if (!binary_keys.has_key("Description")) {
					of.put_string("Description:");
					foreach (var line in this.description.split("\n")) {
						if (line.strip() == "") {
							line = ".";
						}
						of.put_string(" %s\n".printf(line));
					}
				} else {
					of.put_string("Description: %s\n".printf(binary_keys.get("Description")));
				}
				dis.close();
				// 644 permissions)
				Posix.chmod(f_control_path, 420);
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to write data to debian/control file (%s)").printf(e.message));
				return true;
			}
			return false;
		}

		private void add_package_name(string[] elements, bool building) {
			foreach (var dep in elements) {
				var fulldep = dep.strip();
				if (fulldep == "") {
					continue;
				}
				if (fulldep.index_of_char('|') != -1) {
					if (building) {
						this.source_packages.add(fulldep);
					} else {
						this.binary_packages.add(fulldep);
					}
					continue;
				}
				var pos  = fulldep.index_of_char('(');
				var dep2 = "";
				if (pos != -1) {
					dep2 = fulldep.substring(0, pos).strip();
				} else {
					dep2 = fulldep;
				}
				if (building) {
					if (this.source_packages.index_of(dep2) == -1) {
						this.source_packages.add(fulldep);
					}
				} else {
					if (this.binary_packages.index_of(dep2) == -1) {
						this.binary_packages.add(fulldep);
					}
				}
			}
		}

		/**
		 * Creates de debian/rules file
		 * @param path The 'debian' path
		 * @return false if everything went OK; true if there was an error
		 */
		private bool create_rules(string path) {
			var fname   = Path.build_filename(path, "rules");
			var f_rules = File.new_for_path(fname);
			// if the file already exists, don't touch it
			if (!f_rules.query_exists()) {
				try {
					var dis = f_rules.create_readwrite(GLib.FileCreateFlags.PRIVATE);
					var of  = new DataOutputStream(dis.output_stream as FileOutputStream);

					var o_rules = File.new_for_path(Path.build_filename(AutoValaConstants.PKGDATADIR, "debian", "rules"));
					var dis2    = new DataInputStream(o_rules.read());

					string line;
					while ((line = dis2.read_line(null)) != null) {
						var line2 = line.replace("%(PROJECT_NAME)", this.config.globalData.projectName);
						of.put_string(line2 + "\n");
					}
					dis.close();
					dis2.close();
					// 755 permissions)
					Posix.chmod(fname, 493);
				} catch (Error e) {
					ElementBase.globalData.addError(_("Failed to write data to debian/rules file (%s)").printf(e.message));
					try {
						f_rules.delete();
					} catch (GLib.Error e) {
						ElementBase.globalData.addError(_("Failed to delete invalid debian/rules file (%s)").printf(e.message));
					}
					return true;
				}
			}
			// 755 permissions (octal)
			GLib.FileUtils.chmod(fname, 0x1ED);
			return false;
		}

		/**
		 * Creates de debian/preinst file
		 * @param path The 'debian' path
		 * @return false if everything went OK; true if there was an error
		 */
		private bool create_preinst(string path) {
			if (this.pre_inst.length == 0) {
				return false;
			}

			var f_rules_path = Path.build_filename(path, "preinst");
			var f_rules      = File.new_for_path(f_rules_path);
			if (f_rules.query_exists()) {
				// if the file already exists, don't touch it
				return false;
			}

			try {
				var dis = f_rules.create_readwrite(GLib.FileCreateFlags.PRIVATE);
				var of  = new DataOutputStream(dis.output_stream as FileOutputStream);

				of.put_string("#!/bin/sh\n\n");

				foreach (var line in this.pre_inst) {
					of.put_string(line + "\n");
				}
				dis.close();
				// 755 permissions)
				Posix.chmod(f_rules_path, 493);
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to write data to debian/preinst file (%s)").printf(e.message));
				try {
					f_rules.delete();
				} catch (GLib.Error e) {
					ElementBase.globalData.addError(_("Failed to delete invalid debian/preinst file (%s)").printf(e.message));
				}
				return true;
			}
			return false;
		}

		/**
		 * Creates de debian/prerm file
		 * @param path The 'debian' path
		 * @return false if everything went OK; true if there was an error
		 */
		private bool create_prerm(string path) {
			if (this.pre_rm.length == 0) {
				return false;
			}

			var f_rules_path = Path.build_filename(path, "prerm");
			var f_rules      = File.new_for_path(f_rules_path);
			if (f_rules.query_exists()) {
				// if the file already exists, don't touch it
				return false;
			}

			try {
				var dis = f_rules.create_readwrite(GLib.FileCreateFlags.PRIVATE);
				var of  = new DataOutputStream(dis.output_stream as FileOutputStream);

				of.put_string("#!/bin/sh\n\n");

				foreach (var line in this.pre_rm) {
					of.put_string(line + "\n");
				}
				dis.close();
				// 755 permissions)
				Posix.chmod(f_rules_path, 493);
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to write data to debian/prerm file (%s)").printf(e.message));
				try {
					f_rules.delete();
				} catch (GLib.Error e) {
					ElementBase.globalData.addError(_("Failed to delete invalid debian/prerm file (%s)").printf(e.message));
				}
				return true;
			}
			return false;
		}

		/**
		 * Creates de debian/postinst file
		 * @param path The 'debian' path
		 * @return false if everything went OK; true if there was an error
		 */
		private bool create_postinst(string path) {
			if (this.post_inst.length == 0) {
				return false;
			}

			var f_rules_path = Path.build_filename(path, "postinst");
			var f_rules      = File.new_for_path(f_rules_path);
			if (f_rules.query_exists()) {
				// if the file already exists, don't touch it
				return false;
			}

			try {
				var dis = f_rules.create_readwrite(GLib.FileCreateFlags.PRIVATE);
				var of  = new DataOutputStream(dis.output_stream as FileOutputStream);

				of.put_string("#!/bin/sh\n\nset -e\n\n");

				foreach (var line in this.post_inst) {
					of.put_string(line + "\n");
				}
				dis.close();
				// 755 permissions
				Posix.chmod(f_rules_path, 493);
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to write data to debian/postinst file (%s)").printf(e.message));
				try {
					f_rules.delete();
				} catch (GLib.Error e) {
					ElementBase.globalData.addError(_("Failed to delete invalid debian/postinst file (%s)").printf(e.message));
				}
				return true;
			}
			return false;
		}

		/**
		 * Creates de debian/postrm file
		 * @param path The 'debian' path
		 * @return false if everything went OK; true if there was an error
		 */
		private bool create_postrm(string path) {
			if (this.post_rm.length == 0) {
				return false;
			}

			var f_rules_path = Path.build_filename(path, "postrm");
			var f_rules      = File.new_for_path(f_rules_path);
			if (f_rules.query_exists()) {
				// if the file already exists, don't touch it
				return false;
			}

			try {
				var dis = f_rules.create_readwrite(GLib.FileCreateFlags.PRIVATE);
				var of  = new DataOutputStream(dis.output_stream as FileOutputStream);

				of.put_string("#!/bin/sh\n\nset -e\n\n");

				foreach (var line in this.post_rm) {
					of.put_string(line + "\n");
				}
				dis.close();
				// 755 permissions
				Posix.chmod(f_rules_path, 493);
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to write data to debian/postrm file (%s)").printf(e.message));
				try {
					f_rules.delete();
				} catch (GLib.Error e) {
					ElementBase.globalData.addError(_("Failed to delete invalid debian/postrm file (%s)").printf(e.message));
				}
				return true;
			}
			return false;
		}

/**
		 * Creates de debian/compat file
		 * @param path The 'debian' path
		 * @return false if everything went OK; true if there was an error
		 */
		private bool create_compat(string path) {

			var f_rules_path = Path.build_filename(path, "compat");
			var f_rules      = File.new_for_path(f_rules_path);
			if (f_rules.query_exists()) {
				// if the file already exists, don't touch it
				return false;
			}

			try {
				var dis = f_rules.create_readwrite(GLib.FileCreateFlags.PRIVATE);
				var of  = new DataOutputStream(dis.output_stream as FileOutputStream);

				of.put_string("10\n");
				dis.close();
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to write data to debian/compat file (%s)").printf(e.message));
				try {
					f_rules.delete();
				} catch (GLib.Error e) {
					ElementBase.globalData.addError(_("Failed to delete invalid debian/compat file (%s)").printf(e.message));
				}
				return true;
			}
			return false;
		}

		/**
		 * Creates de debian/changelog file
		 * @param path The 'debian' path
		 * @return false if everything went OK; true if there was an error
		 */
		private bool create_changelog(string path) {
			var fname       = Path.build_filename(path, "changelog");
			var f_changelog = File.new_for_path(fname);

			string[] lines         = {};
			bool     version_found = false;

			// if the file already exists, check for the current version number
			if (f_changelog.query_exists()) {
				try {
					var    dis = new DataInputStream(f_changelog.read());
					string line;
					while ((line = dis.read_line(null)) != null) {
						lines += line;
						if (version_found) {
							continue;
						}
						if (line.length == 0) {
							continue;
						}
						if ((line[0] == ' ') || (line[0] == '\t')) {
							continue;
						}
						var pos1 = line.index_of_char('(');
						if (pos1 == -1) {
							continue;
						}
						var pos2 = line.index_of_char(')', pos1);
						if (pos2 == -1) {
							continue;
						}
						var version = line.substring(pos1 + 1, pos2 - pos1 - 1);
						var pos3    = version.last_index_of_char('-');
						if (pos3 != -1) {
							// remove the debian_revision field
							version = version.substring(0, pos3);
						}
						if (version == this.version) {
							version_found = true;
						}
					}
					dis.close();
					f_changelog.delete();
				} catch (Error e) {
					ElementBase.globalData.addError(_("Failed to delete old debian/changelog file (%s)").printf(e.message));
					return true;
				}
			}

			try {
				var dis = f_changelog.create_readwrite(GLib.FileCreateFlags.PRIVATE);
				var of  = new DataOutputStream(dis.output_stream as FileOutputStream);

				if (!version_found) {
					var    now   = new GLib.DateTime.now_local();
					string day   = "";
					string month = "";
					switch (now.get_day_of_week()) {
					case 1:
						day = "Mon";
						break;

					case 2:
						day = "Tue";
						break;

					case 3:
						day = "Wed";
						break;

					case 4:
						day = "Thu";
						break;

					case 5:
						day = "Fri";
						break;

					case 6:
						day = "Sat";
						break;

					case 7:
						day = "Sun";
						break;
					}
					switch (now.get_month()) {
					case 1:
						month = "Jan";
						break;

					case 2:
						month = "Feb";
						break;

					case 3:
						month = "Mar";
						break;

					case 4:
						month = "Apr";
						break;

					case 5:
						month = "May";
						break;

					case 6:
						month = "Jun";
						break;

					case 7:
						month = "Jul";
						break;

					case 8:
						month = "Aug";
						break;

					case 9:
						month = "Sep";
						break;

					case 10:
						month = "Oct";
						break;

					case 11:
						month = "Nov";
						break;

					case 12:
						month = "Dec";
						break;
					}

					var  offset  = now.get_utc_offset();
					int  offset1 = (int) (offset / GLib.TimeSpan.HOUR);
					int  offset2 = (int) ((offset % GLib.TimeSpan.HOUR) / GLib.TimeSpan.MINUTE);
					char sign    = '+';
					if (offset1 < 0) {
						sign    = '-';
						offset1 = -offset1;
					}
					if (offset2 < 0) {
						sign    = '-';
						offset2 = -offset2;
					}
					of.put_string("%s (%s-%s1) %s; urgency=low\n\n  * Changes made\n\n -- %s <%s>  %s, %02d %s %04d %02d:%02d:%02d %c%02d%02d\n\n".printf(this.config.globalData.projectName,
					                                                                                                                                      this.version, this.distro_name, this.distro_version_name, this.author_package, this.email_package,
					                                                                                                                                      day, now.get_day_of_month(), month, now.get_year(), now.get_hour(), now.get_minute(), now.get_second(), sign, offset1, offset2));
				}
				foreach (var line in lines) {
					of.put_string(line + "\n");
				}
				dis.close();
				// 644 permissions)
				Posix.chmod(fname, 420);
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to write data to debian/changelog file (%s)").printf(e.message));
				try {
					f_changelog.delete();
				} catch (Error e) {
					ElementBase.globalData.addError(_("Failed to delete invalid debian/changelog file (%s)").printf(e.message));
					return true;
				}
				return true;
			}

			return false;
		}
	}
}
