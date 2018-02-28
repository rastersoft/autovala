/*
 * Copyright 2015 (C) Raster Software Vigo (Sergio Costas)
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
	private class ElementAppData : ElementBase {
		public ElementAppData() {
		}

		public static bool autoGenerate() {
			bool error    = false;
			var  filePath = File.new_for_path(Path.build_filename(ElementBase.globalData.projectFolder, "data"));

			if (filePath.query_exists()) {
				var files = ElementBase.getFilesFromFolder("data", { ".appdata.xml", ".metainfo.xml" }, false);
				foreach (var file in files) {
					var element = new ElementAppData();
					error |= element.autoConfigure(file);
				}
			}
			return error;
		}

		public override bool configureLine(string line, bool automatic, string ? condition, bool invertCondition, int lineNumber, string[] ? comments) {
			// The line starts with 'appdata: '
			if (line.has_prefix("appdata: ")) {
				this._type   = ConfigType.APPDATA;
				this.command = "appdata";
			} else {
				var badCommand = line.split(": ")[0];
				ElementBase.globalData.addError(_("Invalid command %s after command %s (line %d)").printf(badCommand, this.command, lineNumber));
				return true;
			}
			var data = line.substring(2 + this.command.length).strip();
			this.comments = comments;
			return this.configureElement(data, null, null, automatic, condition, invertCondition);
		}

		public override bool autoConfigure(string ? pathP = null) {
			string path;
			if (pathP == null) {
				path = this.fullPath;
			} else {
				path = pathP;
			}
			this._type   = ConfigType.APPDATA;
			this.command = "appdata";

			if (pathP != null) {
				return this.configureElement(path, null, null, true, null, false);
			} else {
				return false;
			}
		}

		public override bool generateCMake(DataOutputStream dataStream) {
			try {
				dataStream.put_string("install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/" + this.name + " DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/appdata/ )\n");
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to add file %s").printf(this.name));
				return true;
			}
			return false;
		}

		public override bool generateMeson(ConditionalText dataStream, MesonCommon mesonCommon) {
			try {
				var counter = Globals.counter;
				dataStream.put_string("installfile_%d = files('%s')\n".printf(counter, Path.build_filename(this._path, this._name)));
				dataStream.put_string("install_data(installfile_%d, install_dir: join_paths(get_option('prefix'),'appdata'))\n".printf(counter));
			} catch (GLib.Error e) {
				ElementBase.globalData.addError(_("Failed to write to meson.build at '%s' element, at '%s' path: %s").printf(this.command, this._path, e.message));
				return true;
			}
			return false;
		}
	}
}
