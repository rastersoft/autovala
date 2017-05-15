/*
 Copyright 2013-2014 (C) Raster Software Vigo (Sergio Costas)

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

// project version=0.99

namespace AutoVala {

	public class ManageProject: GLib.Object {

		private Configuration config;

		public void showErrors() {
			this.config.showErrors();
		}

		public string[] getErrors() {
			return this.config.getErrors();
		}

		private bool copy_recursive (string srcS, string destS) {

			var src=File.new_for_path(srcS);
			var dest=File.new_for_path(destS);
			if (!src.query_exists()) {
				ElementBase.globalData.addError(_("Can't copy folder %s to %s; it doesn't exists.").printf(srcS,destS));
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

		public bool init(string projectName,string ?basePath = null) {

			bool error=false;

			this.config=new AutoVala.Configuration(basePath,projectName,false);
			if(this.config.globalData.error) {
				return true; // if there was at least one error during initialization, return
			}
			string configPath;
			if (basePath == null) {
				configPath=Posix.realpath(GLib.Environment.get_current_dir());
			} else {
				configPath = basePath;
			}
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
			error|=this.createPath(configPath,"data/bash_completion");
			error|=this.createIgnore(configPath,".gitignore");
			error|=this.createIgnore(configPath,".bzrignore");
			error|=this.createIgnore(configPath,".hgignore");

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

		public bool cmake(string ?basePath = null) {

			bool error;

			this.config = new AutoVala.Configuration(basePath);
			if(this.config.globalData.error) {
				return true; // if there was at least one error during initialization, return
			}
			var globalData = ElementBase.globalData;

			error=config.readConfiguration();
			if (error) {
				return true;
			}

			string configPath=this.config.globalData.projectFolder;
			string origin = Path.build_filename(AutoValaConstants.PKGDATADIR,"cmake");
			string destiny = Path.build_filename(configPath,"cmake");
			var folder=File.new_for_path(destiny);
			var folder2=File.new_for_path(origin);
			if (folder2.query_exists()) {
				if (folder.query_exists()) {
					this.delete_recursive(destiny);
				}
				this.copy_recursive(origin,destiny);
			} else {
				ElementBase.globalData.addError(_("Folder %s doesn't exists. Autovala is incorrectly installed").printf(origin));
				return true;
			}

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

		public bool refresh(string ?basePath = null) {

			bool error;

			this.config = new AutoVala.Configuration(basePath);
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
			error|=ElementBashCompletion.autoGenerate();
			error|=ElementValaBinary.autoGenerate();

			if (error==false) {
				error|=this.config.saveConfiguration();
			}
			return error;
		}

		public string[]? get_files(string ?basePath = null) {

			string[] all_files = {};

			this.config = new AutoVala.Configuration(basePath);
			if(this.config.globalData.error) {
				return null; // if there was at least one error during initialization, return
			}

			var error=this.config.readConfiguration();
			if (error) {
				return null;
			}

			ElementBase.globalData.generateExtraData();
			all_files += GLib.Path.get_basename(ElementBase.globalData.configFile);
			all_files += "CMakeLists.txt";
			foreach(var path in ElementBase.globalData.pathList) {
				all_files+= GLib.Path.build_filename(path,"CMakeLists.txt");
			}
			var cmake_files = ElementBase.getFilesFromFolder("cmake",null,true);
			foreach(var element2 in cmake_files) {
				all_files+=element2;
			}
			var file = File.new_for_path(Path.build_filename(ElementBase.globalData.projectFolder,"cmake","CMakeLists.txt"));
			if (file.query_exists()) {
				all_files+=Path.build_filename("cmake","CMakeLists.txt");
			}
			foreach(var element in ElementBase.globalData.globalElements) {
				element.add_files();
				foreach(var element2 in element.file_list) {
					all_files+=element2;
				}
			}
			return all_files;
		}

		public bool gettext(string ?basePath = null) {
			// run xgettext to generate the basic pot file

			this.config = new AutoVala.Configuration(basePath);
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
						string callString = "xgettext -d %s -o %s -p %s --keyword='_' -f po/POTFILES.in".printf(ElementBase.globalData.projectName,ElementBase.globalData.projectName+".pot",element.path);
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


		public bool clear(string ?basePath = null) {

			this.config=new AutoVala.Configuration(basePath);
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

		public bool remove_binary(string? projectPath, string binary_name) {

			var config=new AutoVala.Configuration(projectPath);
			if (config.globalData.error) {
				return true;
			}

			if (config.readConfiguration()) {
				return true;
			}

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

		public string ? process_binary(string? original_name, string? projectPath, string binary_name, bool is_library, string base_path, string vala_options, string c_options, string libraries) {

			string retval = "";

			var config=new AutoVala.Configuration(projectPath);
			if (config.globalData.error) {
				return null;
			}

			if (config.readConfiguration()) {
				return null;
			}

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
					retval+=_("The element doesn't exists");
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
				if (element.configureLine(line,false,null,false,0)) {
					var errors = config.globalData.getErrorList();
					string retString = "";
					foreach(var error in errors) {
						retString+=error+"\n";
					}
					return retString;
				}
				element.setCompileOptions(vala_options,false, null, false, 0);
				element.setCompileCOptions(c_options,false, null, false, 0);
				element.setCLibrary(libraries,false,null,false,0);
				element.autoConfigure();
			} else {
				original_element.set_name(binary_name);
				original_element.set_type(is_library);
				original_element.set_path(base_path3);
				original_element.setCompileOptions(vala_options,false, null, false, 0,true);
				original_element.setCompileCOptions(c_options,false, null, false, 0,true);
				original_element.setCLibrary(libraries,false,null,false,0,true);
				original_element.autoConfigure();
			}
			config.saveConfiguration();
			return null;
		}

		public ValaProject ? get_binaries_list(string ?basePath = null) {

			this.config=new AutoVala.Configuration(basePath);
			if (config.globalData.error) {
				return null;
			}

			if (config.readConfiguration()) {
				return null;
			}

			var project = new ValaProject();

			project.elements = new Gee.ArrayList<PublicElement>();
			project.projectPath = config.globalData.projectFolder;
			project.projectName = config.globalData.projectName;
			project.projectFile = config.globalData.configFile;

			foreach (var element in config.globalData.globalElements) {
				var newElement = new PublicElement(element.eType, element.fullPath, element.name);
				if ((element.eType == ConfigType.VALA_LIBRARY) || (element.eType == ConfigType.VALA_BINARY)) {
					var binElement = element as ElementValaBinary;
					newElement.set_binary_data(binElement.get_vala_opts(),binElement.get_c_opts(),binElement.get_libraries());
					newElement.sources = binElement.sources;
					newElement.c_sources = binElement.cSources;
					newElement.unitests = binElement.unitests;
					newElement.vapis = binElement.vapis;
				}
				project.elements.add(newElement);
			}
			return project;
		}

		public bool create_deb(bool ask = false, string ? basePath = null) {

			bool retval;

			this.config=new AutoVala.Configuration(basePath);
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
		
		public bool create_rpm(bool ask = false, string ? basePath = null) {

			bool retval;

			this.config=new AutoVala.Configuration(basePath);
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
	}

	public class ValaProject : GLib.Object {

		public string projectPath;
		public string projectName;
		public string projectFile;
		public Gee.List<PublicElement>? elements;
	}

	public class PublicElement : GLib.Object {

		public ConfigType type;
		public string? fullPath;
		public string name;
		public string vala_opts;
		public string c_opts;
		public string libraries;
		public Gee.List<SourceElement ?> sources;
		public Gee.List<SourceElement ?> c_sources;
		public Gee.List<VapiElement ?> vapis;
		public Gee.List<SourceElement ?> unitests;

		public PublicElement(ConfigType type,string? fullPath, string name) {
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
		}

		public void set_binary_data(string vala_options,string c_options,string libraries) {
			this.vala_opts = vala_options;
			this.c_opts = c_options;
			this.libraries = libraries;
		}
	}
}
