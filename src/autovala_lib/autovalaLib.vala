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
				var mainPath = GLib.Path.build_filename(this.globalData.projectFolder,"CMakeLists.txt");
				var file = File.new_for_path(mainPath);
				if (file.query_exists()) {
					file.delete();
				}
				var dis = file.create(FileCreateFlags.NONE);
				var dataStream = new DataOutputStream(dis);
				error |= globalElement.generateMainCMakeHeader(dataStream);

				// and now, generate each one of the CMakeLists.txt files in each folder
				foreach(var path in this.globalData.pathList) {
					var fullPath = GLib.Path.build_filename(this.globalData.projectFolder,path,"CMakeLists.txt");
					file = File.new_for_path(fullPath);
					if (file.query_exists()) {
						file.delete();
					}
					dis = file.create(FileCreateFlags.NONE);
					dataStream = new DataOutputStream(dis);

					error |= globalElement.generateCMakeHeader(dataStream);
					foreach(var element in this.globalData.globalElements) {
						if (element.path!=path) {
							continue;
						}
						error |= element.generateCMakeHeader(dataStream);
					}

					var condition = new ConditionalText(dataStream,true);
					error |= globalElement.generateCMake(dataStream);
					foreach(var element in this.globalData.globalElements) {
						if (element.path!=path) {
							continue;
						}
						condition.printCondition(element.condition,element.invertCondition);
						error |= element.generateCMake(dataStream);
					}
					condition.printTail();

					error |= globalElement.generateCMakePostData(dataStream);
					foreach(var element in this.globalData.globalElements) {
						if (element.path!=path) {
							continue;
						}
						error |= element.generateCMakePostData(dataStream);
					}

					globalElement.endedCMakeFile();
					foreach(var element in this.globalData.globalElements) {
						if (element.path!=path) {
							continue;
						}
						element.endedCMakeFile();
					}
					dataStream.close();
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
			ElementBase.globalData.clearAutomatic();
			ElementBase.globalData.generateExtraData();

			// refresh the automatic configuration for the manually set elements 
			foreach (var element in ElementBase.globalData.globalElements) {
				element.autoConfigure();
			}

			error|=ElementPo.autoGenerate();
			error|=ElementIcon.autoGenerate();
			error|=ElementPixmap.autoGenerate();
			error|=ElementDesktop.autoGenerate();
			error|=ElementDBusService.autoGenerate();
			error|=ElementEosPlug.autoGenerate();
			error|=ElementScheme.autoGenerate();
			error|=ElementGlade.autoGenerate();
			error|=ElementBinary.autoGenerate();
			error|=ElementData.autoGenerate();
			error|=ElementDoc.autoGenerate();
			error|=ElementManPage.autoGenerate();
			error|=ElementValaBinary.autoGenerate();

			if (error==false) {
				error|=config.saveConfiguration();
			}

			return error;
		}

	}
}
