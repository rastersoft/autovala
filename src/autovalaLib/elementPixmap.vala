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

	private class ElementPixmap : ElementBase {

		public ElementPixmap() {
			this._type = ConfigType.PIXMAP;
			this.command = "pixmap";
		}

		public static bool autoGenerate() {

			bool error=false;
			var filePath = File.new_for_path(Path.build_filename(ElementBase.globalData.projectFolder,"data","pixmaps"));

			if (filePath.query_exists()) {
				var files = ElementBase.getFilesFromFolder("data/pixmaps",{".png",".svg",".jpg"},true);
				foreach (var file in files) {
					var element = new ElementPixmap();
					error|=element.autoConfigure(file);
				}
			}
			return error;
		}


		public override bool generateCMake(DataOutputStream dataStream) {

			try {
				dataStream.put_string("install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/"+this.name+" DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/"+ElementBase.globalData.projectName+"/ )\n");
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to add pixmap %s").printf(this.fullPath));
				return true;
			}
			return false;
		}

		public override bool generateMeson(ConditionalText dataStream, MesonCommon mesonCommon) {

			try {
				var origin = GLib.Path.build_filename(this._path,this._name);
				dataStream.put_string("install_data('%s',install_dir: join_paths(get_option('prefix'),get_option('datadir'),'%s'))\n".printf(origin,ElementBase.globalData.projectName));
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to write to meson.build at '%s' element, at '%s' path: %s").printf(this.command,this._path,e.message));
				return true;
			}
			return false;
		}
	}
}
