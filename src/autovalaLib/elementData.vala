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

namespace AutoVala {

	private class ElementData : ElementBase {

		public ElementData() {
			this._type = ConfigType.DATA;
			this.command = "data";
		}

		public static bool autoGenerate() {

			bool error=false;
			var filePath = File.new_for_path(Path.build_filename(ElementBase.globalData.projectFolder,"data/local"));

			if (filePath.query_exists()) {
				var element = new ElementData();
				error|=element.autoConfigure("data/local");
			}
			return error;
		}


		public override void add_files() {

			this.file_list = ElementBase.getFilesFromFolder(this._path,null,true);
		}

		public override bool generateCMake(DataOutputStream dataStream) {

			try {
				dataStream.put_string("file(GLOB list_data RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} *)\n");
				dataStream.put_string("foreach(file_data ${list_data})\n");
				dataStream.put_string("\tIF(IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/${file_data})\n");
				dataStream.put_string("\t\tinstall(DIRECTORY\n");
				dataStream.put_string("\t\t\t${file_data}\n");
				dataStream.put_string("\t\tDESTINATION\n");
				dataStream.put_string("\t\t\t"+Path.build_filename("${CMAKE_INSTALL_DATAROOTDIR}",ElementBase.globalData.projectName)+"\n");
				dataStream.put_string("\t\t)\n");
				dataStream.put_string("\tELSE()\n");
				dataStream.put_string("\t\tinstall(FILES\n");
				dataStream.put_string("\t\t\t${file_data}\n");
				dataStream.put_string("\t\tDESTINATION\n");
				dataStream.put_string("\t\t\t"+Path.build_filename("${CMAKE_INSTALL_DATAROOTDIR}",ElementBase.globalData.projectName)+"\n");
				dataStream.put_string("\t\t)\n");
				dataStream.put_string("\tENDIF()\n");
				dataStream.put_string("endforeach()\n\n");
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to install local files at %s").printf(this.fullPath));
				return true;
			}
			return false;
		}

		public override bool generateMeson(ConditionalText dataStream, MesonCommon mesonCommon) {
			try {
				mesonCommon.create_install_script();
				dataStream.put_string("meson.add_install_script(join_paths(meson.current_source_dir(),'meson_scripts','install_data.sh'),join_paths(get_option('prefix'),get_option('datadir'),'%s'),join_paths(meson.current_source_dir(),'%s','%s','*'))\n\n".printf(ElementBase.globalData.projectName,this._path,this._name));
			} catch (GLib.Error e) {
				ElementBase.globalData.addError(_("Failed to write to meson.build file at '%s' element, at '%s' path: %s").printf(this.command,this._path,e.message));
				return true;
			}
			return false;
		}
	}
}
