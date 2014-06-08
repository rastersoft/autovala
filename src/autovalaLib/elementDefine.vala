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

	private class ElementDefine : ElementBase {

		public ElementDefine() {
			this._type = ConfigType.DEFINE;
			this.command = "define";
		}

		public override bool configureLine(string line, bool automatic, string? condition, bool invertCondition, int lineNumber) {

			if (false == line.has_prefix("define: ")) {
				var badCommand = line.split(": ")[0];
				ElementBase.globalData.addError(_("Invalid command %s after command %s (line %d)").printf(badCommand,this.command, lineNumber));
				return true;
			}
			// The line starts with 'define: '
			var data=line.substring(8).strip();
			return this.addNewDefine(data,automatic);
		}

		public bool addNewDefine(string data,bool automatic=true) {

			foreach (var element in ElementBase.globalData.globalElements) {
				if (element.name == data) {
					return false; // this DEFINE already exists
				}
			}
			return this.configureElement(null,data,data,automatic,null,false);
		}

		public override bool autoConfigure(string? path=null) {
			return false;
		}
	}
}
