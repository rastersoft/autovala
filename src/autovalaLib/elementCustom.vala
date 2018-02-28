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
	private class ElementCustom : ElementBase {
		private string source;
		private string destination;

		public ElementCustom() {
			this._type   = ConfigType.CUSTOM;
			this.command = "custom";
		}

		public override void add_files() {
			var file = File.new_for_path(Path.build_filename(ElementBase.globalData.projectFolder, this.source));
			if (file.query_file_type(FileQueryInfoFlags.NONE) == GLib.FileType.DIRECTORY) {
				this.file_list = ElementBase.getFilesFromFolder(this._path, null, true);
			} else {
				this.file_list  = {};
				this.file_list += this.source;
			}
		}

		public override bool configureLine(string line, bool automatic, string ? condition, bool invertCondition, int lineNumber, string[] ? comments) {
			if (false == line.has_prefix("custom: ")) {
				var badCommand = line.split(": ")[0];
				ElementBase.globalData.addError(_("Invalid command %s after command %s (line %d)").printf(badCommand, this.command, lineNumber));
				return true;
			}
			// The line starts with 'custom: '
			var data = line.substring(8).strip().split(" ");
			if (data.length != 2) {
				ElementBase.globalData.addError(_("Custom command needs two parameters (line %d)").printf(lineNumber));
				return true;
			}
			this.source = data[0];
			if (this.source.has_suffix(Path.DIR_SEPARATOR_S)) {
				this.source = this.source.substring(0, this.source.length - 1);
			}
			this.destination = data[1];

			bool retval = this.configureElement(null, null, null, automatic, condition, invertCondition);

			var file = File.new_for_path(Path.build_filename(ElementBase.globalData.projectFolder, this.source));
			if (file.query_file_type(FileQueryInfoFlags.NONE) != FileType.DIRECTORY) {
				this._path = GLib.Path.get_dirname(this.source);
				this._name = GLib.Path.get_basename(this.source);
			} else {
				this._path = this.source;
				this._name = "";
			}
			this.comments = comments;
			return retval;
		}

		public override bool generateCMake(DataOutputStream dataStream) {
			try {
				dataStream.put_string("IF(IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/%s)\n".printf(this.name));
				dataStream.put_string("\tinstall(DIRECTORY\n");
				dataStream.put_string("\t\t${CMAKE_CURRENT_SOURCE_DIR}/%s\n".printf(this.name));
				dataStream.put_string("\tDESTINATION\n");
				dataStream.put_string("\t\t" + this.destination + "\n");
				dataStream.put_string("\t)\n");
				dataStream.put_string("ELSE()\n");
				dataStream.put_string("\tinstall(FILES\n");
				dataStream.put_string("\t\t${CMAKE_CURRENT_SOURCE_DIR}/%s\n".printf(this.name));
				dataStream.put_string("\tDESTINATION\n");
				dataStream.put_string("\t\t" + this.destination + "\n");
				dataStream.put_string("\t)\n");
				dataStream.put_string("ENDIF()\n\n");
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to write the CMakeLists file for custom file %s").printf(this.source));
				return true;
			}
			return false;
		}

		public override bool generateMeson(ConditionalText dataStream, MesonCommon mesonCommon) {
			try {
				string destination;
				if (this.destination[0] == '/') {
					destination = "'%s'".printf(this.destination);
				} else {
					destination = "join_paths(get_option('prefix'),'%s')".printf(this.destination);
				}
				mesonCommon.create_install_script();
				dataStream.put_string("meson.add_install_script(join_paths(meson.current_source_dir(),'meson_scripts','install_data.sh'),%s,join_paths(meson.current_source_dir(),'%s','%s'))\n\n".printf(destination, this._path, this._name));
			} catch (GLib.Error e) {
				ElementBase.globalData.addError(_("Failed to write to meson.build at '%s' element, at '%s' path: %s").printf(this.command, this._path, e.message));
				return true;
			}
			return false;
		}

		public override bool storeConfig(DataOutputStream dataStream, ConditionalText printConditions) {
			try {
				if (this._automatic) {
					dataStream.put_string("*");
				}
				dataStream.put_string("custom: %s %s\n".printf(this.source, this.destination));
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to store 'custom: %s %s' at config").printf(this.source, this.destination));
				return true;
			}
			return false;
		}
	}
}
