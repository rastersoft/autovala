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

namespace AutoVala {

	private class Configuration:GLib.Object {

		public Globals globalData = null;

		public string basepath; // Contains the full path where the configuration file is stored

		public int currentVersion; // Contains the version of the currently supported syntax

		private int version;
		private int lineNumber;

		private string currentCondition;
		private bool conditionInverted;

		/**
		 * @param projectName The name for this project. Left blank if opening an existing project.
		 * @param init_gettext When called from an internal function, set it to false to avoid initializating gettext twice
		 */

		public Configuration(string ?basePath,string projectName="",bool init_gettext=true) {

			if (init_gettext) {
				Intl.bindtextdomain(AutoValaConstants.GETTEXT_PACKAGE, Path.build_filename(AutoValaConstants.DATADIR,"locale"));
			}

			this.currentVersion=24; // currently we support version 24 of the syntax
			this.version=0;

			this.globalData = new AutoVala.Globals(projectName,basePath);

			this.globalData.valaVersionMajor=0;
			this.globalData.valaVersionMinor=16;
			this.resetCondition();
		}

		/**
		 * Shows all the errors ocurred until now
		 */
		public void showErrors() {

			var errorList = this.globalData.getErrorList();
			foreach(var e in errorList) {
				GLib.stderr.printf("%s\n".printf(e));
			}
			this.globalData.clearErrors();
		}

		/**
		 * Returns all the errors ocurred until now
		 */
		public string[] getErrors() {

			string[] retval = {};
			var errorList = this.globalData.getErrorList();
			foreach(var e in errorList) {
				retval += e;
			}
			this.globalData.clearErrors();
			return retval;
		}

		/**
		 * Removes all the non-automatic elements
		 */

		 public void clearAutomatic() {
			this.globalData.clearAutomatic();
		 }

		/**
		 * Condition management methods
		 */
		private void resetCondition() {
			this.currentCondition="";
			this.conditionInverted=false;
		}

		private void getCurrentCondition(out string? condition, out bool inverted) {
			if (this.currentCondition=="") {
				condition=null;
				inverted=false;
			} else {
				condition=this.currentCondition;
				inverted=this.conditionInverted;
			}
		}

		private bool addCondition(string? condition) {
			if (this.currentCondition!="") {
				this.globalData.addError(_("Nested IFs not allowed (line %d)").printf(this.lineNumber));
				return true;
			} else {
				this.currentCondition=condition;
				this.conditionInverted=false;
				var newCondition=" "+(condition.replace("("," ").replace(")"," "))+" ";
				var listConditions=newCondition.replace(" AND "," ").replace(" and "," ").replace(" And "," ").replace(" OR "," ").replace(" or "," ").replace(" Or "," ").replace(" NOT "," ").replace(" not "," ").replace(" Not "," ").split(" ");
				foreach(var l in listConditions) {
					if ((l!="")&&(l.ascii_casecmp("true")!=0)&&(l.ascii_casecmp("false")!=0)) {
						var define=new ElementDefine();
						define.addNewDefine(l);
					}
				}
				return false;
			}
		}

		private bool removeCondition() {
			if (this.currentCondition=="") {
				this.globalData.addError(_("Mismatched END (line %d)").printf(this.lineNumber));
				return true;
			} else {
				this.resetCondition();
				return false;
			}
		}

		private bool invertCondition() {
			if (this.currentCondition=="") {
				this.globalData.addError(_("Mismatched ELSE (line %d)").printf(this.lineNumber));
				return true;
			} else {
				if (this.conditionInverted) {
					this.globalData.addError(_("Mismatched ELSE (line %d)").printf(this.lineNumber));
					return true;
				} else {
					this.conditionInverted=true;
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
		 * @return //false// if there was no error; //true// if there was an error. this.globalData.errorList will contain one or more strings with all
		 * the warnings and errors
		 */

		public bool readConfiguration() {

			this.resetCondition();

			if (this.globalData.configFile == null) {
				return true;
			}

			var file=File.new_for_path(this.globalData.configFile);
			bool error=false;
			int ifLineNumber=0;
			try {
				var dis = new DataInputStream(file.read());

				this.lineNumber=0;
				string line;
				ElementBase element=null;
				bool automatic=false;

				string[] comments = {};

				while((line = dis.read_line(null))!=null) {
					string ?cond=null;
					bool invert=false;
					this.getCurrentCondition(out cond,out invert);

					this.lineNumber++;

					if (line[0]==';') { // it is a comment; forget it
						continue;
					}

					if (line[0]=='#') { // it is a comment; append it to the comment lis
						if (line.has_prefix("### AutoVala Project ###")) {
							continue; // don't add the header comment
						}
						comments += line.strip();
						continue;
					}
					var finalline=line.strip();
					if (finalline=="") {
						continue;
					}
					if (line[0]=='*') { // it's an element added automatically, not by the user
						automatic=true;
						line=line.substring(1).strip();
					} else {
						automatic=false;
					}

					if (line.has_prefix("external: ")) {
						element = new ElementExternal();
					} else if (line.has_prefix("vapidir: ")) {
						element = new ElementVapidir();
					} else if (line.has_prefix("translate: ")) {
						element = new ElementTranslation();
					} else if (line.has_prefix("gresource: ")) {
						element = new ElementGResource();
					} else if (line.has_prefix("custom: ")) {
						element = new ElementCustom();
					} else if (line.has_prefix("bash_completion: ")) {
						element = new ElementBashCompletion();
					} else if (line.has_prefix("binary: ")) {
						element = new ElementBinary();
					} else if ((line.has_prefix("icon: ")) || (line.has_prefix("full_icon: ")) || (line.has_prefix("fixed_size_icon: "))) {
						element = new ElementIcon();
					} else if (line.has_prefix("manpage: ")) {
						element = new ElementManPage();
					} else if (line.has_prefix("pixmap: ")) {
						element = new ElementPixmap();
					} else if (line.has_prefix("po: ")) {
						element = new ElementPo();
					} else if (line.has_prefix("doc: ")) {
						element = new ElementDoc();
					} else if (line.has_prefix("dbus_service: ")) {
						element = new ElementDBusService();
					} else if (line.has_prefix("desktop: ")) {
						element = new ElementDesktop();
					} else if (line.has_prefix("autostart: ")) {
						element = new ElementDesktop();
					} else if (line.has_prefix("eos_plug: ")) {
						element = new ElementEosPlug();
					} else if (line.has_prefix("scheme: ")) {
						element = new ElementScheme();
					} else if (line.has_prefix("glade: ")) {
						element = new ElementGlade();
					} else if (line.has_prefix("data: ")) {
						element = new ElementData();
					} else if (line.has_prefix("ignore: ")) {
						element = new ElementIgnore();
					} else if (line.has_prefix("source_dependency: ")) {
						element = new ElementSDepend();
					} else if (line.has_prefix("binary_dependency: ")) {
						element = new ElementBDepend();
					} else if (line.has_prefix("appdata: ")) {
						element = new ElementAppData();
					} else if ((line.has_prefix("vala_binary: "))||(line.has_prefix("vala_library: "))) {
						if (this.checkConditionals(cond)) {
							error=true;
							continue;
						}
						element = new ElementValaBinary();
					} else if (line.has_prefix("include: ")) {
						element = new ElementInclude();
					} else if (line.has_prefix("define: ")) {
						if (this.checkConditionals(cond)) {
							error=true;
							continue;
						}
						element = new ElementDefine();
					} else if (line.has_prefix("if ")) {
						error |= this.addCondition(line.substring(3).strip());
						ifLineNumber=this.lineNumber;
						continue;
					} else if (line.strip()=="else") {
						error|=this.invertCondition();
						continue;
					} else if (line.strip()=="end") {
						error|=this.removeCondition();
						continue;
					} else if (line.has_prefix("vala_version: ")) {
						if (this.checkConditionals(cond)) {
							this.globalData.addError(_("Vala version can't be conditional (line %d)").printf(this.lineNumber));
							error=true;
							continue;
						}
						var version=line.substring(14).strip();
						if (false==this.check_version(version)) {
							this.globalData.addError(_("Vala version string not valid. It must be in the form N.N or N.N.N (line %d)").printf(this.lineNumber));
							error=true;
						} else {
							var version_elements=version.split(".");

							int fMajor;
							int fMinor;

							fMajor=int.parse(version_elements[0]);
							fMinor=int.parse(version_elements[1]);
							if ((fMajor>this.globalData.valaMajor)||((fMajor==this.globalData.valaMajor)&&(fMinor>this.globalData.valaMinor))) {
								this.globalData.configFile="";
								this.resetCondition();
								this.globalData.addError(_("This project needs Vala version %s or greater, but you have version %d.%d. Can't open it.").printf(version,this.globalData.valaMajor,this.globalData.valaMinor));
								error=true;
								break;
							}
							this.globalData.valaVersionMajor=fMajor;
							this.globalData.valaVersionMinor=fMinor;
							this.globalData.versionAutomatic = automatic;
						}
						continue;
					} else if (line.has_prefix("project_name: ")) {
						if (this.checkConditionals(cond)) {
							error=true;
							continue;
						}
						this.globalData.projectName=line.substring(14).strip();
						continue;
					} else if (line.has_prefix("autovala_version: ")) {
						if (this.checkConditionals(cond)) {
							error=true;
							continue;
						}
						this.version=int.parse(line.substring(18).strip());
						if (this.version>this.currentVersion) {
							this.globalData.configFile="";
							this.resetCondition();
							this.globalData.addError(_("This project was created with a newer version of Autovala. Can't open it."));
							error=true;
							break;
						}
						continue;
					}
					error|=element.configureLine(line,automatic,cond,invert,lineNumber,comments);
					comments = {};
				}
			} catch (Error e) {
				this.globalData.configFile="";
				this.resetCondition();
				this.globalData.addError(_("Can't open configuration file"));
				error=true;
			}
			string ?condition;
			bool invert;
			this.getCurrentCondition(out condition,out invert);
			if (condition!=null) {
				this.globalData.addError(_("IF without END in line %d").printf(ifLineNumber));
				error=true;
			}
			return error;
		}

		private bool checkConditionals(string ?cond) {

			if (cond!=null) {
				this.globalData.addError(_("Conditionals are not supported in this statement (line %d)").printf(this.lineNumber));
				this.resetCondition();
				return true;
			}
			return false;
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
			if (file.query_exists()) {
				try {
					file.delete();
				} catch (Error e) {
					this.globalData.addError(_("Failed to delete the old config file %s").printf(this.globalData.configFile));
					return true;
				}
			}
			this.globalData.addMessage(_("Storing configuration in file %s").printf(this.globalData.configFile));
			this.globalData.sortElements();
			try {
				var dis = file.create(FileCreateFlags.NONE);
				var data_stream = new DataOutputStream(dis);
				data_stream.put_string("### AutoVala Project ###\n");
				data_stream.put_string("autovala_version: %d\n".printf(this.currentVersion));
				data_stream.put_string("project_name: %s\n".printf(this.globalData.projectName));
				if (this.globalData.versionAutomatic) {
					data_stream.put_string("*vala_version: %d.%d\n\n".printf(this.globalData.valaMajor,this.globalData.valaMinor));
				} else {
					data_stream.put_string("vala_version: %d.%d\n\n".printf(this.globalData.valaVersionMajor,this.globalData.valaVersionMinor));
				}
				this.storeData(ConfigType.IGNORE,data_stream);
				this.storeData(ConfigType.CUSTOM,data_stream);
				this.storeData(ConfigType.DEFINE,data_stream);
				this.storeData(ConfigType.GRESOURCE,data_stream);
				this.storeData(ConfigType.VAPIDIR,data_stream);
				this.storeData(ConfigType.VALA_BINARY,data_stream);
				this.storeData(ConfigType.VALA_LIBRARY,data_stream);
				this.storeData(ConfigType.PO,data_stream);
				this.storeData(ConfigType.TRANSLATION,data_stream);
				this.storeData(ConfigType.DATA,data_stream);
				this.storeData(ConfigType.APPDATA,data_stream);
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
				this.storeData(ConfigType.BASH_COMPLETION,data_stream);
				this.storeData(ConfigType.SOURCE_DEPENDENCY,data_stream);
				this.storeData(ConfigType.BINARY_DEPENDENCY,data_stream);
				this.storeData(ConfigType.EXTERNAL,data_stream);
			} catch (Error e) {
				this.globalData.addError(_("Can't create the config file %s").printf(this.globalData.configFile));
				return true;
			}
			return false;
		}
		private void storeData(ConfigType type, GLib.DataOutputStream dataStream) {

			bool printed = false;
			var printConditions = new ConditionalText(dataStream,false);
			foreach(var element in this.globalData.globalElements) {
				if (element.eType == type) {
					printConditions.printCondition(element.condition,element.invertCondition);
					if (element.comments != null) {
						foreach(var comment in element.comments) {
							dataStream.put_string("%s\n".printf(comment));
						}
					}
					element.storeConfig(dataStream,printConditions);
					printed = true;
				}
			}
			printConditions.printTail();
			if (printed) {
				try {
					dataStream.put_string("\n");
				} catch (Error e) {
					this.globalData.addError(_("Error while storing the data"));
				}
			}
		}
	}
}

