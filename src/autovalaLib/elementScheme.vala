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

	private class ElementScheme : ElementBase {

		private bool addedSchemePrefix;

		public ElementScheme() {
			this._type = ConfigType.SCHEME;
			this.command = "scheme";
			this.addedSchemePrefix=false;
		}

		public static bool autoGenerate() {

			bool error=false;
			var filePath = File.new_for_path(Path.build_filename(ElementBase.globalData.projectFolder,"data"));

			if (filePath.query_exists()) {
				var files = ElementBase.getFilesFromFolder("data",{".gschema.xml"},false);
				foreach (var file in files) {
					var element = new ElementScheme();
					error|=element.autoConfigure(file);
				}
			}
			return error;
		}

		public override bool generateCMake(DataOutputStream dataStream) {

			try {
				if (addedSchemePrefix==false) {
					dataStream.put_string("include(GSettings)\n");
					addedSchemePrefix=true;
				}
				dataStream.put_string("add_schema("+this.name+")\n");
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to add schema %s").printf(this.name));
				return true;
			}
			return false;
		}

		public override bool generateMeson(ConditionalText dataStream, MesonCommon mesonCommon) {

			try {
				var origin = GLib.Path.build_filename(this._path,this._name);
				dataStream.put_string("install_data('%s', install_dir: join_paths(get_option('prefix'),get_option('datadir'), 'glib-2.0', 'schemas'))\n".printf(origin));
				dataStream.put_string("meson.add_install_script('meson_scripts/install_schemas.py')\n");
				mesonCommon.create_schemas_script();
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to write to meson.build at '%s' element, at '%s' path: %s").printf(this.command,this._path,e.message));
				return true;
			}
			return false;
		}
	}
}
