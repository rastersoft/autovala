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

	private class ElementExternal : ElementBase {

		public string owner;
		public string data;

		public ElementExternal() {
			this._type = ConfigType.EXTERNAL;
			this.command = "external";
		}

		public override bool configureLine(string originalLine, bool automatic, string? condition, bool invertCondition, int lineNumber, string[]? comments) {

			if (false == originalLine.has_prefix("external: ")) {
				var badCommand = originalLine.split(": ")[0];
				ElementBase.globalData.addError(_("Invalid command %s after command %s (line %d)").printf(badCommand,this.command, lineNumber));
				return true;
			}

			// The line starts with 'external: '
			var line = originalLine.substring(10).strip();
			var pos = line.index_of_char(' ');
			if (pos == -1) {
				ElementBase.globalData.addError(_("External command needs two parameters (line %d)").printf(lineNumber));
				return true;
			}

			this.owner = line.substring(0,pos).strip();
			this.data = line.substring(pos).strip();
			this.comments = comments;
			return this.configureElement(null,null,null,false,condition,invertCondition);
		}

		public override bool storeConfig(DataOutputStream dataStream,ConditionalText printConditions) {

			if (this.data == "") {
				return false;
			}

			try {
				dataStream.put_string("external: %s %s\n".printf(this.owner, this.data));
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to store 'external: %s %s' at config").printf(this.owner, this.data));
				return true;
			}
			return false;
		}

		public override string? getSortId() {
			return this.owner + " " + this.data;
		}
	}
}
