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

	class namespaces_element:GLib.Object {

		public string namespace_s;
		public string current_file;
		public string filename;
		public string[] filenames;
		public int major;
		public int minor;
		public bool checkable;

		public namespaces_element(string namespace_s) {
			this.namespace_s=namespace_s;
			this.major=0;
			this.minor=0;
			this.current_file="";
			this.filename="";
			this.filenames={};
			this.checkable=false;
		}

		public void add_file(string filename,Gee.Set<string> pkgconfigs, int gir_major, int gir_minor) {
			int c_major;
			int c_minor;

			c_major=gir_major;
			c_minor=gir_minor;

			string file;
			if (filename.has_suffix(".vapi")) {
				file=filename.substring(0,filename.length-5); // remove the .vapi extension
			} else {
				file=filename;
			}
			this.filenames+=file;
			string newfile=file;
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

			if ((this.current_file=="")||(newfile.length<this.current_file.length)) { // always take the shortest filename
				this.current_file=newfile;
				this.filename=file;
				this.major=c_major;
				this.minor=c_minor;
				this.checkable=pkgconfigs.contains(file);
				return;
			}
			if (this.current_file==newfile) { // for the same filename, take always the greatest version
				if((c_major>this.major)||((c_major==this.major)&&(c_minor>this.minor))) {
					this.major=c_major;
					this.minor=c_minor;
					this.filename=file;
					this.checkable=pkgconfigs.contains(file);
					return;
				}
			}
		}
	}

	public class manage_project:GLib.Object {

		private configuration config;
		private string[] error_list;
		private Gee.Map<string,namespaces_element> ?namespaces;
		private Gee.Map<string,config_element> ?local_namespaces;
		private Gee.Set<string> ?pkgconfigs;
		private string current_namespace;
		private bool several_namespaces;

		public manage_project() {
			this.error_list={};
			this.namespaces=null;
			this.local_namespaces=null;
			this.pkgconfigs=null;
		}

		public void clear_errors() {
			this.error_list={};
		}

		public void show_errors() {
			foreach(var e in this.error_list) {
				GLib.stdout.printf("%s\n".printf(e));
			}
			this.clear_errors();
		}

		public string[] get_error_list() {
			return this.error_list;
		}

		private void add_errors(string[] ? errors) {
			if (errors!=null) {
				foreach (var e in errors) {
					this.error_list+=e;
				}
			}
		}

		private void cant_create(string folder) {

			error_list+=_("Warning: Unable to create the %s directory").printf(folder);
		}

		private void folder_exists(string folder) {

			error_list+=_("Warning: the %s directory already exists").printf(folder);
		}

		/**
		 * Creates a new project from scratch in the specified folder.
		 * If config_path is an empty string, will use the current folder.
		 * If there is already a project there, will return an error.
		 */
		public bool init(string project_name, string i_config_path="") {

			bool error=false;
			this.error_list={};
			string config_path;
			if (i_config_path=="") {
				config_path=Posix.realpath(GLib.Environment.get_current_dir());
			} else {
				config_path=Posix.realpath(i_config_path);
			}
			var directory=File.new_for_path(config_path);
			try {
				var enumerator = directory.enumerate_children(FileAttribute.STANDARD_NAME, 0);
				FileInfo file_info;
				while ((file_info = enumerator.next_file ()) != null) {
					if (file_info.get_name().has_suffix(".avprj")) {
						error_list+=_("There's already a project in folder %s").printf(config_path);
						return true; // there's already a project here!!!!
					}
				}
			} catch (Error e) {
				error_list+=_("Failed to list path %s").printf(config_path);
				return true;
			}

			try {
				var folder=File.new_for_path(Path.build_filename(config_path,"src"));
				if (folder.query_exists()) {
					this.folder_exists("SRC");
				} else {
					folder.make_directory_with_parents();
				}
			} catch (Error e) {
				this.cant_create("SRC");
			}
			try {
				var folder=File.new_for_path(Path.build_filename(config_path,"src","vapis"));
				if (folder.query_exists()) {
					this.folder_exists("SRC/VAPIS");
				} else {
					folder.make_directory_with_parents();
				}
			} catch (Error e) {
				this.cant_create("SRC/VAPIS");
			}
			try {
				var folder=File.new_for_path(Path.build_filename(config_path,"po"));
				if (folder.query_exists()) {
					this.folder_exists("PO");
				} else {
					folder.make_directory_with_parents();
				}
			} catch (Error e) {
				this.cant_create("PO");
			}
			try {
				var folder=File.new_for_path(Path.build_filename(config_path,"doc"));
				if (folder.query_exists()) {
					this.folder_exists("DOC");
				} else {
					folder.make_directory_with_parents();
				}
			} catch (Error e) {
				this.cant_create("DOC");
			}
			try {
				var folder=File.new_for_path(Path.build_filename(config_path,"install"));
				if (folder.query_exists()) {
					this.folder_exists("INSTALL");
				} else {
					folder.make_directory_with_parents();
				}
			} catch (Error e) {
				this.cant_create("INSTALL");
			}
			try {
				var folder=File.new_for_path(Path.build_filename(config_path,"data"));
				if (folder.query_exists()) {
					this.folder_exists("DATA");
				} else {
					folder.make_directory_with_parents();
				}
			} catch (Error e) {
				this.cant_create("DATA");
			}
			try {
				var folder=File.new_for_path(Path.build_filename(config_path,"data","icons"));
				if (folder.query_exists()) {
					this.folder_exists("DATA/ICONS");
				} else {
					folder.make_directory_with_parents();
				}
			} catch (Error e) {
				this.cant_create("DATA/ICONS");
			}
			try {
				var folder=File.new_for_path(Path.build_filename(config_path,"data","pixmaps"));
				if (folder.query_exists()) {
					this.folder_exists("DATA/PIXMAPS");
				} else {
					folder.make_directory_with_parents();
				}
			} catch (Error e) {
				this.cant_create("DATA/PIXMAPS");
			}
			try {
				var folder=File.new_for_path(Path.build_filename(config_path,"data","interface"));
				if (folder.query_exists()) {
					this.folder_exists("DATA/INTERFACE");
				} else {
					folder.make_directory_with_parents();
				}
			} catch (Error e) {
				this.cant_create("DATA/INTERFACE");
			}
			try {
				var folder=File.new_for_path(Path.build_filename(config_path,"data","local"));
				if (folder.query_exists()) {
					this.folder_exists("DATA/LOCAL");
				} else {
					folder.make_directory_with_parents();
				}
			} catch (Error e) {
				this.cant_create("DATA/LOCAL");
			}
			if (error) {
				return true;
			}

			this.config=new configuration(project_name);
			this.config.project_name=project_name;
			int major;
			int minor;
			if (this.config.get_vala_version(out major, out minor)) {
				this.error_list+=_("Can't get the version of the installed Vala binary. Asuming version 0.16");
				major=0;
				minor=16;
			}
			this.config.vala_version="%d.%d".printf(major,minor);
			this.config.set_config_filename(Path.build_filename(config_path,project_name+".avprj"));
			if (this.config.save_configuration()) {
				this.add_errors(this.config.get_error_list());
				this.config.clear_errors();
				return true;
			}
			return error;
		}

		public bool cmake(string config_path="") {

			this.config=new AutoVala.configuration();
			bool retval=this.config.read_configuration(config_path);
			this.add_errors(this.config.get_error_list()); // there can be warnings
			this.config.clear_errors();
			if (retval) {
				return true;
			}
			var make=new AutoVala.cmake(this.config);
			retval=make.create_cmake();
			this.add_errors(make.get_error_list()); // there can be warnings
			make.clear_errors();
			if (retval) {
				return true;
			}
			return false;
		}

		private void fill_pkgconfig_files(string basepath) {
			var newpath=File.new_for_path(Path.build_filename(basepath,"pkgconfig"));
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
					if (fname.has_suffix(".pc")==false) {
						continue;
					}
					var final_name=fname.substring(0,fname.length-3); // remove .pc extension
					this.pkgconfigs.add(final_name); // add to the list
				}
			} catch (Error e) {
				return;
			}
		}

		private void check_vapi_file(string basepath, string file_s) {

			/*
			 * This method checks the namespace provided by a .vapi file
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
								namespace_s="GIO-unix";
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
								element=new namespaces_element(namespace_s);
								this.namespaces.set(namespace_s,element);
							}
							element.add_file(file_s,this.pkgconfigs,gir_major,gir_minor);
						}
						break;
					}
				}
			} catch (Error e) {
				return;
			}
		}

		private void fill_namespaces(string basepath) {

			/*
			 * This method fills the NAMESPACES hashmap with a list of each namespace and the files that provides it, and also the "best" one
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

		public bool refresh(string config_path="") {

			int major;
			int minor;

			this.namespaces=new Gee.HashMap<string,namespaces_element>();
			this.local_namespaces=new Gee.HashMap<string,config_element>();
			this.pkgconfigs=new Gee.HashSet<string>();
			this.current_namespace="";

			this.config=new AutoVala.configuration();
			if (this.config.get_vala_version(out major, out minor)) {
				this.error_list+=_("Can't determine the version of the Vala compiler");
				return true;
			}

			this.fill_pkgconfig_files("/usr/lib");
			this.fill_pkgconfig_files("/usr/share");
			this.fill_pkgconfig_files("/usr/lib/i386-linux-gnu");
			this.fill_pkgconfig_files("/usr/lib/x86_64-linux-gnu");
			this.fill_pkgconfig_files("/usr/local/lib");
			this.fill_pkgconfig_files("/usr/local/share");
			this.fill_pkgconfig_files("/usr/local/lib/i386-linux-gnu");
			this.fill_pkgconfig_files("/usr/local/lib/x86_64-linux-gnu");
			var other_pkgconfig=GLib.Environment.get_variable("PKG_CONFIG_PATH");
			if (other_pkgconfig!=null) {
				foreach(var element in other_pkgconfig.split(":")) {
					this.fill_pkgconfig_files(element);
				}
			}
			this.fill_namespaces("/usr/share/vala");
			this.fill_namespaces("/usr/share/vala-%d.%d".printf(major,minor));
			this.fill_namespaces("/usr/local/share/vala");
			this.fill_namespaces("/usr/local/share/vala-%d.%d".printf(major,minor));
			bool retval=this.config.read_configuration(config_path);
			this.add_errors(this.config.get_error_list()); // there can be warnings
			this.config.clear_errors();
			if (retval) {
				return true;
			}

			this.config.clear_automatic(); // remove all automatic entries

			// files_set will contain all files already processed
			// First, fill it with manually configured files
			var files_set=new Gee.HashSet<string>();
			// And also get all the paths with binaries and libraries
			Gee.Map<string,string> binaries=new Gee.HashMap<string,string>();
			Gee.Map<string,string> libraries=new Gee.HashMap<string,string>();
			string path_s;
			foreach(var element in this.config.configuration_data) {
				// but don't add VALA_BINARY or VALA_LIBRARY, because those would need extra automatic configuration
				if (element.type==Config_Type.VALA_BINARY) {
					if (false==binaries.has_key(element.path)) {
						binaries.set(element.path,element.file);
					}
					continue;
				}
				if (element.type==Config_Type.VALA_LIBRARY) {
					if (false==libraries.has_key(element.path)) {
						libraries.set(element.path,element.file);
					}
					continue;
				}
				if ((element.type==Config_Type.IGNORE)||(element.type==Config_Type.PO)||(element.type==Config_Type.DATA)||(element.type==Config_Type.DOC)) {
					path_s=Path.build_filename(this.config.basepath,element.path);
				} else {
					path_s=Path.build_filename(this.config.basepath,element.path,element.file);
				}
				files_set.add(path_s);
			}
			if ((false==binaries.has_key("src"))&&(false==libraries.has_key("src"))) {
				binaries.set("src",this.config.project_name);
			}

			this.try_to_add(files_set,Config_Type.PO,"po/");
			this.try_to_add(files_set,Config_Type.DATA,"data/local/");
			this.try_to_add(files_set,Config_Type.DOC,"doc/");
			string[] extensions={".png",".svg"};
			this.process_folder(files_set,"data/icons",Config_Type.ICON,extensions,true);
			extensions={".png",".svg",".jpg"};
			this.process_folder(files_set,"data/pixmaps",Config_Type.PIXMAP,extensions,true);
			extensions={".ui"};
			this.process_folder(files_set,"data/interface",Config_Type.GLADE,extensions,true);
			extensions={".desktop"};
			this.process_folder(files_set,"data",Config_Type.DESKTOP,extensions,false);
			extensions={".sh"};
			this.process_folder(files_set,"data",Config_Type.BINARY,extensions,false);
			extensions={".service",".service.base"};
			this.process_folder(files_set,"data",Config_Type.DBUS_SERVICE,extensions,false);
			extensions={".gschema.xml"};
			this.process_folder(files_set,"data",Config_Type.SCHEME,extensions,false);
			extensions={".plug"};
			this.process_folder(files_set,"data",Config_Type.EOS_PLUG,extensions,false);
			foreach(var binary_path in libraries.keys) {
				this.process_binary(files_set,binary_path,binaries,libraries,Config_Type.VALA_LIBRARY);
			}
			foreach(var binary_path in binaries.keys) {
				this.process_binary(files_set,binary_path,binaries,libraries,Config_Type.VALA_BINARY);
			}
			this.config.save_configuration();
			this.add_errors(this.config.get_error_list()); // there can be warnings
			this.config.clear_errors();
			return false;
		}

		private void process_folder(Gee.Set files_set,string folder, Config_Type type, string[] extensions,bool recursive) {

			var directory=File.new_for_path(Path.build_filename(this.config.basepath,folder));
			if (directory.query_exists()) {
				try {
					var enumerator = directory.enumerate_children (FileAttribute.STANDARD_NAME+","+FileAttribute.STANDARD_TYPE, 0);
					FileInfo file_info;
					while ((file_info = enumerator.next_file ()) != null) {
						var fname=file_info.get_name();
						var ftype=file_info.get_file_type();
						if (type!=Config_Type.VALA_BINARY) {
							if (ftype==FileType.REGULAR) {
								foreach(var e in extensions) {
									if (fname.has_suffix(e)) {
										try_to_add(files_set,type,folder,fname);
										break;
									}
								}
							} else if ((ftype==FileType.DIRECTORY)&&(recursive)) { // process recursively
								var newfolder=Path.build_filename(folder,fname);
								this.process_folder(files_set,newfolder,type,extensions, recursive);
								continue;
							}
						}
					}
				} catch (Error e) {
					error_list+=_("Warning: failed to add files at folder %s").printf(folder);
				}
			}

		}

		private void try_to_add(Gee.Set<string> files_set, Config_Type type, string path, string file_s="") {
			string path_s;
			string mpath_s;
			if (file_s=="") {
				path_s=Path.build_filename(this.config.basepath,path);
				mpath_s=path;
			} else {
				path_s=Path.build_filename(this.config.basepath,path,file_s);
				mpath_s=Path.build_filename(path,file_s);
			}
			if (type==Config_Type.ICON) {
				if (file_s.has_suffix("-symbolic.svg")) {
					mpath_s="status "+mpath_s;
				} else {
					mpath_s="apps "+mpath_s;
				}
			}
			if (files_set.contains(path_s)==true) {
				return; // this file has been already processed (or it has a IGNORE flag)
			}
			var file=File.new_for_path(path_s);
			if (file.query_exists()) {
				this.config.add_new_entry(mpath_s,type,true);
			}
		}

		private void check_files(string fname,string path,string path_s,Gee.Set<string> files_set,Gee.Set<string> filelist,
					 Gee.Set<string> filelist_path,Gee.Set<string> namespaces_list, ref string version, ref string current_version) {
			if (fname.has_suffix(".vala")) {
				var fullpath_s=Path.build_filename(path_s,fname);
				if (false==files_set.contains(fullpath_s)) {
					filelist.add("*"+fname);
					filelist_path.add(fullpath_s);
				}
				var relative_path=Path.build_filename(path,fname);
				if (this.get_namespaces(fullpath_s,relative_path,namespaces_list,out version)) {
					this.error_list+=_("Warning: couldn't get the namespace list for %s").printf(relative_path);
				}
				if (version!="") {
					if ((current_version!="")&&(current_version!=version)) {
						this.error_list+=_("Warning: overwriting the version number for %s").printf(relative_path);
					}
					current_version=version;
				}
			}
		}

		private void process_binary(Gee.Set<string> files_set, string path, Gee.Map<string,string>binaries, Gee.Map<string,string>libraries,
									Config_Type type) {

			this.local_namespaces=new Gee.HashMap<string,config_element>();
			// find the block in the configuration for this path
			foreach(var element in this.config.configuration_data) {
				if ((element.path==path)&&((element.type==Config_Type.VALA_BINARY)||(element.type==Config_Type.VALA_LIBRARY))) {
					foreach(var package in element.packages) {
						if(package.type==package_type.local) {
							if (this.local_namespaces.has_key(package.package)==false) {
								this.local_namespaces.set(package.package,element);
							}
						}
					}
				}
			}

			string file_s;
			if (type==Config_Type.VALA_BINARY) {
				file_s=binaries.get(path);
			} else {
				file_s=libraries.get(path);
			}
			this.current_namespace="";
			this.several_namespaces=false;
			Gee.Set<string> namespaces_list=new Gee.HashSet<string>();

			var path_s=Path.build_filename(this.config.basepath,path);
			if (files_set.contains(path_s)) {
				return; // this folder has been already processed (or it has an IGNORE flag)
			}

			var file=File.new_for_path(path_s);
			if (file.query_exists()==false) {
				return; // this folder doesn't exists
			}

			Gee.Set<string> filelist=new Gee.HashSet<string>();
			Gee.Set<string> filelist_path=new Gee.HashSet<string>();
			string version="";
			string current_version="";
			var folderlist=new Gee.ArrayList<string>();
			folderlist.add("");

			var mpath_s=Path.build_filename(path,file_s);
			string searchpath;
			string fname;
			do {
				searchpath=folderlist.read_only_view[0];
				folderlist.remove(searchpath);
				if (searchpath!="") {
					file=File.new_for_path(Path.build_filename(this.config.basepath,path,searchpath));
				}
				try {
					var enumerator = file.enumerate_children(FileAttribute.STANDARD_NAME+","+FileAttribute.STANDARD_TYPE, 0);
					FileInfo file_info;
					while ((file_info = enumerator.next_file ()) != null) {
						var filetype=file_info.get_file_type();
						if(searchpath=="") {
							fname=file_info.get_name();
						} else {
							fname=Path.build_filename(searchpath,file_info.get_name());
						}
						if (filetype==FileType.REGULAR) {
							this.check_files(fname,path,path_s,files_set,filelist,filelist_path,namespaces_list, ref version, ref current_version);
							continue;
						} else if (filetype==FileType.DIRECTORY) {
							var tmp_path=Path.build_filename(path,fname);
							var fullpath=Path.build_filename(this.config.basepath,path,fname);
							if (files_set.contains(fullpath)) {
								continue; // this folder has been already processed (or it has an IGNORE flag)
							}
							if ((binaries.has_key(tmp_path)==false)&&(libraries.has_key(tmp_path)==false)) {
								folderlist.add(fname);
							}
						}
					}
				} catch (Error e) {
					this.error_list+=_("Warning: couldn't process binary %s").printf(Path.build_filename(path,file_s));
					return;
				}
			} while(folderlist.size>0);

			this.local_namespaces=new Gee.HashMap<string,config_element>();
			// also check the namespaces required by manually added sources, and local libraries
			foreach(var element in this.config.configuration_data) {
				if ((element.path==path)&&((element.type==Config_Type.VALA_BINARY)||(element.type==Config_Type.VALA_LIBRARY))) {
					foreach(var checkfile in element.sources) {
						if (checkfile.automatic==false) {
							this.check_files(checkfile.source,path,path_s,files_set,filelist,filelist_path,namespaces_list, ref version, ref current_version);
						}
					}
				}
			}

			current_version="*"+current_version;

			/* Get the packages manually provided by the user, to avoid adding a newer version
			 * (eg: the user put manually gtk+-2.0; without this, autovala would add automatically gtk+-3.0, with the logical conflict)
			 */
			Gee.Set<string> provided_packages=new Gee.HashSet<string>();
			foreach (var element in this.config.configuration_data) {
				if ((element.type!=Config_Type.VALA_BINARY)&&(element.type!=Config_Type.VALA_LIBRARY)) {
					continue;
				}
				if ((element.path!=path)||(element.file!=file_s)) {
					continue;
				}
				foreach (var element2 in element.packages) {
					foreach (var key in this.namespaces.keys) {
						foreach (var filenames in this.namespaces.get(key).filenames) {
							if (element2.package==filenames) {
								if (provided_packages.contains(key)==false) {
									provided_packages.add(key);
								}
							}
						}
					}
				}
				break;
			}

			// Get all the custom VAPIs for this binary/library
			string[] custom_vapis={};
			file=File.new_for_path(Path.build_filename(this.config.basepath,path,"vapis"));
			if(file.query_exists()) {
				try {
					var enumerator = file.enumerate_children(FileAttribute.STANDARD_NAME, 0);
					FileInfo file_info;
					while ((file_info = enumerator.next_file ()) != null) {
						fname=file_info.get_name();
						if(fname.has_suffix(".vapi")==false) {
							continue;
						}
						var fullpath=Path.build_filename(this.config.basepath,path,"vapis",fname);
						if(files_set.contains(fullpath)) {
							continue;
						}
						custom_vapis+="*"+Path.build_filename("vapis",fname);
					}
				} catch (Error e) {
					this.error_list+=_("Warning: can't read the VAPIS folder for %s").printf(path);
				}
			}
			string[] packages={};
			string[] check_packages={};
			string[] local_packages={};
			foreach (var element in namespaces_list) {
				if (provided_packages.contains(element)) {
					continue;
				}
				if (this.namespaces.has_key(element)) {
					var package=this.namespaces.get(element);
					if (package.checkable) {
						check_packages+="*"+package.filename;
					} else {
						packages+="*"+package.filename;
					}
				} else {
					local_packages+=element;
				}
			}
			if (type==Config_Type.VALA_LIBRARY) {
				this.config.add_new_binary(mpath_s,Config_Type.VALA_LIBRARY, true, filelist,packages,check_packages,local_packages,custom_vapis,current_version,this.current_namespace,this.several_namespaces);
			} else {
				this.config.add_new_binary(mpath_s,Config_Type.VALA_BINARY, true, filelist,packages,check_packages,local_packages,custom_vapis,current_version);
			}
		}

		private bool get_namespaces(string fullpath, string relative_path, Gee.Set<string> namespaces_list,out string version) {

			version="";
			var file_f = File.new_for_path (fullpath);
			try {
				var dis = new DataInputStream (file_f.read ());
				string line;
				while ((line = dis.read_line (null)) != null) {
					if (line.has_prefix("const string project_version=\"")) { // add the version (old, deprecated format)
						this.error_list+=_("Warning: The contruction 'const string project_version=\"...\"' is deprecated. Replace it with '// project version=...'");
						var pos=line.index_of("\"",30);
						if (pos!=-1) {
							version=line.substring(30,pos-30);
						}
					} else if (line.strip().has_prefix("// project version=")) { // add the version
						version=line.strip().substring(19);
					} else if (line.has_prefix("using ")) { // add the packages used by this source file
						var pos=line.index_of(";");
						if (pos==-1) {
							continue;
						}
						var namespace_found=line.substring(6,pos-6).strip();
						if ((this.namespaces.has_key(namespace_found)==false)&&(this.local_namespaces.has_key(namespace_found)==false)) {
							this.error_list+=_("Warning: can't find namespace %s in file %s").printf(namespace_found,relative_path);
							continue;
						}
						if (false==namespaces_list.contains(namespace_found)) {
							namespaces_list.add(namespace_found);
						}
					} else if (line.has_prefix("namespace ")) { // add the namespace in this source file
						var pos=line.index_of("{");
						if (pos==-1) {
							continue;
						}
						var namespace_found=line.substring(10,pos-10).strip();
						if ((this.current_namespace!="")&&(this.current_namespace!=namespace_found)) {
							this.several_namespaces=true;
						}
						this.current_namespace=namespace_found;
					}
				}
			} catch (Error e) {
				return true;
			}
			return false;
		}
	}
}
