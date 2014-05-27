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

	private class ElementBinary : ElementBase {

		public ElementBinary() {
			this._type = ConfigType.BINARY;
			this.command = "binary";
		}

		public static bool autoGenerate() {

			bool error=false;
			var filePath = File.new_for_path(Path.build_filename(ElementBase.globalData.projectFolder,"data"));

			if (filePath.query_exists()) {
				var files = ElementBase.getFilesFromFolder("data",{".sh"},false);
				foreach (var file in files) {
					var element = new ElementBinary();
					error|=element.autoConfigure(file);
				}
			}
			return error;
		}

		public override bool generateCMake(DataOutputStream dataStream) {

			try {
				dataStream.put_string("install(PROGRAMS ${CMAKE_CURRENT_SOURCE_DIR}/"+this.name+" DESTINATION ${CMAKE_INSTALL_BINDIR})\n");
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to add binary %s").printf(this.name));
				return true;
			}

			return false;
		}
	}
}
