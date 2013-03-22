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

	public class manage_project:GLib.Object {

		private configuration config;
		private string[] error_list;

		public void clear_errors() {
			this.error_list={};
		}

		public void show_errors() {
			foreach(var e in this.error_list) {
				GLib.stdout.printf("%s\n".printf(e));
			}
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
			var enumerator = directory.enumerate_children(FileAttribute.STANDARD_NAME, 0);
			FileInfo file_info;
			while ((file_info = enumerator.next_file ()) != null) {
				if (file_info.get_name().has_suffix(".avprj")) {
					error_list+=_("There's already a project in folder %s").printf(config_path);
					return true; // there's already a project here!!!!
				}
			}

			try {
				var folder=File.new_for_path(Path.build_filename(config_path,"src"));
				folder.make_directory_with_parents();
			} catch (Error e) {
				error_list+=_("Warning: Unable to create the SRC directory");
			}
			try {
				var folder=File.new_for_path(Path.build_filename(config_path,"po"));
				folder.make_directory_with_parents();
			} catch (Error e) {
				error_list+=_("Warning: Unable to create the PO directory");
			}
			try {
				var folder=File.new_for_path(Path.build_filename(config_path,"doc"));
				folder.make_directory_with_parents();
			} catch (Error e) {
				error_list+=_("Warning: Unable to create the DOC directory");
			}
			try {
				var folder=File.new_for_path(Path.build_filename(config_path,"data"));
				folder.make_directory_with_parents();
			} catch (Error e) {
				error_list+=_("Warning: Unable to create the DATA directory");
			}
			try {
				var folder=File.new_for_path(Path.build_filename(config_path,"data","icons"));
				folder.make_directory_with_parents();
			} catch (Error e) {
				error_list+=_("Warning: Unable to create the data/icons directory");
			}
			try {
				var folder=File.new_for_path(Path.build_filename(config_path,"data","pixmaps"));
				folder.make_directory_with_parents();
			} catch (Error e) {
				error_list+=_("Warning: Unable to create the data/pixmaps directory");
			}
			try {
				var folder=File.new_for_path(Path.build_filename(config_path,"data","interface"));
				folder.make_directory_with_parents();
			} catch (Error e) {
				error_list+=_("Warning: Unable to create the data/interface directory");
			}

			if (error) {
				return true;
			}

			this.config=new configuration(project_name);
			this.config.project_name=project_name;
			this.config.set_config_filename(Path.build_filename(config_path,project_name+".avprj"));
			if (this.config.add_new_entry("po/",Config_Type.PO,true)) {
				this.add_errors(this.config.get_error_list());
				return true;
			}
			if (this.config.add_new_binary("src/"+project_name,Config_Type.VALA_BINARY,true)) {
				this.add_errors(this.config.get_error_list());
				return true;
			}
			if (this.config.save_configuration()) {
				this.add_errors(this.config.get_error_list());
				return true;
			}
			return error;
		}

		public bool cmake(string config_path="") {

			this.config=new autovala.configuration();
			bool retval=this.config.read_configuration(config_path);
			this.add_errors(this.config.get_error_list()); // there can be warnings
			if (retval) {
				return true;
			}
			var make=new autovala.cmake(this.config);
			retval=make.create_cmake();
			this.add_errors(make.get_error_list()); // there can be warnings
			if (retval) {
				return true;
			}
			return false;
		}

		public bool autorefresh(string config_path="") {

			this.config=new autovala.configuration();
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
			string path_s;
			foreach(var element in this.config.configuration_data) {
				// but don't add VALA_BINARY or VALA_LIBRARY, because those would need extra automatic configuration
				if ((element.type==Config_Type.VALA_BINARY)||(element.type==Config_Type.VALA_LIBRARY)) {
					continue;
				}
				if ((element.type==Config_Type.IGNORE)||(element.type==Config_Type.PO)) {
					path_s=Path.build_filename(this.config.basepath,element.path);
				} else {
					path_s=Path.build_filename(this.config.basepath,element.path,element.file);
				}
				files_set.add(path_s);
			}

			this.try_to_add(files_set,Config_Type.PO,"po/");
			string[] extensions={".png",".svg"};
			this.process_folder(files_set,"data/icons",Config_Type.ICON,extensions,true);
			this.process_folder(files_set,"data/pixmaps",Config_Type.PIXMAP,extensions,true);
			extensions={".ui"};
			this.process_folder(files_set,"data/interface",Config_Type.GLADE,extensions,true);
			extensions={".desktop"};
			this.process_folder(files_set,"data",Config_Type.DESKTOP,extensions,false);
			extensions={".service",".service.base"};
			this.process_folder(files_set,"data",Config_Type.DBUS_SERVICE,extensions,false);
			extensions={".gschema.xml"};
			this.process_folder(files_set,"data",Config_Type.SCHEME,extensions,false);
			extensions={".plug"};
			this.process_folder(files_set,"data",Config_Type.EOS_PLUG,extensions,false);

			this.config.save_configuration();
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
				} catch (Error e) {
					error_list+=_("Warning: failed to add icons");
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
			if (files_set.contains(path_s)==true) {
				return; // this file has been already processed
			}
			var file=File.new_for_path(path_s);
			if (file.query_exists()) {
				this.config.add_new_entry(mpath_s,type,true);
			}
		}
	}
}
