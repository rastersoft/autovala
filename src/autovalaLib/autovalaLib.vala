/*
 Copyright 2013-2015 (C) Raster Software Vigo (Sergio Costas)

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
using Readline;

// project version=1.0

namespace AutoVala {

	public class ManageProject: GLib.Object {

		private Configuration config;

		public string getProjectPath() {
			return this.config.globalData.projectFolder;
		}

		public void showErrors() {
			this.config.showErrors();
		}

		/**
		 * Returns a list with all the errors generated during the process, and clears the error list
		 * @return A list with the errors and warnings, one on each element.
		 */
		public string[] getErrors() {
			return this.config.getErrors();
		}

		/**
		 * Copy recursively all the files in a folder to another
		 * @param srcS The source folder
		 * @param destS The destination folder
		 * @return TRUE if there was an error; FALSE if everything went fine
		 */
		private bool copy_recursive (string srcS, string destS) {

			var src=File.new_for_path(srcS);
			var dest=File.new_for_path(destS);
			if (!src.query_exists()) {
				ElementBase.globalData.addError(_("Can't copy folder %s to %s; it doesn't exist.").printf(srcS,destS));
				return true;
			}

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

		public static bool delete_recursive (string fileFolder) {

			var src=File.new_for_path(fileFolder);

			GLib.FileType srcType = src.query_file_type (GLib.FileQueryInfoFlags.NONE, null);
			if (srcType == GLib.FileType.DIRECTORY) {
				string srcPath = src.get_path ();
				try {
					GLib.FileEnumerator enumerator = src.enumerate_children (GLib.FileAttribute.STANDARD_NAME, GLib.FileQueryInfoFlags.NONE, null);
					for ( GLib.FileInfo? info = enumerator.next_file (null) ; info != null ; info = enumerator.next_file (null) ) {
						if (ManageProject.delete_recursive (GLib.Path.build_filename (srcPath, info.get_name ()))) {
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


		private bool createPath(string configPath, string path, bool do_check) {
			try {
				var folder=File.new_for_path(Path.build_filename(configPath,path));
				if (folder.query_exists()) {
					if (do_check) {
						ElementBase.globalData.addWarning(_("The folder '%s' already exists").printf(path));
					}
				} else {
					folder.make_directory_with_parents();
				}
			} catch (Error e) {
				ElementBase.globalData.addError(_("Can't create the folder '%s'").printf(path));
				return true;
			}
			return false;
		}

		private bool createIgnore(string basePath, string filePath) {

			try {
				var ignoreFile=File.new_for_path(Path.build_filename(basePath,filePath));
				if (ignoreFile.query_exists()) {
					return false;
				} else {
					var dos = new DataOutputStream (ignoreFile.create (FileCreateFlags.REPLACE_DESTINATION));
					dos.put_string(".gitignore\n");
					dos.put_string(".bzrignore\n");
					dos.put_string(".hgignore\n");
					dos.put_string("install\n");
					if (filePath == ".gitignore") {
						dos.put_string("*~\n");
					}
				}
			} catch (Error e) {
				ElementBase.globalData.addError(_("Can't create the file '%s'").printf(filePath));
				return false;
			}
			return false;
		}

		private bool copy_cmake(string configPath) {

			string? origin = GLib.Environment.get_variable("AUTOVALA_CMAKE_SCRIPT");
			if ((origin != null) && (origin != "")) {
				var folderTmp = File.new_for_path(origin);
				if ((folderTmp.query_exists() == false) || (folderTmp.query_file_type(FileQueryInfoFlags.NONE) != FileType.DIRECTORY)) {
					origin = null;
				}
			} else {
				origin = null;
			}

			if (origin != null) {
				ElementBase.globalData.addWarning(_("Copying CMAKE scripts from %s").printf(origin));
			} else {
				origin = Path.build_filename(AutoValaConstants.PKGDATADIR,"cmake");
			}
			string destiny = Path.build_filename(configPath,"cmake");
			var folder=File.new_for_path(destiny);
			var folder2=File.new_for_path(origin);
			if (folder2.query_exists()) {
				if (folder.query_exists()) {
					ManageProject.delete_recursive(destiny);
				}
				this.copy_recursive(origin,destiny);
			} else {
				ElementBase.globalData.addError(_("Folder %s doesn't exist. Autovala is incorrectly installed").printf(origin));
				return true;
			}
			return false;
		}

		/**
		 * Creates the folders for the project
		 */
		private bool create_folders(string configPath, bool do_check) {

			var error = this.createPath(configPath,"src", do_check);
			error |= this.createPath(configPath,"src/vapis", do_check);
			error |= this.createPath(configPath,"po", do_check);
			error |= this.createPath(configPath,"doc", do_check);
			error |= this.createPath(configPath,"install", do_check);
			error |= this.createPath(configPath,"packages", do_check);
			error |= this.createPath(configPath,"data", do_check);
			error |= this.createPath(configPath,"data/icons", do_check);
			error |= this.createPath(configPath,"data/pixmaps", do_check);
			error |= this.createPath(configPath,"data/interface", do_check);
			error |= this.createPath(configPath,"data/local", do_check);
			error |= this.createPath(configPath,"data/bash_completion", do_check);
			error |= this.createPath(configPath,"data/dbus", do_check);
			error |= this.createIgnore(configPath,".gitignore");
			error |= this.createIgnore(configPath,".bzrignore");
			error |= this.createIgnore(configPath,".hgignore");
			return error;
		}

		/**
		 * Creates a new Autovala project in an specified path
		 * @param projectName The name for the project
		 * @param isGenie True if it is a Genie project; false if it is a Vala project
		 * @param basePath The path where to create the project, or NULL to create in the working path
		 * @return TRUE if there was an error; FALSE if everything went fine
		 */
		public bool init(string projectName, bool isGenie, string ?basePath = null) {

			bool error=false;

			try {
				this.config = new AutoVala.Configuration(basePath,projectName,false);
			} catch (GLib.Error e) {
				return true;
			}
			if(this.config.globalData.error) {
				return true; // if there was at least one error during initialization, return
			}
			string configPath;
			if (basePath == null) {
				configPath = Posix.realpath(GLib.Environment.get_current_dir());
			} else {
				configPath = basePath;
			}
			var directory = File.new_for_path(configPath);

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


			var folder = File.new_for_path(Path.build_filename(configPath,"cmake"));
			if (folder.query_exists()) {
				ElementBase.globalData.addWarning(_("The 'cmake' folder already exists"));
			} else {
				this.copy_cmake(configPath);
			}

			error |= this.create_folders(configPath, true);

			try {
				var extension = isGenie ? ".gs" : ".vala";
				var srcFile=File.new_for_path(Path.build_filename(configPath,"src",projectName+extension));
				if (false==srcFile.query_exists()) {
					srcFile.create(FileCreateFlags.NONE);
				}
			} catch (Error e) {
				ElementBase.globalData.addWarning(_("Can't create the initial source file"));
			}

			this.config.globalData.valaVersionMajor=this.config.globalData.valaMajor;
			this.config.globalData.valaVersionMinor=this.config.globalData.valaMinor;
			if (basePath == null) {
				this.config.globalData.setConfigFilename(projectName+".avprj");
			} else {
				this.config.globalData.setConfigFilename(Path.build_filename(basePath,projectName+".avprj"));
			}

			if (error==false) {
				error |= this.config.saveConfiguration();
			}
			return error;
		}

		/**
		 * Generates the MESON.BUILD file for a project
		 * @param basePath A base file or folder; the code will check if that file is a valid .avprj file; if not (or if it is a folder) will search in the folder containing it if there is a valid .avprj file. If not, will search upwards until a valid .avprj file is found, or the root is reached. NULL means to start searching in the current working directory
		 * @return TRUE if there was an error; FALSE if everything went fine
		 */
		public bool meson(string ?basePath = null) {

			bool error;

			Globals.resetCounter();

			try {
				this.config = new AutoVala.Configuration(basePath);
			} catch (GLib.Error e) {
				return true;
			}
			if(this.config.globalData.error) {
				return true; // if there was at least one error during initialization, return
			}
			var globalData = ElementBase.globalData;

			error = config.readConfiguration();
			if (error) {
				return true;
			}

			globalData.generateExtraData();

			var globalElement = new ElementGlobal();

			var mesonCommon = new MesonCommon();
			mesonCommon.init();

			DataOutputStream dataStream;
			try {
				var mainPath = GLib.Path.build_filename(globalData.projectFolder,"meson.build");
				var file = File.new_for_path(mainPath);
				if (file.query_exists()) {
					file.delete();
				}
				var dis = file.create(FileCreateFlags.NONE);
				dataStream = new DataOutputStream(dis);
				var condition = new ConditionalText(dataStream,ConditionalType.MESON);
				error |= globalElement.generateMeson(condition, mesonCommon);
				foreach(var element in globalData.globalElements) {
					element.processed = false;
					if ((element.eType == ConfigType.VALA_BINARY) || (element.eType == ConfigType.VALA_LIBRARY)) {
						continue;
					}
					error |= element.generateMesonHeader(condition, mesonCommon);
				}

				foreach(var element in globalData.globalElements) {
					if ((element.eType == ConfigType.VALA_BINARY) || (element.eType == ConfigType.VALA_LIBRARY)) {
						continue;
					}
					condition.printCondition(element.condition,element.invertCondition);
					error |= element.generateMeson(condition, mesonCommon);
					element.processed = true;
				}
				condition.printTail();
				var paths = new Gee.HashMap<string, ElementValaBinary>();
				foreach(var element in ElementBase.globalData.globalElements) {
					element.processed = false;
					if ((element.eType != ConfigType.VALA_BINARY) && (element.eType != ConfigType.VALA_LIBRARY)) {
						continue;
					}
					if (!paths.has_key(element.path)) {
						paths.set(element.path, element as ElementValaBinary);
					}
				}
				var created = new Gee.HashSet<string>();
				bool added_one = true;
				while(added_one) {
					added_one = false;
					foreach(var path in paths.keys) {
						var element = paths.get(path);
						if (element.processed) {
							continue;
						}
						bool ready = true;
						foreach(var dependency in element.packages) {
							if (dependency.type != packageType.LOCAL) {
								continue;
							}
							if (!created.contains(dependency.elementName)) {
								// this binary or library has an unmet dependency
								ready = false;
								break;
							}
						}
						if (ready) {
							dataStream.put_string("subdir('%s')\n".printf(path));
							added_one = true;
							element.processed = true;
							string name;
							if(element.currentNamespace != null) {
								name = element.currentNamespace;
							} else {
								name = element.name.replace("-","_");
							}
							created.add(name);
						}
					}
				}
				dataStream.close();
				foreach(var path in paths.keys) {
					var element = paths.get(path);
					if (element.processed) {
						continue;
					}
					string errorText = _("Failed to find the following dependencies for '%s' in meson: ").printf(element.name);
					foreach(var dependency in element.packages) {
						if (dependency.type != packageType.LOCAL) {
							continue;
						}
						if (!created.contains(dependency.elementName)) {
							errorText += dependency.elementName;
						}
					}
					ElementBase.globalData.addError(errorText);
				}
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to write to meson.build at '%s' element, at '%s' path: %s").printf("autovalaLib","/",e.message));
				return true;
			}

			Gee.Set<string> paths = new Gee.HashSet<string>();
			foreach(var element in ElementBase.globalData.globalElements) {
				if ((element.eType != ConfigType.VALA_BINARY) && (element.eType != ConfigType.VALA_LIBRARY)) {
					continue;
				}
				if (!paths.contains(element.path)) {
					paths.add(element.path);
				}
			}

			foreach(var path in paths) {
				var mainPath = GLib.Path.build_filename(globalData.projectFolder, path, "meson.build");
				var file = File.new_for_path(mainPath);
				if (file.query_exists()) {
					file.delete();
				}
				var dis = file.create(FileCreateFlags.NONE);
				dataStream = new DataOutputStream(dis);
				var condition = new ConditionalText(dataStream,ConditionalType.MESON);

				foreach(var element in globalData.globalElements) {
					if ((element.eType != ConfigType.VALA_BINARY) && (element.eType != ConfigType.VALA_LIBRARY)) {
						continue;
					}
					element.processed = false;
					if (path != element.path) {
						continue;
					}
					error |= element.generateMesonHeader(condition, mesonCommon);
				}

				bool allProcessed=false;
				Gee.Set<string> packagesFound=new Gee.HashSet<string>();
				while(allProcessed == false) {
					bool addedOne = false;
					allProcessed = true;
					foreach(var element in globalData.globalElements) {
						if ((element.eType != ConfigType.VALA_BINARY) && (element.eType != ConfigType.VALA_LIBRARY)) {
							continue;
						}
						if (element.processed) {
							continue;
						}
						var binElement = element as ElementValaBinary;
						var valid = true;
						allProcessed = false;
						foreach(var package in binElement.packages) {
							if((package.type == packageType.LOCAL) && (false == packagesFound.contains(package.elementName))) {
								valid=false;
								break;
							}
						}
						if (valid == false) { // has dependencies still not satisfied
							continue;
						}
						addedOne = true;
						element.processed = true;
						if (path == element.path) {
							condition.printCondition(element.condition,element.invertCondition);
							error |= element.generateMeson(condition, mesonCommon);
						}
						if ((binElement.eType == ConfigType.VALA_LIBRARY) && (binElement.currentNamespace != "")) {
							packagesFound.add(binElement.currentNamespace);
						}
					}
					if ((allProcessed == false) && (addedOne == false)) {
						string text_error = _("The following local dependencies cannot be satisfied:");
						foreach(var element in globalData.globalElements) {
							if ((element.processed) || ((element.eType != ConfigType.VALA_LIBRARY) && (element.eType != ConfigType.VALA_BINARY))) {
								continue;
							}
							if (element.eType == ConfigType.VALA_LIBRARY) {
								text_error += _("\n\tLibrary %s, packages:").printf(Path.build_filename(element.path,element.name));
							} else {
								text_error += _("\n\tBinary %s, packages:").printf(Path.build_filename(element.path,element.name));
							}
							var binElement = element as ElementValaBinary;
							foreach(var package in binElement.packages) {
								if((package.type == packageType.LOCAL) && (false == packagesFound.contains(package.elementName))) {
									text_error += " "+package.elementName;
								}
							}
						}
						ElementBase.globalData.addError(text_error);
						return true;
					}
				}
				condition.printTail();

				foreach(var element in globalData.globalElements) {
					if (element.path != path) {
						continue;
					}
					element.endedMeson(mesonCommon);
				}
			}
			return error;
		}

		/**
		 * Generates the CMAKE files for a project
		 * @param basePath A base file or folder; the code will check if that file is a valid .avprj file; if not (or if it is a folder) will search in the folder containing it if there is a valid .avprj file. If not, will search upwards until a valid .avprj file is found, or the root is reached. NULL means to start searching in the current working directory
		 * @return TRUE if there was an error; FALSE if everything went fine
		 */
		public bool cmake(string ?basePath = null) {

			bool error;

			try {
				this.config = new AutoVala.Configuration(basePath);
			} catch (GLib.Error e) {
				return true;
			}
			if(this.config.globalData.error) {
				return true; // if there was at least one error during initialization, return
			}
			var globalData = ElementBase.globalData;
			AutoVala.Globals.resetCounter();
			error=config.readConfiguration();
			if (error) {
				return true;
			}
			string configPath=this.config.globalData.projectFolder;
			if (this.copy_cmake(configPath)) {
				return true;
			}
			globalData.generateExtraData();

			var globalElement = new ElementGlobal();
			DataOutputStream dataStreamGlobal;
			try {
				var mainPath = GLib.Path.build_filename(globalData.projectFolder,"CMakeLists.txt");
				var file = File.new_for_path(mainPath);
				if (file.query_exists()) {
					file.delete();
				}
				var dis = file.create(FileCreateFlags.NONE);
				dataStreamGlobal = new DataOutputStream(dis);
				error |= globalElement.generateMainCMakeHeader(dataStreamGlobal);
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed while generating the main CMakeLists.txt file"));
				return true;
			}
			try {
				// and now, generate each one of the CMakeLists.txt files in each folder
				foreach(var path in globalData.pathList) {
					if (path[0] == GLib.Path.DIR_SEPARATOR) {
						continue;
					}
					var fullPath = GLib.Path.build_filename(globalData.projectFolder,path,"CMakeLists.txt");
					var file = File.new_for_path(fullPath);
					if (file.query_exists()) {
						file.delete();
					}
					var dis = file.create(FileCreateFlags.NONE);
					var dataStream = new DataOutputStream(dis);

					error |= globalElement.generateCMakeHeader(dataStream);
					foreach(var element in globalData.globalElements) {
						if (element.path != path) {
							continue;
						}
						error |= element.generateCMakeHeader(dataStream);
					}
					var condition = new ConditionalText(dataStream,ConditionalType.CMAKE);
					error |= globalElement.generateCMake(dataStream);
					foreach(var element in globalData.globalElements) {
						if (element.path != path) {
							continue;
						}
						condition.printCondition(element.condition,element.invertCondition);
						error |= element.generateCMake(dataStream);
					}
					condition.printTail();
					error |= globalElement.generateCMakePostData(dataStream,dataStream);
					foreach(var element in globalData.globalElements) {
						if (element.path!=path) {
							continue;
						}
						error |= element.generateCMakePostData(dataStream,dataStreamGlobal);
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
				ElementBase.globalData.addError(_("Failed while generating the CMakeLists.txt files: %s").printf(e.message));
				error = true;
			}
			try{
				dataStreamGlobal.close();
			} catch (GLib.IOError e) {
				ElementBase.globalData.addError(_("Failed while generating the CMakeLists.txt files: %s").printf(e.message));
			}
			return error;
		}


		/**
		 * Updates the .avprj file of a project
		 * @param basePath A base file or folder; the code will check if that file is a valid .avprj file; if not (or if it is a folder) will search in the folder containing it if there is a valid .avprj file. If not, will search upwards until a valid .avprj file is found, or the root is reached. NULL means to start searching in the current working directory
		 * @return TRUE if there was an error; FALSE if everything went fine
		 */
		public bool refresh(string ?basePath = null) {

			bool error;

			try {
				this.config = new AutoVala.Configuration(basePath);
			} catch (GLib.Error e) {
				return true;
			}
			if(this.config.globalData.error) {
				return true; // if there was at least one error during initialization, return
			}

			error=config.readConfiguration();
			if (error) {
				return true;
			}

			//print("Carpeta: %s\n".printf(GLib.Path.get_dirname(ElementBase.globalData.configFile)));
			// recreate the folders to add every new folder to the project
			this.create_folders(GLib.Path.get_dirname(ElementBase.globalData.configFile), false);

			ElementBase.globalData.clearAutomatic();
			ElementBase.globalData.generateExtraData();
			// refresh the automatic configuration for the manually set elements
			foreach (var element in ElementBase.globalData.globalElements) {
				element.autoConfigure();
			}
			error |= ElementVapidir.autoGenerate();
			error |= ElementGResource.autoGenerate();
			error |= ElementBashCompletion.autoGenerate();
			error |= ElementBinary.autoGenerate();
			error |= ElementData.autoGenerate();
			error |= ElementDBusService.autoGenerate();
			error |= ElementDBusConfiguration.autoGenerate();
			error |= ElementDesktop.autoGenerate();
			error |= ElementDoc.autoGenerate();
			error |= ElementEosPlug.autoGenerate();
			error |= ElementGlade.autoGenerate();
			error |= ElementIcon.autoGenerate();
			error |= ElementManPage.autoGenerate();
			error |= ElementPixmap.autoGenerate();
			error |= ElementPo.autoGenerate();
			error |= ElementScheme.autoGenerate();
			error |= ElementValaBinary.autoGenerate();
			error |= ElementAppData.autoGenerate();
			error |= ElementTranslation.autoGenerate();

			if (error==false) {
				error |= this.config.saveConfiguration();
			}
			return error;
		}

		private bool check_file(Gee.ArrayList<string> list,string file) {
			var f = File.new_for_path(Path.build_filename(ElementBase.globalData.projectFolder,file));
			if (f.query_exists()) {
				list.add(file);
				return true;
			}
			return false;
		}

		/**
		 * Returns all the files belonging to a project. Useful for version control systems.
		 * @param basePath A base file or folder; the code will check if that file is a valid .avprj file; if not (or if it is a folder) will search in the folder containing it if there is a valid .avprj file. If not, will search upwards until a valid .avprj file is found, or the root is reached. NULL means to start searching in the current working directory
		 * @return A list with all the files, relative to the project's root, or NULL if there was an error
		 */
		public string[]? get_files(string ?basePath = null) {

			Gee.ArrayList<string> all_files = new Gee.ArrayList<string>();;

			try {
				this.config = new AutoVala.Configuration(basePath);
			} catch (GLib.Error e) {
				return null;
			}
			if(this.config.globalData.error) {
				return null; // if there was at least one error during initialization, return
			}

			var error=this.config.readConfiguration();
			if (error) {
				return null;
			}

			ElementBase.globalData.generateExtraData();
			this.check_file(all_files,GLib.Path.get_basename(ElementBase.globalData.configFile));

			this.check_file(all_files,"CMakeLists.txt");
			this.check_file(all_files,"meson.build");
			this.check_file(all_files,"meson_options.txt");

			foreach(var path in ElementBase.globalData.pathList) {
				this.check_file(all_files,GLib.Path.build_filename(path,"CMakeLists.txt"));
				this.check_file(all_files,GLib.Path.build_filename(path,"meson.build"));
			}
			var cmake_files = ElementBase.getFilesFromFolder("cmake",null,true);
			foreach(var element2 in cmake_files) {
				this.check_file(all_files,element2);
			}
			var meson_files = ElementBase.getFilesFromFolder("meson_scripts",null,true);
			foreach(var element2 in meson_files) {
				this.check_file(all_files,element2);
			}
			this.check_file(all_files,Path.build_filename("cmake","CMakeLists.txt"));
			var globalElement = new ElementGlobal();
			globalElement.add_files();
			foreach(var element2 in globalElement.file_list) {
				this.check_file(all_files,element2);
			}
			foreach(var element in ElementBase.globalData.globalElements) {
				element.add_files();
				foreach(var element2 in element.file_list) {
					this.check_file(all_files,element2);
				}
			}

			all_files.sort();
			string[] all_files2 = {};
			foreach (var element in all_files) {
				all_files2 += element;
			}
			return all_files2;
		}

		/**
		 * Generates the PO files for a project, using gettext for extracting the strings from the source files
		 * @param basePath A base file or folder; the code will check if that file is a valid .avprj file; if not (or if it is a folder) will search in the folder containing it if there is a valid .avprj file. If not, will search upwards until a valid .avprj file is found, or the root is reached. NULL means to start searching in the current working directory
		 * @return TRUE if there was an error; FALSE if everything went fine
		 */
		public bool gettext(string ?basePath = null) {
			// run xgettext to generate the basic pot file

			try {
				this.config = new AutoVala.Configuration(basePath);
			} catch (GLib.Error e) {
				return true;
			}
			if(this.config.globalData.error) {
				return true; // if there was at least one error during initialization, return
			}

			bool error=this.config.readConfiguration();
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
						string callString = "xgettext --from-code=UTF-8 -d %s -o %s -p %s --keyword='_' -f po/POTFILES.in".printf(ElementBase.globalData.projectName,ElementBase.globalData.projectName+".pot",element.path);
						ElementBase.globalData.addMessage(_("Launching command %s").printf(callString));
						retVal=GLib.Process.spawn_command_line_sync(callString,out ls_stdout,out ls_stderr, out ls_status);
					} catch (GLib.SpawnError e) {
						retVal=false;
					}

					if ((!retVal)||(ls_status!=0)) {
						ElementBase.globalData.addWarning(_("Failed to run 'xgettext' to generate the base POT file"));
					}

					if (ls_stdout != "") {
						ElementBase.globalData.addMessage(_("Command output: %s\n").printf(ls_stdout));
					}

					if (ls_stderr != "") {
						ElementBase.globalData.addMessage(_("Error output: %s\n").printf(ls_stderr));
					}

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

		/**
		 * Clears the .avprj file, removing all the automatic elements and leaving only the manually added ones
		 * @param basePath A base file or folder; the code will check if that file is a valid .avprj file; if not (or if it is a folder) will search in the folder containing it if there is a valid .avprj file. If not, will search upwards until a valid .avprj file is found, or the root is reached. NULL means to start searching in the current working directory
		 * @return TRUE if there was an error; FALSE if everything went fine
		 */
		public bool clear(string ?basePath = null) {

			try {
				this.config = new AutoVala.Configuration(basePath);
			} catch (GLib.Error e) {
				return true;
			}
			if(config.globalData.error) {
				return true; // if there was at least one error during initialization, return
			}
			var retval=config.readConfiguration();
			if (retval) {
				return true;
			}
			config.clearAutomatic();
			config.saveConfiguration();
			return false;
		}

		/**
		 * Removes a binary from a project
		 * @param projectPath A base file or folder; the code will check if that file is a valid .avprj file; if not (or if it is a folder) will search in the folder containing it if there is a valid .avprj file. If not, will search upwards until a valid .avprj file is found, or the root is reached. NULL means to start searching in the current working directory
		 * @param binary_name The name of the binary to remove
		 * @return TRUE if there was an error; FALSE if everything went fine
		 */
		public bool remove_binary(string? projectPath, string binary_name) {

			try {
				this.config = new AutoVala.Configuration(projectPath);
			} catch (GLib.Error e) {
				return true;
			}
			if (config.globalData.error) {
				return true;
			}

			if (config.readConfiguration()) {
				return true;
			}

			ElementBase.globalData.generateExtraData();
			ElementBase element_found = null;
			foreach(var element in config.globalData.globalElements) {
				if ((element.eType == AutoVala.ConfigType.VALA_BINARY) || (element.eType == AutoVala.ConfigType.VALA_LIBRARY)) {
					if ( element.name == binary_name) {
						element_found = element;
						break;
					}
				}
			}
			if (element_found != null) {
				config.globalData.globalElements.remove(element_found);
			}
			config.saveConfiguration();
			return false;
		}

		/**
		 * Allows to add or modify a binary in a project
		 * @param original_name The name of the binary to modify, or NULL to create a new one
		 * @param projectPath A base file or folder; the code will check if that file is a valid .avprj file; if not (or if it is a folder) will search in the folder containing it if there is a valid .avprj file. If not, will search upwards until a valid .avprj file is found, or the root is reached. NULL means to start searching in the current working directory
		 * @param binary_name The name of the binary to create, or the new name for an existing binary
		 * @param is_library TRUE if the binary is a library; FALSE if it is an executable
		 * @param base_path The root path for the binary, where all the source files will be searched
		 * @param vala_options A list of options to pass to the Vala compiler
		 * @param c_options A list of options to pass to the C compiler
		 * @param libraries A list of C libraries (separated with blank spaces) needed to compile this binary
		 * @return NULL if everything went fine, or an string with several messages specifying the errors ocurred during the process
		 */
		public string ? process_binary(string? original_name, string? projectPath, string binary_name, bool is_library, string base_path, string vala_options, string c_options, string libraries) {

			string retval = "";

			try {
				this.config = new AutoVala.Configuration(projectPath);
			} catch (GLib.Error e) {
				return null;
			}
			if (config.globalData.error) {
				return null;
			}

			if (config.readConfiguration()) {
				return null;
			}

			ElementBase.globalData.generateExtraData();
			string base_path2;
			string base_path3 = "";
			string projectPath2;

			if (base_path.has_suffix(Path.DIR_SEPARATOR_S)) {
				base_path2 = base_path;
			} else {
				base_path2 = base_path+Path.DIR_SEPARATOR_S;
			}
			if (config.globalData.projectFolder.has_suffix(Path.DIR_SEPARATOR_S)) {
				projectPath2 = config.globalData.projectFolder;
			} else {
				projectPath2 = config.globalData.projectFolder+Path.DIR_SEPARATOR_S;
			}

			if (base_path2 == projectPath2) {
				retval+=_("The path can't be the project's root path");
			} else if (!base_path2.has_prefix(projectPath2)) {
				retval+=_("The selected path is outside the project folder");
			} else {
				base_path3 = base_path2.substring(projectPath2.length);
			}

			bool path_already_in_use = false;
			bool name_already_in_use = false;
			ElementValaBinary? original_element = null;
			foreach(var element in config.globalData.globalElements) {
				if (element.eType == AutoVala.ConfigType.IGNORE) {
					continue;
				}
				if ((element.eType == AutoVala.ConfigType.VALA_BINARY) || (element.eType == AutoVala.ConfigType.VALA_LIBRARY)) {
					if ((Path.build_filename(config.globalData.projectFolder,element.path) == base_path) && (element.name != original_name)) {
						path_already_in_use = true;
					}
					if ( element.name == binary_name) {
						name_already_in_use = true;
					}
					if ( element.name == original_name) {
						original_element = element as AutoVala.ElementValaBinary;
					}
				} else {
					if (Path.build_filename(config.globalData.projectFolder,element.path) == base_path) {
						path_already_in_use = true;
					}
				}
			}
			if (path_already_in_use) {
				if (retval != "") {
					retval+="\n";
				}
				retval+=_("Path already in use in other element");
			}
			if (original_name == null) { // create a new binary element
				if (name_already_in_use) {
					if (retval != "") {
						retval+="\n";
					}
					retval+=_("Name already in use in other executable or library");
				}
			} else {
				if (original_element==null) {
					if (retval != "") {
						retval+="\n";
					}
					retval+=_("The element doesn't exist");
				}
			}
			if (retval != "") {
				return retval;
			}

			if (original_name == null) {
				ElementValaBinary element = new ElementValaBinary();
				string line;
				if (is_library) {
					line = "vala_library: ";
				} else {
					line = "vala_binary: ";
				}
				line+=Path.build_filename(base_path3,binary_name);

				if (element.configureLine(line,false,null,false,0,null)) {
					var errors = config.globalData.getErrorList();
					string retString = "";
					foreach(var error in errors) {
						retString+=error+"\n";
					}
					return retString;
				}
				element.setCompileOptions(vala_options,false, null, false, 0,null);
				element.setCompileCOptions(c_options,false, null, false, 0,null);
				element.setCLibrary(libraries,false,null,false,0,null);
				element.autoConfigure();
			} else {
				original_element.set_name(binary_name);
				original_element.set_type(is_library);
				original_element.set_path(base_path3);
				original_element.setCompileOptions(vala_options,false, null, false, 0,null,true);
				original_element.setCompileCOptions(c_options,false, null, false, 0,null,true);
				original_element.setCLibrary(libraries,false,null,false,0,null,true);
				original_element.autoConfigure();
			}
			config.saveConfiguration();
			return null;
		}

		/**
		 * Creates the metadata for a DEB package
		 * @param ask If TRUE, will ask using the command line data like the packager's name, the linux distribution name, or the version; if FALSE, it will presume that the data is available in the user's configuration file (at ~/.config/autovala/packages.cfg)
		 * @param projectPath A base file or folder; the code will check if that file is a valid .avprj file; if not (or if it is a folder) will search in the folder containing it if there is a valid .avprj file. If not, will search upwards until a valid .avprj file is found, or the root is reached. NULL means to start searching in the current working directory
		 * @return TRUE if there was an error; FALSE if everything went fine
		 */
		public bool create_deb(bool ask = false, string ? basePath = null) {

			bool retval;

			try {
				this.config = new AutoVala.Configuration(basePath);
			} catch (GLib.Error e) {
				return true;
			}
			if (config.globalData.error) {
				return true;
			}

			if (config.readConfiguration()) {
				return true;
			}

			var t = new AutoVala.packages_deb();

			retval = t.init_all(config);
			if (!retval) {
				if (ask) {
					t.ask_name();
					t.ask_distro();
					t.ask_distro_version();
				}
				retval = t.create_deb_package();
			}
			return retval;
		}

		/**
		 * Creates the metadata for an RPM package
		 * @param ask If TRUE, will ask using the command line data like the packager's name, the linux distribution name, or the version; if FALSE, it will presume that the data is available in the user's configuration file (at ~/.config/autovala/packages.cfg)
		 * @param projectPath A base file or folder; the code will check if that file is a valid .avprj file; if not (or if it is a folder) will search in the folder containing it if there is a valid .avprj file. If not, will search upwards until a valid .avprj file is found, or the root is reached. NULL means to start searching in the current working directory
		 * @return TRUE if there was an error; FALSE if everything went fine
		 */
		public bool create_rpm(bool ask = false, string ? basePath = null) {

			bool retval;

			try {
				this.config = new AutoVala.Configuration(basePath);
			} catch (GLib.Error e) {
				return true;
			}
			if (config.globalData.error) {
				return true;
			}

			if (config.readConfiguration()) {
				return true;
			}

			var t = new AutoVala.packages_rpm();

			retval = t.init_all(config);
			if (!retval) {
				if (ask) {
					t.ask_name();
				}
				retval = t.create_rpm_package();
			}
			return retval;
		}

        /**
		 * Creates the metadata for a PACMAN package
		 * @param ask If TRUE, will ask using the command line data like the packager's name, the linux distribution name, or the version; if FALSE, it will presume that the data is available in the user's configuration file (at ~/.config/autovala/packages.cfg)
		 * @param projectPath A base file or folder; the code will check if that file is a valid .avprj file; if not (or if it is a folder) will search in the folder containing it if there is a valid .avprj file. If not, will search upwards until a valid .avprj file is found, or the root is reached. NULL means to start searching in the current working directory
		 * @return TRUE if there was an error; FALSE if everything went fine
		 */
		public bool create_pacman(bool ask = false, string ? basePath = null) {

			bool retval;

			try {
				this.config = new AutoVala.Configuration(basePath);
			} catch (GLib.Error e) {
				return true;
			}
			if (config.globalData.error) {
				return true;
			}

			if (config.readConfiguration()) {
				return true;
			}

			var t = new AutoVala.packages_pacman();

			retval = t.init_all(config);
			if (!retval) {
				retval = t.create_pacman_package();
			}
			return retval;
		}

		/**
		 * Returns an object with all the binaries in this project and its source files
		 * @param basePath A base file or folder; the code will check if that file is a valid .avprj file; if not (or if it is a folder) will search in the folder containing it if there is a valid .avprj file. If not, will search upwards until a valid .avprj file is found, or the root is reached. NULL means to start searching in the current working directory
		 * @param owner The application identifier that is asking for the data, to include the EXTERNAL data
		 * @return NULL if there was an error; or a ValaProject object with the data of this project
		 */
		public ValaProject ? get_binaries_list(string ?basePath = null, string? owner = null) {

			try {
				this.config = new AutoVala.Configuration(basePath);
			} catch (GLib.Error e) {
				return null;
			}
			if (config.globalData.error) {
				return null;
			}

			if (config.readConfiguration()) {
				return null;
			}

			ElementBase.globalData.generateExtraData();
			var project = new ValaProjectInternal();

			project.projectPath = config.globalData.projectFolder;
			project.projectName = config.globalData.projectName;
			project.projectFile = config.globalData.configFile;

			foreach (var element in config.globalData.globalElements) {
				if ((element.eType == ConfigType.VALA_LIBRARY) || (element.eType == ConfigType.VALA_BINARY)) {
					project.add_binary(element as ElementValaBinary);
					continue;
				}
				if (element.eType == ConfigType.GLADE) {
					project.add_glade(element as ElementGlade);
					continue;
				}
				if ((owner != null) && (element.eType == ConfigType.EXTERNAL)) {
					var element2 = element as ElementExternal;
					if (element2.owner == owner) {
						project.external.add(element2.data);
					}
				}
			}
			return project;
		}

		/**
		 * Allows to update the external data for an specific owner
		 * @param owner the owner identifier of the data to update
		 * @param data a list of the strings to store in the project file
		 * @param basePath A base file or folder; the code will check if that file is a valid .avprj file; if not (or if it is a folder) will search in the folder containing it if there is a valid .avprj file. If not, will search upwards until a valid .avprj file is found, or the root is reached. NULL means to start searching in the current working directory
		 * @return True if there was an error; False if everything worked fine
		 */
		public bool set_external_data(string owner,Gee.List<string> data, string ?basePath = null) {

			try {
				this.config = new AutoVala.Configuration(basePath);
			} catch (GLib.Error e) {
				return true;
			}
			if (config.globalData.error) {
				return true;
			}

			if (config.readConfiguration()) {
				return true;
			}

			ElementBase.globalData.generateExtraData();

			ElementExternal[] tmpList = {};//new Gee.ArrayList<ElementExternal>();

			foreach (var element in config.globalData.globalElements) {
				if (element.eType == ConfigType.EXTERNAL) {
					var element2 = element as ElementExternal;
					if (element2.owner == owner) {
						tmpList += element2; // we have to create a different list before removing the elements in the globalElements list
					}
				}
			}

			foreach(var element in tmpList) {
				// we remove the External data from the project
				config.globalData.globalElements.remove(element);
			}

			foreach(var extdata in data) {
				var element = new ElementExternal();
				element.owner = owner;
				element.data = extdata;
				element.configureElement(null,null,null,false,null,false);
			}
			config.saveConfiguration();
			return false;
		}
	}

	public class ValaProject : GLib.Object {

		public string projectPath;
		public string projectName;
		public string projectFile;
		public Gee.List<PublicBinary>? binaries;
		public Gee.List<PublicGlade>? ui;
		public Gee.List<string>external;

		public ValaProject() {
			this.binaries = new Gee.ArrayList<PublicBinary>();
			this.ui = new Gee.ArrayList<PublicGlade>();
			this.external = new Gee.ArrayList<string>();
		}
	}

	/**
	 * This class allows to use private classes as parameters to initialize a ValaProject object
	 */
	private class ValaProjectInternal : ValaProject {

		public void add_binary(ElementValaBinary binElement) {

			var newElement = new PublicBinary(binElement.eType, binElement.fullPath, binElement.name, binElement.currentNamespace);
			newElement.set_binary_data(binElement.get_vala_opts(),binElement.get_c_opts(),binElement.get_libraries());
			newElement.sources = binElement.sources;
			newElement.c_sources = binElement.cSources;
			newElement.unitests = binElement.unitests;
			newElement.vapis = binElement.vapis;
			newElement.packages = binElement.packages;
			this.binaries.add(newElement);
		}

		public void add_glade(ElementGlade element) {
			var newElement = new PublicGlade(element.fullPath);
			this.ui.add(newElement);
		}
	}

	public class PublicGlade : GLib.Object {

		public string fullPath;

		public PublicGlade(string path) {
			this.fullPath = path;
		}
	}

	public class PublicBinary : GLib.Object {

		public ConfigType type;
		public string? library_namespace;
		public string? fullPath;
		public string name;
		public string vala_opts;
		public string c_opts;
		public string libraries;
		public Gee.List<SourceElement ?> sources;
		public Gee.List<SourceElement ?> c_sources;
		public Gee.List<VapiElement ?> vapis;
		public Gee.List<SourceElement ?> unitests;
		public Gee.List<PackageElement ?> packages;
		public int major=0;
		public int minor=0;
		public int revision=0;

		public PublicBinary(ConfigType type,string? fullPath, string name, string? current_namespace) {
			this.type = type;
			this.fullPath = fullPath;
			this.name = name;
			this.vala_opts = "";
			this.c_opts = "";
			this.libraries = "";
			this.sources = null;
			this.c_sources = null;
			this.vapis = null;
			this.unitests = null;
			this.library_namespace = current_namespace;
		}

		public void set_binary_data(string vala_options,string c_options,string libraries) {
			this.vala_opts = vala_options;
			this.c_opts = c_options;
			this.libraries = libraries;
		}
	}
}
