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

// project version=0.94

namespace AutoVala {

	public class ManageProject: GLib.Object {

		private Configuration config;

		public ManageProject() {
		}

		public void showErrors() {
			this.config.showErrors();
		}

		private bool copy_recursive (string srcS, string destS) {

			var src=File.new_for_path(srcS);
			var dest=File.new_for_path(destS);

			GLib.FileType srcType = src.query_file_type (GLib.FileQueryInfoFlags.NONE, null);
			if (srcType == GLib.FileType.DIRECTORY) {
				try {
					dest.make_directory (null);
					src.copy_attributes (dest, GLib.FileCopyFlags.NONE, null);
				} catch (Error e) {
					ElementBase.globalData.addError(_("Failed when creating folder %s").printf(destS));
					return true;
				}

				string srcPath = src.get_path ();
				string destPath = dest.get_path ();
				try {
					GLib.FileEnumerator enumerator = src.enumerate_children (GLib.FileAttribute.STANDARD_NAME, GLib.FileQueryInfoFlags.NONE, null);
					for ( GLib.FileInfo? info = enumerator.next_file (null) ; info != null ; info = enumerator.next_file (null) ) {
						if (copy_recursive (GLib.Path.build_filename (srcPath, info.get_name ()),GLib.Path.build_filename (destPath, info.get_name ()))) {
							return true;
						}
					}
				} catch (Error e) {
					ElementBase.globalData.addError(_("Failed when copying recursively the folder %s to %s").printf(srcS,destS));
					return true;
				}
			} else if ( srcType == GLib.FileType.REGULAR ) {
				try {
					src.copy (dest, GLib.FileCopyFlags.NONE, null);
				} catch (Error e) {
					ElementBase.globalData.addError(_("Failed when copying the file %s to %s").printf(srcS,destS));
					return true;
				}
			}
			return false;
		}

		private bool delete_recursive (string fileFolder) {

			var src=File.new_for_path(fileFolder);

			GLib.FileType srcType = src.query_file_type (GLib.FileQueryInfoFlags.NONE, null);
			if (srcType == GLib.FileType.DIRECTORY) {
				string srcPath = src.get_path ();
				try {
					GLib.FileEnumerator enumerator = src.enumerate_children (GLib.FileAttribute.STANDARD_NAME, GLib.FileQueryInfoFlags.NONE, null);
					for ( GLib.FileInfo? info = enumerator.next_file (null) ; info != null ; info = enumerator.next_file (null) ) {
						if (delete_recursive (GLib.Path.build_filename (srcPath, info.get_name ()))) {
							return true;
						}
					}
				} catch (Error e) {
					ElementBase.globalData.addError(_("Failed when deleting recursively the folder %s").printf(fileFolder));
					return true;
				}
			}
			try {
				src.delete();
			} catch (Error e) {
				if (srcType != GLib.FileType.DIRECTORY) {
					ElementBase.globalData.addError(_("Failed when deleting the file %s").printf(fileFolder));
				}
				return true;
			}
			return false;
		}


		private bool createPath(string configPath, string path) {
			try {
				var folder=File.new_for_path(Path.build_filename(configPath,path));
				if (folder.query_exists()) {
					ElementBase.globalData.addWarning(_("The folder '%s' already exists").printf(path));
				} else {
					folder.make_directory_with_parents();
				}
			} catch (Error e) {
				ElementBase.globalData.addError(_("Can't create the folder '%s'").printf(path));
				return true;
			}
			return false;
		}

		public bool init(string projectName) {

			bool error=false;

			this.config=new AutoVala.Configuration(projectName,false);
			if(this.config.globalData.error) {
				return true; // if there was at least one error during initialization, return
			}
			string configPath=Posix.realpath(GLib.Environment.get_current_dir());
			var directory=File.new_for_path(configPath);

			try {
				var enumerator = directory.enumerate_children(FileAttribute.STANDARD_NAME, 0);
				FileInfo file_info;
				while ((file_info = enumerator.next_file ()) != null) {
					if (file_info.get_name().has_suffix(".avprj")) {
						ElementBase.globalData.addError(_("There's already a project in folder %s").printf(configPath));
						return true; // there's already a project here!!!!
					}
				}
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to list path %s").printf(configPath));
				return true;
			}


			var folder=File.new_for_path(Path.build_filename(configPath,"cmake"));
			if (folder.query_exists()) {
				ElementBase.globalData.addWarning(_("The 'cmake' folder already exists"));
			} else {
				this.copy_recursive(Path.build_filename(AutoValaConstants.PKGDATADIR,"cmake"),Path.build_filename(configPath,"cmake"));
			}

			error|=this.createPath(configPath,"src");
			error|=this.createPath(configPath,"src/vapis");
			error|=this.createPath(configPath,"po");
			error|=this.createPath(configPath,"doc");
			error|=this.createPath(configPath,"install");
			error|=this.createPath(configPath,"data");
			error|=this.createPath(configPath,"data/icons");
			error|=this.createPath(configPath,"data/pixmaps");
			error|=this.createPath(configPath,"data/interface");
			error|=this.createPath(configPath,"data/local");

			try {
				var srcFile=File.new_for_path(Path.build_filename(configPath,"src",projectName+".vala"));
				if (false==srcFile.query_exists()) {
					srcFile.create(FileCreateFlags.NONE);
				}
			} catch (Error e) {
				ElementBase.globalData.addWarning(_("Can't create the initial source file"));
			}

			this.config.globalData.valaVersionMajor=this.config.globalData.valaMajor;
			this.config.globalData.valaVersionMinor=this.config.globalData.valaMinor;
			this.config.globalData.setConfigFilename(projectName+".avprj");
			if (error==false) {
				error |= this.config.saveConfiguration();
			}
			return error;
		}

		public bool cmake() {

			bool error;

			this.config = new AutoVala.Configuration();
			if(this.config.globalData.error) {
				return true; // if there was at least one error during initialization, return
			}
			var globalData = ElementBase.globalData;

			error=config.readConfiguration();
			if (error) {
				return true;
			}

			string configPath=this.config.globalData.projectFolder;
			var folder=File.new_for_path(Path.build_filename(configPath,"cmake"));
			if (folder.query_exists()) {
				this.delete_recursive(Path.build_filename(configPath,"cmake"));
			}
			this.copy_recursive(Path.build_filename(AutoValaConstants.PKGDATADIR,"cmake"),Path.build_filename(configPath,"cmake"));

			globalData.generateExtraData();
			var globalElement = new ElementGlobal();
			try {
				var mainPath = GLib.Path.build_filename(globalData.projectFolder,"CMakeLists.txt");
				var file = File.new_for_path(mainPath);
				if (file.query_exists()) {
					file.delete();
				}
				var dis = file.create(FileCreateFlags.NONE);
				var dataStream = new DataOutputStream(dis);
				error |= globalElement.generateMainCMakeHeader(dataStream);
				dataStream.close();
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed while generating the main CMakeLists.txt file"));
				return true;
			}

			try {
				// and now, generate each one of the CMakeLists.txt files in each folder
				foreach(var path in globalData.pathList) {
					var fullPath = GLib.Path.build_filename(globalData.projectFolder,path,"CMakeLists.txt");
					var file = File.new_for_path(fullPath);
					if (file.query_exists()) {
						file.delete();
					}
					var dis = file.create(FileCreateFlags.NONE);
					var dataStream = new DataOutputStream(dis);

					error |= globalElement.generateCMakeHeader(dataStream);
					foreach(var element in globalData.globalElements) {
						if (element.path!=path) {
							continue;
						}
						error |= element.generateCMakeHeader(dataStream);
					}

					var condition = new ConditionalText(dataStream,true);
					error |= globalElement.generateCMake(dataStream);
					foreach(var element in globalData.globalElements) {
						if (element.path!=path) {
							continue;
						}
						condition.printCondition(element.condition,element.invertCondition);
						error |= element.generateCMake(dataStream);
					}
					condition.printTail();

					error |= globalElement.generateCMakePostData(dataStream);
					foreach(var element in globalData.globalElements) {
						if (element.path!=path) {
							continue;
						}
						error |= element.generateCMakePostData(dataStream);
					}

					globalElement.endedCMakeFile();
					foreach(var element in globalData.globalElements) {
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

			this.config = new AutoVala.Configuration();
			if(this.config.globalData.error) {
				return true; // if there was at least one error during initialization, return
			}

			error=config.readConfiguration();
			if (error) {
				return true;
			}
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


		public bool gettext() {
			// run xgettext to generate the basic pot file

			this.config = new AutoVala.Configuration();
			if(this.config.globalData.error) {
				return true; // if there was at least one error during initialization, return
			}

			bool error=config.readConfiguration();
			if (error) {
				return true;
			}

			// first, remember the current folder
			string currentDir=GLib.Environment.get_current_dir();
			GLib.Environment.set_current_dir(ElementBase.globalData.projectFolder);
			bool retVal;
			string ls_stdout;
			string ls_stderr;
			int ls_status;

			foreach (var element in ElementBase.globalData.globalElements) {
				if (element.eType==ConfigType.PO) {
					try {
						string callString = "xgettext -d %s -o %s -p %s -a --keyword='_' -f po/POTFILES.in".printf(ElementBase.globalData.projectName,ElementBase.globalData.projectName+".pot",element.path);
						ElementBase.globalData.addMessage(_("Launching command %s").printf(callString));
						retVal=GLib.Process.spawn_command_line_sync(callString,out ls_stdout,out ls_stderr, out ls_status);
					} catch (GLib.SpawnError e) {
						retVal=false;
					}

					if ((!retVal)||(ls_status!=0)) {
						ElementBase.globalData.addWarning(_("Failed to run 'xgettext' to generate the base POT file"));
					}

					ElementBase.globalData.addMessage(_("\nCommand output: %s\nError output: %s\n").printf(ls_stdout,ls_stderr));

					// run msgmerge for all .po files, to update them.
					var potFile=Path.build_filename(ElementBase.globalData.projectFolder,element.path);
					var src = File.new_for_path(potFile);
					GLib.FileType srcType = src.query_file_type (GLib.FileQueryInfoFlags.NONE, null);
					if (srcType == GLib.FileType.DIRECTORY) {
						string srcPath = src.get_path ();
						try {
							GLib.FileEnumerator enumerator = src.enumerate_children (GLib.FileAttribute.STANDARD_NAME, GLib.FileQueryInfoFlags.NONE, null);
							for ( GLib.FileInfo? info = enumerator.next_file (null) ; info != null ; info = enumerator.next_file (null) ) {
								if (info.get_name().has_suffix(".po")) {
									string callString = "msgmerge --update %s %s".printf(Path.build_filename(potFile,info.get_name()),Path.build_filename(potFile,ElementBase.globalData.projectName+".pot"));
									ElementBase.globalData.addMessage(_("Launching command %s").printf(callString));
									try {
										retVal=GLib.Process.spawn_command_line_sync(callString,out ls_stdout,out ls_stderr, out ls_status);
									} catch (GLib.SpawnError e) {
										retVal=false;
									}
									if ((!retVal)||(ls_status!=0)) {
										ElementBase.globalData.addWarning(_("Failed to run msgmerge"));
									}
									ElementBase.globalData.addMessage(_("\nCommand output: %s\nError output: %s\n").printf(ls_stdout,ls_stderr));
								}
							}
						} catch (Error e) {
							ElementBase.globalData.addError(_("Failed to get the files inside %s").printf(srcPath));
							return true;
						}
					}
				}
			}
			GLib.Environment.set_current_dir(currentDir);
			return error;
		}


		public bool clear() {

			var config=new AutoVala.Configuration();
			if(this.config.globalData.error) {
				return true; // if there was at least one error during initialization, return
			}
			var retval=config.readConfiguration();
			config.showErrors();
			if (retval) {
				return true;
			}
			config.clearAutomatic();
			config.saveConfiguration();
			return false;
		}
	}
}
