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

// project version=0.26

namespace AutoVala {

	public enum package_type {no_check, do_check, local}

	public class Configuration:GLib.Object {

		private Globals globalData = null;

		public string basepath; // Contains the full path where the configuration file is stored
		public string vala_version; // Minimun Vala version needed to compile this

		public int current_version; // Contains the version of the currently supported syntax
		public Gee.List<string> conditional_elements;


		private int version;
		private int lineNumber;

		private string current_condition;
		private bool condition_inverted;

		/**
		 * @param projectName The name for this project. Left blank if opening an existing project.
		 * @param init_gettext When called from an internal function, set it to false to avoid initializating gettext twice
		 */

		public Configuration(string projectName="",bool init_gettext=true) {
			if (init_gettext) {
				Intl.bindtextdomain(Constants.GETTEXT_PACKAGE, Path.build_filename(Constants.DATADIR,"locale"));
			}

			this.current_version=7; // currently we support version 7 of the syntax
			this.conditional_elements=new Gee.ArrayList<string>();
			this.version=0;

			this.globalData = new Globals(projectName);

			this.vala_version="0.16";
			this.reset_condition();
		}

		/**
		 * Shows all the errors ocurred until now
		 */
		public void showErrors() {

			var errorList = this.globalData.getErrorList();
			foreach(var e in errorList) {
				GLib.stdout.printf("%s\n".printf(e));
			}
			this.globalData.clearErrors();
		}

		/**
		 * Condition management methods
		 */
		private void reset_condition() {
			this.current_condition="";
			this.condition_inverted=false;
		}

		private void get_current_condition(out string? condition, out bool inverted) {
			if (this.current_condition=="") {
				condition=null;
				inverted=false;
			} else {
				condition=this.current_condition;
				inverted=this.condition_inverted;
			}
		}

		private bool add_condition(string condition) {
			if (this.current_condition!="") {
				this.globalData.addError(_("Nested IFs not allowed (line %d)").printf(this.lineNumber));
				return true;
			} else {
				this.current_condition=condition;
				this.condition_inverted=false;
				var new_condition=" "+(condition.replace("("," ").replace(")"," "))+" ";
				var list_conditions=new_condition.replace(" AND "," ").replace(" and "," ").replace(" And "," ").replace(" OR "," ").replace(" or "," ").replace(" Or "," ").replace(" NOT "," ").replace(" not "," ").replace(" Not "," ").split(" ");
				foreach(var l in list_conditions) {
					if (l=="") {
						continue;
					}
					if (this.conditional_elements.contains(l)) {
						continue;
					}
					this.conditional_elements.add(l);
				}
				return false;
			}
		}

		private bool remove_condition() {
			if (this.current_condition=="") {
				this.globalData.addError(_("Mismatched END (line %d)").printf(this.lineNumber));
				return true;
			} else {
				this.reset_condition();
				return false;
			}
		}

		private bool invert_condition() {
			if (this.current_condition=="") {
				this.globalData.addError(_("Mismatched ELSE (line %d)").printf(this.lineNumber));
				return true;
			} else {
				if (this.condition_inverted) {
					this.globalData.addError(_("Mismatched ELSE (line %d)").printf(this.lineNumber));
					return true;
				} else {
					this.condition_inverted=true;
					return false;
				}
			}
		}

		/**
		 * Reads the configuration file for a project.
		 *
		 * If no file/path is given, it will search from the current
		 * path upwards until it finds a file with .avprj (in lowercase) extension.
		 * 
		 * If the path of a file with .avprj extension is passed, it will try to open that file
		 *
		 * If another kind of file, or a path is given, it will search for a file with .avprj extension in that path (or in the path
		 * passed), and upwards. This allows to just pass the path to a file of a project, and it will automatically find the project
		 * configuration file.
		 *
		 * @param open_file The path where to start to search for a configuration file
		 *
		 * @return //false// if there was no error; //true// if there was an error. this.globalData.errorList will contain one or more strings with all
		 * the warnings and errors
		 */

		public bool readConfiguration() {

			this.reset_condition();

			var file=File.new_for_path(this.globalData.configFile);
			bool error=false;
			int ifLineNumber=0;
			try {
				var dis = new DataInputStream(file.read());

				this.lineNumber=0;
				string line;

				ElementBase element=null;

				while((line = dis.read_line(null))!=null) {
					string ?cond=null;
					bool invert=false;
					bool automatic=false;

					if (element!=null) {
						error|=element.configureLine(line,automatic,cond,invert,lineNumber);
						this.globalData.addElement(element);
						element=null;
					}

					this.lineNumber++;

					if ((line[0]=='#')||(line[0]==';')) { // it is a comment; forget it
						continue;
					}
					var finalline=line.strip();
					if (finalline=="") {
						continue;
					}
					if (line[0]=='*') { // it's an element added automatically, not by the user
						automatic=true;
						line=line.substring(1).strip();
					}

					this.get_current_condition(out cond,out invert);

					if (line.has_prefix("vala_package: ")) {
						continue;
					}
					if (line.has_prefix("vala_check_package: ")) {
						continue;
					}
					if (line.has_prefix("vala_local_package: ")) {
						continue;
					}
					if (line.has_prefix("vala_vapi: ")) {
						continue;
					}
					if (line.has_prefix("vala_source: ")) {
						continue;
					}
					if (line.has_prefix("custom: ")) {
						element = new ElementCustom();
						continue;
					}
					if (line.has_prefix("binary: ")) {
						element = new ElementBinary();
						continue;
					}
					if (line.has_prefix("icon: ")) {
						element = new ElementIcon();
						continue;
					}
					if (line.has_prefix("manpage: ")) {
						element = new ElementManPage();
						continue;
					}
					if (line.has_prefix("pixmap: ")) {
						element = new ElementPixmap();
						continue;
					}
					if (line.has_prefix("po: ")) {
						element = new ElementPo();
						continue;
					}
					if (line.has_prefix("doc: ")) {
						element = new ElementDoc();
						continue;
					}
					if (line.has_prefix("dbus_service: ")) {
						element = new ElementDBusService();
						continue;
					}
					if (line.has_prefix("desktop: ")) {
						element = new ElementDesktop();
						continue;
					}
					if (line.has_prefix("autostart: ")) {
						element = new ElementDesktop();
						continue;
					}
					if (line.has_prefix("eos_plug: ")) {
						element = new ElementEosPlug();
						continue;
					}
					if (line.has_prefix("scheme: ")) {
						element = new ElementScheme();
						continue;
					}
					if (line.has_prefix("glade: ")) {
						element = new ElementGlade();
						continue;
					}
					if (line.has_prefix("data: ")) {
						element = new ElementData();
						continue;
					}
					if (line.has_prefix("ignore: ")) {
						element = new ElementIgnore();
						continue;
					}
					if (line.has_prefix("if ")) {
						error|=this.add_condition(line.substring(3).strip());
						ifLineNumber=this.lineNumber;
						continue;
					}
					if (line.strip()=="else") {
						error|=this.invert_condition();
						continue;
					}
					if (line.strip()=="end") {
						error|=this.remove_condition();
						continue;
					}

					if (cond!=null) {
						error=true;
						this.globalData.addError(_("Conditionals are not supported in this statement (line %d)").printf(this.lineNumber));
						this.reset_condition();
					}

					if (line.has_prefix("vala_version: ")) {
						var version=line.substring(14).strip();
						if (false==this.check_version(version)) {
							this.globalData.addError(_("Vala version string not valid. It must be in the form N.N or N.N.N (line %d)").printf(this.lineNumber));
							error=true;
						} else {
							var version_elements=version.split(".");

							int f_major;
							int f_minor;

							f_major=int.parse(version_elements[0]);
							f_minor=int.parse(version_elements[1]);
							if ((f_major>this.globalData.valaMajor)||((f_major==this.globalData.valaMajor)&&(f_minor>this.globalData.valaMinor))) {
								this.globalData.configFile="";
								this.reset_condition();
								this.globalData.addError(_("This project needs Vala version %s or greater, but you have version %d.%d. Can't open it.").printf(version,this.globalData.valaMajor,this.globalData.valaMinor));
								error=true;
								break;
							}
							this.vala_version=version;
						}
						continue;
					}
					if (line.has_prefix("vala_binary: ")) {
						continue;
					}
					if (line.has_prefix("vala_library: ")) {
						continue;
					}
					if (line.has_prefix("version: ")) {
						continue;
					}
					if (line.has_prefix("namespace: ")) {
						continue;
					}
					if (line.has_prefix("include: ")) {
						element = new ElementInclude();
						continue;
					}
					if (line.has_prefix("compile_options: ")) {
						continue;
					}
					if (line.has_prefix("project_name: ")) {
						this.globalData.projectName=line.substring(14).strip();
						continue;
					}
					if (line.has_prefix("vala_destination: ")) {
						continue;
					}
					if (line.has_prefix("define: ")) {
						element = new ElementDefine();
						continue;
					}
					if (line.has_prefix("autovala_version: ")) {
						this.version=int.parse(line.substring(18).strip());
						if (this.version>this.current_version) {
							this.globalData.configFile="";
							this.reset_condition();
							this.globalData.addError(_("This project was created with a newer version of Autovala. Can't open it."));
							error=true;
							break;
						}
						continue;
					}
					error=true;
					this.globalData.addError(_("Syntax error in line %d").printf(this.lineNumber));
				}
			} catch (Error e) {
				this.globalData.configFile="";
				this.reset_condition();
				this.globalData.addError(_("Can't open configuration file"));
				error=true;
			}
			string ?condition;
			bool invert;
			this.get_current_condition(out condition,out invert);
			if (condition!=null) {
				this.globalData.addError(_("IF without END in line %d").printf(ifLineNumber));
				error=true;
			}
			return error;
		}


		private bool check_version(string version) {
			return Regex.match_simple("^[0-9]+.[0-9]+(.[0-9]+)?$",version);
		}

		/**
		 * Saves this configuration to the current filename, overwriting it if it already exists
		 *
		 * @param filename If a path and filename is given, the configuration will be stored there instead of in the current filename. The current filename is overwriten with this value
		 *
		 * @return //false// if there was no error, //true// if there was an error
		 */

		public bool saveConfiguration(string filename="") {

			if(this.globalData.projectName=="") {
				this.globalData.addError(_("Can't store the configuration. Project name not defined."));
				return true;
			}

			if((filename=="")&&(this.globalData.configFile=="")) {
				this.globalData.addError(_("Can't store the configuration. Path not defined."));
				return true;
			}
			if (filename!="") {
				if (GLib.Path.is_absolute(filename)) {
					this.globalData.configFile=filename;
				} else {
					this.globalData.configFile=GLib.Path.build_filename(GLib.Environment.get_current_dir(),filename);
				}
			}
			this.basepath=GLib.Path.get_dirname(this.globalData.configFile);
			var file=File.new_for_path(this.globalData.configFile);
			this.globalData.addError(_("Storing configuration in file %s").printf(this.globalData.configFile));
			if (file.query_exists()) {
				try {
					file.delete();
				} catch (Error e) {
					this.globalData.addError(_("Failed to delete the old config file %s").printf(this.globalData.configFile));
					return true;
				}
			}
			this.globalData.addError(_("Storing configuration in file %s").printf(this.globalData.configFile));
			//this.sort_configuration();
			try {
				var dis = file.create(FileCreateFlags.NONE);
				var data_stream = new DataOutputStream(dis);
				data_stream.put_string("### AutoVala Project ###\n");
				data_stream.put_string("autovala_version: %d\n".printf(this.current_version));
				data_stream.put_string("project_name: "+this.globalData.projectName+"\n");
				data_stream.put_string("vala_version: "+this.vala_version+"\n\n");
				this.storeData(ConfigType.IGNORE,data_stream);
				this.storeData(ConfigType.CUSTOM,data_stream);
				this.storeData(ConfigType.DEFINE,data_stream);
				this.storeData(ConfigType.VALA_BINARY,data_stream);
				this.storeData(ConfigType.VALA_LIBRARY,data_stream);
				this.storeData(ConfigType.PO,data_stream);
				this.storeData(ConfigType.DATA,data_stream);
				this.storeData(ConfigType.DOC,data_stream);
				this.storeData(ConfigType.BINARY,data_stream);
				this.storeData(ConfigType.DESKTOP,data_stream);
				this.storeData(ConfigType.AUTOSTART,data_stream);
				this.storeData(ConfigType.DBUS_SERVICE,data_stream);
				this.storeData(ConfigType.EOS_PLUG,data_stream);
				this.storeData(ConfigType.SCHEME,data_stream);
				this.storeData(ConfigType.GLADE,data_stream);
				this.storeData(ConfigType.ICON,data_stream);
				this.storeData(ConfigType.PIXMAP,data_stream);
				this.storeData(ConfigType.INCLUDE,data_stream);
				this.storeData(ConfigType.MANPAGE,data_stream);
			} catch (Error e) {
				this.globalData.addError(_("Can't create the config file %s").printf(this.globalData.configFile));
				return true;
			}
			return false;
		}
		private void storeData(ConfigType type, GLib.DataOutputStream dataStream) {
			foreach(var element in this.globalData.globalElements) {
				element.storeConfig(dataStream,type);
			}
		}
	}
}

