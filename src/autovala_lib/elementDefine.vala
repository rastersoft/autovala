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

	class ElementDefine : ElementBase {

		public ElementDefine() {
			this._type = ConfigType.DEFINE;
			this.command = "define";
		}

		public override bool configureLine(string line, bool automatic, string? condition, bool invertCondition) {

			// The line starts with 'define: '
			var data=line.substring(8).strip();

			return this.configureElement(data,data,data,automatic,condition,invertCondition);
		}

		public override bool autoConfigure(string path) {

			return false;
		}

		public override bool generateCMake(DataOutputStream dataStream, ConfigType type) {

			return false;
		}
	}
}
