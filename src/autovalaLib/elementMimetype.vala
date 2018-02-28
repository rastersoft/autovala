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
	private class ElementMimetype : ElementBase {
		public ElementMimetype() {
			this._type   = ConfigType.MIMETYPE;
			this.command = "mimetype";
		}

		public static bool autoGenerate() {
			bool error = false;

			var files = ElementBase.getFilesFromFolder("data", { ".xml" }, true);
			foreach (var file in files) {
				var handle = File.new_for_path(Path.build_filename(ElementBase.globalData.projectFolder, file));

				var    dis = new DataInputStream(handle.read());
				string line;
				// Read lines until end of file (null) is reached
				int  nline = 0;
				bool found = false;
				while ((line = dis.read_line(null)) != null) {
					line = line.strip();
					if (line == "") {
						continue;                         // empty lines don't count
					}
					nline++;
					if (nline == 1) {
						if (!line.has_prefix("<?xml ")) {
							found = false;
							break;
						} else {
							continue;
						}
					}
					if (nline == 2) {
						// The file must have at its second line this text
						if (line.has_prefix("<mime-info ")) {
							found = true;
						}
						break;
					}
				}
				if (found) {
					ElementMimetype element = new ElementMimetype();
					error |= element.autoConfigure(file);
				}
			}
			return error;
		}

		public override bool generateCMake(DataOutputStream dataStream) {
			try {
				dataStream.put_string("install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/" + this.name + " DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/mime/packages/)\n");
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to write the CMakeLists file for %s").printf(this.name));
				return true;
			}

			return false;
		}

		public override bool generateMeson(ConditionalText dataStream, MesonCommon mesonCommon) {
			try {
				dataStream.put_string("install_data( '%s',install_dir: join_paths(get_option('prefix'),get_option('datadir'),'mime','packages'))\n".printf(this._fullPath));
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to write to meson.build at '%s' element, at '%s' path: %s").printf(this.command, this._path, e.message));
				return true;
			}
			return false;
		}
	}
}
