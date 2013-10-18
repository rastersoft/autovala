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
using Gtk;

namespace AutoVala {

	public class cmake:GLib.Object {

		private string[] error_list;
		private configuration config;
		private string append_text;
		private Gee.Map<string,string>? local_modules;

		public cmake(configuration conf) {
			this.config=conf;
			this.error_list={};
			this.local_modules=null;
		}

		public void clear_errors() {
			this.error_list={};
		}

		public void show_errors() {
			foreach(var e in this.error_list) {
				GLib.stdout.printf("%s\n".printf(e));
			}
			this.clear_errors();
		}

		public string[] get_error_list() {
			return this.error_list;
		}

		public bool create_cmake() {
			if (this.config.config_path=="") {
				return true;
			}

			// Get all the diferent paths in the project
			// to create in each one its CMakeLists file
			// Also store the paths for local libraries
			this.local_modules=new Gee.HashMap<string,string>();
			var ignore_list=new Gee.HashSet<string>();
			foreach(var element in this.config.configuration_data) {
				if ((element.type==Config_Type.IGNORE)&&(ignore_list.contains(element.path)==false)) {
					ignore_list.add(element.path);
				}
				if ((element.type==Config_Type.VALA_LIBRARY)&&(element.current_namespace!="")&&(this.local_modules.has_key(element.current_namespace)==false)) {
					this.local_modules.set(element.current_namespace,element.path);
				}
			}
			var paths=new Gee.HashMap<string,config_element>();
			foreach(var element in this.config.configuration_data) {
				if ((paths.has_key(element.path)==false)&&(ignore_list.contains(element.path)==false)) {
					if ((element.type==Config_Type.VALA_BINARY)||(element.type==Config_Type.VALA_LIBRARY)) {
						if (element.sources.size==0) { // don't add binary folders without source files
							continue;
						}
					}
					paths.set(element.path,element);
				}
			}

			// Create CMakeLists file in the project root directory
			try {
				var file=File.new_for_path(Path.build_filename(this.config.basepath,"CMakeLists.txt"));
				if (file.query_exists()) {
					file.delete();
				}
				var dis = file.create(FileCreateFlags.NONE);
				var data_stream = new DataOutputStream(dis);
				data_stream.put_string("### CMakeLists automatically created with AutoVala\n### Do not edit\n\n");
				data_stream.put_string("project ("+this.config.project_name+")\n");
				data_stream.put_string("cmake_minimum_required (VERSION 2.6)\n");
				data_stream.put_string("cmake_policy (VERSION 2.8)\n");
				data_stream.put_string("list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)\n");
				data_stream.put_string("enable_testing ()\n\n");
				data_stream.put_string("option(BUILD_VALADOC \"Build API documentation if Valadoc is available\" OFF)\n\n");
				data_stream.put_string("set(HAVE_VALADOC OFF)\n");
				data_stream.put_string("if(BUILD_VALADOC)\n");
				data_stream.put_string("\tfind_package(Valadoc)\n");
				data_stream.put_string("\tif(VALADOC_FOUND)\n");
				data_stream.put_string("\t\tset(HAVE_VALADOC ON)\n");
				data_stream.put_string("\t\tinclude(Valadoc)\n");
				data_stream.put_string("\telse()\n");
				data_stream.put_string("\t\tmessage(\"Valadoc not found, will not build documentation\")\n");
				data_stream.put_string("\tendif()\n");
				data_stream.put_string("endif()\n\n");

				data_stream.put_string("find_package(PkgConfig)\n\n");

				data_stream.put_string("set(MODULES_TO_CHECK\n");
				Gee.Set<string> tocheck=new Gee.HashSet<string>();
				foreach(var element in config.configuration_data) {
					if ((element.type!=Config_Type.VALA_BINARY)&&(element.type!=Config_Type.VALA_LIBRARY)) {
						continue;
					}
					foreach(var module in element.packages) {
						if (module.type==package_type.do_check) {
							if (tocheck.contains(module.package)) {
								continue;
							}
							if (module.condition!=null) {
								continue;
							}
							data_stream.put_string("\t"+module.package+"\n");
							tocheck.add(module.package);
						}
					}
				}
				data_stream.put_string(")\n\n");
				string current_condition=null;
				bool inverted_condition=false;
				foreach(var element in config.configuration_data) {
					if ((element.type!=Config_Type.VALA_BINARY)&&(element.type!=Config_Type.VALA_LIBRARY)) {
						continue;
					}
					foreach(var module in element.packages) {
						if (module.type==package_type.do_check) {
							if (tocheck.contains(module.package)) {
								continue;
							}
							if (module.condition==null) {
								continue;
							}
							if (module.condition==current_condition) {
								if ((module.condition!=null) && (module.invert_condition!=inverted_condition)) {
									data_stream.put_string("ELSE()\n");
									inverted_condition=module.invert_condition;
								}
							} else {
								inverted_condition=false;
								if(current_condition!=null) {
									data_stream.put_string("ENDIF()\n");
								}
								if(module.condition!=null) {
									data_stream.put_string("IF (%s)\n".printf(module.condition));
									if (module.invert_condition==true) {
										data_stream.put_string("ELSE()\n");
										inverted_condition=module.invert_condition;
									}
								}
								current_condition=module.condition;
							}
							data_stream.put_string("\tset (MODULES_TO_CHECK ${MODULES_TO_CHECK} "+module.package+")\n");
							tocheck.add(module.package);
						}
					}
					if (current_condition!=null) {
						data_stream.put_string("ENDIF()\n\n");
					}
				}



				data_stream.put_string("pkg_check_modules(DEPS REQUIRED ${MODULES_TO_CHECK})\n\n");

				// now, put all the binary and library folders, in order of satisfied dependencies
				Gee.Set<string> packages_found=new Gee.HashSet<string>();
				bool all_processed=false;
				while(all_processed==false) {
					bool added_one=false;
					all_processed=true;
					foreach(var path in paths.keys) {
						var element=paths.get(path);
						if (element.type==Config_Type.DEFINE) {
							continue;
						}
						if (element.processed) {
							continue;
						}
						if ((element.type!=Config_Type.VALA_LIBRARY)&&(element.type!=Config_Type.VALA_BINARY)) {
							element.processed=true;
							add_folder_to_main_cmakelists(path,data_stream);
							added_one=true;
							continue;
						}
						all_processed=false;
						bool valid=true;
						foreach(var package in element.packages) {
							if((package.type==package_type.local)&&(false==packages_found.contains(package.package))) {
								valid=false;
								break;
							}
						}
						if (valid==false) { // has dependencies still not satisfied
							continue;
						}

						add_folder_to_main_cmakelists(path,data_stream);
						added_one=true;
						element.processed=true;
						if ((element.type==Config_Type.VALA_LIBRARY)&&(element.current_namespace!="")) {
							packages_found.add(element.current_namespace);
						}
					}
					if ((all_processed==false)&&(added_one==false)) {
						string error=_("The following local dependencies cannot be satisfied:");
						foreach(var path in paths.keys) {
							var element=paths.get(path);
							if ((element.processed)||((element.type!=Config_Type.VALA_LIBRARY)&&(element.type!=Config_Type.VALA_BINARY))) {
								continue;
							}
							if (element.type==Config_Type.VALA_LIBRARY) {
								error+=_("\n\tLibrary %s, packages:").printf(Path.build_filename(element.path,element.file));
							} else {
								error+=_("\n\tBinary %s, packages:").printf(Path.build_filename(element.path,element.file));
							}
							foreach(var package in element.packages) {
								if((package.type==package_type.local)&&(false==packages_found.contains(package.package))) {
									error+=" "+package.package;
								}
							}
						}
						this.error_list+=error;
						return true;
					}
				}

				if (this.create_cmake_for_dir("",data_stream,ignore_list)) {
					return true;
				}
				data_stream.close();
			} catch (Error e) {
				this.error_list+=_("Failed to create the main CMakeLists file");
				return true;
			}

			foreach(var element in paths.keys) {
				if (element!="") { // don't check the main folder
					var dirpath=File.new_for_path(Path.build_filename(this.config.basepath,element));
					if(dirpath.query_exists()==false) {
						continue;
					}
					var filepath=Path.build_filename(this.config.basepath,element,"CMakeLists.txt");
					var file=File.new_for_path(filepath);
					if (file.query_exists()) {
						try {
							file.delete();
						} catch (Error e) {
							this.error_list+=_("Failed to delete the old CMakeLists file at %s").printf(element);
							return true;
						}
					}
					try {
						var dis = file.create(FileCreateFlags.NONE);
						var data_stream = new DataOutputStream(dis);
						data_stream.put_string("### CMakeLists automatically created with AutoVala\n### Do not edit\n\n");
						data_stream.put_string("if(${CMAKE_INSTALL_PREFIX} MATCHES usr/local/? )\n");
						data_stream.put_string("\tset( AUTOVALA_INSTALL_PREFIX \"/usr/local\")\n");
						data_stream.put_string("else()\n");
						data_stream.put_string("\tset( AUTOVALA_INSTALL_PREFIX \"/usr\")\n");
						data_stream.put_string("endif()\n\n");
						data_stream.put_string("STRING (REPLACE \"/\" \";\" AUTOVALA_PATH_LIST ${CMAKE_INSTALL_PREFIX})\n");
						data_stream.put_string("SET (FINAL_AUTOVALA_PATH \"\")\n\n");
						data_stream.put_string("FOREACH(element ${AUTOVALA_PATH_LIST})\n");
						data_stream.put_string("\tIF (${FOUND_USR})\n");
						data_stream.put_string("\t\tSET(FINAL_AUTOVALA_PATH ${FINAL_AUTOVALA_PATH}/.. )\n");
						data_stream.put_string("\tELSE()\n");
						data_stream.put_string("\t\tIF(${element} STREQUAL \"usr\")\n");
						data_stream.put_string("\t\t\tSET(FOUND_USR 1)\n");
						data_stream.put_string("\t\t\tSET(FINAL_AUTOVALA_PATH ${FINAL_AUTOVALA_PATH}.. )\n");
						data_stream.put_string("\t\tENDIF()\n");
						data_stream.put_string("\tENDIF()\n");
						data_stream.put_string("ENDFOREACH()\n\n");
						if (this.create_cmake_for_dir(element,data_stream,ignore_list)) {
							return true;
						}
						data_stream.close();
					} catch (Error e) {
						this.error_list+=_("Failed to create file %s").printf(filepath);
						return true;
					}
				}
			}
			return false;
		}

		private void add_folder_to_main_cmakelists(string element, DataOutputStream data_stream) {

			var dirpath=File.new_for_path(Path.build_filename(this.config.basepath,element));
			if (dirpath.query_exists()==false) {
				this.error_list+=_("Warning: directory %s doesn't exists").printf(element);
				return;
			} else {
				if (element!="src") {
					bool has_childrens=false;
					try {
						var enumerator = dirpath.enumerate_children (FileAttribute.STANDARD_NAME+","+FileAttribute.STANDARD_TYPE, 0);
						FileInfo file_info;
						while ((file_info = enumerator.next_file ()) != null) {
							var fname=file_info.get_name();
							var ftype=file_info.get_file_type();
							if (ftype==FileType.DIRECTORY) {
								continue; // don't add folders that only contains folders
							}
							if (fname=="CMakeLists.txt") {
								continue;
							}
							has_childrens=true; // found a file, so we add it
							break;
						}
					} catch (Error e) {
						this.error_list+=_("Warning: can't access folder %s").printf(element);
						return;
					}
					if (has_childrens==false) {
						return;
					}
				}
				try {
					data_stream.put_string("add_subdirectory("+element+")\n");
				} catch (Error e) {
					this.error_list+=_("Warning: can't add subdirectory %s").printf(element);
				}
			}

		}

		private bool create_cmake_for_dir(string dir,DataOutputStream data_stream,Gee.Set<string> ignore_list) {

			this.append_text="";
			string includes="";
			bool added_vala_binaries=false;
			bool added_icon_suffix=false;
			bool added_dbus_prefix=false;
			bool added_scheme_prefix=false;
			Gee.Set<string> defines=new Gee.HashSet<string>();

			bool error=false;

			foreach(var element in this.config.configuration_data) {
				if (element.type==Config_Type.DEFINE) {
					defines.add(element.path);
				}
			}

			foreach(var element in this.config.configuration_data) {
				if (element.path!=dir) {
					continue;
				}
				var fullpath_s=Path.build_filename(this.config.basepath,dir,element.file);
				if (ignore_list.contains(fullpath_s)) {
					continue;
				}
				if ((element.type!=Config_Type.VALA_BINARY)&&(element.type!=Config_Type.VALA_LIBRARY)&&(element.type!=Config_Type.PO)&&(element.type!=Config_Type.DATA)&&(element.type!=Config_Type.DOC)) {
					var fullpath=File.new_for_path(fullpath_s);
					if (fullpath.query_exists()==false) {
						this.error_list+=_("Warning: file %s doesn't exists").printf(Path.build_filename(dir,element.file));
						continue;
					}
				}
				switch(element.type) {
				case Config_Type.CUSTOM:
					error=this.create_custom(dir,element,data_stream);
					break;
				case Config_Type.DATA:
					error=this.create_data(dir,data_stream);
					break;
				case Config_Type.DOC:
					error=this.create_doc(dir,data_stream);
					break;
				case Config_Type.PO:
					error=this.create_po(dir,data_stream);
					break;
				case Config_Type.VALA_BINARY:
					error=this.create_vala_binary(dir,data_stream,element,false,added_vala_binaries,ignore_list,defines);
					added_vala_binaries=true;
					break;
				case Config_Type.VALA_LIBRARY:
					error=this.create_vala_binary(dir,data_stream,element,true,added_vala_binaries,ignore_list,defines);
					added_vala_binaries=true;
					break;
				case Config_Type.BINARY:
					try {
						data_stream.put_string("install(PROGRAMS ${CMAKE_CURRENT_SOURCE_DIR}/"+element.file+" DESTINATION bin/)\n");
					} catch (Error e) {
						this.error_list+=_("Failed to add binary %s").printf(element.file);
						error=true;
					}
					break;
				case Config_Type.ICON:
					error=this.create_icon(dir, data_stream, element.file, element.icon_path, added_icon_suffix);
					added_icon_suffix=true;
					break;
				case Config_Type.PIXMAP:
				case Config_Type.GLADE:
					try {
						data_stream.put_string("install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/"+element.file+" DESTINATION share/"+this.config.project_name+"/ )\n");
					} catch (Error e) {
						this.error_list+=_("Failed to add file %s").printf(element.file);
						error=true;
					}
					break;
				case Config_Type.DBUS_SERVICE:
					error=this.create_dbus_service(dir,data_stream,element.file,added_dbus_prefix);
					added_dbus_prefix=true;
					break;
				case Config_Type.DESKTOP:
					try {
						data_stream.put_string("install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/"+element.file+" DESTINATION share/applications/ )\n");
					} catch (Error e) {
						this.error_list+=_("Failed to add file %s").printf(element.file);
						error=true;
					}
					break;
				case Config_Type.AUTOSTART:
					error=this.create_autostart(dir,data_stream,element.file);
					break;
				case Config_Type.EOS_PLUG:
					try {
						data_stream.put_string("configure_file(${CMAKE_CURRENT_SOURCE_DIR}/"+element.file+" ${CMAKE_CURRENT_BINARY_DIR}/"+element.file+")\n");
						data_stream.put_string("install(FILES ${CMAKE_CURRENT_BINARY_DIR}/"+element.file+" DESTINATION lib/plugs/"+config.project_name+"/"+config.project_name+"/)\n");
					} catch (Error e) {
						this.error_list+=_("Failed to add file %s").printf(element.file);
						error=true;
					}
					break;
				case Config_Type.SCHEME:
					try {
						if (added_scheme_prefix==false) {
							data_stream.put_string("include(GSettings)\n");
							added_scheme_prefix=true;
						}
						data_stream.put_string("add_schema("+element.file+")\n");
					} catch (Error e) {
						this.error_list+=_("Failed to add schema %s").printf(element.file);
						error=true;
					}
					break;
				case Config_Type.INCLUDE:
					includes+="include(${CMAKE_CURRENT_SOURCE_DIR}/"+element.file+")\n";
					break;
				default:
					break;
				}

				if (error) {
					break;
				}
			}
			if ((error==false)&&(this.append_text!="")) {
				try {
					data_stream.put_string(this.append_text);
				} catch (Error e) {
					this.error_list+=_("Can't append data to CMakeLists file at %s").printf(dir);
					error=true;
				}
			}
			if ((error==false)&&(includes!="")) {
				try {
					data_stream.put_string(includes);
				} catch (Error e) {
					this.error_list+=_("Can't append INCLUDEs to CMakeLists file at %s").printf(dir);
					error=true;
				}
			}
			return error;
		}

		private bool create_autostart(string dir, DataOutputStream data_stream, string element_file) {

			// .desktop files for programs that must be launched automatically during gnome/kde/whatever startup

			try {
				data_stream.put_string("install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/"+element_file+" DESTINATION ${FINAL_AUTOVALA_PATH}/etc/xdg/autostart/ )\n");
			} catch (Error e) {
				this.error_list+=_("Failed to write the CMakeLists file for %s").printf(element_file);
				return true;
			}
			return false;
		}


		private bool create_custom(string dir,config_element element,DataOutputStream data_stream) {
			string destination;
			if (element.destination[0]!='/') {
				destination=element.destination;
			} else {
				destination="${FINAL_AUTOVALA_PATH}%s".printf(element.destination);
			}
			try {
				data_stream.put_string("IF(IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/%s)\n".printf(element.file));
				data_stream.put_string("\tinstall(DIRECTORY\n");
				data_stream.put_string("\t\t${CMAKE_CURRENT_SOURCE_DIR}/%s\n".printf(element.file));
				data_stream.put_string("\tDESTINATION\n");
				data_stream.put_string("\t\t"+destination+"\n");
				data_stream.put_string("\t)\n");
				data_stream.put_string("ELSE()\n");
				data_stream.put_string("\tinstall(FILES\n");
				data_stream.put_string("\t\t${CMAKE_CURRENT_SOURCE_DIR}/%s\n".printf(element.file));
				data_stream.put_string("\tDESTINATION\n");
				data_stream.put_string("\t\t"+destination+"\n");
				data_stream.put_string("\t)\n");
				data_stream.put_string("ENDIF()\n\n");
			} catch (Error e) {
				this.error_list+=_("Failed to write the CMakeLists file for custom file %s").printf(element.file);
				return true;
			}
			return false;
		}

		private bool create_dbus_service(string dir, DataOutputStream data_stream, string element_file,bool added_dbus_prefix) {

			// DBus files must have the full path for the binary, so, in case we are building a deb or rpm package, we need to know
			// where the binary will be really
			if (added_dbus_prefix==false) {
				try {
					data_stream.put_string("SET(DBUS_PREFIX ${AUTOVALA_INSTALL_PREFIX})\n");
				} catch (Error e) {
					this.error_list+=_("Can't append data to CMakeLists file at %s").printf(dir);
					return true;
				}
			}

			try {
				// DBus files must use DBUS_PREFIX in their path, instead of a fixed one, to allow them to be installed both in /usr or /usr/local
				data_stream.put_string("configure_file(${CMAKE_CURRENT_SOURCE_DIR}/"+element_file+" ${CMAKE_CURRENT_BINARY_DIR}/"+element_file+")\n");
				data_stream.put_string("install(FILES ${CMAKE_CURRENT_BINARY_DIR}/"+element_file+" DESTINATION ${CMAKE_INSTALL_PREFIX}/share/dbus-1/services/)\n");
			} catch (Error e) {
				this.error_list+=_("Failed to write the CMakeLists file for %s").printf(element_file);
				return true;
			}
			return false;
		}

		private bool create_icon(string dir, DataOutputStream data_stream, string element_file,string l_icon_path,bool added_suffix) {

			var full_path=Path.build_filename(this.config.basepath,dir,element_file);
			int size=0;

			string icon_path=l_icon_path;

			// For each PNG file, find the icon size to which it belongs
			if (element_file.has_suffix(".png")) {
				if (icon_path=="") {
					icon_path="apps";
				}
				try {
					var picture=new Gdk.Pixbuf.from_file(full_path);
					int w=picture.width;
					int h=picture.height;
					int[] sizes = {16, 22, 24, 32, 36, 48, 64, 72, 96, 128, 192, 256};
					size=512;
					foreach (var s in sizes) {
						if ((w<=s) && (h<=s)) {
							size=s;
							break;
						}
					}
				} catch (Error e) {
					this.error_list+=_("Can't get the size for icon %s").printf(full_path);
					return true;
				}
				try {
					data_stream.put_string("install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/%s DESTINATION share/icons/hicolor/%d/%s/)\n".printf(element_file,size,icon_path));
				} catch (Error e) {
					this.error_list+=_("Failed to write the CMakeLists file for icon %s").printf(full_path);
					return true;
				}
			} else if (element_file.has_suffix(".svg")) {
				try {
					// For SVG icons, if they are "symbolic", put them in STATUS, not in APPS
					if (element_file.has_suffix("-symbolic.svg")) {
						if (icon_path=="") {
							icon_path="status";
						}
						data_stream.put_string("install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/%s DESTINATION share/icons/hicolor/scalable/%s/)\n".printf(element_file,icon_path));
					} else {
						if (icon_path=="") {
							icon_path="apps";
						}
						data_stream.put_string("install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/%s DESTINATION share/icons/hicolor/scalable/%s/)\n".printf(element_file,icon_path));
					}
				} catch (Error e) {
					this.error_list+=_("Failed to write the CMakeLists file for icon %s").printf(full_path);
					return true;
				}
			} else {
				this.error_list+=_("Unknown icon type %s. Must be .png or .svg (in lowercase)").printf(element_file);
				return true;
			}

			// Refresh the icon cache (but only if ICON_UPDATE is not OFF; that means we are building a package)
			if (added_suffix==false) {
				this.append_text+="\nIF(NOT (DEFINED ICON_UPDATE))\n";
				this.append_text+="\tSET (ICON_UPDATE \"ON\")\n";
				this.append_text+="ENDIF()\n";
				this.append_text+="IF( NOT (${ICON_UPDATE} STREQUAL \"OFF\" ))\n";
				this.append_text+="\tinstall (CODE \"execute_process ( COMMAND /usr/bin/gtk-update-icon-cache-3.0 -t ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor )\" )\n";
				this.append_text+="ENDIF()\n";
			}
			return false;
		}

		private bool create_data(string dir,DataOutputStream data_stream) {

			try {
				data_stream.put_string("file(GLOB list_data RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} *)\n");
				data_stream.put_string("foreach(file_data ${list_data})\n");
				data_stream.put_string("\tIF(IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/${file_data})\n");
				data_stream.put_string("\t\tinstall(DIRECTORY\n");
				data_stream.put_string("\t\t\t${file_data}\n");
				data_stream.put_string("\t\tDESTINATION\n");
				data_stream.put_string("\t\t\t"+Path.build_filename("share",this.config.project_name)+"\n");
				data_stream.put_string("\t\t)\n");
				data_stream.put_string("\tELSE()\n");
				data_stream.put_string("\t\tinstall(FILES\n");
				data_stream.put_string("\t\t\t${file_data}\n");
				data_stream.put_string("\t\tDESTINATION\n");
				data_stream.put_string("\t\t\t"+Path.build_filename("share",this.config.project_name)+"\n");
				data_stream.put_string("\t\t)\n");
				data_stream.put_string("\tENDIF()\n");
				data_stream.put_string("endforeach()\n\n");
			} catch (Error e) {
				this.error_list+=_("Failed to install local files at %s").printf(dir);
				return true;
			}
			return false;
		}

		private bool create_doc(string dir,DataOutputStream data_stream) {

			try {
				data_stream.put_string("file(GLOB list_data RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} *)\n");
				data_stream.put_string("foreach(file_data ${list_data})\n");
				data_stream.put_string("\tIF(IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/${file_data})\n");
				data_stream.put_string("\t\tinstall(DIRECTORY\n");
				data_stream.put_string("\t\t\t${file_data}\n");
				data_stream.put_string("\t\tDESTINATION\n");
				data_stream.put_string("\t\t\t"+Path.build_filename("share/doc",this.config.project_name)+"\n");
				data_stream.put_string("\t\t)\n");
				data_stream.put_string("\tELSE()\n");
				data_stream.put_string("\t\tinstall(FILES\n");
				data_stream.put_string("\t\t\t${file_data}\n");
				data_stream.put_string("\t\tDESTINATION\n");
				data_stream.put_string("\t\t\t"+Path.build_filename("share/doc",this.config.project_name)+"\n");
				data_stream.put_string("\t\t)\n");
				data_stream.put_string("\tENDIF()\n");
				data_stream.put_string("endforeach()\n\n");
			} catch (Error e) {
				this.error_list+=_("Failed to install document files at %s").printf(dir);
				return true;
			}
			return false;
		}

		private bool create_po(string dir,DataOutputStream data_stream) {

			var fname=File.new_for_path(Path.build_filename(this.config.basepath,dir,"POTFILES.in"));
			if (fname.query_exists()==true) {
				try {
					fname.delete();
				} catch (Error e) {
					this.error_list+=_("Failed to delete the old POTFILES.in file");
					return true;
				}
			}

			// Generate the POTFILES.in file for compatibility with xgettext
			try {
				var dis = fname.create(FileCreateFlags.NONE);
				var data_stream2 = new DataOutputStream(dis);

				foreach(var e in this.config.configuration_data) {
					var final_path=Path.build_filename(e.path,e.file);
					switch (e.type) {
					case Config_Type.VALA_BINARY:
					case Config_Type.VALA_LIBRARY:
						var directory = File.new_for_path(Path.build_filename(this.config.basepath,e.path));
						if (directory.query_exists()==false) {
							continue;
						}
						var enumerator = directory.enumerate_children(FileAttribute.STANDARD_NAME, 0);
						FileInfo file_info;
						while ((file_info = enumerator.next_file ()) != null) {
							if (file_info.get_name().has_suffix(".vala")) {
								data_stream2.put_string(Path.build_filename(e.path,file_info.get_name())+"\n");
							}
						}
					break;
					case Config_Type.GLADE:
						data_stream2.put_string("[type: gettext/glade]"+final_path+"\n");
					break;
					default:
					break;
					}
				}
				data_stream2.close();

				data_stream.put_string("include (Translations)\n");
				data_stream.put_string("add_translations_directory(\""+config.project_name+"\")\n");

				// Calculate the number of "../" needed to go from the PO folder to the root of the project
				string[] translatable_paths={};
				var toupper=dir.split(Path.DIR_SEPARATOR_S).length;
				var tmp_path="";
				for(var c=0;c<toupper;c++) {
					tmp_path+="../";
				}

				// Find all the folders with translatable files
				foreach (var element in this.config.configuration_data) {
					if ((element.type==Config_Type.VALA_BINARY) || (element.type==Config_Type.GLADE)) {
						bool found=false;
						foreach (var p in translatable_paths) {
							if (p==element.path) {
								found=true;
								break;
							}
						}
						if (found==false) {
							translatable_paths+=element.path;
						}
					}
				}

				// Add the files to translate using the VALA CMAKE macros
				if (translatable_paths.length!=0) {
					data_stream.put_string("add_translations_catalog(\""+config.project_name+"\" ");
					foreach(var p in translatable_paths) {
						data_stream.put_string(tmp_path+p+" ");
					}
					data_stream.put_string(")\n");
				}
			} catch (Error e) {
				this.error_list+=_("Failed to create the PO files");
				return true;
			}
			return false;
		}

		private bool create_vala_binary(string dir,DataOutputStream data_stream, config_element element, bool is_library,
				bool added_vala_binaries, Gee.Set<string> ignore_list, Gee.Set<string> defines) {

			string gir_filename="";
			string lib_filename=element.file;
			if (element.current_namespace!="") {
				// Build the GIR filename
				gir_filename=element.current_namespace+"-"+element.version.split(".")[0]+".0.gir";
				lib_filename=element.current_namespace;
			}

			string ?destination;
			if (element.destination==null) {
				destination=null;
			} else {
				if (element.destination[0]!='/') {
					destination=element.destination;
				} else {
					destination="${FINAL_AUTOVALA_PATH}%s".printf(element.destination);
				}
			}

			var fname=File.new_for_path(Path.build_filename(this.config.basepath,dir,"Config.vala.cmake"));
			try {
				if (fname.query_exists()) {
					fname.delete();
				}
				var dis = fname.create(FileCreateFlags.NONE);
				var data_stream2 = new DataOutputStream(dis);
				if (is_library && (element.current_namespace!="")) {
					data_stream2.put_string("namespace "+lib_filename+"Constants {\n");
				} else {
					data_stream2.put_string("namespace Constants {\n");
				}
				data_stream2.put_string("\tpublic const string DATADIR = \"@DATADIR@\";\n");
				data_stream2.put_string("\tpublic const string PKGDATADIR = \"@PKGDATADIR@\";\n");
				data_stream2.put_string("\tpublic const string GETTEXT_PACKAGE = \"@GETTEXT_PACKAGE@\";\n");
				data_stream2.put_string("\tpublic const string RELEASE_NAME = \"@RELEASE_NAME@\";\n");
				data_stream2.put_string("\tpublic const string VERSION = \"@VERSION@\";\n");
				data_stream2.put_string("}\n");
				data_stream2.close();
			} catch (Error e) {
				this.error_list+=_("Failed to create the Config.vala.cmake file");
				return true;
			}

			try {
				if (added_vala_binaries==false) {
					data_stream.put_string("set (DATADIR \"${AUTOVALA_INSTALL_PREFIX}/share\")\n");
					data_stream.put_string("set (PKGDATADIR \"${DATADIR}/"+config.project_name+"\")\n");
					data_stream.put_string("set (GETTEXT_PACKAGE \""+config.project_name+"\")\n");
					data_stream.put_string("set (RELEASE_NAME \""+config.project_name+"\")\n");
					data_stream.put_string("set (CMAKE_C_FLAGS \"\")\n");
					data_stream.put_string("set (PREFIX ${CMAKE_INSTALL_PREFIX})\n");
					data_stream.put_string("set (VERSION \""+element.version+"\")\n");
					data_stream.put_string("set (DOLLAR \"$\")\n\n");
					if (dir!="") {
						data_stream.put_string("configure_file (${CMAKE_SOURCE_DIR}/"+dir+"/Config.vala.cmake ${CMAKE_BINARY_DIR}/"+dir+"/Config.vala)\n");
					} else {
						data_stream.put_string("configure_file (${CMAKE_SOURCE_DIR}/Config.vala.cmake ${CMAKE_BINARY_DIR}/Config.vala)\n");
					}
					data_stream.put_string("add_definitions(-DGETTEXT_PACKAGE=\\\"${GETTEXT_PACKAGE}\\\")\n");
				}

				string pc_filename=lib_filename+".pc";

				if (is_library) {
					fname=File.new_for_path(Path.build_filename(this.config.basepath,dir,lib_filename+".pc"));
					if (fname.query_exists()) {
						fname.delete();
					}
					try {
						var dis = fname.create(FileCreateFlags.NONE);
						var data_stream2 = new DataOutputStream(dis);
						data_stream2.put_string("prefix=@AUTOVALA_INSTALL_PREFIX@\n");
						data_stream2.put_string("real_prefix=@CMAKE_INSTALL_PREFIX@\n");
						data_stream2.put_string("exec_prefix=@DOLLAR@{prefix}\n");
						data_stream2.put_string("libdir=@DOLLAR@{exec_prefix}/lib\n");
						data_stream2.put_string("includedir=@DOLLAR@{exec_prefix}/include\n\n");
						data_stream2.put_string("Name: "+lib_filename+"\n");
						data_stream2.put_string("Description: "+lib_filename+"\n");
						data_stream2.put_string("Version: "+element.version+"\n");
						data_stream2.put_string("Libs: -L@DOLLAR@{libdir} -l"+lib_filename+"\n");
						data_stream2.put_string("Cflags: -I@DOLLAR@{includedir}\n");
						data_stream2.close();
					} catch (Error e) {
						this.error_list+=_("Failed to create the Config.vala.cmake file");
						return true;
					}
					data_stream.put_string("configure_file (${CMAKE_CURRENT_SOURCE_DIR}/"+pc_filename+" ${CMAKE_CURRENT_BINARY_DIR}/"+pc_filename+")\n");
				}

				data_stream.put_string("set (VERSION \""+element.version+"\")\n");

				data_stream.put_string("add_definitions(${DEPS_CFLAGS})\n");

				bool added_prefix=false;
				foreach(var module in element.packages) {
					if (module.type==package_type.local) {
						if (this.local_modules.has_key(module.package)) {
							if (added_prefix==false) {
								data_stream.put_string("include_directories( ");
								added_prefix=true;
							}
							data_stream.put_string("${CMAKE_BINARY_DIR}/"+local_modules.get(module.package)+" ");
						} else {
							this.error_list+=_("Warning: Can't set package %s for binary %s").printf(module.package,element.file);
						}
					}
				}
				if (added_prefix) {
					data_stream.put_string(")\n");
				}

				data_stream.put_string("link_libraries( ${DEPS_LIBRARIES} ");
				foreach(var module in element.packages) {
					if ((module.type==package_type.local)&&(this.local_modules.has_key(module.package))) {
						data_stream.put_string("-l"+module.package+" ");
					}
				}
				data_stream.put_string(")\n");
				data_stream.put_string("link_directories( ${DEPS_LIBRARY_DIRS} ");
				foreach(var module in element.packages) {
					if ((module.type==package_type.local)&&(this.local_modules.has_key(module.package))) {
						data_stream.put_string("${CMAKE_BINARY_DIR}/"+local_modules.get(module.package)+" ");
					}
				}
				data_stream.put_string(")\n");
				data_stream.put_string("find_package(Vala REQUIRED)\n");
				data_stream.put_string("include(ValaVersion)\n");
				data_stream.put_string("ensure_vala_version(\""+this.config.vala_version+"\" MINIMUM)\n");
				data_stream.put_string("include(ValaPrecompile)\n\n");

				data_stream.put_string("set(VALA_PACKAGES\n");
				foreach(var module in element.packages) {
					if(module.type!=package_type.local) {
						if (module.condition!=null) {
							continue;
						}
						data_stream.put_string("\t"+module.package+"\n");
					}
				}
				data_stream.put_string(")\n\n");

				string current_condition=null;
				bool inverted_condition=false;
				foreach(var module in element.packages) {
					if (module.condition==null) {
						continue;
					}
					if (module.condition==current_condition) {
						if ((module.condition!=null) && (module.invert_condition!=inverted_condition)) {
							data_stream.put_string("ELSE()\n");
							inverted_condition=module.invert_condition;
						}
					} else {
						inverted_condition=false;
						if(current_condition!=null) {
							data_stream.put_string("ENDIF()\n");
						}
						if(module.condition!=null) {
							data_stream.put_string("IF (%s)\n".printf(module.condition));
							if (module.invert_condition==true) {
								data_stream.put_string("ELSE()\n");
								inverted_condition=module.invert_condition;
							}
						}
						current_condition=module.condition;
					}
					data_stream.put_string("\tset (VALA_PACKAGES ${VALA_PACKAGES} "+module.package+")\n");
				}
				if (current_condition!=null) {
					data_stream.put_string("ENDIF()\n\n");
				}

				data_stream.put_string("set(APP_SOURCES\n");
				if ((is_library==false)||(element.current_namespace!="")) {
					data_stream.put_string("\t${CMAKE_CURRENT_BINARY_DIR}/Config.vala\n");
				}
				foreach (var filename in element.sources) {
					data_stream.put_string("\t"+filename.source+"\n");
				}
				data_stream.put_string(")\n\n");

				bool found_local=false;
				foreach(var module in element.packages) {
					if (module.type==package_type.local) {
						found_local=true;
					}
				}


				if ((element.vapis.size!=0)||(found_local==true)) {
					data_stream.put_string("set(CUSTOM_VAPIS_LIST\n");
					foreach (var filename in element.vapis) {
						data_stream.put_string("\t${CMAKE_SOURCE_DIR}/"+Path.build_filename(dir,filename.vapi)+"\n");
					}
					foreach(var module in element.packages) {
						if (module.type==package_type.local) {
							if (this.local_modules.has_key(module.package)) {
								data_stream.put_string("\t${CMAKE_BINARY_DIR}/"+Path.build_filename(local_modules.get(module.package),module.package+".vapi")+"\n");
							}
						}
					}
					data_stream.put_string(")\n\n");
				}

				bool added_defines=false;
				foreach(var l in defines) {
					if (added_defines==false) {
						added_defines=true;
						element.compile_options+=" ${OPTION_DEFINES}";
					}
					data_stream.put_string("IF (%s)\n".printf(l));
					data_stream.put_string("\tSET(OPTION_DEFINES ${OPTION_DEFINES} -D %s)\n".printf(l));
					data_stream.put_string("ENDIF()\n");
				}
				if (added_defines) {
					data_stream.put_string("\n");
				}

				data_stream.put_string("vala_precompile(VALA_C "+lib_filename+"\n");
				data_stream.put_string("\t${APP_SOURCES}\n");
				data_stream.put_string("PACKAGES\n");
				data_stream.put_string("\t${VALA_PACKAGES}\n");
				data_stream.put_string("CUSTOM_VAPIS\n");
				data_stream.put_string("\t${CUSTOM_VAPIS_LIST}\n");

				var final_options=element.compile_options;
				if (is_library) {
					// If it is a library, generate the Gobject Introspection file
					final_options="--library="+lib_filename;
					if (gir_filename!="") {
						final_options+=" --gir "+gir_filename;
					} else {
						this.error_list+=_("Warning: no namespace specified in library %s; GIR file will not be generated").printf(element.file);;
					}
					final_options+=" "+element.compile_options;
				}

				if (final_options!="") {
					data_stream.put_string("OPTIONS\n");
					data_stream.put_string("\t"+final_options+"\n");
				}

				if (is_library) {
					// Generate both VAPI and headers
					data_stream.put_string("GENERATE_VAPI\n");
					data_stream.put_string("\t"+lib_filename+"\n");
					data_stream.put_string("GENERATE_HEADER\n");
					data_stream.put_string("\t"+lib_filename+"\n");
				}

				data_stream.put_string(")\n\n");
				if (is_library) {
					data_stream.put_string("add_library("+lib_filename+" SHARED ${VALA_C})\n\n");

					// Set library version number
					data_stream.put_string("set_target_properties( "+lib_filename+" PROPERTIES\n");
					data_stream.put_string("VERSION\n");
					data_stream.put_string("\t"+element.version+"\n");
					data_stream.put_string("SOVERSION\n");
					data_stream.put_string("\t"+element.version.split(".")[0]+" )\n\n");

					// Install library
					data_stream.put_string("install(TARGETS\n");
					data_stream.put_string("\t"+lib_filename+"\n");
					data_stream.put_string("LIBRARY DESTINATION\n");
					if (destination==null) {
						data_stream.put_string("\tlib/\n");
					} else {
						data_stream.put_string("\t%s\n".printf(destination));
					}
					data_stream.put_string(")\n");

					// Install headers
					data_stream.put_string("install(FILES\n");
					data_stream.put_string("\t${CMAKE_CURRENT_BINARY_DIR}/"+lib_filename+".h\n");
					data_stream.put_string("DESTINATION\n");
					if (destination==null) {
						data_stream.put_string("\tinclude/\n");
					} else {
						data_stream.put_string("\t%s\n".printf(destination));
					}
					data_stream.put_string(")\n");

					// Install VAPI
					data_stream.put_string("install(FILES\n");
					data_stream.put_string("\t${CMAKE_CURRENT_BINARY_DIR}/"+lib_filename+".vapi\n");
					data_stream.put_string("DESTINATION\n");
					if (destination==null) {
						data_stream.put_string("\tshare/vala/vapi/\n");
					} else {
						data_stream.put_string("\t%s\n".printf(destination));
					}
					data_stream.put_string(")\n");

					// Install GIR
					if (gir_filename!="") {
						data_stream.put_string("install(FILES\n");
						data_stream.put_string("\t${CMAKE_CURRENT_BINARY_DIR}/"+gir_filename+"\n");
						data_stream.put_string("DESTINATION\n");
					if (destination==null) {
						data_stream.put_string("\tshare/gir-1.0/\n");
					} else {
						data_stream.put_string("\t%s\n".printf(destination));
					}
						data_stream.put_string(")\n");
					}

					// Install PC
					data_stream.put_string("install(FILES\n");
					data_stream.put_string("\t${CMAKE_CURRENT_BINARY_DIR}/"+pc_filename+"\n");
					data_stream.put_string("DESTINATION\n");
					if (destination==null) {
						data_stream.put_string("\tlib/pkgconfig/\n");
					} else {
						data_stream.put_string("\t%s\n".printf(destination));
					}
					data_stream.put_string(")\n");

				} else {

					// Install executable
					data_stream.put_string("add_executable("+lib_filename+" ${VALA_C})\n\n");
					data_stream.put_string("install(TARGETS\n");
					data_stream.put_string("\t"+lib_filename+"\n");
					data_stream.put_string("RUNTIME DESTINATION\n");
					if (destination==null) {
						data_stream.put_string("\tbin/\n");
					} else {
						data_stream.put_string("\t%s\n".printf(destination));
					}
					data_stream.put_string(")\n\n");
				}

				data_stream.put_string("if(HAVE_VALADOC)\n");
				data_stream.put_string("\tvaladoc("+lib_filename+"\n");
				data_stream.put_string("\t\t${CMAKE_BINARY_DIR}/"+Path.build_filename("valadoc",lib_filename)+"\n");
				data_stream.put_string("\t\t${APP_SOURCES}\n");
				data_stream.put_string("\tPACKAGES\n");
				data_stream.put_string("\t\t${VALA_PACKAGES}\n");
				data_stream.put_string("\tCUSTOM_VAPIS\n");
				data_stream.put_string("\t\t${CUSTOM_VAPIS_LIST}\n");
				data_stream.put_string("\t)\n");

				data_stream.put_string("\tinstall(DIRECTORY\n");
				data_stream.put_string("\t\t${CMAKE_BINARY_DIR}/valadoc\n");
				data_stream.put_string("\tDESTINATION\n");
				data_stream.put_string("\t\t"+Path.build_filename("share/doc",this.config.project_name)+"\n");
				data_stream.put_string("\t)\n");
				data_stream.put_string("endif()\n");
			} catch (Error e) {
				this.error_list+=_("Failed to write the CMakeLists file for binary %s").printf(lib_filename);
				return true;
			}
			return false;

		}
	}
}

