/*
 Copyright 2016 (C) Raster Software Vigo (Sergio Costas)

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

namespace AutoVala {

	private class ElementGResource : ElementBase {

		private string[] gresource_files;
		private string identifier;

		public ElementGResource() {
			this._type = ConfigType.GRESOURCE;
			this.command = "gresource";
			this.gresource_files = {};
			this.identifier = "";
		}

		public override bool configureLine(string line, bool automatic, string? condition, bool invertCondition, int lineNumber) {

			if (false == line.has_prefix(this.command+": ")) {
				var badCommand = line.split(": ")[0];
				ElementBase.globalData.addError(_("Invalid command %s after command %s (line %d)").printf(badCommand,this.command, lineNumber));
				return true;
			}
			var data=line.substring(2+this.command.length).strip();
			var pos = data.index_of_char(' ');
			if (pos == -1) {
				ElementBase.globalData.addError(_("GRESOURCE command lacks path or identifier (line %d)").printf(lineNumber));
				return true;
			}
			this.identifier = data.substring(0,pos).strip();
			return this.configureElement(data.substring(pos).strip(),null,null,automatic,condition,invertCondition);
		}

		public static bool autoGenerate() {

			bool error=false;
			var filePath = File.new_for_path(Path.build_filename(ElementBase.globalData.projectFolder,"data"));

			if (filePath.query_exists()) {
				var files = ElementBase.getFilesFromFolder("data",{".gresource.xml"},false);
				foreach (var file in files) {
					var element = new ElementGResource();
					error |= element.autoConfigure(file);
					error |= element.add_inner_files();
					element.identifier = GLib.Path.get_basename(file).replace(" ","_").replace(".","_");
				}
			}
			return error;
		}

		public bool add_inner_files() {

			GResourceXML parser;

			try {
				parser = new GResourceXML(Path.build_filename(ElementBase.globalData.projectFolder,this._fullPath));
			} catch (MarkupError e) {
				ElementBase.globalData.addError(e.message);
				return true;
			}

			bool found_error = false;
			foreach(var filename in parser.files) {
				string full_filename = Path.build_filename(ElementBase.globalData.projectFolder,this.path,filename);
				string filename2 = Path.build_filename(this.path,filename);
				var f = File.new_for_path(full_filename);
				if (f.query_exists() == false) {
					found_error = true;
					ElementBase.globalData.addError(_("The file %s, defined in the GResource file %s, doesn't exist").printf(filename2,this._fullPath));
					continue;
				}
				this.gresource_files += filename;
				ElementBase.globalData.addExclude(filename2);
			}

			return found_error;
		}

		public override bool generateCMake(DataOutputStream dataStream) {

			this.add_inner_files();

			var c_name = this._name+".c";
			var h_name = this._name+".h";

			try {
				dataStream.put_string("EXECUTE_PROCESS( COMMAND glib-compile-resources --sourcedir=${CMAKE_CURRENT_SOURCE_DIR} --generate-source --target=%s %s)\n".printf(Path.build_filename("${CMAKE_CURRENT_BINARY_DIR}",c_name),Path.build_filename("${CMAKE_CURRENT_SOURCE_DIR}",this._name)));
				
				dataStream.put_string("EXECUTE_PROCESS( COMMAND glib-compile-resources --sourcedir=${CMAKE_CURRENT_SOURCE_DIR} --generate-header --target=%s %s)\n".printf(Path.build_filename("${CMAKE_CURRENT_BINARY_DIR}",h_name),Path.build_filename("${CMAKE_CURRENT_SOURCE_DIR}",this._name)));
				dataStream.put_string("ADD_CUSTOM_COMMAND (\n");

				dataStream.put_string("\tOUTPUT %s\n".printf(Path.build_filename("${CMAKE_CURRENT_BINARY_DIR}/",c_name)));
				dataStream.put_string("\tDEPENDS %s".printf(Path.build_filename("${CMAKE_CURRENT_SOURCE_DIR}/",this._name)));
				foreach(var f in this.gresource_files) {
					dataStream.put_string(" %s".printf(Path.build_filename("${CMAKE_CURRENT_SOURCE_DIR}",f)));
				}

				dataStream.put_string("\n\tCOMMAND glib-compile-resources --sourcedir=${CMAKE_CURRENT_SOURCE_DIR} --generate-source --target=%s %s\n".printf(Path.build_filename("${CMAKE_CURRENT_BINARY_DIR}",c_name),Path.build_filename("${CMAKE_CURRENT_SOURCE_DIR}",this._name)));
				dataStream.put_string("\n\tCOMMAND glib-compile-resources --sourcedir=${CMAKE_CURRENT_SOURCE_DIR} --generate-header --target=%s %s\n".printf(Path.build_filename("${CMAKE_CURRENT_BINARY_DIR}",h_name),Path.build_filename("${CMAKE_CURRENT_SOURCE_DIR}",this._name)));
				dataStream.put_string(")\n\n");
				dataStream.put_string("add_custom_target(%s DEPENDS %s)\n".printf(this.identifier,Path.build_filename("${CMAKE_CURRENT_BINARY_DIR}/",c_name)));
				dataStream.put_string("SET (%s_C_FILE %s PARENT_SCOPE)\n".printf(this.identifier,Path.build_filename("${CMAKE_CURRENT_BINARY_DIR}/",c_name)));
				dataStream.put_string("SET (%s_H_FILE %s PARENT_SCOPE)\n".printf(this.identifier,Path.build_filename("${CMAKE_CURRENT_BINARY_DIR}/",h_name)));
				//dataStream.put_string("add_dependencies(%s do_%s)\n\n".printf(,c_name));
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to install local files at %s").printf(this.fullPath));
				return true;
			}
			return false;
		}

		public override bool storeConfig(DataOutputStream dataStream,ConditionalText printConditions) {

			try {
				if (this._automatic) {
					dataStream.put_string("*");
				}
				dataStream.put_string("gresource: %s %s\n".printf(this.identifier,this.fullPath));
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to store 'gresource: %s %s' at config").printf(this.identifier,this.fullPath));
				return true;
			}
			return false;
		}
	}
}
