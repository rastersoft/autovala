/*
 * Copyright 2013 (C) Raster Software Vigo (Sergio Costas)
 *
 * This file is part of AutoVala
 *
 * AutoVala is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * AutoVala is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>. */

using GLib;

namespace AutoVala {
	private class ElementPolkit : ElementBase {
		public ElementPolkit() {
			this._type   = ConfigType.POLKIT;
			this.command = "polkit";
		}

		public static bool autoGenerate() {
			bool error = false;

			var files = ElementBase.getFilesFromFolder("data", { ".policy" }, true);
			foreach (var file in files) {
				ElementPolkit element = new ElementPolkit();
				error |= element.autoConfigure(file);
			}
			return error;
		}

		public override bool generateCMake(DataOutputStream dataStream) {
			try {
				dataStream.put_string("install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/" + this.name + " DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/polkit-1/actions/)\n");
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to write the CMakeLists file for %s").printf(this.name));
				return true;
			}

			return false;
		}

		public override bool generateMeson(ConditionalText dataStream, MesonCommon mesonCommon) {
			try {
				dataStream.put_string("install_data( '%s',install_dir: join_paths(get_option('prefix'),get_option('datadir'),'polkit-1','actions'))\n".printf(this._fullPath));
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to write to meson.build at '%s' element, at '%s' path: %s").printf(this.command, this._path, e.message));
				return true;
			}
			return false;
		}
	}
}
