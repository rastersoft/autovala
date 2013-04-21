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

// project version=0.14

namespace AutoVala {

	public enum Config_Type {VALA_BINARY, VALA_LIBRARY, BINARY, ICON, PIXMAP, PO, GLADE, DBUS_SERVICE, DESKTOP, AUTOSTART,
							 EOS_PLUG, SCHEME, DATA, DOC, INCLUDE, IGNORE}

	public enum package_type {no_check, do_check, local}

	public class package_element:GLib.Object {
		public string package;
		public package_type type;
		public bool automatic;

		public package_element(string package, package_type type, bool automatic) {
			this.package=package;
			this.type=type;
			this.automatic=automatic;
		}
	}

	public class source_element:GLib.Object {
		public string source;
		public bool automatic;

		public source_element(string source, bool automatic) {
			this.source=source;
			this.automatic=automatic;
		}
	}

	public class vapi_element:GLib.Object {
		public string vapi;
		public bool automatic;

		public vapi_element(string vapi, bool automatic) {
			this.vapi=vapi;
			this.automatic=automatic;
		}
	}

	public class config_element:GLib.Object {

		public string path;
		public Config_Type type;
		public string file;
		public string compile_options;
		public string icon_path;
		public string version;
		public bool version_set;
		public bool version_manually_set;
		public bool automatic;
		public Gee.List<package_element ?> packages;
		public Gee.List<source_element ?> sources;
		public Gee.List<vapi_element ?> vapis;
		public string current_namespace;
		public bool namespace_manually_set;
		public bool processed;

		public config_element(string file, string path, Config_Type type,bool automatic,string icon_path) {
			this.automatic=automatic;
			this.type=type;
			this.file=file;
			this.path=path;
			this.icon_path=icon_path;
			this.packages=new Gee.ArrayList<package_element ?>();
			this.sources=new Gee.ArrayList<source_element ?>();
			this.vapis=new Gee.ArrayList<vapi_element ?>();
			this.compile_options="";
			this.version="1.0.0";
			this.version_set=false;
			this.version_manually_set=false;
			this.current_namespace="";
			this.namespace_manually_set=false;
		}

		public void clear_automatic() {
			var tmp_packages=new Gee.ArrayList<package_element ?>();
			foreach (var p in this.packages) {
				if (p.automatic==false) {
					tmp_packages.add(p);
				}
			}
			this.packages=tmp_packages;
			var tmp_sources=new Gee.ArrayList<source_element ?>();
			foreach (var s in this.sources) {
				if (s.automatic==false) {
					tmp_sources.add(s);
				}
			}
			this.sources=tmp_sources;
			if (this.namespace_manually_set==false) {
				this.current_namespace="";
			}
			if (this.version_manually_set==false) {
				this.version="1.0.0";
				this.version_set=false;
			}
		}

		public void set_namespace(string current_namespace,bool automatic) {
			this.current_namespace=current_namespace;
			if (automatic==false) {
				this.namespace_manually_set=true;
				this.transform_to_non_automatic();
			}
		}

		public void set_version(string version,bool automatic) {
			this.version=version;
			this.version_set=true;
			if (automatic==false) {
				this.version_manually_set=true;
				this.transform_to_non_automatic();
			}
		}

		public void set_compile_options(string options) {
			this.compile_options=options;
			this.transform_to_non_automatic();
		}

		private void transform_to_non_automatic() {

			this.automatic=false;
			/*foreach(var l in this.packages) {
				l.automatic=false;
			}*/
		}

		public void add_source(string source,bool automatic) {

			// adding a non-automatic source to an automatic binary transforms this binary to non-automatic
			if ((automatic==false)&&(this.automatic==true)) {
				this.transform_to_non_automatic();
			}

			foreach(var s in this.sources) {
				if (s.source==source) {
					return;
				}
			}
			var element=new source_element(source,automatic);
			this.sources.add(element);
		}

		public void add_vapi(string vapi,bool automatic) {

			// adding a non-automatic source to an automatic binary transforms this binary to non-automatic
			if ((automatic==false)&&(this.automatic==true)) {
				this.transform_to_non_automatic();
			}

			foreach(var s in this.vapis) {
				if (s.vapi==vapi) {
					return;
				}
			}
			var element=new vapi_element(vapi,automatic);
			this.vapis.add(element);
		}

		public void add_package(string pkg,package_type type,bool automatic) {

			// adding a non-automatic package to an automatic binary transforms this binary to non-automatic
			if ((automatic==false)&& (this.automatic==true)) {
				this.transform_to_non_automatic();
			}

			foreach(var p in this.packages) {
				if (p.package==pkg) {
					return;
				}
			}
			var element=new package_element(pkg,type,automatic);
			this.packages.add(element);
		}

		public bool check(string file, string path, Config_Type type, out bool overwriting) {
			overwriting=false;
			if ((type!=Config_Type.VALA_BINARY)&&(type!=Config_Type.VALA_LIBRARY)) {
				if ((this.file==file)&&(this.path==path)&&(this.type==type)) {
					return true;
				} else {
					return false;
				}
			} else {
				// Vala binaries and libraries are determined by the path (there can be only one binary or library per path)
				if (this.path==path) {
					if ((this.type==type)&&(this.file==file)) {
						return true;
					} else {
						overwriting=true;
						return true;
					}
				} else {
					return false;
				}
			}
		}

		public void printall() {
			GLib.stdout.printf("Path: %s, file: %s\n",this.path,this.file);
			foreach(var l in this.packages) {
				GLib.stdout.printf("\tPackage: %s",l.package);
				switch (l.type) {
				case package_type.no_check:
					GLib.stdout.printf(" (don't check it)");
					break;
				case package_type.do_check:
					GLib.stdout.printf(" (check it)");
					break;
				case package_type.local:
					GLib.stdout.printf(" (local package)");
					break;
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

		public string project_name; // Contains the project name
		public string config_path; // Contains the full path to the configuration file (both path and filename)
		public string basepath; // Contains the full path where the configuration file is stored
		public Gee.List<config_element ?> configuration_data; // Contains all the configuration read
		public string vala_version; // Minimun Vala version needed to compile this

		private int current_version; // Contains the version of the currently supported syntax
		private string[] error_list;

		private weak config_element ? last_element;
		private int version;
		private int line_number;

		/**
		 * @param project_name The name for this project. Left blank if opening an existing project.
		 * @param init_gettext When called from an internal function, get it to false to avoid initializating gettext twice
		 */

		public configuration(string project_name="",bool init_gettext=true) {
			if (init_gettext) {
				Intl.bindtextdomain(AutoValaConstants.GETTEXT_PACKAGE, Path.build_filename(AutoValaConstants.DATADIR,"locale"));
			}
			this.current_version=4; // currently we support version 4 of the syntax
			this.config_path="";
			this.configuration_data=new Gee.ArrayList<config_element ?>();
			this.last_element=null;
			this.version=0;
			this.project_name=project_name;
			this.error_list={};
			this.vala_version="0.16";
		}

		/**
		 * Returns the version of Vala compiler installed in the system (the default one)
		 *
		 * @param major Returns the major version number
		 * @param minor Returns the minor version number
		 *
		 * @return //false// if there was no error, //true// if the version can't be determined
		 */

		public bool get_vala_version(out int major, out int minor) {

			/*
			 * Maybe a not very elegant way of doing it. I accept patches
			 */
			major=0;
			minor=0;

			if (0!=Posix.system("valac --version > /var/tmp/current_vala_version")) {
				return true;
			}
			var file=File.new_for_path("/var/tmp/current_vala_version");
			try {
				var dis = new DataInputStream(file.read());
				string ?line;
				while((line=dis.read_line(null))!=null) {
					var version=line.split(" ");
					foreach(var element in version) {
						if (Regex.match_simple("^[0-9]+.[0-9]+(.[0-9]+)?$",element)) {
							var numbers=element.split(".");
							major=int.parse(numbers[0]);
							minor=int.parse(numbers[1]);
							return false;
						}
					}
				}
			} catch (Error e) {
				return true;
			}
			return true;
		}

		/**
		 * Removes all the automatic-made configuration parameters
		 *
		 * After calling this method, only the ones manually added by the user will remain
		 */

		public void clear_automatic() {
			var new_config=new Gee.ArrayList<config_element ?>();
			foreach (var element in this.configuration_data) {
				if (element.automatic==false) {
					new_config.add(element);
					element.clear_automatic();
				}
			}
			this.configuration_data=new_config;
		}

		/**
		 * Clears the error list
		 */

		public void clear_errors() {
			this.error_list={};
		}

		/**
		 * Prints the list of errors and warnings to the standard output
		 */

		public void show_errors() {
			foreach(var e in this.error_list) {
				GLib.stdout.printf("%s\n".printf(e));
			}
			this.clear_errors();
		}

		/**
		 * Return the list of errors and warnings, to allow to show it from another program
		 *
		 * @return An array with one error or warning in each string
		 */

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
				enumerator = directory.enumerate_children(GLib.FileAttribute.STANDARD_NAME+","+GLib.FileAttribute.STANDARD_TYPE,GLib.FileQueryInfoFlags.NOFOLLOW_SYMLINKS,null);
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
			} catch (Error e) {
				return "";
			}
			return (full_path);
		}

		/**
		 * Sets the configuration file
		 *
		 * This method is useful when creating a new project; after creating a new configuration object (specifying the project name), use
		 * this method to set the path and filename where to store it, before calling //save_configuration()//.
		 *
		 * @param path The path for the configuration file. If given as a relative path, it will be internally expanded to the full path
		 */

		public void set_config_filename(string path) {

			if (GLib.Path.is_absolute(path)) {
				this.config_path=path;
			} else {
				this.config_path=GLib.Path.build_filename(GLib.Environment.get_current_dir(),path);
			}
			this.basepath=GLib.Path.get_dirname(this.config_path);
		}


		/**
		 * Reads the configuration file for a project.
		 *
		 * If no file/path is given, it will search from the current
		 * path upwards until it finds a file with .avprj (in lowercase) extension.
		 * 
		 * If the path of a file with .avprj extension is passed, it will try to open that file
		 *
		 * If another kind of file, or a path is given, it will search for a file with .avprj extension in that path (or in the path
		 * passed), and upwards. This allows to just pass the path to a file of a project, and it will automatically find the project
		 * configuration file.
		 *
		 * @param open_file The path where to start to search for a configuration file
		 *
		 * @return //false// if there was no error; //true// if there was an error. this.error_list will contain one or more strings with all
		 * the warnings and errors
		 */

		public bool read_configuration(string open_file="") {

			this.configuration_data=new Gee.ArrayList<config_element ?>();

			this.config_path="";
			if (false==open_file.has_suffix(".avprj")) {
				string[] basepath;
				int len;
				if (open_file=="") {
					basepath=GLib.Environment.get_current_dir().split(Path.DIR_SEPARATOR_S);
					len=basepath.length;
				} else {
					string tmp_basepath;
					if (GLib.Path.is_absolute(open_file)) {
						tmp_basepath=open_file;
					} else {
						tmp_basepath=GLib.Path.build_filename(GLib.Environment.get_current_dir(),open_file);
					}
					basepath=tmp_basepath.split(Path.DIR_SEPARATOR_S);
					var filepath=File.new_for_path(tmp_basepath);
					if (filepath.query_exists()==false) {
						this.error_list+="The path passed to READ_CONFIGURATION doesn't exists";
						return true;
					}
					len=basepath.length;
					if (filepath.query_file_type(FileQueryInfoFlags.NOFOLLOW_SYMLINKS)!=FileType.DIRECTORY) {
						len--; // if it's not a directory, remove the file name
					}
				}

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
					this.error_list+="No configuration file found";
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
							var version_elements=version.split(".");
							int major;
							int minor;
							if (this.get_vala_version(out major, out minor)) {
								this.error_list+=_("Can't get the version of the installed Vala binary. Asuming version 0.16");
								major=0;
								minor=16;
							}
							int f_major;
							int f_minor;

							f_major=int.parse(version_elements[0]);
							f_minor=int.parse(version_elements[1]);
							if ((f_major>major)||((f_major==major)&&(f_minor>minor))) {
								this.config_path="";
								this.configuration_data=new Gee.ArrayList<config_element ?>();
								this.error_list+=_("This project needs Vala version %s or greater, but you have version %d.%d. Can't open it.").printf(version,major,minor);
								error=true;
								break;
							}
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
						error|=this.add_package(line.substring(14).strip(),package_type.no_check,automatic);
						continue;
					}
					if (line.has_prefix("vala_vapi: ")) {
						error|=this.add_vapi(line.substring(11).strip(),automatic);
						continue;
					}
					if (line.has_prefix("vala_check_package: ")) {
						error|=this.add_package(line.substring(20).strip(),package_type.do_check,automatic);
						continue;
					}
					if (line.has_prefix("vala_local_package: ")) {
						error|=this.add_package(line.substring(20).strip(),package_type.local,automatic);
						continue;
					}
					if (line.has_prefix("vala_source: ")) {
						error|=this.add_source(line.substring(13).strip(),automatic);
						continue;
					}
					if (line.has_prefix("version: ")) {
						error|=this.set_version(line.substring(9).strip(),automatic);
						continue;
					}
					if (line.has_prefix("namespace: ")) {
						error|=this.set_namespace(line.substring(11).strip(),automatic);
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
					if (line.has_prefix("doc: ")) {
						var po_folder=line.substring(5).strip();
						error|=this.add_entry(po_folder,Config_Type.DOC,automatic);
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
					if (line.has_prefix("data: ")) {
						error|=this.add_entry(line.substring(6).strip(),Config_Type.DATA,automatic);
						continue;
					}
					if (line.has_prefix("include: ")) {
						error|=this.add_entry(line.substring(9).strip(),Config_Type.INCLUDE,automatic);
						continue;
					}
					if (line.has_prefix("ignore: ")) {
						error|=this.add_entry(line.substring(8).strip(),Config_Type.IGNORE,automatic);
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
					if (line.has_prefix("autovala_version: ")) {
						this.version=int.parse(line.substring(18).strip());
						if (this.version>this.current_version) {
							this.config_path="";
							this.configuration_data=new Gee.ArrayList<config_element ?>();
							this.error_list+=_("This project was created with a newer version of Autovala. Can't open it.");
							error=true;
							break;
						}
						continue;
					}
					error=true;
					this.error_list+=_("Syntax error in line %d").printf(this.line_number);
				}
			} catch (Error e) {
				this.config_path="";
				this.configuration_data=new Gee.ArrayList<config_element ?>();
				this.error_list+=_("Can't open configuration file");
				error=true;
			}

			return error;
		}

		private bool set_version(string version,bool automatic) {

			if (this.last_element==null) {
				this.error_list+=_("Found 'file_version' command after a non vala_binary, nor vala_library command (line %d)").printf(this.line_number);
				return true;
			}

			if ((this.last_element.version_set==true)&&(this.last_element.version_manually_set==true)&&(automatic==false)) {
				this.error_list+=_("Warning: overwriting version number (line %d)").printf(this.line_number);
			}

			if (this.last_element.type==Config_Type.VALA_LIBRARY) {
				// Only accept version string in the format N, N.N or N.N.N (with N a number of one or more digits)
				if (false==this.check_version(version)) {
					this.error_list+=_("Version string %s not valid for a library. It must be in the form N.N or N.N.N (line %d)").printf(version,this.line_number);
					return true;
				}
			}
			if ((this.last_element.version_set==false)||((this.last_element.version_manually_set==false)&&(automatic==false))) { // Don't overwrite a preexisting version if the new one is automatic
				this.last_element.set_version(version,automatic);
			}
			return false;
		}

		private bool check_version(string version) {
			return Regex.match_simple("^[0-9]+.[0-9]+(.[0-9]+)?$",version);
		}

		private bool add_compiling_options(string options) {

			if (this.last_element==null) {
				this.error_list+=_("Found 'compile_options' command after a non vala_binary, nor vala_library command (line %d)").printf(this.line_number);
				return true;
			}

			if (this.last_element.compile_options!="") {
				this.error_list+=_("Warning: overwriting compile options (line %d)").printf(this.line_number);
			}
			this.last_element.set_compile_options(options);
			return false;
		}

		private bool set_namespace(string current_namespace,bool automatic) {

			if (this.last_element==null) {
				this.error_list+=_("Found 'namespace' command after a non vala_binary, nor vala_library command (line %d)").printf(this.line_number);
				return true;
			}

			if ((this.last_element.current_namespace!="")&&(automatic==false)) {
				this.error_list+=_("Warning: overwriting namespace (line %d)").printf(this.line_number);
			}
			if ((this.last_element.current_namespace=="")||(automatic==false)) { // Don't overwrite a preexisting namespace if the new one is automatic
				this.last_element.set_namespace(current_namespace,automatic);
			}
			return false;
		}

		private bool add_source(string source,bool automatic) {

			if (this.config_path=="") {
				return true;
			}

			if (this.last_element==null) {
				this.error_list+=_("Found vala_source after a non vala_binary, nor vala_library command (line %d)").printf(this.line_number);
				return true;
			}
			this.last_element.add_source(source,automatic);
			return false;
		}

		private bool add_package(string pkg,package_type type,bool automatic) {

			if (this.config_path=="") {
				return true;
			}

			if (this.last_element==null) {
				this.error_list+=_("Found 'XXXXX_package' command after a non vala_binary, nor vala_library command (line %d)").printf(this.line_number);
				return true;
			}
			this.last_element.add_package(pkg,type,automatic);
			return false;
		}

		private bool add_vapi(string vapi,bool automatic) {

			if (this.config_path=="") {
				return true;
			}

			if (this.last_element==null) {
				this.error_list+=_("Found 'vala_vapi' command after a non vala_binary, nor vala_library command (line %d)").printf(this.line_number);
				return true;
			}
			this.last_element.add_vapi(vapi,automatic);
			return false;
		}

		/**
		 * Adds a new entry of the specified type to the current configuration
		 *
		 * This method can't be used for binaries or libraries; use //add_new_binary()// instead
		 *
		 * @param filename The filename (must be relative to the project's base path)
		 * @param type The type of file (can't be Config_Type.VALA_BINARY or Config_Type.VALA_LIBRARY)
		 * @param automatic If //false//, this entry is a manual one, while if //true//, this entry has been determined automatically
		 *
		 * @return //false// if there was no error, //true// if there was an error
		 */

		public bool add_new_entry(string filename, Config_Type type, bool automatic) {

			if ((type!=Config_Type.VALA_BINARY)&&(type!=Config_Type.VALA_LIBRARY)) {
				return this.add_entry(filename,type,automatic);
			} else {
				return true;
			}
		}

		/**
		 * Adds a new entry of the type //binary// or //library// to the current configuration
		 *
		 * @param filename The path and filename for the binary or library (must be relative to the project's base path)
		 * @param type The type of file (must be Config_Type.VALA_BINARY or Config_Type.VALA_LIBRARY)
		 * @param automatic If //false//, this entry is a manual one, while if //true//, this entry has been determined automatically
		 * @param sources A list of source files to add to this binary/library. They must be specified relative to the path set in //filename//
		 * @param packages A list of the Vala packages that this binary or library needs, that doesn't have a //pkgconfig// file
		 * @param check_packages A list of the Vala packages that this binary or library needs, that have a //pkgconfig// file
		 * @param local_packages A list of the Vala libraries that are being built in this same project needed by this binary or library
		 * @param vapis A list of custom VAPI files needes by this binary or library. The path must be relative to the path set in //filename//
		 * @param version A string with the version number of this binary or library, in the format XX.YY or XX.YY.ZZ
		 * @param current_namespace The namespace defined for this binary or library
		 * @param several_namespaces //true// if the file contains several namespaces; //false// if it contains only one or none
		 * @param compile_options A textual string with the compilation options to pass to the Vala compiler
		 *
		 * @return //false// if there was no error, //true// if there was an error
		 */

		public bool add_new_binary(string filename, Config_Type type, bool automatic, Gee.Set<string> ?sources=null, string[] ?packages=null, string[] ?check_packages=null, string[] ?local_packages=null,string[] ?vapis=null, string version="", string current_namespace="", bool several_namespaces=false, string compile_options="") {

			if ((type!=Config_Type.VALA_BINARY)&&(type!=Config_Type.VALA_LIBRARY)) {
				return true;
			}

			bool version_automatic=false;
			string newversion;
			if (version[0]=='*') {
				newversion=version.substring(1);
				version_automatic=true;
			} else {
				newversion=version;
			}
			if ((newversion!="") && (false==this.check_version(newversion))) {
				return true;
			}

			this.add_entry(filename,type,automatic);
			if (newversion!="") {
				this.set_version(newversion,version_automatic);
			}
			bool p_automatic;
			string source;
			if (sources!=null) {
				foreach(var s in sources) {
					if (s[0]=='*') {
						p_automatic=true;
						source=s.substring(1);
					} else{
						p_automatic=false;
						source=s;
					}
					this.add_source(source,p_automatic);
				}
			}
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
					this.add_package(package,package_type.no_check,p_automatic);
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
					this.add_package(package,package_type.do_check,p_automatic);
				}
			}
			if (local_packages!=null) {
				foreach(var l in local_packages) {
					if (l[0]=='*') {
						p_automatic=true;
						package=l.substring(1);
					} else{
						p_automatic=false;
						package=l;
					}
					this.add_package(package,package_type.local,p_automatic);
				}
			}
			string vapi;
			if (vapis!=null) {
				foreach(var l in vapis) {
					if (l[0]=='*') {
						p_automatic=true;
						vapi=l.substring(1);
					} else{
						p_automatic=false;
						vapi=l;
					}
					this.add_vapi(vapi,p_automatic);
				}
			}
			if (compile_options!="") {
				this.add_compiling_options(compile_options);
			}
			if (type==Config_Type.VALA_LIBRARY) {
				if (current_namespace=="") {
					this.error_list+=_("Warning: library %s uses no namespace. Will not generate .GIR file").printf(filename);
				} else if (several_namespaces) {
					this.error_list+=_("Warning: library %s contains several namespaces. Will not generate .GIR file").printf(filename);
				} else {
					this.set_namespace(current_namespace,true);
				}
			}
			return false;
		}

		private bool add_entry(string l_filename, Config_Type type,bool automatic) {

			if (this.config_path=="") {
				this.error_list+=_("Trying to add an entry with the class unconfigured");
				return true;
			}

			var filename=l_filename;
			if ((type==Config_Type.PO)||(type==Config_Type.DATA)||(type==Config_Type.DOC)) {
				if (false==filename.has_suffix(Path.DIR_SEPARATOR_S)) {
					filename+=Path.DIR_SEPARATOR_S;
				}
			}
			string icon_path="";
			if (type==Config_Type.ICON) {
				var pos=l_filename.index_of(" ");
				if (pos!=-1) { // there is a path for the icon; use it instead the default one
					icon_path=l_filename.substring(0,pos);
					filename=l_filename.substring(pos+1).strip();
				}
			}

			string file;
			string path;
			if (type!=Config_Type.IGNORE) {
				file=Path.get_basename(filename);
				path=Path.get_dirname(filename);
			} else {
				if((filename.length>1)&&(filename.has_suffix(Path.DIR_SEPARATOR_S))) {
					file=filename.substring(0,filename.length-1);
				} else {
					file=filename;
				}
				path=file;
			}
			foreach(var e in this.configuration_data) {
				bool overwriting;
				bool retval;
				retval=e.check(file,path,type,out overwriting);
				if (retval) {
					if ((type==Config_Type.VALA_BINARY)||(type==Config_Type.VALA_LIBRARY)) {
						if(overwriting) { // a binary or a library is overwriting other
							this.error_list+=_("A binary or library is trying to overwrite another at line %d %s %s").printf(line_number,path,file);
							this.last_element=null;
							return true;
						} else {
							this.last_element=e;
						}
					} else {
						this.last_element=null;
					}
					return false;
				}
			}

			var element=new config_element(file,path,type,automatic,icon_path);
			this.configuration_data.add(element);
			if ((type==Config_Type.VALA_BINARY)||(type==Config_Type.VALA_LIBRARY)) {
				this.last_element=element;
			} else {
				this.last_element=null;
			}
			return false;
		}

		/**
		 * Prints to stdout all the entries in this configuration class
		 */

		public void list_all() {
			GLib.stdout.printf("Current configuration:\n");
			foreach(var e in this.configuration_data) {
				e.printall();
			}
		}

		/**
		 * Saves this configuration to the current filename, overwriting it if it already exists
		 *
		 * @param filename If a path and filename is given, the configuration will be stored there instead of in the current filename. The current filename is overwriten with this value
		 *
		 * @return //false// if there was no error, //true// if there was an error
		 */

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
			var file=File.new_for_path(this.config_path);
			if (file.query_exists()) {
				try {
					file.delete();
				} catch (Error e) {
					this.error_list+=_("Failed to delete the old config file %s").printf(this.config_path);
					return true;
				}
			}
			this.error_list+=_("Storing configuration in file %s").printf(this.config_path);
			try {
				var dis = file.create(FileCreateFlags.NONE);
				var data_stream = new DataOutputStream(dis);
				data_stream.put_string("### AutoVala Project ###\n");
				data_stream.put_string("autovala_version: %d\n".printf(this.current_version));
				data_stream.put_string("project_name: "+this.project_name+"\n");
				data_stream.put_string("vala_version: "+this.vala_version+"\n\n");
				this.store_data(Config_Type.PO,data_stream);
				this.store_data(Config_Type.DATA,data_stream);
				this.store_data(Config_Type.DOC,data_stream);
				this.store_data(Config_Type.IGNORE,data_stream);
				this.store_data(Config_Type.VALA_BINARY,data_stream);
				this.store_data(Config_Type.VALA_LIBRARY,data_stream);
				this.store_data(Config_Type.BINARY,data_stream);
				this.store_data(Config_Type.DESKTOP,data_stream);
				this.store_data(Config_Type.AUTOSTART,data_stream);
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

			bool found=false;

			try {
				foreach(var element in this.configuration_data) {
					if (element.type!=type) {
						continue;
					}
					found=true;
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
						if ((element.version!="")&&(element.version_set==true)) {
							if (element.version_manually_set==false) {
								data_stream.put_string("*");
							}
							data_stream.put_string("version: "+element.version+"\n");
						}
						if (element.compile_options!="") {
							data_stream.put_string("compile_options: "+element.compile_options+"\n");
						}
						if (element.current_namespace!="") {
							if (element.namespace_manually_set==false) {
								data_stream.put_string("*");
							}
							data_stream.put_string("namespace: "+element.current_namespace+"\n");
						}
						foreach(var l in element.packages) {
							if (l.automatic) {
								data_stream.put_string("*");
							}
							switch(l.type) {
							case package_type.do_check:
								data_stream.put_string("vala_check_package: ");
								break;
							case package_type.no_check:
								data_stream.put_string("vala_package: ");
								break;
							case package_type.local:
								data_stream.put_string("vala_local_package: ");
								break;
							}
							data_stream.put_string(l.package+"\n");
						}
						foreach(var s in element.sources) {
							if (s.automatic) {
								data_stream.put_string("*");
							}
							data_stream.put_string("vala_source: "+s.source+"\n");
						}
						foreach(var v in element.vapis) {
							if (v.automatic) {
								data_stream.put_string("*");
							}
							data_stream.put_string("vala_vapi: "+v.vapi+"\n");
						}
						data_stream.put_string("\n"); // add a separator after each new binary or library to simplify manual edition
						found=false; // avoid to put more than one separator
						break;
					case Config_Type.BINARY:
						data_stream.put_string("binary: "+fullpathname+"\n");
						break;
					case Config_Type.ICON:
						data_stream.put_string("icon: "+element.icon_path+" "+fullpathname+"\n");
						break;
					case Config_Type.PIXMAP:
						data_stream.put_string("pixmap: "+fullpathname+"\n");
						break;
					case Config_Type.PO:
						data_stream.put_string("po: "+element.path+"\n");
						break;
					case Config_Type.DOC:
						data_stream.put_string("doc: "+element.path+"\n");
						break;
					case Config_Type.IGNORE:
						data_stream.put_string("ignore: "+element.path+"\n");
						break;
					case Config_Type.GLADE:
						data_stream.put_string("glade: "+fullpathname+"\n");
						break;
					case Config_Type.DATA:
						data_stream.put_string("data: "+element.path+"\n");
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
				if (found) {
					data_stream.put_string("\n"); // add a separator after each new category to simplify manual edition
				}
			} catch (Error e) {
				return true;
			}
			return false;
		}
	}
}

