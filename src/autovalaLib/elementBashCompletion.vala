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

	class ElementBashCompletion : ElementBase {

		public ElementBashCompletion() {
			this._type = ConfigType.BASH_COMPLETION;
			this.command = "bash_completion";
		}

		public static bool autoGenerate() {

			bool error=false;
			var filePath = File.new_for_path(Path.build_filename(ElementBase.globalData.projectFolder,"data/bash_completion"));

			if (filePath.query_exists()) {
				var files = ElementBase.getFilesFromFolder("data/bash_completion",null,false);
				foreach (var file in files) {
					var element = new ElementBashCompletion();
					error|=element.autoConfigure(file);
				}
			}
			return error;
		}

		public override bool generateCMake(DataOutputStream dataStream) {

			try {
				dataStream.put_string("IF( NOT ( ${CMAKE_INSTALL_PREFIX} MATCHES \"^/home/\" ) )\n");
				dataStream.put_string("\tEXEC_PROGRAM (\n");
				dataStream.put_string("\t\tpkg-config\n");
				dataStream.put_string("\tARGS\n");
				dataStream.put_string("\t\t--variable=completionsdir bash-completion\n");
				dataStream.put_string("\tOUTPUT_VARIABLE INSTALL_BASH_COMPLETION\n");
				dataStream.put_string("\t)\n\n");
				dataStream.put_string("\tIF( NOT ( INSTALL_BASH_COMPLETION STREQUAL \"\" ))\n");
				dataStream.put_string("\t\tinstall(FILES\n");
				dataStream.put_string("\t\t\t${CMAKE_CURRENT_SOURCE_DIR}/%s\n".printf(this.name));
				dataStream.put_string("\t\tDESTINATION\n");
				dataStream.put_string("\t\t\t${INSTALL_BASH_COMPLETION}\n");
				dataStream.put_string("\t\t)\n");
				dataStream.put_string("\tENDIF()\n\n");
				dataStream.put_string("ENDIF()\n\n");
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to write the CMakeLists file for custom file %s").printf(this.name));
				return true;
			}
			return false;
		}

		public override bool generateMeson(DataOutputStream dataStream) {
			try {
				var counter = Globals.counter;
				dataStream.put_string("runoutput_%d = run_command('pkg-config',['--variable=completionsdir','bash-completion'])\n".printf(counter));
				dataStream.put_string("if (runoutput_%d.stdout().strip() != '')\n".printf(counter));
				dataStream.put_string("\tinstallfile_%d = files('%s')\n".printf(counter,Path.build_filename(this._path,this._name)));
				dataStream.put_string("\tinstall_data(installfile_%d, install_dir: runoutput_%d.stdout().strip())\n".printf(counter,counter));
				dataStream.put_string("else\n");
				dataStream.put_string("\tmessage('%s')\n".printf(_("Bash completion isn't installed. Definitions will not be built.").replace("'","\\'")));
				dataStream.put_string("endif\n");
			} catch (GLib.Error e) {
				ElementBase.globalData.addError(_("Failed to write to meson.build file at elementBashCompletion: %s").printf(e.message));
				return true;
			}
			return false;
		}
	}
}
