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

	/**
	 * Represents a generic file of the project, with its path, filename, compilation condition...
	 * This class must be inherited by several subclasses, one for each kind of file allowed in AutoVala
	 */

	class ElementDoc : ElementBase {

		public ElementDoc() {
			this._type = ConfigType.DOC;
			this.command = "doc";
		}

		public override bool configureLine(string line, bool automatic, string? condition, bool invertCondition, int lineNumber) {

			// The line starts with 'doc: '
			var data=line.substring(5).strip();
			if (false==data.has_suffix(Path.DIR_SEPARATOR_S)) {
				data+=Path.DIR_SEPARATOR_S;
			}

			return this.configureElement(data,null,null,automatic,condition,invertCondition);
		}

		public override bool generateCMake(DataOutputStream dataStream, ConfigType type) {

			// only process this file if it is of the desired type
			if (type!=this.eType) {
				return false;
			}

			try {
				dataStream.put_string("file(GLOB list_data RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} *)\n");
				dataStream.put_string("foreach(file_data ${list_data})\n");
				dataStream.put_string("\tIF(IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/${file_data})\n");
				dataStream.put_string("\t\tinstall(DIRECTORY\n");
				dataStream.put_string("\t\t\t${file_data}\n");
				dataStream.put_string("\t\tDESTINATION\n");
				dataStream.put_string("\t\t\t"+Path.build_filename("share/doc",ElementBase.globalData.projectName)+"\n");
				dataStream.put_string("\t\t)\n");
				dataStream.put_string("\tELSE()\n");
				dataStream.put_string("\t\tinstall(FILES\n");
				dataStream.put_string("\t\t\t${file_data}\n");
				dataStream.put_string("\t\tDESTINATION\n");
				dataStream.put_string("\t\t\t"+Path.build_filename("share/doc",ElementBase.globalData.projectName)+"\n");
				dataStream.put_string("\t\t)\n");
				dataStream.put_string("\tENDIF()\n");
				dataStream.put_string("endforeach()\n\n");
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to install document files at %s").printf(this.fullPath));
				return true;
			}
			return false;
		}
	}
}
