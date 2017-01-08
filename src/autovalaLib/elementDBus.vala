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

	private class ElementDBusService : ElementBase {

		private static bool addedDBusPrefix;

		public ElementDBusService() {
			addedDBusPrefix=false;
			this._type = ConfigType.DBUS_SERVICE;
			this.command = "dbus_service";
		}

		public static bool autoGenerate() {

			bool error=false;
			var filePath = File.new_for_path(Path.build_filename(ElementBase.globalData.projectFolder,"data"));

			if (filePath.query_exists()) {
				var files = ElementBase.getFilesFromFolder("data",{".service",".service.base"},false);
				foreach (var file in files) {
					var element = new ElementDBusService();
					error|=element.autoConfigure(file);
				}
			}
			return error;
		}

		public override bool generateCMakeHeader(DataOutputStream dataStream) {

			if (ElementDBusService.addedDBusPrefix==false) {
				try {
					dataStream.put_string("SET(DBUS_PREFIX ${CMAKE_INSTALL_PREFIX})\n");
					ElementDBusService.addedDBusPrefix=true;
				} catch (Error e) {
					ElementBase.globalData.addError(_("Can't append DBUS data to the header CMakeLists file at %s").printf(this._path));
					return true;
				}
			}
			return false;
		}

		public override bool generateCMake(DataOutputStream dataStream) {

			try {
				// DBus files must use DBUS_PREFIX in their path, instead of a fixed one, to allow them to be installed both in /usr or /usr/local
				string final_name;
				if (this.name.has_suffix(".service.base")) {
				    final_name = this.name.substring(0,this.name.length-5);
				} else {
				    final_name = this.name;
				}
				dataStream.put_string("configure_file(${CMAKE_CURRENT_SOURCE_DIR}/"+this.name+" ${CMAKE_CURRENT_BINARY_DIR}/"+final_name+")\n");
				dataStream.put_string("install(FILES ${CMAKE_CURRENT_BINARY_DIR}/"+final_name+" DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/dbus-1/services/)\n");
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to write the CMakeLists file for %s").printf(this.name));
				return true;
			}

			return false;
		}

		public override void endedCMakeFile() {
			ElementDBusService.addedDBusPrefix=false; // set the flag to false to allow to add more DBus services in other CMakeList.txt files
		}

		public override bool generateMesonHeader(DataOutputStream dataStream) {

			if (ElementDBusService.addedDBusPrefix == false) {
				try {
					dataStream.put_string("cfg_dbus_data = configuration_data()\ncfg_dbus_data.set ('DBUS_PREFIX',get_option('prefix'))\n");
					ElementDBusService.addedDBusPrefix = true;
				} catch (Error e) {
					ElementBase.globalData.addError(_("Failed to write to meson.build header at '%s' element, at '%s' path: %s").printf(this.command,this._path,e.message));
					return true;
				}
			}
			return false;
		}

		public override bool generateMeson(DataOutputStream dataStream) {
			try {
				string final_name;
				if (this.name.has_suffix(".service.base")) {
				    final_name = this.name.substring(0,this.name.length-5);
				} else {
				    final_name = this.name;
				}
				var name = this._name.replace("-","_").replace(".","_").replace("+","");
				dataStream.put_string("dbus_cfg_%s = configure_file(input: '%s',output: '%s', configuration: cfg_dbus_data)\n".printf(name,Path.build_filename(this._path,this._name),final_name));
				dataStream.put_string("install_data(dbus_cfg_%s,install_dir: join_paths(get_option('prefix'),get_option('datadir'),'dbus-1','services'))\n".printf(name));
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to write to meson.build at '%s' element, at '%s' path: %s").printf(this.command,this._path,e.message));
				return true;
			}
			return false;
		}

		public override void endedMeson() {
			ElementDBusService.addedDBusPrefix=false; // set the flag to false to allow to create a new meson file if needed
		}

	}
}
