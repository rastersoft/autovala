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

namespace autovala {

enum Config_Type {VALA_BINARY, VALA_LIBRARY, BINARY, ICON, PIXMAP, PO, GLADE, DBUS_SERVICE, DESKTOP, AUTOSTART, EOS_PLUG, SCHEME}

	class config_element:GLib.Object {

		public string path;
		public Config_Type type;
		public string file;
		public string compile_options;
		public string[] packages;
		public string[] check_packages;

		public config_element(string file, string path, Config_Type type) {
			this.type=type;
			this.file=file;
			this.path=path;
			this.packages={};
			this.check_packages={};
			this.compile_options="";
		}

		public void add_package(string pkg,bool to_check) {
			foreach(var p in this.packages) {
				if (p==pkg) {
					return;
				}
			}
			foreach(var p in this.check_packages) {
				if (p==pkg) {
					return;
				}
			}
			if (to_check) {
				this.check_packages+=pkg;
			} else {
				this.packages+=pkg;
			}
		}

		public bool check(string file, string path, Config_Type type) {
			if ((this.file==file)&&(this.path==path)&&(this.type==type)) {
				return true;
			} else {
				return false;
			}
		}

		public void printall() {
			GLib.stdout.printf("Path: %s, file: %s\n",this.path,this.file);
			foreach(var l in this.check_packages) {
				GLib.stdout.printf("    Check package: %s\n",l);
			}
			foreach(var l in this.packages) {
				GLib.stdout.printf("    Package: %s\n",l);
			}
		}
	}

	class configuration:GLib.Object {
	
		public string project_name;
		public string config_path;
		public string basepath;
		public Gee.List<config_element ?> configuration;
		public string[] error_list;

		private weak config_element ? last_element;
		private int version;
		private int line_number;

		public configuration() {
			this.config_path="";
			this.configuration=new Gee.ArrayList<config_element ?>();
			this.last_element=null;
			this.version=0;
			this.project_name="";
			this.error_list={};
		}

		string find_configuration(string basepath) {

			FileEnumerator enumerator;
			FileInfo info_file;
			string full_path="";
			string[] filename;
			string extension;
			FileType typeinfo;

			var directory = File.new_for_path(basepath);
			try {
				enumerator = directory.enumerate_children(FileAttribute.STANDARD_NAME+","+FileAttribute.STANDARD_TYPE,FileQueryInfoFlags.NOFOLLOW_SYMLINKS,null);
			} catch (Error e) {
				return "";
			}
			while ((info_file = enumerator.next_file(null)) != null) {
				full_path="";
				typeinfo=info_file.get_file_type();
				if (typeinfo!=FileType.REGULAR) {
					continue;
				}
				filename=info_file.get_name().split(".");
				extension=filename[filename.length-1];
				if (extension.casefold()!="avprj".casefold()) {
					continue;
				}
				full_path=Path.build_filename(basepath,info_file.get_name());

				// check it's a AutoVala Project file
				var file=File.new_for_path(full_path);
				try {
					var dis = new DataInputStream (file.read ());
					string line;
					line = dis.read_line(null);
					if (!line.has_prefix("### AutoVala Project ###")) {
						continue;
					}
				} catch (Error e) {
					continue;
				}
				break;
			}
			return (full_path);
		}

		public bool read_configuration(string open_file="") {

			this.configuration=new Gee.ArrayList<config_element ?>();

			this.config_path="";
			if (open_file=="") {
				var basepath=GLib.Environment.get_current_dir().split(Path.DIR_SEPARATOR_S);
				int len=basepath.length;
				while(len>=0) {
					var path=Path.DIR_SEPARATOR_S;
					for(var i=0;i<len;i++) {
						path=Path.build_filename(path,basepath[i]);
					}
					this.config_path=this.find_configuration(path);
					if (this.config_path!="") {
						break;
					}
					len--;
				}
				if (this.config_path=="") {
					return false; // no configuration file found
				}
			} else {
				if (GLib.Path.is_absolute(open_file)) {
					this.config_path=open_file;
				} else {
					this.config_path=GLib.Path.build_filename(GLib.Environment.get_current_dir(),open_file);
				}
			}

			this.config_path=Posix.realpath(this.config_path);
			this.basepath=GLib.Path.get_dirname(this.config_path);

			var file=File.new_for_path(this.config_path);
			bool error=false;
			try {
				var dis = new DataInputStream(file.read());

				this.line_number=0;
				string line;
				this.error_list={};

				while((line = dis.read_line(null))!=null) {
					this.line_number++;
					if ((line[0]=='#')||(line[0]==';')) {
						continue;
					}
					var finalline=line.strip();
					if (finalline=="") {
						continue;
					}
					if (line.has_prefix("vala_binary: ")) {
						this.add_entry(line.substring(13).strip(),Config_Type.VALA_BINARY);
						continue;
					}
					if (line.has_prefix("vala_library: ")) {
						this.add_entry(line.substring(14).strip(),Config_Type.VALA_LIBRARY);
						continue;
					}
					if (line.has_prefix("vala_package: ")) {
						this.add_package(line.substring(14).strip(),false);
						continue;
					}
					if (line.has_prefix("vala_check_package: ")) {
						this.add_package(line.substring(20).strip(),true);
						continue;
					}
					if (line.has_prefix("binary: ")) {
						this.add_entry(line.substring(8).strip(),Config_Type.BINARY);
						continue;
					}
					if (line.has_prefix("icon: ")) {
						this.add_entry(line.substring(6).strip(),Config_Type.ICON);
						continue;
					}
					if (line.has_prefix("pixmap: ")) {
						this.add_entry(line.substring(8).strip(),Config_Type.PIXMAP);
						continue;
					}
					if (line.has_prefix("po: ")) {
						var po_folder=line.substring(4).strip();
						if (false==po_folder.has_suffix("/")) {
							po_folder+="/";
						}
						this.add_entry(po_folder,Config_Type.PO);
						continue;
					}
					if (line.has_prefix("dbus_service: ")) {
						this.add_entry(line.substring(14).strip(),Config_Type.DBUS_SERVICE);
						continue;
					}
					if (line.has_prefix("desktop: ")) {
						this.add_entry(line.substring(9).strip(),Config_Type.DESKTOP);
						continue;
					}
					if (line.has_prefix("autostart: ")) {
						this.add_entry(line.substring(11).strip(),Config_Type.AUTOSTART);
						continue;
					}
					if (line.has_prefix("eos_plug: ")) {
						this.add_entry(line.substring(10).strip(),Config_Type.EOS_PLUG);
						continue;
					}
					if (line.has_prefix("scheme: ")) {
						this.add_entry(line.substring(8).strip(),Config_Type.SCHEME);
						continue;
					}
					if (line.has_prefix("glade: ")) {
						this.add_entry(line.substring(7).strip(),Config_Type.GLADE);
						continue;
					}
					if (line.has_prefix("compile_options: ")) {
						this.add_compiling_options(line.substring(17).strip());
						continue;
					}
					if (line.has_prefix("project_name: ")) {
						this.project_name=line.substring(14).strip();
						continue;
					}
					if (line.has_prefix("version: ")) {
						this.version=int.parse(line.substring(9).strip());
						continue;
					}
					error=true;
					this.error_list+=_("Syntax error in line %d").printf(this.line_number);
				}
			} catch (Error e) {
				this.config_path="";
				this.error_list+=_("Can't open configuration file");
				error=true;
			}
			return error;
		}

		private bool add_compiling_options(string options) {

			if (this.last_element==null) {
				this.error_list+=_("Adding compiling options after a non vala_binary or vala_library command (line %d)").printf(this.line_number);
				return false;
			}
			
			if (this.last_element.compile_options!="") {
				this.error_list+=_("Warning: overwriting compile options (line %d)").printf(this.line_number);
			}
			this.last_element.compile_options=options;
			return true;
		}

		private bool add_package(string pkg,bool check) {

			if (this.config_path=="") {
				return false;
			}

			if (this.last_element==null) {
				return false;
			}
			this.last_element.add_package(pkg,check);
			return true;
		}

		private bool add_entry(string filename, Config_Type type) {

			if (this.config_path=="") {
				return false;
			}

			var file=Path.get_basename(filename);
			var path=Path.get_dirname(filename);

			foreach(var e in this.configuration) {
				if (e.check(file,path,type)) {
					return true;
				}
			}

			var element=new config_element(file,path,type);
			this.configuration.add(element);
			if ((type==Config_Type.VALA_BINARY)||(type==Config_Type.VALA_LIBRARY)) {
				this.last_element=element;
			} else {
				this.last_element=null;
			}
			return true;
		}
		
		public void list_all() {
			foreach(var e in this.configuration) {
				e.printall();
			}
		}
	}
}

