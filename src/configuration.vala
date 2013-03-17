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

	public enum Config_Type {VALA_BINARY, VALA_LIBRARY, BINARY, ICON, PIXMAP, PO, GLADE, DBUS_SERVICE, DESKTOP, AUTOSTART, EOS_PLUG, SCHEME, INCLUDE}

	public class package_element:GLib.Object {

		public string package;
		public bool do_check;
		public bool automatic;

		public package_element(string package, bool do_check, bool automatic) {
			this.package=package;
			this.do_check=do_check;
			this.automatic=automatic;
		}
	}

	public class config_element:GLib.Object {

		public string path;
		public Config_Type type;
		public string file;
		public string compile_options;
		public string version;
		public bool version_set;
		public bool automatic;
		public Gee.List<package_element ?> packages;

		public config_element(string file, string path, Config_Type type,bool automatic) {
			this.automatic=automatic;
			this.type=type;
			this.file=file;
			this.path=path;
			this.packages=new Gee.ArrayList<package_element ?>();
			this.compile_options="";
			this.version="1.0.0";
			this.version_set=false;
		}

		public void add_package(string pkg,bool to_check,bool automatic) {
			foreach(var p in this.packages) {
				if (p.package==pkg) {
					return;
				}
			}
			var element=new package_element(pkg,to_check,automatic);
			this.packages.add(element);
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
			foreach(var l in this.packages) {
				GLib.stdout.printf("\tPackage: %s",l.package);
				if (l.do_check) {
					GLib.stdout.printf(" (check it)");
				}
				if (l.automatic) {
					GLib.stdout.printf(" (added automatically)");
				}
				GLib.stdout.printf("\n");
			}
			if (this.compile_options!="") {
				GLib.stdout.printf("\tCompile options: %s\n",this.compile_options);
			}
		}
	}

	public class configuration:GLib.Object {

		public string project_name;
		public string config_path;
		public string basepath;
		public Gee.List<config_element ?> configuration_data;
		public string vala_version;

		private string[] error_list;

		private weak config_element ? last_element;
		private int version;
		private int line_number;

		public configuration(string project_name="") {
			this.config_path="";
			this.configuration_data=new Gee.ArrayList<config_element ?>();
			this.last_element=null;
			this.version=0;
			this.project_name=project_name;
			this.error_list={};
			this.vala_version="0.16.0";
		}

		public string[] get_error_list() {
			return this.error_list;
		}

		private string find_configuration(string basepath) {

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

			this.configuration_data=new Gee.ArrayList<config_element ?>();

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
					return true; // no configuration file found
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
					bool automatic=false;
					if ((line[0]=='#')||(line[0]==';')) {
						continue;
					}
					var finalline=line.strip();
					if (finalline=="") {
						continue;
					}
					if (line[0]=='*') { // it's an element added automatically, not by the user
						automatic=true;
						line=line.substring(1).strip();
					}
					if (line.has_prefix("vala_version: ")) {
						var version=line.substring(14).strip();
						if (false==this.check_version(version)) {
							this.error_list+=_("Vala version string not valid. It must be in the form N.N or N.N.N (line %d)").printf(this.line_number);
							error=true;
						} else {
							this.vala_version=version;
						}
						continue;
					}
					if (line.has_prefix("vala_binary: ")) {
						error|=this.add_entry(line.substring(13).strip(),Config_Type.VALA_BINARY,automatic);
						continue;
					}
					if (line.has_prefix("vala_library: ")) {
						error|=this.add_entry(line.substring(14).strip(),Config_Type.VALA_LIBRARY,automatic);
						continue;
					}
					if (line.has_prefix("vala_package: ")) {
						error|=this.add_package(line.substring(14).strip(),false,automatic);
						continue;
					}
					if (line.has_prefix("vala_check_package: ")) {
						error|=this.add_package(line.substring(20).strip(),true,automatic);
						continue;
					}
					if (line.has_prefix("file_version: ")) {
						error|=this.set_version(line.substring(14).strip());
						continue;
					}
					if (line.has_prefix("binary: ")) {
						error|=this.add_entry(line.substring(8).strip(),Config_Type.BINARY,automatic);
						continue;
					}
					if (line.has_prefix("icon: ")) {
						error|=this.add_entry(line.substring(6).strip(),Config_Type.ICON,automatic);
						continue;
					}
					if (line.has_prefix("pixmap: ")) {
						error|=this.add_entry(line.substring(8).strip(),Config_Type.PIXMAP,automatic);
						continue;
					}
					if (line.has_prefix("po: ")) {
						var po_folder=line.substring(4).strip();
						error|=this.add_entry(po_folder,Config_Type.PO,automatic);
						continue;
					}
					if (line.has_prefix("dbus_service: ")) {
						error|=this.add_entry(line.substring(14).strip(),Config_Type.DBUS_SERVICE,automatic);
						continue;
					}
					if (line.has_prefix("desktop: ")) {
						error|=this.add_entry(line.substring(9).strip(),Config_Type.DESKTOP,automatic);
						continue;
					}
					if (line.has_prefix("autostart: ")) {
						error|=this.add_entry(line.substring(11).strip(),Config_Type.AUTOSTART,automatic);
						continue;
					}
					if (line.has_prefix("eos_plug: ")) {
						error|=this.add_entry(line.substring(10).strip(),Config_Type.EOS_PLUG,automatic);
						continue;
					}
					if (line.has_prefix("scheme: ")) {
						error|=this.add_entry(line.substring(8).strip(),Config_Type.SCHEME,automatic);
						continue;
					}
					if (line.has_prefix("glade: ")) {
						error|=this.add_entry(line.substring(7).strip(),Config_Type.GLADE,automatic);
						continue;
					}
					if (line.has_prefix("include: ")) {
						error|=this.add_entry(line.substring(9).strip(),Config_Type.INCLUDE,automatic);
						continue;
					}
					if (line.has_prefix("compile_options: ")) {
						error|=this.add_compiling_options(line.substring(17).strip());
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

		private bool set_version(string version) {

			if (this.last_element==null) {
				this.error_list+=_("Version number after a non vala_binary or vala_library command (line %d)").printf(this.line_number);
				return true;
			}

			if (this.last_element.version_set) {
				this.error_list+=_("Warning: overwriting version number (line %d)").printf(this.line_number);
			}

			if (this.last_element.type==Config_Type.VALA_LIBRARY) {
				// Only accept version string in the format N, N.N or N.N.N (with N a number of one or more digits)
				if (false==this.check_version(version)) {
					this.error_list+=_("Version string not valid for a library. It must be in the form N.N or N.N.N (line %d)").printf(this.line_number);
					return true;
				}
			}
			this.last_element.version=version;
			this.last_element.version_set=true;
			return false;
		}
		
		private bool check_version(string version) {
			return Regex.match_simple("^[0-9]+.[0-9]+(.[0-9]+)?$",version);
		}

		private bool add_compiling_options(string options) {

			if (this.last_element==null) {
				this.error_list+=_("Adding compiling options after a non vala_binary or vala_library command (line %d)").printf(this.line_number);
				return true;
			}

			if (this.last_element.compile_options!="") {
				this.error_list+=_("Warning: overwriting compile options (line %d)").printf(this.line_number);
			}
			this.last_element.compile_options=options;
			return false;
		}

		private bool add_package(string pkg,bool check,bool automatic) {

			if (this.config_path=="") {
				return true;
			}

			if (this.last_element==null) {
				return true;
			}
			this.last_element.add_package(pkg,check,automatic);
			return false;
		}

		public bool add_new_entry(string filename, Config_Type type, bool automatic) {

			if ((type!=Config_Type.VALA_BINARY)&&(type!=Config_Type.VALA_LIBRARY)) {
				return this.add_entry(filename,type,automatic);
			} else {
				return true;
			}
		}

		public bool add_new_binary(string filename, Config_Type type, bool automatic, string[] ?packages=null, string[] ?check_packages=null, string version="", string compile_options="") {
		
			if ((type!=Config_Type.VALA_BINARY)&&(type!=Config_Type.VALA_LIBRARY)) {
				return true;
			}
			
			if ((version!="") && (false==this.check_version(version))) {
				return true;
			}
			
			this.add_entry(filename,type,automatic);
			if (version!="") {
				this.set_version(version);
			}
			bool p_automatic;
			string package;

			if (packages!=null) {
				foreach(var l in packages) {
					if (l[0]=='*') {
						p_automatic=true;
						package=l.substring(1);
					} else{
						p_automatic=false;
						package=l;
					}
					this.add_package(package,false,p_automatic);
				}
			}
			if (check_packages!=null) {
				foreach(var l in check_packages) {
					if (l[0]=='*') {
						p_automatic=true;
						package=l.substring(1);
					} else{
						p_automatic=false;
						package=l;
					}
					this.add_package(package,true,p_automatic);
				}
			}
			if (compile_options!="") {
				this.add_compiling_options(compile_options);
			}
			return false;
		}

		private bool add_entry(string l_filename, Config_Type type,bool automatic) {

			if (this.config_path=="") {
				return true;
			}

			var filename=l_filename;
			if (type==Config_Type.PO) {
				if (false==filename.has_suffix("/")) {
					filename+="/";
				}
			}

			var file=Path.get_basename(filename);
			var path=Path.get_dirname(filename);

			foreach(var e in this.configuration_data) {
				if (e.check(file,path,type)) {
					return false;
				}
			}

			var element=new config_element(file,path,type,automatic);
			this.configuration_data.add(element);
			if ((type==Config_Type.VALA_BINARY)||(type==Config_Type.VALA_LIBRARY)) {
				this.last_element=element;
			} else {
				this.last_element=null;
			}
			return false;
		}

		public void list_all() {
			foreach(var e in this.configuration_data) {
				e.printall();
			}
		}

		public bool save_configuration(string filename="") {

			if(this.project_name=="") {
				this.error_list+=_("Can't store the configuration. Project name not defined.");
				return true;
			}

			if((filename=="")&&(this.config_path=="")) {
				this.error_list+=_("Can't store the configuration. Path not defined.");
				return true;
			}
			if (filename!="") {
				if (GLib.Path.is_absolute(filename)) {
					this.config_path=filename;
				} else {
					this.config_path=GLib.Path.build_filename(GLib.Environment.get_current_dir(),filename);
				}
			}
			this.basepath=GLib.Path.get_dirname(this.config_path);
			GLib.stdout.printf("Paths: %s  %s  y  %s\n",filename,this.config_path,this.basepath);
			var file=File.new_for_path(this.config_path);
			if (file.query_exists()) {
				try {
					file.delete();
				} catch (Error e) {
					this.error_list+=_("Failed to delete the old config file %s").printf(this.config_path);
					return true;
				}
			}
			try {
				var dis = file.create(FileCreateFlags.NONE);
				var data_stream = new DataOutputStream(dis);
				data_stream.put_string("### AutoVala Project ###\n");
				data_stream.put_string("version: 1\n");
				data_stream.put_string("project_name: "+this.project_name+"\n");
				data_stream.put_string("vala_version: "+this.vala_version+"\n");
				this.store_data(Config_Type.PO,data_stream);
				this.store_data(Config_Type.AUTOSTART,data_stream);
				this.store_data(Config_Type.VALA_BINARY,data_stream);
				this.store_data(Config_Type.VALA_LIBRARY,data_stream);
				this.store_data(Config_Type.BINARY,data_stream);
				this.store_data(Config_Type.DESKTOP,data_stream);
				this.store_data(Config_Type.DBUS_SERVICE,data_stream);
				this.store_data(Config_Type.EOS_PLUG,data_stream);
				this.store_data(Config_Type.SCHEME,data_stream);
				this.store_data(Config_Type.GLADE,data_stream);
				this.store_data(Config_Type.ICON,data_stream);
				this.store_data(Config_Type.PIXMAP,data_stream);
				this.store_data(Config_Type.INCLUDE,data_stream);
			} catch (Error e) {
				this.error_list+=_("Can't create the config file %s").printf(this.config_path);
				return true;
			}
			return false;
		}

		private bool store_data(Config_Type type,DataOutputStream data_stream) {

			try {
				foreach(var element in this.configuration_data) {
					if (element.type!=type) {
						continue;
					}
					if (element.automatic) {
						data_stream.put_string("*");
					}
					var fullpathname=Path.build_filename(element.path,element.file);
					switch(element.type) {
					case Config_Type.VALA_BINARY:
					case Config_Type.VALA_LIBRARY:
						if (element.type==Config_Type.VALA_BINARY) {
							data_stream.put_string("vala_binary: "+fullpathname+"\n");
						} else {
							data_stream.put_string("vala_library: "+fullpathname+"\n");
						}
						if (element.version_set) {
							data_stream.put_string("file_version: "+element.version+"\n");
						}
						if (element.compile_options!="") {
							data_stream.put_string("compile_options: "+element.compile_options+"\n");
						}
						foreach(var l in element.packages) {
							if (l.automatic) {
								data_stream.put_string("*");
							}
							if (l.do_check) {
								data_stream.put_string("vala_check_package: ");
							} else {
								data_stream.put_string("vala_package: ");
							}
							data_stream.put_string(Path.build_filename(l.package)+"\n");
						}
						break;
					case Config_Type.BINARY:
						data_stream.put_string("binary: "+fullpathname+"\n");
						break;
					case Config_Type.ICON:
						data_stream.put_string("icon: "+fullpathname+"\n");
						break;
					case Config_Type.PIXMAP:
						data_stream.put_string("pixmap: "+fullpathname+"\n");
						break;
					case Config_Type.PO:
						data_stream.put_string("po: "+element.path+"\n");
						break;
					case Config_Type.GLADE:
						data_stream.put_string("glade: "+fullpathname+"\n");
						break;
					case Config_Type.DBUS_SERVICE:
						data_stream.put_string("dbus_service: "+fullpathname+"\n");
						break;
					case Config_Type.DESKTOP:
						data_stream.put_string("desktop: "+fullpathname+"\n");
						break;
					case Config_Type.AUTOSTART:
						data_stream.put_string("autostart: "+fullpathname+"\n");
						break;
					case Config_Type.EOS_PLUG:
						data_stream.put_string("eos_plug: "+fullpathname+"\n");
						break;
					case Config_Type.SCHEME:
						data_stream.put_string("scheme: "+fullpathname+"\n");
						break;
					case Config_Type.INCLUDE:
						data_stream.put_string("include: "+fullpathname+"\n");
						break;
					}
				}
			} catch (Error e) {
				return true;
			}
			return false;
		}
	}
}

