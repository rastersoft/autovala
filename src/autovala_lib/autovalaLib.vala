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
using Gee;
using Posix;
//using GIO

namespace AutoVala {

	class ManageProject: GLib.Object {

		private AutoVala.Configuration config;
		private AutoVala.Globals globalData;

		public ManageProject() {
			this.config = new AutoVala.Configuration();
			this.globalData = ElementBase.globalData;
		}

		public bool init(string projectName) {
			return false;
		}

		public void showErrors() {
			this.config.showErrors();
		}

		public bool cmake() {

			bool error;

			error=config.readConfiguration();
			if (error) {
				return true;
			}
			this.globalData.generateExtraData();
			var globalElement = new ElementGlobal();
			try {
				foreach(var path in this.globalData.pathList) {
					var fullPath = GLib.Path.build_filename(this.globalData.projectFolder,path,"CMakeLists.txt");
					var file = File.new_for_path(fullPath);
					if (file.query_exists()) {
						file.delete();
					}
					var dis = file.create(FileCreateFlags.NONE);
					var dataStream = new DataOutputStream(dis);
					foreach(var element in this.globalData.globalElements) {
						if (element.path!=path) {
							continue;
						}
						error |= globalElement.generateCMakeHeader(dataStream);
						error |= element.generateCMakeHeader(dataStream);
						error |= globalElement.generateCMake(dataStream);
						error |= element.generateCMake(dataStream);
						error |= globalElement.generateCMakePostData(dataStream);
						error |= element.generateCMakePostData(dataStream);
					}
					foreach(var element in this.globalData.globalElements) {
						if (element.path!=path) {
							continue;
						}
						element.endedCMakeFile();
					}
				}
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed while generating the CMakeLists.txt files"));
				return true;
			}
			return error;
		}

		public bool refresh() {

			bool error;

			error=config.readConfiguration();
			error|=config.saveConfiguration();

			return false;
		}

	}
}
