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
		private string[] error_text;
		
		/**
		 * Creates a new project from scratch in the specified folder.
		 * If config_path is an empty string, will use the current folder.
		 * If there is already a project there, will return an error.
		 */
		public bool create(string project_name, string i_config_path="") {
		
			bool error=false;
			this.error_text={};
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
					error_text+=_("There's already a project in folder %s").printf(config_path);
					return true; // there's already a project here!!!!
				}
			}

			try {
				var folder=File.new_for_path(Path.build_filename(config_path,"src"));
				if (false==folder.make_directory_with_parents()) {
					error_text+=_("Unable to create the SRC directory");
					error=true;
				}
				folder=File.new_for_path(Path.build_filename(config_path,"data"));
				if (false==folder.make_directory_with_parents()) {
					error_text+=_("Unable to create the DATA directory");
					error=true;
				}
				folder=File.new_for_path(Path.build_filename(config_path,"po"));
				if (false==folder.make_directory_with_parents()) {
					error_text+=_("Unable to create the PO directory");
					error=true;
				}
				folder=File.new_for_path(Path.build_filename(config_path,"doc"));
				if (false==folder.make_directory_with_parents()) {
					error_text+=_("Unable to create the DOC directory");
					error=true;
				}
				folder=File.new_for_path(Path.build_filename(config_path,"data","icons"));
				if (false==folder.make_directory_with_parents()) {
					error_text+=_("Unable to create the data/icons directory");
					error=true;
				}
				folder=File.new_for_path(Path.build_filename(config_path,"data","pixmaps"));
				if (false==folder.make_directory_with_parents()) {
					error_text+=_("Unable to create the data/pixmaps directory");
					error=true;
				}
				folder=File.new_for_path(Path.build_filename(config_path,"data","interface"));
				if (false==folder.make_directory_with_parents()) {
					error_text+=_("Unable to create the data/interface directory");
					error=true;
				}
			} catch (Error e) {
				error_text+=_("Unable to create folder");
				error=true;
			}

			this.config=new configuration(project_name);
			this.config.project_name=project_name;
			this.config.add_new_entry("po/",Config_Type.PO,true);
			this.config.add_new_binary("src/"+project_name,Config_Type.VALA_BINARY,true);
			return error;
		}	
	}
}
