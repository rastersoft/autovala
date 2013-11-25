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
//using GIO;

namespace AutoVala {

	class ElementCustom : ElementBase {

		private string destination;

		public ElementCustom() {
			this._type = ConfigType.CUSTOM;
			this.command = "custom";
		}

		public override bool configureLine(string line, bool automatic, string? condition, bool invertCondition, int lineNumber) {

			// The line starts with 'custom: '
			var data=line.substring(8).strip().split(" ");
			if (data.length!=2) {
				ElementBase.globalData.addError(_("custom command needs two parameters (line %d)").printf(lineNumber));
				return true;
			}
			var file = data[0];
			this.destination = data[1];

			return this.configureElement(file,null,null,automatic,condition,invertCondition);
		}

		public override bool generateCMake(DataOutputStream dataStream, ConfigType type) {

			// only process this file if it is of the desired type
			if (type!=this.eType) {
				return false;
			}

			string finalDestination;
			if (this.destination[0]!='/') {
				finalDestination=this.destination;
			} else {
				finalDestination="${FINAL_AUTOVALA_PATH}%s".printf(this.destination);
			}
			try {
				dataStream.put_string("IF(IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/%s)\n".printf(this.file));
				dataStream.put_string("\tinstall(DIRECTORY\n");
				dataStream.put_string("\t\t${CMAKE_CURRENT_SOURCE_DIR}/%s\n".printf(this.file));
				dataStream.put_string("\tDESTINATION\n");
				dataStream.put_string("\t\t"+finalDestination+"\n");
				dataStream.put_string("\t)\n");
				dataStream.put_string("ELSE()\n");
				dataStream.put_string("\tinstall(FILES\n");
				dataStream.put_string("\t\t${CMAKE_CURRENT_SOURCE_DIR}/%s\n".printf(this.file));
				dataStream.put_string("\tDESTINATION\n");
				dataStream.put_string("\t\t"+finalDestination+"\n");
				dataStream.put_string("\t)\n");
				dataStream.put_string("ENDIF()\n\n");
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to write the CMakeLists file for custom file %s").printf(this.file));
				return true;
			}
			return false;
		}

		public override bool storeConfig(DataOutputStream dataStream, ConfigType type) {

			// only process this file if it is of the desired type
			if (type!=this.eType) {
				return false;
			}

			try {
				if (this.automatic) {
					dataStream.put_string("*");
				}
				dataStream.put_string("custom: %s %s\n".printf(this.fullPath, this.destination));
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to store 'custom: %s %s' at config").printf(this.fullPath, this.destination));
				return true;
			}
			return false;
		}
	}
}
