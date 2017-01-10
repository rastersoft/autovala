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

	private class ElementSDepend : ElementBase {

		public ElementSDepend() {
			this._type = ConfigType.SOURCE_DEPENDENCY;
			this.command = "source_dependency";
		}

		public override void add_files() {
			this.file_list = {};
		}

		public override bool autoConfigure(string? path=null) {
			return false;
		}

		public override bool configureLine(string line, bool automatic, string? condition, bool invertCondition, int lineNumber, string[]? comments) {

			if (false == line.has_prefix(this.command+": ")) {
				var badCommand = line.split(": ")[0];
				ElementBase.globalData.addError(_("Invalid command %s after command %s (line %d)").printf(badCommand,this.command, lineNumber));
				return true;
			}
			var data = line.substring(2 + this.command.length).strip();
			this.comments = comments;
			return this.configureElement(null,data,data,false,condition,invertCondition);
		}

		public override bool generateMeson(DataOutputStream dataStream, MesonCommon mesonCommon) {
			try {
				var elements = this._name.split(" ");
				if (elements.length > 1) {
					dataStream.put_string("run_command('/prueba.sh')\n");
					return false; // at this moment we can't check the existence of one of several files
				}
				string data = "";
				foreach (var element in elements) {
					if (data != "") {
						data += ", ";
					}
					data += "'%s'".printf(element);
				}
				dataStream.put_string("files([%s])\n".printf(data));
			} catch (GLib.Error e) {
				ElementBase.globalData.addError(_("Failed to write to meson.build at '%s' element, at '%s' path: %s").printf(this.command,this._path,e.message));
				return true;
			}
			return false;
		}
	}
}
