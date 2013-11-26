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

	class ElementScheme : ElementBase {

		private bool addedSchemePrefix;

		public ElementScheme() {
			this._type = ConfigType.SCHEME;
			this.command = "scheme";
			this.addedSchemePrefix=false;
		}

		public override bool generateCMake(DataOutputStream dataStream, ConfigType type) {

			// only process this file if it is of the desired type
			if (type!=this.eType) {
				return false;
			}
			try {
				if (addedSchemePrefix==false) {
					dataStream.put_string("include(GSettings)\n");
					addedSchemePrefix=true;
				}
				dataStream.put_string("add_schema("+this.file+")\n");
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to add schema %s").printf(this.file));
				return true;
			}
			return false;
		}
	}
}
