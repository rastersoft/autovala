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

	class ElementEosPlug : ElementBase {

		public ElementEosPlug() {
			this._type = ConfigType.EOS_PLUG;
			this.command = "eos_plug";
		}

		public override bool generateCMake(DataOutputStream dataStream) {

			try {
				dataStream.put_string("configure_file(${CMAKE_CURRENT_SOURCE_DIR}/"+this.file+" ${CMAKE_CURRENT_BINARY_DIR}/"+this.file+")\n");
				dataStream.put_string("install(FILES ${CMAKE_CURRENT_BINARY_DIR}/"+this.file+" DESTINATION lib/plugs/"+ElementBase.globalData.projectName+"/"+ElementBase.globalData.projectName+"/)\n");
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to add file %s").printf(this.file));
			}
			return false;
		}
	}
}
