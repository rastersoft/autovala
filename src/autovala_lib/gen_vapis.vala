/*
 Copyright 2013 (C) Raster Software Vigo (Sergio Costas)

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

	struct namespaces_element {

		string namespace_s;
		string current_file;
		string filename;
		string[] filenames;
		int major;
		int minor;

		public namespaces_element(string namespace_s) {
			this.namespace_s=namespace_s;
			this.filenames={};
		}
	}



	class ReadVapis:GLib.Object {

		private string[] error_list;
		private Gee.Map<string,namespaces_element?> ?namespaces;

		public ReadVapis(int major, int minor) {

			this.error_list={};
			this.namespaces=new Gee.HashMap<string,namespaces_element?>();

			this.fill_namespaces("/usr/share/vala");
			this.fill_namespaces("/usr/share/vala-%d.%d".printf(major,minor));
			this.fill_namespaces("/usr/local/share/vala");
			this.fill_namespaces("/usr/local/share/vala-%d.%d".printf(major,minor));
		}


		public void add_file(namespaces_element element, string filename, int gir_major, int gir_minor) {
			int c_major;
			int c_minor;
			string file;
			string newfile;

			c_major=gir_major;
			c_minor=gir_minor;

			if (filename.has_suffix(".vapi")) {
				file=filename.substring(0,filename.length-5); // remove the .vapi extension
			} else {
				file=filename;
			}
			element.filenames+=file;
			newfile=file;
			// if the filename has a version number, remove it
			if (Regex.match_simple("-[0-9]+(.[0-9]+)?$",file)) {
				var pos=file.last_index_of("-");
				newfile=file.substring(0,pos);
				// if there is no version number inside, use the one in the filename
				if ((c_major==0)&&(c_minor==0)) {
					var version=file.substring(pos+1);
					pos=version.index_of(".");
					if (pos==-1) { // only one number
						c_major=int.parse(version);
						c_minor=0;
					} else {
						c_major=int.parse(version.substring(0,pos));
						c_minor=int.parse(version.substring(pos+1));
					}
				} else {

				}
			}

			if ((element.current_file=="")||(newfile.length<element.current_file.length)) { // always take the shortest filename
				element.current_file=newfile;
				element.filename=file;
				element.major=c_major;
				element.minor=c_minor;
				//element.checkable=pkgconfigs.contains(file);
				return;
			}
			if (element.current_file==newfile) { // for the same filename, take always the greatest version
				if((c_major>element.major)||((c_major==element.major)&&(c_minor>element.minor))) {
					element.major=c_major;
					element.minor=c_minor;
					element.filename=file;
					//element.checkable=pkgconfigs.contains(file);
					return;
				}
			}
		}

		private void check_vapi_file(string basepath, string file_s) {

			/*
			 * This method checks the namespaces provided by a .vapi file
			 */

			string file=file_s;
			if (file.has_suffix(".vapi")==false) {
				return;
			}
			file=file.substring(0,file_s.length-5); // remove the .vapi extension

			var file_f = File.new_for_path (basepath);
			int gir_major=0;
			int gir_minor=0;
			MatchInfo found_string;
			MatchInfo found_version;
			try {
				var reg_expression=new GLib.Regex("gir_version( )*=( )*\"[0-9]+(.[0-9]+)?\"");
				var reg_expression2=new GLib.Regex("[0-9]+(.[0-9]+)?");
				var dis = new DataInputStream (file_f.read ());
				string line;
				while ((line = dis.read_line (null)) != null) {
					if (reg_expression.match(line,0,out found_string)) {
						if (reg_expression2.match(found_string.fetch(0),0, out found_version)) {
							var version=found_version.fetch(0);
							var pos=version.index_of(".");
							if (pos==-1) { // single number
								gir_major=int.parse(version);
								gir_minor=0;
							} else {
								var elements=version.split(".");
								gir_major=int.parse(elements[0]);
								gir_minor=int.parse(elements[1]);
							}
						}
					}
					if (line.has_prefix("namespace ")) {
						var namespace_s=line.split(" ")[1];
						if (namespace_s=="GLib") { // GLib needs several tricks
							if (file_s.has_prefix("glib-")) {
							} else if (file_s.has_prefix("gio-unix-")) {
								namespace_s="GIO-unix";
							} else if (file_s.has_prefix("gio")) {
								namespace_s="GIO";
							} else if (file_s.has_prefix("gmodule-")) {
								namespace_s="GModule";
							} else if (file_s.has_prefix("gobject-")) {
								namespace_s="GObject";
							} else {
								this.error_list+=_("Unknown file %s uses namespace GLib. Contact the author.").printf(file_s);
								namespace_s="";
							}
						}

						if (namespace_s!="") {
							namespaces_element element;
							if (this.namespaces.has_key(namespace_s)) {
								element=this.namespaces.get(namespace_s);
							} else {
								element=namespaces_element(namespace_s);//(namespace_s);
								this.namespaces.set(namespace_s,element);
							}
							this.add_file(element,file_s,gir_major,gir_minor);
						}
					}
				}
			} catch (Error e) {
				return;
			}
		}

		private void fill_namespaces(string basepath) {

			/*
			 * Fills the NAMESPACES hashmap with a list of each namespace and the files that provides it, and also the "best" one
			 * (bigger version)
			 */
			var newpath=File.new_for_path(Path.build_filename(basepath,"vapi"));
			if (newpath.query_exists()==false) {
				return;
			}
			FileInfo file_info;
			FileEnumerator enumerator;
			try {
				enumerator = newpath.enumerate_children (FileAttribute.STANDARD_NAME+","+FileAttribute.STANDARD_TYPE, 0);
				while ((file_info = enumerator.next_file ()) != null) {
					var fname=file_info.get_name();
					var ftype=file_info.get_file_type();
					if (ftype==FileType.DIRECTORY) {
						continue;
					}
					if (fname.has_suffix(".vapi")==false) {
						continue;
					}
					this.check_vapi_file(Path.build_filename(basepath,"vapi",fname),fname);
				}
			} catch (Error e) {
				return;
			}
		}
	}
}
