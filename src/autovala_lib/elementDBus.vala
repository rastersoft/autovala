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

	class ElementDBusService : ElementBase {

		private static bool addedDBusPrefix;

		public ElementDBusService() {
			addedDBusPrefix=false;
			this._type = ConfigType.DBUS_SERVICE;
			this.command = "dbus_service";
		}

		public override bool generateCMake(DataOutputStream dataStream, ConfigType type) {

			// only process this file if it is of the desired type
			if (type!=this.eType) {
				return false;
			}

			if (ElementDBusService.addedDBusPrefix==false) {
				try {
					dataStream.put_string("SET(DBUS_PREFIX ${AUTOVALA_INSTALL_PREFIX})\n");
					ElementDBusService.addedDBusPrefix=true;
				} catch (Error e) {
					ElementBase.globalData.addError(_("Can't append data to CMakeLists file at %s").printf(this._path));
					return true;
				}
			}

			try {
				// DBus files must use DBUS_PREFIX in their path, instead of a fixed one, to allow them to be installed both in /usr or /usr/local
				dataStream.put_string("configure_file(${CMAKE_CURRENT_SOURCE_DIR}/"+this.file+" ${CMAKE_CURRENT_BINARY_DIR}/"+this.file+")\n");
				dataStream.put_string("install(FILES ${CMAKE_CURRENT_BINARY_DIR}/"+this.file+" DESTINATION ${CMAKE_INSTALL_PREFIX}/share/dbus-1/services/)\n");
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to write the CMakeLists file for %s").printf(this.file));
				return true;
			}

			return false;
		}

		public virtual bool generateCMakePostData(DataOutputStream dataStream, ConfigType type) {
			ElementDBusService.addedDBusPrefix=false; // set the flag to false to allow to add more DBus services in other CMakeList.txt files
			return false;
		}
	}
}
