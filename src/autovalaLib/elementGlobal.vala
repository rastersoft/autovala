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

	private class ElementGlobal : ElementBase {

		public ElementGlobal() {
			this._type = ConfigType.GLOBAL;
			this.command = "";
		}

		public override bool configureLine(string line, bool automatic, string? condition, bool invertCondition, int lineNumber) {
			return false;
		}

		public override void add_files() {
		}

		private void addFolderToMainCMakeLists(string element, DataOutputStream dataStream) {

			var path = Path.build_filename(ElementBase.globalData.projectFolder,element);
			var dirpath=File.new_for_path(path);
			if (dirpath.query_exists()==false) {
				ElementBase.globalData.addWarning(_("Directory %s doesn't exists").printf(element));
				return;
			} else {
				if (element!="src") {
					bool hasChildrens=false;
					try {
						var enumerator = dirpath.enumerate_children (FileAttribute.STANDARD_NAME+","+FileAttribute.STANDARD_TYPE, 0);
						FileInfo fileInfo;
						while ((fileInfo = enumerator.next_file ()) != null) {
							var fname=fileInfo.get_name();
							var ftype=fileInfo.get_file_type();
							if (ftype==FileType.DIRECTORY) {
								continue; // don't add folders that only contains folders
							}
							if (fname=="CMakeLists.txt") {
								continue;
							}
							hasChildrens=true; // found a file, so we add it
							break;
						}
					} catch (Error e) {
						ElementBase.globalData.addWarning(_("Can't access folder %s").printf(element));
						return;
					}
					if (hasChildrens==false) {
						return;
					}
				}
				try {
					dataStream.put_string("add_subdirectory("+element+")\n");
				} catch (Error e) {
					ElementBase.globalData.addWarning(_("Can't add subdirectory %s").printf(element));
				}
			}
		}

		public bool generateMainCMakeHeader(DataOutputStream dataStream) {

			try {
				dataStream.put_string("### CMakeLists automatically created with AutoVala\n### Do not edit\n\n");
				dataStream.put_string("project ("+ElementBase.globalData.projectName+")\n");
				dataStream.put_string("cmake_minimum_required (VERSION 2.6)\n");
				dataStream.put_string("cmake_policy (VERSION 2.8)\n");
				dataStream.put_string("list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)\n");
				dataStream.put_string("enable_testing ()\n");
				dataStream.put_string("option(ICON_UPDATE \"Update the icon cache after installing\" ON)\n");
				dataStream.put_string("option(BUILD_VALADOC \"Build API documentation if Valadoc is available\" OFF)\n");

				foreach(var element in ElementBase.globalData.globalElements) {
					if (element.eType!=ConfigType.DEFINE) {
						continue;
					}
					dataStream.put_string("option(%s \"%s\" OFF)\n".printf(element.name,element.name));
				}
				dataStream.put_string("\ninclude(GNUInstallDirs)\n");
				dataStream.put_string("if( ( ${CMAKE_INSTALL_PREFIX} MATCHES \"^/usr/local\" ) )\n");
				dataStream.put_string("\t# A workaround to ensure that works 'out of the box' in Debian-based systems\n");
				dataStream.put_string("\tset(CMAKE_INSTALL_LIBDIR lib)\n");
				dataStream.put_string("endif()\n");
				dataStream.put_string("\nset(HAVE_VALADOC OFF)\n");
				dataStream.put_string("if(BUILD_VALADOC)\n");
				dataStream.put_string("\tfind_package(Valadoc)\n");
				dataStream.put_string("\tif(VALADOC_FOUND)\n");
				dataStream.put_string("\t\tset(HAVE_VALADOC ON)\n");
				dataStream.put_string("\t\tinclude(Valadoc)\n");
				dataStream.put_string("\telse()\n");
				dataStream.put_string("\t\tmessage(\"Valadoc not found, will not build documentation\")\n");
				dataStream.put_string("\tendif()\n");
				dataStream.put_string("endif()\n\n");

				dataStream.put_string("find_package(PkgConfig)\n\n");

				Gee.Set<string> tocheck=new Gee.HashSet<string>();
				Gee.List<GenericElement> elements=new Gee.ArrayList<GenericElement>();

				// First add the ones without conditions
				foreach(var element in ElementBase.globalData.globalElements) {
					if ((element.eType!=ConfigType.VALA_BINARY)&&(element.eType!=ConfigType.VALA_LIBRARY)) {
						continue;
					}
					var binElement = element as ElementValaBinary;
					foreach(var module in binElement.packages) {
						if (((module.type==packageType.DO_CHECK)||(module.type==packageType.C_DO_CHECK))&&(module.condition==null)) {
							if (tocheck.contains(module.elementName)) {
								continue;
							}
							elements.add(module);
							tocheck.add(module.elementName);
						}
					}
				}

				// And now add the ones with conditions, so those present with and without conditions will be checked unconditionally
				foreach(var element in ElementBase.globalData.globalElements) {
					if ((element.eType!=ConfigType.VALA_BINARY)&&(element.eType!=ConfigType.VALA_LIBRARY)) {
						continue;
					}
					var binElement = element as ElementValaBinary;
					foreach(var module in binElement.packages) {
						if (((module.type==packageType.DO_CHECK)||(module.type==packageType.C_DO_CHECK))&&(module.condition!=null)) {
							if (tocheck.contains(module.elementName)) {
								continue;
							}
							elements.add(module);
						}
					}
				}

				elements.sort(ElementValaBinary.comparePackages);
				var printConditions=new ConditionalText(dataStream,true);
				foreach(var module in elements) {
					printConditions.printCondition(module.condition,module.invertCondition);
					dataStream.put_string("set(MODULES_TO_CHECK ${MODULES_TO_CHECK} %s)\n".printf(module.elementName));
				}
				printConditions.printTail();

				dataStream.put_string("\n");

				dataStream.put_string("pkg_check_modules(DEPS REQUIRED ${MODULES_TO_CHECK})\n\n");

				var ignoreList=new Gee.HashSet<string>();
				foreach(var element in ElementBase.globalData.globalElements) {
					if ((element.eType==ConfigType.IGNORE)&&(ignoreList.contains(element.path)==false)) {
						ignoreList.add(element.path);
					}
				}

                // Check for files that must be available
                foreach(var element in ElementBase.globalData.globalElements) {
					if ((element.eType != ConfigType.SOURCE_DEPENDENCY) && (element.eType!=ConfigType.BINARY_DEPENDENCY)) {
						continue;
					}
				    printConditions.printCondition(element.condition,element.invertCondition);
					dataStream.put_string("if ( NOT EXISTS \"%s\" )\n\tmessage(FATAL_ERROR \"Can't find the file %s\")\nendif()\n".printf(element.path,element.path));
					printConditions.printTail();
					dataStream.put_string("\n");
				}

				// check for PANDOC, but only if there are man pages in non-groff format
				foreach(var element in ElementBase.globalData.globalElements) {
					if (element.eType!=ConfigType.MANPAGE) {
						continue;
					}
					var len=element.name.length;
					if ((len>1)&&(element.name[len-2]!='.')&&(element.name[len-1]>='1')&&(element.name[len-1]<='9')) {
						continue; // this filename ends in .1, .2, ..., .9, so it is a groff man page
					}
					// if we reach here, it is a non-groff man page, so ask for PANDOC
					dataStream.put_string("find_program ( WHERE_PANDOC pandoc )\n");
					dataStream.put_string("if ( NOT WHERE_PANDOC )\n\tMESSAGE(FATAL_ERROR \"Error! PANDOC is not installed.\")\nendif()\n\n");
					break;
				}

				// now, put all the binary and library folders, in order of satisfied dependencies
				var paths=new Gee.HashMap<string,ElementBase>();
				foreach(var element in ElementBase.globalData.globalElements) {
					if ((paths.has_key(element.path)==false)&&(ignoreList.contains(element.path)==false)) {
						if ((element.eType==ConfigType.VALA_BINARY)||(element.eType==ConfigType.VALA_LIBRARY)) {
							var binElement = element as ElementValaBinary;
							if (binElement.sources.size==0) { // don't add binary folders without source files
								continue;
							}
						}
						paths.set(element.path,element);
					}
				}
				Gee.Set<string> packagesFound=new Gee.HashSet<string>();
				bool allProcessed=false;
				while(allProcessed==false) {
					bool addedOne=false;
					allProcessed=true;
					foreach(var path in paths.keys) {
						var element=paths.get(path);
						if ((element.eType==ConfigType.DEFINE) || (element.eType == ConfigType.SOURCE_DEPENDENCY) || (element.eType == ConfigType.BINARY_DEPENDENCY)) {
							continue;
						}
						if (element.processed) {
							continue;
						}
						if ((element.eType!=ConfigType.VALA_LIBRARY) && (element.eType!=ConfigType.VALA_BINARY)) {
							element.processed=true;
							this.addFolderToMainCMakeLists(path,dataStream);
							addedOne=true;
							continue;
						} else {
							var binElement = element as ElementValaBinary;
							allProcessed=false;
							bool valid=true;
							foreach(var package in binElement.packages) {
								if((package.type==packageType.LOCAL)&&(false==packagesFound.contains(package.elementName))) {
									valid=false;
									break;
								}
							}
							if (valid==false) { // has dependencies still not satisfied
								continue;
							}

							addFolderToMainCMakeLists(path,dataStream);
							addedOne=true;
							element.processed=true;
							if ((binElement.eType==ConfigType.VALA_LIBRARY)&&(binElement.currentNamespace!="")) {
								packagesFound.add(binElement.currentNamespace);
							}
						}
					}
					if ((allProcessed==false)&&(addedOne==false)) {
						string error=_("The following local dependencies cannot be satisfied:");
						foreach(var path in paths.keys) {
							var element=paths.get(path);
							if ((element.processed)||((element.eType!=ConfigType.VALA_LIBRARY)&&(element.eType!=ConfigType.VALA_BINARY))) {
								continue;
							}
							if (element.eType==ConfigType.VALA_LIBRARY) {
								error+=_("\n\tLibrary %s, packages:").printf(Path.build_filename(element.path,element.name));
							} else {
								error+=_("\n\tBinary %s, packages:").printf(Path.build_filename(element.path,element.name));
							}
							var binElement = element as ElementValaBinary;
							foreach(var package in binElement.packages) {
								if((package.type==packageType.LOCAL)&&(false==packagesFound.contains(package.elementName))) {
									error+=" "+package.elementName;
								}
							}
						}
						ElementBase.globalData.addError(error);
						return true;
					}
				}
				dataStream.put_string("\n");
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to generate the main CMakeLists.txt file"));
			}
			return false;
		}

		public override bool generateCMakeHeader(DataOutputStream dataStream) {

			try {
				dataStream.put_string("### CMakeLists automatically created with AutoVala\n### Do not edit\n\n");
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to store a header"));
				return true;
			}
			return false;
		}
	}
}
