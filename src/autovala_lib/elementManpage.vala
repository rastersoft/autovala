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

	class ElementManPage : ElementBase {

		private string? language;
		private int pageSection;

		public ElementManPage() {
			this._type = ConfigType.MANPAGE;
			this.command = "manpage";
		}

		public override bool configureLine(string line, bool automatic, string? condition, bool invertCondition, int lineNumber) {

			if (false == line.has_prefix("manpage: ")) {
				var badCommand = line.split(": ")[0];
				ElementBase.globalData.addError(_("Error: invalid command %s after command %s (line %d)").printf(badCommand,this.command, lineNumber));
				return true;
			}
			// The line starts with 'manpage: '
			var data=line.substring(9).strip();

			string filename;

			this.language = null;
			this.pageSection = 1;
			var elements=data.split(" ");
			switch (elements.length) {
			default:
				ElementBase.globalData.addError(_("manpage command needs one, two or three parameters (line %d)").printf(lineNumber));
				return true;
			case 1: // manpage in default language, section 1
				filename=elements[0];
			break;
			case 2: // manpage in specific language, section 1
				filename=elements[0];
				if (elements[1]!="default") {
					language=elements[1];
				}
			break;
			case 3: // manpage in specific language and custom section
				filename=elements[0];
				if (elements[1]!="default") {
					language=elements[1];
				}
				pageSection=int.parse(elements[2]);
				if ((pageSection<1)||(pageSection>9)) {
					ElementBase.globalData.addError(_("Man page section must be a number between 1 and 9 (line %d)").printf(lineNumber));
					return true;
				}
			break;
			}

			return this.configureElement(filename,null,null,automatic,condition,invertCondition);
		}

		public override bool generateCMake(DataOutputStream dataStream, ConfigType type) {

			// only process this file if it is of the desired type
			if (type!=this.eType) {
				return false;
			}

			return false;
		}

		public override bool storeConfig(DataOutputStream dataStream,ConditionalText printConditions) {

			try {
				if (this.automatic) {
					dataStream.put_string("*");
				}
				dataStream.put_string("manpage: "+this.fullPath);
				if ((this.language!=null) || (this.pageSection!=1)) {
					if (this.language!=null) {
						dataStream.put_string(" "+this.language);
					} else {
						dataStream.put_string(" default");
					}
				}
				if (this.pageSection!=1) {
					dataStream.put_string(" %d".printf(this.pageSection));
				}
				dataStream.put_string("\n");
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to store 'manpage: %s' at config").printf(this.fullPath));
				return true;
			}
			return false;
		}
	}
}
