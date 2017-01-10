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

	private class ElementEosPlug : ElementBase {

		public static bool addedEosPrefix;

		public ElementEosPlug() {
			ElementEosPlug.addedEosPrefix = false;
			this._type = ConfigType.EOS_PLUG;
			this.command = "eos_plug";
		}

		public static bool autoGenerate() {

			bool error=false;
			var filePath = File.new_for_path(Path.build_filename(ElementBase.globalData.projectFolder,"data"));

			if (filePath.query_exists()) {
				var files = ElementBase.getFilesFromFolder("data",{".plug"},false);
				foreach (var file in files) {
					var element = new ElementEosPlug();
					error|=element.autoConfigure(file);
				}
			}
			return error;
		}

		public override bool generateCMake(DataOutputStream dataStream) {

			try {
				dataStream.put_string("configure_file(${CMAKE_CURRENT_SOURCE_DIR}/"+this.name+" ${CMAKE_CURRENT_BINARY_DIR}/"+this.name+")\n");
				dataStream.put_string("install(FILES ${CMAKE_CURRENT_BINARY_DIR}/"+this.name+" DESTINATION lib/plugs/"+ElementBase.globalData.projectName+"/"+ElementBase.globalData.projectName+"/)\n");
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to add file %s").printf(this.name));
			}
			return false;
		}

		public override bool generateMesonHeader(DataOutputStream dataStream) {

			if (ElementEosPlug.addedEosPrefix == false) {
				try {
					dataStream.put_string("cfg_eos_plug_data = configuration_data()\ncfg_eos_plug_data.set ('DBUS_PREFIX',get_option('prefix'))\n");
					ElementEosPlug.addedEosPrefix = true;
				} catch (Error e) {
					ElementBase.globalData.addError(_("Failed to write to meson.build header at '%s' element, at '%s' path: %s").printf(this.command,this._path,e.message));
					return true;
				}
			}
			return false;
		}

		public override bool generateMeson(DataOutputStream dataStream) {
			try {
				var name = this._name.replace("-","_").replace(".","_").replace("+","");
				dataStream.put_string("eos_plug_cfg_%s = configure_file(input: '%s',output: '%s', configuration: cfg_eos_plug_data)\n".printf(name
					,Path.build_filename(this._path,this._name),this._name));
				dataStream.put_string("install_data(eos_plug_cfg_%s,install_dir: join_paths(get_option('prefix'),'lib','plugs','%s'))\n".printf(name,ElementBase.globalData.projectName));
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to write to meson.build at '%s' element, at '%s' path: %s").printf(this.command,this._path,e.message));
				return true;
			}
			return false;
		}
	}
}
