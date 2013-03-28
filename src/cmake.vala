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

		public cmake(configuration conf) {
			this.config=conf;
			this.error_list={};
		}

		public void clear_errors() {
			this.error_list={};
		}

		public void show_errors() {
			foreach(var e in this.error_list) {
				GLib.stdout.printf("%s\n".printf(e));
			}
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
			var ignore_list=new Gee.HashSet<string>();
			foreach(var element in this.config.configuration_data) {
				if ((element.type==Config_Type.IGNORE)&&(ignore_list.contains(element.path)==false)) {
					ignore_list.add(element.path);
				}
			}
			var paths=new Gee.HashSet<string>();
			foreach(var element in this.config.configuration_data) {
				if ((paths.contains(element.path)==false)&&(ignore_list.contains(element.path)==false)) {
					if ((element.type==Config_Type.VALA_BINARY)||(element.type==Config_Type.VALA_LIBRARY)) {
						if (element.sources.size==0) { // don't add binary folders without source files
							continue;
						}
					}
					paths.add(element.path);
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
				data_stream.put_string("enable_testing ()\n");
				foreach(var element in paths) {
					var dirpath=File.new_for_path(Path.build_filename(this.config.basepath,element));
					if (dirpath.query_exists()==false) {
						this.error_list+=_("Warning: directory %s doesn't exists").printf(element);
						continue;
					} else {
						if (element!="") {
							data_stream.put_string("add_subdirectory("+element+")\n");
						}
					}
				}
				if (this.create_cmake_for_dir("",data_stream,ignore_list)) {
					return true;
				}
				data_stream.close();
			} catch (Error e) {
				this.error_list+=_("Failed to create the main CMakeLists file\n");
				return true;
			}

			foreach(var element in paths) {
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
							this.error_list+=_("Failed to delete the old CMakeLists file at %s\n").printf(element);
							return true;
						}
					}
					try {
						var dis = file.create(FileCreateFlags.NONE);
						var data_stream = new DataOutputStream(dis);
						data_stream.put_string("### CMakeLists automatically created with AutoVala\n### Do not edit\n\n");
						if (this.create_cmake_for_dir(element,data_stream,ignore_list)) {
							return true;
						}
						data_stream.close();
					} catch (Error e) {
						this.error_list+=_("Failed to create file %s\n").printf(filepath);
						return true;
					}
				}
			}
			return false;
		}

		private bool create_cmake_for_dir(string dir,DataOutputStream data_stream,Gee.Set<string> ignore_list) {

			this.append_text="";
			string includes="";
			bool added_vala_binaries=false;
			bool added_icon_suffix=false;
			bool added_dbus_prefix=false;
			bool added_autostart_prefix=false;
			bool added_scheme_prefix=false;

			bool error=false;
			foreach(var element in this.config.configuration_data) {
				if (element.path!=dir) {
					continue;
				}
				var fullpath_s=Path.build_filename(this.config.basepath,dir,element.file);
				if (ignore_list.contains(fullpath_s)) {
					continue;
				}
				if ((element.type!=Config_Type.VALA_BINARY)&&(element.type!=Config_Type.VALA_LIBRARY)&&(element.type!=Config_Type.PO)) {
					var fullpath=File.new_for_path(fullpath_s);
					if (fullpath.query_exists()==false) {
						this.error_list+=_("Warning: file %s doesn't exists").printf(Path.build_filename(dir,element.file));
						continue;
					}
				}
				switch(element.type) {
				case Config_Type.PO:
					error=this.create_po(dir,data_stream);
					break;
				case Config_Type.VALA_BINARY:
					error=this.create_vala_binary(dir,data_stream,element,false,added_vala_binaries,ignore_list);
					added_vala_binaries=true;
					break;
				case Config_Type.VALA_LIBRARY:
					error=this.create_vala_binary(dir,data_stream,element,true,added_vala_binaries,ignore_list);
					added_vala_binaries=true;
					break;
				case Config_Type.BINARY:
					try {
						data_stream.put_string("install(PROGRAMS ${CMAKE_CURRENT_SOURCE_DIR}/"+element.file+" DESTINATION bin/)\n");
					} catch (Error e) {
						this.error_list+=_("Failed to add binary %s\n").printf(element.file);
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
						this.error_list+=_("Failed to add file %s\n").printf(element.file);
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
						this.error_list+=_("Failed to add file %s\n").printf(element.file);
						error=true;
					}
					break;
				case Config_Type.AUTOSTART:
					error=this.create_autostart(dir,data_stream,element.file,added_autostart_prefix);
					added_autostart_prefix=true;
					break;
				case Config_Type.EOS_PLUG:
					try {
						data_stream.put_string("configure_file(${CMAKE_CURRENT_SOURCE_DIR}/"+element.file+" ${CMAKE_CURRENT_BINARY_DIR}/"+element.file+")\n");
						data_stream.put_string("install(FILES ${CMAKE_CURRENT_BINARY_DIR}/"+element.file+" DESTINATION lib/plugs/"+config.project_name+"/"+config.project_name+"/)\n");
					} catch (Error e) {
						this.error_list+=_("Failed to add file %s\n").printf(element.file);
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
						this.error_list+=_("Failed to add schema %s\n").printf(element.file);
						error=true;
					}
					break;
				case Config_Type.INCLUDE:
					includes+="include(${CMAKE_CURRENT_SOURCE_DIR}/"+element.file+")\n";
					break;
				default:
					error=false;
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
					this.error_list+=_("Can't append data to CMakeLists file at %s\n").printf(dir);
					error=true;
				}
			}
			if ((error==false)&&(includes!="")) {
				try {
					data_stream.put_string(includes);
				} catch (Error e) {
					this.error_list+=_("Can't append INCLUDEs to CMakeLists file at %s\n").printf(dir);
					error=true;
				}
			}
			return error;
		}

		private bool create_autostart(string dir, DataOutputStream data_stream, string element_file,bool added_autostart_prefix) {

			// .desktop files for programs that must be launched automatically during gnome/kde/whatever startup
			// We need to know where we are installing all, because if we put a fixed /etc/xdg/autostart, the process will
			// fail when creating a deb or rpm packages, because they preinstall everything at CMAKE_INSTALL_PREFIX
			if (added_autostart_prefix==false) {
				try {
					data_stream.put_string("STRING (REPLACE \"/\" \";\" PATH_LIST ${CMAKE_INSTALL_PREFIX})\n");
					data_stream.put_string("SET (FINAL_PATH \"\")\n\n");
					data_stream.put_string("FOREACH(element ${PATH_LIST})\n");
					data_stream.put_string("\tIF (${FOUND_USR})\n");
					data_stream.put_string("\t\tSET(FINAL_PATH ${FINAL_PATH}/.. )\n");
					data_stream.put_string("\tELSE()\n");
					data_stream.put_string("\t\tIF(${element} STREQUAL \"usr\")\n");
					data_stream.put_string("\t\t\tSET(FOUND_USR 1)\n");
					data_stream.put_string("\t\t\tSET(FINAL_PATH ${FINAL_PATH}.. )\n");
					data_stream.put_string("\t\tENDIF()\n");
					data_stream.put_string("\tENDIF()\n");
					data_stream.put_string("ENDFOREACH()\n\n");
				} catch (Error e) {
					this.error_list+=_("Can't append data to CMakeLists file at %s\n").printf(dir);
					return true;
				}
			}

			try {
				data_stream.put_string("install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/"+element_file+" DESTINATION ${FINAL_PATH}/etc/xdg/autostart/ )\n");
			} catch (Error e) {
				this.error_list+=_("Failed to write the CMakeLists file for %s\n").printf(element_file);
				return true;
			}
			return false;
		}


		private bool create_dbus_service(string dir, DataOutputStream data_stream, string element_file,bool added_dbus_prefix) {

			// DBus files must have the full path for the binary, so, in case we are building a deb or rpm package, we need to know
			// where the binary will be really
			if (added_dbus_prefix==false) {
				try {
					data_stream.put_string("IF(${CMAKE_INSTALL_PREFIX} MATCHES usr/local/? )\n");
					data_stream.put_string("\tSET( DBUS_PREFIX \"/usr/local\")\n");
					data_stream.put_string("ELSE()\n");
					data_stream.put_string("\tSET (DBUS_PREFIX \"/usr\")\n");
					data_stream.put_string("ENDIF()\n\n");
				} catch (Error e) {
					this.error_list+=_("Can't append data to CMakeLists file at %s\n").printf(dir);
					return true;
				}
			}

			try {
				// DBus files must use DBUS_PREFIX in their path, instead of a fixed one, to allow them to be installed both in /usr or /usr/local
				data_stream.put_string("configure_file(${CMAKE_CURRENT_SOURCE_DIR}/"+element_file+" ${CMAKE_CURRENT_BINARY_DIR}/"+element_file+")\n");
				data_stream.put_string("install(FILES ${CMAKE_CURRENT_BINARY_DIR}/"+element_file+" DESTINATION ${CMAKE_INSTALL_PREFIX}/share/dbus-1/services/)\n");
			} catch (Error e) {
				this.error_list+=_("Failed to write the CMakeLists file for %s\n").printf(element_file);
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
					this.error_list+=_("Can't get the size for icon %s\n").printf(full_path);
					return true;
				}
				try {
					data_stream.put_string("install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/%s DESTINATION share/icons/hicolor/%d/%s/)\n".printf(element_file,size,icon_path));
				} catch (Error e) {
					this.error_list+=_("Failed to write the CMakeLists file for icon %s\n").printf(full_path);
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
					this.error_list+=_("Failed to write the CMakeLists file for icon %s\n").printf(full_path);
					return true;
				}
			} else {
				this.error_list+=_("Unknown icon type %s. Must be .png or .svg (in lowercase)\n").printf(element_file);
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

		private bool create_po(string dir,DataOutputStream data_stream) {

			var fname=File.new_for_path(Path.build_filename(this.config.basepath,dir,"POTFILES.in"));
			if (fname.query_exists()==true) {
				try {
					fname.delete();
				} catch (Error e) {
					this.error_list+=_("Failed to delete the old POTFILES.in file\n");
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
				this.error_list+=_("Failed to create the PO files\n");
				return true;
			}
			return false;
		}

		private bool create_vala_binary(string dir,DataOutputStream data_stream, config_element element, bool is_library,
				bool added_vala_binaries, Gee.Set<string> ignore_list) {

			string gir_filename="";
			string lib_filename=element.file;
			if (element.current_namespace!="") {
				// Build the GIR filename
				gir_filename=element.current_namespace+"-"+element.version.split(".")[0]+".0.gir";
				lib_filename=element.current_namespace;
			}

			var fname=File.new_for_path(Path.build_filename(this.config.basepath,dir,"Config.vala.cmake"));
			if (fname.query_exists()==false) {
				try {
					var dis = fname.create(FileCreateFlags.NONE);
					var data_stream2 = new DataOutputStream(dis);
					data_stream2.put_string("namespace Constants {\n");
					data_stream2.put_string("\tpublic const string DATADIR = \"@DATADIR@\";\n");
					data_stream2.put_string("\tpublic const string PKGDATADIR = \"@PKGDATADIR@\";\n");
					data_stream2.put_string("\tpublic const string GETTEXT_PACKAGE = \"@GETTEXT_PACKAGE@\";\n");
					data_stream2.put_string("\tpublic const string RELEASE_NAME = \"@RELEASE_NAME@\";\n");
					data_stream2.put_string("\tpublic const string VERSION = \"@VERSION@\";\n");
					data_stream2.put_string("\tpublic const string PLUGINDIR = \"@PLUGINDIR@\";\n");
					data_stream2.put_string("}\n");
					data_stream2.close();
				} catch (Error e) {
					this.error_list+=_("Failed to create the Config.vala.cmake file\n");
					return true;
				}
			}

			try {
				if (added_vala_binaries==false) {
					data_stream.put_string("set (DATADIR \"${CMAKE_INSTALL_PREFIX}/share\")\n");
					data_stream.put_string("set (PKGDATADIR \"${DATADIR}/"+config.project_name+"\")\n");
					data_stream.put_string("set (GETTEXT_PACKAGE \""+config.project_name+"\")\n");
					data_stream.put_string("set (RELEASE_NAME \""+config.project_name+"\")\n");
					data_stream.put_string("set (CMAKE_C_FLAGS \"\")\n");
					data_stream.put_string("set (PREFIX ${CMAKE_INSTALL_PREFIX})\n\n");
					if (dir!="") {
						data_stream.put_string("configure_file (${CMAKE_SOURCE_DIR}/"+dir+"/Config.vala.cmake ${CMAKE_BINARY_DIR}/"+dir+"/Config.vala)\n");
					} else {
						data_stream.put_string("configure_file (${CMAKE_SOURCE_DIR}/Config.vala.cmake ${CMAKE_BINARY_DIR}/Config.vala)\n");
					}
					data_stream.put_string("add_definitions(-DGETTEXT_PACKAGE=\\\"${GETTEXT_PACKAGE}\\\")\n");
					data_stream.put_string("find_package(PkgConfig)\n\n");
				}

				data_stream.put_string("set (VERSION \""+element.version+"\")\n");
				data_stream.put_string("pkg_check_modules(DEPS REQUIRED\n");
				foreach(var module in element.packages) {
					if (module.do_check) {
						data_stream.put_string("\t"+module.package+"\n");
					}
				}
				data_stream.put_string(")\n\n");

				data_stream.put_string("add_definitions(${DEPS_CFLAGS})\n");
				data_stream.put_string("link_libraries(${DEPS_LIBRARIES})\n");
				data_stream.put_string("link_directories(${DEPS_LIBRARY_DIRS})\n");
				data_stream.put_string("find_package(Vala REQUIRED)\n");
				data_stream.put_string("include(ValaVersion)\n");
				data_stream.put_string("ensure_vala_version(\""+this.config.vala_version+"\" MINIMUM)\n");
				data_stream.put_string("include(ValaPrecompile)\n\n");

				data_stream.put_string("vala_precompile(VALA_C "+lib_filename+"\n");

				foreach (var filename in element.sources) {
					data_stream.put_string("\t"+filename.source+"\n");
				}
				data_stream.put_string("PACKAGES\n");
				foreach(var module in element.packages) {
					data_stream.put_string("\t"+module.package+"\n");
				}

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
					data_stream.put_string("\tlib/\n");
					data_stream.put_string(")\n");

					// Install headers
					data_stream.put_string("install(FILES\n");
					data_stream.put_string("\t${CMAKE_CURRENT_BINARY_DIR}/"+lib_filename+".h\n");
					data_stream.put_string("DESTINATION\n");
					data_stream.put_string("\tinclude/"+this.config.project_name+"/\n");
					data_stream.put_string(")\n");

					// Install VAPI
					data_stream.put_string("install(FILES\n");
					data_stream.put_string("\t${CMAKE_CURRENT_BINARY_DIR}/"+lib_filename+".vapi\n");
					data_stream.put_string("DESTINATION\n");
					data_stream.put_string("\tshare/vala/vapi/\n");
					data_stream.put_string(")\n");

					// Install GIR
					if (gir_filename!="") {
						data_stream.put_string("install(FILES\n");
						data_stream.put_string("\t${CMAKE_CURRENT_BINARY_DIR}/"+gir_filename+"\n");
						data_stream.put_string("DESTINATION\n");
						data_stream.put_string("\tshare/gir-1.0/\n");
						data_stream.put_string(")\n");
					}
				} else {

					// Install executable
					data_stream.put_string("add_executable("+lib_filename+" ${VALA_C})\n\n");
					data_stream.put_string("install(TARGETS\n");
					data_stream.put_string("\t"+lib_filename+"\n");
					data_stream.put_string("RUNTIME DESTINATION\n");
					data_stream.put_string("\tbin/\n");
					data_stream.put_string(")\n\n");
				}
			} catch (Error e) {
				this.error_list+=_("Failed to write the CMakeLists file for binary %s\n").printf(lib_filename);
				return true;
			}
			return false;

		}
	}
}

