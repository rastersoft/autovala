/*
 Copyright 2013 (C) Raster Software Vigo (Sergio Costas)

 This file is part of AutoVala

 AutoVala is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 3 of the License, or
 (at your option) any later version.

 AutoVala is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program. If not, see <http://www.gnu.org/licenses/>. */

using GLib;

namespace AutoVala {

	public enum packageType {NO_CHECK, DO_CHECK, C_DO_CHECK, LOCAL}

	public class GenericElement:GLib.Object {
		public string elementName;
		public string? condition;
		public bool invertCondition;
		public bool automatic;
		public string[]? comments = null;
	}

	public class AliasElement:GenericElement {

		public AliasElement(string alias, bool automatic, string? condition, bool inverted) {
			this.elementName = alias;
			this.automatic = automatic;
			this.condition = condition;
			this.invertCondition = inverted;
		}
	}

	public class PackageElement:GenericElement {

		public packageType type;

		public PackageElement(string package, packageType type, bool automatic, string? condition, bool inverted) {
			this.elementName = package;
			this.type = type;
			this.automatic = automatic;
			this.condition = condition;
			this.invertCondition = inverted;
		}
	}

	public class SourceElement:GenericElement {

		public SourceElement(string source, bool automatic, string? condition, bool inverted) {
			this.elementName = source;
			this.automatic = automatic;
			this.condition = condition;
			this.invertCondition = inverted;
		}
	}

	public class VapiElement:GenericElement {

		public VapiElement(string vapi, bool automatic, string? condition, bool inverted) {
			this.elementName = vapi;
			this.automatic = automatic;
			this.condition = condition;
			this.invertCondition = inverted;
		}
	}

	public class CompileElement:GenericElement {
		public CompileElement(string options, bool automatic, string? condition, bool inverted) {
			this.elementName = options;
			this.automatic = automatic;
			this.condition = condition;
			this.invertCondition = inverted;
		}
	}

	public class LibraryElement:GenericElement {
		public LibraryElement(string libraries, bool automatic, string? condition, bool inverted) {
			this.elementName = libraries;
			this.automatic = automatic;
			this.condition = condition;
			this.invertCondition = inverted;
		}
	}

	public class DestinationElement:GenericElement {
		public DestinationElement(string destination, bool automatic, string? condition, bool inverted) {
			this.elementName = destination;
			this.automatic = automatic;
			this.condition = condition;
			this.invertCondition = inverted;
		}
	}

	public class ResourceElement:GenericElement {
		public ResourceElement(string resource, bool automatic, string? condition, bool inverted) {
			this.elementName = resource;
			this.automatic = automatic;
			this.condition = condition;
			this.invertCondition = inverted;
		}
	}

	public class DBusElement:GenericElement {

		public string obj;
		public bool systemBus;
		public bool GDBus;

		public DBusElement(string destination, string obj, bool systemBus, bool GDBus, bool automatic) {
			this.elementName = destination;
			this.obj = obj;
			this.systemBus = systemBus;
			this.automatic = automatic;
			this.condition = null;
			this.invertCondition = false;
			this.GDBus = GDBus;
		}
	}

	private class ElementValaBinary : ElementBase {

		public string version;
		private bool versionSet;
		private bool versionAutomatic;

		private bool has_dependencies;

		private Gee.HashSet<string>? _meson_arrays;

		private Gee.List<ResourceElement ?> _resources;
		public Gee.List<ResourceElement ?> resources {
			get {return this._resources;}
		}
		private Gee.List<AliasElement ?> _aliases;
		public Gee.List<AliasElement ?> aliases {
			get {return this._aliases;}
		}
		private Gee.List<PackageElement ?> _packages;
		public Gee.List<PackageElement ?> packages {
			get {return this._packages;}
		}
		private Gee.List<SourceElement ?> _sources;
		public Gee.List<SourceElement ?> sources {
			get {return this._sources;}
		}
		private Gee.List<SourceElement ?> _cSources;
		public Gee.List<SourceElement ?> cSources {
			get {return this._cSources;}
		}
		private Gee.List<SourceElement ?> _hFolders;
		public Gee.List<SourceElement ?> hFolders {
			get {return this._hFolders;}
		}
		private Gee.List<SourceElement ?> _unitests;
		public Gee.List<SourceElement ?> unitests {
			get {return this._unitests;}
		}
		private Gee.List<VapiElement ?> _vapis;
		public Gee.List<VapiElement ?> vapis {
			get {return this._vapis;}
		}
		private Gee.List<CompileElement ?> _compileOptions;
		private Gee.List<CompileElement ?> _compileCOptions;

		private Gee.List<DBusElement ?> _dbusElements;

		private Gee.List<string> usingList;
		private Gee.List<string> defines;
		private Gee.List<string> namespaces;

		private Gee.List<LibraryElement ?> _link_libraries;
		public Gee.List<LibraryElement ?> link_libraries {
			get {return this._link_libraries;}
		}

		private string? _currentNamespace;
		public string ? currentNamespace {
			get {return this._currentNamespace;}
		}
		private bool namespaceAutomatic;

		private Gee.List<DestinationElement ?> _destination;
		public Gee.List<DestinationElement ?> destination {
			get {return this._destination;}
		}

		private static bool addedValaBinaries;
		private static bool addedLibraryWarning;
		private static int counter;

		private GLib.Regex regexVersion;
		private GLib.Regex regexPackages;
		private GLib.Regex regexPackages2;
		private GLib.Regex regexClasses;

		public string get_vala_opts() {

			string opts = "";
			foreach(var element in this._compileOptions) {
				if (opts != "") {
					opts += " ";
				}
				opts+=element.elementName;
			}
			return opts;
		}

		public string get_c_opts() {

			string opts = "";
			foreach(var element in this._compileCOptions) {
				if (opts != "") {
					opts += " ";
				}
				opts+=element.elementName;
			}
			return opts;
		}

		public string get_libraries() {

			string libs = "";
			foreach(var element in this._link_libraries) {
				if (element.automatic==true) {
					continue; // don't put the automatically added ones
				}
				if (libs != "") {
					libs += " ";
				}
				libs+=element.elementName;
			}
			return libs;
		}

		public void set_name(string new_name) {
			if ((this._name != new_name) && (this._automatic==true)) {
				this.transformToNonAutomatic(false);
			}
			this._name = new_name;
		}

		public void set_type(bool set_as_library) {
			if (set_as_library) {
				if ((this._type == ConfigType.VALA_BINARY) && (this._automatic==true)) {
					this.transformToNonAutomatic(false);
				}
				this._type = ConfigType.VALA_LIBRARY;
			} else {
				if ((this._type == ConfigType.VALA_LIBRARY) && (this._automatic==true)) {
					this.transformToNonAutomatic(false);
				}
				this._type = ConfigType.VALA_BINARY;
			}
		}

		public void set_path(string new_path) {
			if (((this._path != new_path) || (this._fullPath != new_path)) && (this._automatic==true)) {
				this.transformToNonAutomatic(false);
			}

			this._path = new_path;
			this._fullPath = new_path;
		}

		public ElementValaBinary() {
			this._meson_arrays = null;
			this.command = "";
			if (ElementBase.globalData.global_version == null) {
				this.version = "1.0.0";
			} else {
				this.version = ElementBase.globalData.global_version;
			}
			this.versionSet = false;
			this.versionAutomatic = true;
			this._currentNamespace = null;
			this.usingList = null;
			this.defines = null;
			this.namespaceAutomatic = true;
			this.namespaces = null;
			this._aliases=new Gee.ArrayList<AliasElement ?>();
			this._packages=new Gee.ArrayList<PackageElement ?>();
			this._resources=new Gee.ArrayList<ResourceElement ?>();
			this._sources=new Gee.ArrayList<SourceElement ?>();
			this._cSources=new Gee.ArrayList<SourceElement ?>();
			this._hFolders=new Gee.ArrayList<SourceElement ?>();
			this._unitests=new Gee.ArrayList<SourceElement ?>();
			this._vapis=new Gee.ArrayList<VapiElement ?>();
			this._compileOptions=new Gee.ArrayList<CompileElement ?>();
			this._compileCOptions=new Gee.ArrayList<CompileElement ?>();
			this._dbusElements=new Gee.ArrayList<DBusElement ?>();
			this._link_libraries=new Gee.ArrayList<LibraryElement ?>();
			this._destination=new Gee.ArrayList<DestinationElement ?>();
			ElementValaBinary.addedValaBinaries = false;
			ElementValaBinary.addedLibraryWarning = false;
			ElementValaBinary.counter = 1;
			try {
				this.regexVersion = new GLib.Regex("^[ \t]*// *project +version *= *[0-9]+.[0-9]+(.[0-9]+)?;?$");
				this.regexPackages = new GLib.Regex("^([ \t]*// *)?[Uu]sing +[^;]+;?");
				this.regexPackages2 = new GLib.Regex("^([ \t]*// *)?uses +[a-zA-Z_][a-zA-Z0-9_, -]+ *$");
				this.regexClasses = new GLib.Regex("^[ \t]*(public )?(private )?[ \t]*class[ ]+");
			} catch (GLib.Error e) {
				ElementBase.globalData.addError(_("Can't generate the Regexps"));
			}
		}

		private void add_library(string library) {

			foreach (var element in this._link_libraries) {
				var libs = element.elementName.split(" ");
				foreach (var lib in libs) {
					if (lib == "") {
						continue;
					}
					if (lib == library) {
						return; // that library already exists
					}
				}
			}
			this.setCLibrary(library, true, null, false, 0,null);
		}

		public static bool autoGenerate() {

			bool error=false;
			ElementBase.globalData.generateExtraData();
			if (false==ElementBase.globalData.checkExclude("src")) {
				var filePath = File.new_for_path(Path.build_filename(ElementBase.globalData.projectFolder,"src"));

				if (filePath.query_exists()) {
					var generatedElement = new ElementValaBinary();
					error|=generatedElement.autoConfigure("src/"+ElementBase.globalData.projectName);
				}
			}

			foreach(var element in ElementBase.globalData.globalElements) {
				if ((element.eType==ConfigType.VALA_BINARY)||(element.eType==ConfigType.VALA_LIBRARY)) {
					var elementBinary = element as ElementValaBinary;
					elementBinary.checkVAPIs();
					error |= elementBinary.checkDependencies();
				}
			}

			return error;
		}

		public override bool autoConfigure(string? path=null) {

			bool error = false;
			if (path != null) {
				this._type = ConfigType.VALA_BINARY;
				error |= this.configureElement(GLib.Path.get_dirname(path),
							GLib.Path.get_dirname(path),GLib.Path.get_basename(path),true,null,false);
				if (error) {
					return true;
				}
			}

			this.usingList = new Gee.ArrayList<string>();
			this.defines = new Gee.ArrayList<string>();
			this.namespaces = new Gee.ArrayList<string>();

			this.usingList.add("GLib"); // GLib is always needed

			foreach(var element in this._packages) {
				if (element.type!=packageType.LOCAL) {
					continue;
				}
				if (this.usingList.contains(element.elementName)==false) {
					this.usingList.add(element.elementName);
				}
			}

			// Don't add automatically the files inside dbus_generated, because they are
			// automatically (re)generated
			var dbusFolder = Path.build_filename(this._fullPath,"dbus_generated");
			ElementBase.globalData.addExclude(dbusFolder);

			// Check if there are unitary tests
			var unitestsCompleteFolder=Path.build_filename(ElementBase.globalData.projectFolder,this._fullPath,"unitests");
			var unitestsAccess = File.new_for_path(unitestsCompleteFolder);
			if (unitestsAccess.query_exists()) {
				var unitestsFolder=Path.build_filename(this._path,"unitests");
				var files = ElementBase.getFilesFromFolder(unitestsFolder,{".vala",".gs"},true,true,"unitests");
				foreach (var element in files) {
					error |= this.addUnitest(element,true,null,false,-1,null);
					error |= this.processSource(element);
				}
				var unitestsFullFolder=Path.build_filename(this._fullPath,"unitests");
				ElementBase.globalData.addExclude(unitestsFullFolder);
			}

			var files = ElementBase.getFilesFromFolder(this._path,{".vala",".gs"},true,true);
			foreach (var element in files) {
				error |= this.addSource(element,true,null,false,-1,null);
				error |= this.processSource(element);
			}

			files = ElementBase.getFilesFromFolder(this._path,{".c"},true,true);
			foreach (var element in files) {
				error |= this.addCSource(element,true,null,false,-1,null);
			}

			files = ElementBase.getFilesFromFolder(this._path,{".h"},true,true);
			foreach (var element in files) {
				error |= this.addHFolder(GLib.Path.get_dirname(element),true,null,false,-1,null);
			}

			ElementBase.globalData.addExclude(this._path);
			return error;
		}

		private void remove_self_package() {

			var tmpPackages = new Gee.ArrayList<PackageElement ?>();
			foreach(var element in this._packages) {
				if (element.elementName != this._currentNamespace) {
					tmpPackages.add(element);
				}
			}
			this._packages = tmpPackages;
		}

		public override void add_files() {

			this.file_list = ElementBase.getFilesFromFolder(this._path,{".vala",".vapi",".gs",".c",".h",".pc",".deps",".cmake",".base"},true);
			var files = ElementBase.getFilesFromFolder(GLib.Path.build_filename(this._path,"dbus_generated"),{".vala"},true);
			foreach (var element in files) {
				this.file_list+= element;
			}
		}

		private bool checkVAPIs() {

			var vapisPath=GLib.Path.build_filename(this._path,"vapis");
			if(ElementBase.globalData.checkExclude(vapisPath)) {
				return false;
			}

			var fullPath = File.new_for_path(Path.build_filename(ElementBase.globalData.projectFolder,vapisPath));
			if (fullPath.query_exists()==false) {
				return false; // there's no VAPIS folder
			}
			var files = ElementBase.getFilesFromFolder(vapisPath,{".vapi"},true,true);
			bool error=false;
			foreach (var element in files) {
				error |= this.addVapi(GLib.Path.build_filename("vapis",element),true,null,false,-1,null);
			}
			ElementBase.globalData.addExclude(vapisPath);
			return error;
		}

		private bool checkDependencies() {

			// Check which dependencies are resolved by local libraries
			foreach(var element in ElementBase.globalData.localModules.keys) {
				if (this.usingList.contains(element)) {
					this.usingList.remove(element);
				}
			}

			// Check which dependencies are resolved by local VAPIs
			ReadVapis spaceVapis;
			try {
				spaceVapis = new ReadVapis(0,0,true);
			} catch (GLib.Error e) {
				return true;
			}
			// Fill the namespaces defined in the VAPIs for this binary
			foreach(var element in this._vapis) {
				var fullPath = Path.build_filename(ElementBase.globalData.projectFolder,this._path,element.elementName);
				spaceVapis.checkVapiFile(fullPath,fullPath);
			}
			foreach(var element in spaceVapis.getNamespaces()) {
				if (this.usingList.contains(element)) {
					this.usingList.remove(element);
				}
			}

			// Check which dependencies are already resolved by manually added packages
			foreach(var element in this._packages) {
				var namespaces = Globals.vapiList.getNamespaceFromPackage(element.elementName);
				foreach (var namespaceP in namespaces) {
					if ((namespaceP!=null)&&(this.usingList.contains(namespaceP))) {
						this.usingList.remove(namespaceP);
					}
				}
			}

			// Finally, add the dependencies not resolved yet
			foreach(var element in Globals.vapiList.getNamespaces()) {
				if (this.usingList.contains(element)) {
					bool isCheckable=false;
					this.usingList.remove(element);
					var filename = Globals.vapiList.getPackageFromNamespace(element, out isCheckable);
					this.addPackage(filename,isCheckable ? packageType.DO_CHECK : packageType.NO_CHECK, true, null, false, -1,null);
					var dependencies = Globals.vapiList.getDependenciesFromPackage(filename);
					if (dependencies!=null) {
						foreach (var dep in dependencies) {
							this.addPackage(dep,packageType.DO_CHECK, true, null, false, -1,null);
						}
					}
				}
			}

			// If there are dependencies not resolved, show a warning message for each one
			foreach(var element in this.usingList) {
				if (this.namespaces.index_of(element) != -1) {
					continue;
				}
				ElementBase.globalData.addWarning(_("Can't resolve Using %s").printf(element));
			}
			return false;
		}

		// Read a source file and extract all the data about it, like packages, program version, namespaces...
		private bool processSource(string pathP) {

			string line;
			string? version=null;
			int lineCounter=0;
			string regexString;
			MatchInfo regexMatch;
			bool isGenie;

			isGenie = pathP.has_suffix(".gs");
			string path = GLib.Path.build_filename(ElementBase.globalData.projectFolder,this._path,pathP);
			try {
				var file=File.new_for_path(path);
				var dis = new DataInputStream (file.read ());
				bool added_math = false;

				while ((line = dis.read_line (null)) != null) {
					if (version!=null) {
						if ((this.versionSet) && (version != this.version)) {
							ElementBase.globalData.addWarning(_("File %s is overwritting the version number (line %d)").printf(pathP,lineCounter));
						} else {
							this.version = version;
							this.versionSet = true;
						}
						version=null;
					}
					lineCounter++;
					line=line.strip();
					 // add the version (old, deprecated format)
					if (line.has_prefix("const string project_version=\"")) {
						ElementBase.globalData.addWarning(_("The contruction 'const string project_version=...' in file %s is deprecated. Replace it with '// project version=...'").printf(pathP));
						var pos=line.index_of("\"",30);
						if (pos!=-1) {
							this.version = line.substring(30,pos-30);
						}
						continue;
					}
					// add the version
					if (this.regexVersion.match(line,0, out regexMatch)) {
						regexString = regexMatch.fetch(0);
						var pos = regexString.index_of("=");
						var pos2 = regexString.index_of(";");
						if (pos2==-1) {
							pos2 = regexString.length;
						}
						version=regexString.substring(pos+1,pos2-pos-1).strip();
						continue;
					}
					// add the packages used by this source file ("using" statement)

					bool retval;
					if (isGenie) {
						retval = this.regexPackages2.match(line,0, out regexMatch);
					} else {
						retval = this.regexPackages.match(line,0, out regexMatch);
					}

					if (retval) {
						regexString = regexMatch.fetch(0).strip();
						int pos;
						int pos2;
						if (isGenie) {
							pos = -1;
							pos2 = 5 + regexString.index_of("uses ");
						} else {
							pos = regexString.index_of(";");
							pos2 = 2 + regexString.index_of("g ");
						}
						if (pos == -1) {
							pos = regexString.length; // allow to put //using without a ; at the end, but also accept with it
						}
						var namespacesFound=regexString.substring(pos2,pos-pos2).split(",");
						foreach(var namespaceFound_tmp in namespacesFound) {
							var namespaceFound = namespaceFound_tmp.strip();
							if ((namespaceFound == "Math") || (namespaceFound == "GLib.Math")) {
								if (added_math == false) {
									added_math = true;
									this.add_library("m");
								}
								continue;
							}
							if (this.usingList.contains(namespaceFound)==false) {
								this.usingList.add(namespaceFound);
							}
						}
						continue;
					}
					// Check if this source file uses classes, to add the gobject package
					if (this.regexClasses.match(line,0, out regexMatch)) {
						if (this.usingList.contains("GObject")==false) {
							this.usingList.add("GObject");
						}
					}
					/* Check for these words to automatically add the gio package.
					 * Of course, this is NOT an exhaustive list, just the most common, to simplify the use.
					 * In case of needing the Gio package, and not using any of these words in your source, just
					 * add "//using GIO" */
					if ((-1!=line.index_of("FileInfo"))||(-1!=line.index_of("FileType"))||
								(-1!=line.index_of("FileEnumerator"))||(-1!=line.index_of("GLib.File"))||
								(-1!=line.index_of("DataInputStream"))||(-1!=line.index_of("DataOutputStream"))||
								(-1!=line.index_of("FileInputStream"))||(-1!=line.index_of("FileOutputStream"))||
								(-1!=line.index_of("DBus"))||(-1!=line.index_of("Socket"))||
								(-1!=line.index_of("stdout."))||(-1!=line.index_of("stdin."))
								) {
						if (this.usingList.contains("GIO") == false) {
							this.usingList.add("GIO");
						}
					}

					if (line.has_prefix("namespace ")) {
						var pos=line.index_of("{");
						if (pos==-1) {
							pos=line.length;
						}
						var namespaceFound=line.substring(10,pos-10).strip();

						var topNamespaceFound = namespaceFound.split(".")[0];
						if ((this.currentNamespace!=null)&&(this.currentNamespace!=topNamespaceFound)) {
							ElementBase.globalData.addWarning(_("File %s is overwritting the namespace (line %d)").printf(pathP,lineCounter));
							continue;
						}
						this._currentNamespace=topNamespaceFound;
						if (this.namespaces.index_of(namespaceFound) == -1) {
							this.namespaces.add(namespaceFound);
						}
						continue;
					}
					if ((line.has_prefix("#if ")) || (line.has_prefix("#elif "))) { // Add #defines
						var pos=line.index_of(" ");
						string element=line.substring(pos).strip();
						// remove all logical elements to get a set of DEFINEs
						string[] elements=element.replace("&&"," ").replace("||"," ").replace("=="," ").replace("!="," ").replace("!"," ").replace("("," ").replace(")"," ").split(" ");
						foreach(var l in elements) {
							if ((l!="") && (l.ascii_casecmp("true")!=0) && (l.ascii_casecmp("false")!=0) && (this.defines.contains(l)==false) && (l.ascii_casecmp("UNITEST")!=0)) {
								var define=new ElementDefine();
								define.addNewDefine(l);
							}
						}
					}
				}
			} catch (GLib.Error e) {
				ElementBase.globalData.addError(_("Can't open for read the file %s").printf(pathP));
				return true;
			}
			return false;
		}

		public override void clearAutomatic() {

			if ((this.versionSet) && (this.versionAutomatic)) {
				if (ElementBase.globalData.global_version == null) {
					this.version = "1.0.0";
				} else {
					this.version = ElementBase.globalData.global_version;
				}
				this.versionSet = false;
				this.versionAutomatic = true;
			}
			if ((this._currentNamespace!=null)&&(this.namespaceAutomatic)) {
				this._currentNamespace=null;
				this.namespaceAutomatic=true;
			}
			var aliasesTmp = new Gee.ArrayList<AliasElement ?>();
			var packagesTmp = new Gee.ArrayList<PackageElement ?>();
			var sourcesTmp = new Gee.ArrayList<SourceElement ?>();
			var unitestsTmp = new Gee.ArrayList<SourceElement ?>();
			var cSourcesTmp = new Gee.ArrayList<SourceElement ?>();
			var hFoldersTmp = new Gee.ArrayList<SourceElement ?>();
			var vapisTmp = new Gee.ArrayList<VapiElement ?>();
			var compileTmp = new Gee.ArrayList<CompileElement ?>();
			var dbusTmp = new Gee.ArrayList<DBusElement ?>();
			var librariesTmp = new Gee.ArrayList<LibraryElement ?>();

			foreach (var e in this._aliases) {
				if (e.automatic==false) {
					aliasesTmp.add(e);
				}
			}
			foreach (var e in this._packages) {
				if (e.automatic==false) {
					packagesTmp.add(e);
				}
			}
			foreach (var e in this._sources) {
				if (e.automatic==false) {
					sourcesTmp.add(e);
				}
			}
			foreach (var e in this._unitests) {
				if (e.automatic==false) {
					unitestsTmp.add(e);
				}
			}
			foreach (var e in this._cSources) {
				if (e.automatic==false) {
					cSourcesTmp.add(e);
				}
			}
			foreach (var e in this._hFolders) {
				if (e.automatic==false) {
					hFoldersTmp.add(e);
				}
			}
			foreach (var e in this._vapis) {
				if (e.automatic==false) {
					vapisTmp.add(e);
				}
			}
			foreach (var e in this._compileOptions) {
				if (e.automatic==false) {
					compileTmp.add(e);
				}
			}
			foreach (var e in this._dbusElements) {
				if (e.automatic==false) {
					dbusTmp.add(e);
				}
			}
			foreach (var e in this._link_libraries) {
				if (e.automatic==false) {
					librariesTmp.add(e);
				}
			}
			this._aliases = aliasesTmp;
			this._packages = packagesTmp;
			this._sources = sourcesTmp;
			this._unitests = unitestsTmp;
			this._cSources = cSourcesTmp;
			this._hFolders = hFoldersTmp;
			this._vapis = vapisTmp;
			this._compileOptions = compileTmp;
			this._dbusElements = dbusTmp;
			this._link_libraries = librariesTmp;
		}

		public static int comparePackages (GenericElement? a, GenericElement? b) {
			if (a.automatic!=b.automatic) {
				return (a.automatic ? 1 : -1); // put the manual ones first
			}
			if ((a.condition==null)&&(b.condition==null)) {
				return Posix.strcmp(a.elementName,b.elementName);
			}
			if (a.condition==null) {
				return -1;
			}
			if (b.condition==null) {
				return 1;
			}
			if (a.condition==b.condition) {
				if (a.invertCondition==b.invertCondition) {
					return Posix.strcmp(a.elementName,b.elementName); // both are equal; sort alphabetically
				} else {
					return a.invertCondition ? 1 : -1; // the one with the condition not inverted goes first
				}
			}
			return (Posix.strcmp(a.condition,b.condition));
		}

		public override void sortElements() {
			this._packages.sort(AutoVala.ElementValaBinary.comparePackages);
			this._sources.sort(AutoVala.ElementValaBinary.comparePackages);
			this._cSources.sort(AutoVala.ElementValaBinary.comparePackages);
			this._hFolders.sort(AutoVala.ElementValaBinary.comparePackages);
			this._unitests.sort(AutoVala.ElementValaBinary.comparePackages);
			this._vapis.sort(AutoVala.ElementValaBinary.comparePackages);
			this._compileOptions.sort(AutoVala.ElementValaBinary.comparePackages);
			this._dbusElements.sort(AutoVala.ElementValaBinary.comparePackages);
			this._resources.sort(AutoVala.ElementValaBinary.comparePackages);
		}

		private void transformToNonAutomatic(bool automatic) {
			if (automatic) {
				return;
			}
			this._automatic=false;
		}

		private bool checkVersion(string version) {
			return Regex.match_simple("^[0-9]+.[0-9]+(.[0-9]+)?$",version);
		}

		private bool setVersion(string version, bool automatic, int lineNumber) {

			if (this.checkVersion(version)) {
				this.version = version;
				this.versionSet = true;
				if (!automatic) {
					this.versionAutomatic=false;
				}
				this.transformToNonAutomatic(automatic);
				return false;
			} else {
				ElementBase.globalData.addError(_("Syntax error in VERSION statement (line %d)").printf(lineNumber));
				return true;
			}
		}

		private bool setNamespace(string namespaceT, bool automatic, int lineNumber) {
			if (this._currentNamespace==null) {
				this._currentNamespace=namespaceT;
				if (!automatic) {
					this.namespaceAutomatic=false;
				}
			} else {
				ElementBase.globalData.addWarning(_("Ignoring duplicated NAMESPACE command (line %d)").printf(lineNumber));
			}
			return false;
		}

		public bool setCLibrary(string libraries, bool automatic, string? condition, bool invertCondition, int lineNumber, string[]? comments, bool erase_all=false) {

			if (erase_all) {
				// remove the manually added libraries
				var librariesTmp=new Gee.ArrayList<LibraryElement ?>();
				foreach (var e in this._link_libraries) {
					if (e.automatic==true) {
						librariesTmp.add(e);
					}
				}
				this._link_libraries = librariesTmp;
			}

			if (libraries == "") {
				return false;
			}

			// if it is conditional, it MUST be manual, because conditions are not added automatically
			if (condition!=null) {
				automatic=false;
			}

			// adding a non-automatic library to an automatic binary transforms this binary to non-automatic
			if ((automatic==false)&&(this._automatic==true)) {
				this.transformToNonAutomatic(false);
			}

			var element=new LibraryElement(libraries,automatic,condition,invertCondition);
			element.comments = comments;
			this._link_libraries.add(element);

			return false;
		}

		public bool setCompileOptions(string options, bool automatic, string? condition, bool invertCondition, int lineNumber, string[]? comments, bool erase_all=false) {

			if (erase_all) {
				this._compileOptions = new Gee.ArrayList<CompileElement ?>();
			}

			if (options == "") {
				return false;
			}

			// if it is conditional, it MUST be manual, because conditions are not added automatically
			if (condition!=null) {
				automatic=false;
			}

			// adding a non-automatic option to an automatic binary transforms this binary to non-automatic
			if ((automatic==false)&&(this._automatic==true)) {
				this.transformToNonAutomatic(false);
			}

			var element=new CompileElement(options,automatic,condition,invertCondition);
			element.comments = comments;
			this._compileOptions.add(element);

			return false;
		}

		public bool setCompileCOptions(string options, bool automatic, string? condition, bool invertCondition, int lineNumber, string[]? comments, bool erase_all=false) {

			if (erase_all) {
				this._compileCOptions = new Gee.ArrayList<CompileElement ?>();
			}

			if (options == "") {
				return false;
			}

			// if it is conditional, it MUST be manual, because conditions are not added automatically
			if (condition!=null) {
				automatic=false;
			}

			// adding a non-automatic option to an automatic binary transforms this binary to non-automatic
			if ((automatic==false)&&(this._automatic==true)) {
				this.transformToNonAutomatic(false);
			}

			var element=new CompileElement(options,automatic,condition,invertCondition);
			element.comments = comments;
			this._compileCOptions.add(element);

			return false;
		}

		private bool addAlias(string alias, bool automatic, string? condition, bool invertCondition, int lineNumber, string[]? comments) {

			automatic = false; // aliases are always manual

			// adding a non-automatic destination to an automatic binary transforms this binary to non-automatic
			if ((automatic == false) && (this._automatic == true)) {
				this.transformToNonAutomatic(false);
			}

			foreach(var element in this._aliases) {
				if (element.elementName == alias) {
					return false;
				}
			}

			var element = new AliasElement(alias, automatic, condition, invertCondition);
			element.comments = comments;
			this._aliases.add(element);
			return false;
		}


		private bool setDestination(string destination, bool automatic, string? condition, bool invertCondition, int lineNumber, string[]? comments) {

			if (condition!= null) {
				automatic = false;
			}

			// adding a non-automatic destination to an automatic binary transforms this binary to non-automatic
			if ((automatic==false)&&(this._automatic==true)) {
				this.transformToNonAutomatic(false);
			}

			foreach(var element in this._destination) {
				if ((element.elementName==destination) && (automatic==true)) {
					return false;
				}
				if ((element.elementName==destination) && (element.condition==condition) && (element.invertCondition == invertCondition)) {
					ElementBase.globalData.addWarning(_("Ignoring duplicated DESTINATION command (line %d)").printf(lineNumber));
					return false;
				}
			}

			var element=new DestinationElement(destination,automatic,condition,invertCondition);
			element.comments = comments;
			this._destination.add(element);
			return false;
		}

		private bool addPackage(string package, packageType type, bool automatic, string? condition, bool invertCondition, int lineNumber, string[]? comments) {

			// if a package is conditional, it MUST be manual, because conditions are not added automatically
			if (condition!=null) {
				automatic=false;
			}

			// adding a non-automatic package to an automatic binary transforms this binary to non-automatic
			if ((automatic==false)&&(this._automatic==true)) {
				this.transformToNonAutomatic(false);
			}

			foreach(var element in this._packages) {
				if ((element.elementName==package) && ((automatic==true) || (element.type==type))) {
					return false;
				}
			}

			var element=new PackageElement(package,type,automatic,condition,invertCondition);
			element.comments = comments;
			this._packages.add(element);
			return false;
		}

		private bool addSource(string sourceFile, bool automatic, string? condition, bool invertCondition, int lineNumber, string[]? comments) {

			if (condition!=null) {
				automatic=false; // if a source file is conditional, it MUST be manual, because conditions are not added automatically
			}

			// adding a non-automatic source to an automatic binary transforms this binary to non-automatic
			if ((automatic==false)&&(this._automatic==true)) {
				this.transformToNonAutomatic(false);
			}

			bool add_binary = true;
			foreach(var element in this._sources) {
				if (element.elementName == sourceFile) {
					add_binary = false;
					break;
				}
			}

			if (add_binary) {
				var element = new SourceElement(sourceFile,automatic,condition, invertCondition);
				element.comments = comments;
				this._sources.add(element);
			}
			var translation = new ElementTranslation();
			if (sourceFile.has_suffix(".gs")) {
				translation.translate_type = TranslationType.GENIE;
			} else {
				translation.translate_type = TranslationType.VALA;
			}
			translation.configureElement(GLib.Path.build_filename(this._path, sourceFile), null, null, true, null, false);
			return false;
		}

		private bool addResource(string resourceFile, bool automatic, string? condition, bool invertCondition, int lineNumber, string[]? comments) {

			if (condition!=null) {
				automatic=false; // if a resource file is conditional, it MUST be manual, because conditions are not added automatically
			}

			// adding a non-automatic resource to an automatic binary transforms this binary to non-automatic
			if ((automatic==false) && (this._automatic==true)) {
				this.transformToNonAutomatic(false);
			}

			foreach(var element in this._resources) {
				if (element.elementName == resourceFile) {
					return false;
				}
			}

			var element=new ResourceElement(resourceFile,automatic,condition, invertCondition);
			element.comments = comments;
			this._resources.add(element);
			return false;
		}


		private bool addUnitest(string unitestFile, bool automatic, string? condition, bool invertCondition, int lineNumber, string[]? comments) {

			if (condition!=null) {
				automatic=false; // if a source file is conditional, it MUST be manual, because conditions are not added automatically
			}

			// adding a non-automatic source to an automatic binary transforms this binary to non-automatic
			if ((automatic==false)&&(this._automatic==true)) {
				this.transformToNonAutomatic(false);
			}

			foreach(var element in this._unitests) {
				if (element.elementName==unitestFile) {
					return false;
				}
			}
			var element=new SourceElement(unitestFile,automatic,condition, invertCondition);
			element.comments = comments;
			this._unitests.add(element);
			return false;
		}

		private bool addCSource(string sourceFile, bool automatic, string? condition, bool invertCondition, int lineNumber, string[]? comments) {

			if (condition!=null) {
				automatic=false; // if a source file is conditional, it MUST be manual, because conditions are not added automatically
			}

			// adding a non-automatic source to an automatic binary transforms this binary to non-automatic
			if ((automatic==false)&&(this._automatic==true)) {
				this.transformToNonAutomatic(false);
			}

			bool add_source = true;
			foreach(var element in this._cSources) {
				if (element.elementName == sourceFile) {
					add_source = false;
					break;
				}
			}
			if (add_source) {
				var element = new SourceElement(sourceFile,automatic,condition, invertCondition);
				element.comments = comments;
				this._cSources.add(element);
			}

			var translation = new ElementTranslation();
			translation.translate_type = TranslationType.C;
			translation.configureElement(GLib.Path.build_filename(this._path, sourceFile), null, null, true, null, false);
			return false;
		}

		private bool addVapi(string vapiFile, bool automatic, string? condition, bool invertCondition, int lineNumber, string[]? comments) {

			if (condition!=null) {
				automatic=false; // if a VAPI file is conditional, it MUST be manual, because conditions are not added automatically
			}

			// adding a non-automatic VAPI to an automatic binary transforms this binary to non-automatic
			if ((automatic==false)&&(this._automatic==true)) {
				this.transformToNonAutomatic(false);
			}

			foreach(var element in this._vapis) {
				if (element.elementName==vapiFile) {
					return false;
				}
			}
			var element=new VapiElement(vapiFile,automatic,condition, invertCondition);
			element.comments = comments;
			this._vapis.add(element);
			return false;
		}

		private bool addDBus(string DBusLine, bool automatic, string? condition, bool invertCondition, int lineNumber, string[]? comments) {

			if (condition!=null) {
				ElementBase.globalData.addError(_("DBus definitions can't be conditional (line %d)").printf(lineNumber));
				return true;
			}

			// adding a non-automatic DBUS definition to an automatic binary transforms this binary to non-automatic
			if ((automatic==false)&&(this._automatic==true)) {
				this.transformToNonAutomatic(false);
			}

			var datas=DBusLine.split(" ");
			string[] datas2={};
			foreach(var element in datas) {
				if (element!="") {
					datas2+=element;
				}
			}
			if ((datas2.length!=3) && (datas2.length!=4)) {
				ElementBase.globalData.addError(_("DBus definition must have three or four parameters (line %d)").printf(lineNumber));
				return true;
			}

			bool systemBus=false;
			if (datas2[2]=="system") {
				systemBus=true;
			} else if (datas2[2]=="session") {
				systemBus=false;
			} else {
				ElementBase.globalData.addError(_("DBus bus must be either 'system' or 'session' (line %d)").printf(lineNumber));
				return true;
			}

			bool GDBus=true;
			if (datas2.length==4) {
				if (datas2[3]=="gdbus") {
					GDBus=true;
				} else if (datas2[3]=="dbus-glib") {
					GDBus=false;
				} else {
					ElementBase.globalData.addError(_("DBus library must be either 'gdbus' or 'dbus-glib' (line %d)").printf(lineNumber));
					return true;
				}
			}

			foreach(var element in this._dbusElements) {
				if ((element.elementName==datas2[0])&&(element.obj==datas2[1])&&(element.systemBus==systemBus)) {
					return false;
				}
			}

			var element=new DBusElement(datas2[0],datas2[1],systemBus,GDBus,automatic);
			element.comments = comments;
			this._dbusElements.add(element);
			return false;
		}

		private bool addHFolder(string includeFolder, bool automatic, string? condition, bool invertCondition, int lineNumber, string[]? comments) {

			if (condition!=null) {
				automatic=false; // if an include folder is conditional, it MUST be manual, because conditions are not added automatically
			}

			// adding a non-automatic source to an automatic binary transforms this binary to non-automatic
			if ((automatic==false)&&(this._automatic==true)) {
				this.transformToNonAutomatic(false);
			}

			foreach(var element in this._hFolders) {
				if (element.elementName==includeFolder) {
					return false;
				}
			}
			var element=new SourceElement(includeFolder,automatic,condition, invertCondition);
			element.comments = comments;
			this._hFolders.add(element);
			return false;
		}

		public override bool configureLine(string line, bool automatic, string? condition, bool invertCondition, int lineNumber, string[]? comments) {

			if (line.has_prefix("vala_binary: ")) {
				this._type = ConfigType.VALA_BINARY;
				this.command = "vala_binary";
				this.comments = comments;
			} else if (line.has_prefix("vala_library: ")) {
				this._type = ConfigType.VALA_LIBRARY;
				this.command = "vala_library";
				this.comments = comments;
			} else if (line.has_prefix("version: ")) {
				return this.setVersion(line.substring(9).strip(),automatic,lineNumber);
			} else if (line.has_prefix("namespace: ")) {
				return this.setNamespace(line.substring(11).strip(),automatic,lineNumber);
			} else if (line.has_prefix("compile_options: ")) {
				return this.setCompileOptions(line.substring(17).strip(),automatic, condition, invertCondition, lineNumber, comments);
			} else if (line.has_prefix("compile_c_options: ")) {
				return this.setCompileCOptions(line.substring(19).strip(),automatic, condition, invertCondition, lineNumber, comments);
			} else if (line.has_prefix("vala_destination: ")) {
				return this.setDestination(line.substring(18).strip(),automatic,condition, invertCondition, lineNumber, comments);
			} else if (line.has_prefix("vala_package: ")) {
				return this.addPackage(line.substring(14).strip(),packageType.NO_CHECK, automatic, condition, invertCondition, lineNumber, comments);
			} else if (line.has_prefix("vala_check_package: ")) {
				return this.addPackage(line.substring(20).strip(),packageType.DO_CHECK, automatic, condition, invertCondition, lineNumber, comments);
			} else if (line.has_prefix("vala_local_package: ")) {
				return this.addPackage(line.substring(20).strip(),packageType.LOCAL, automatic, condition, invertCondition, lineNumber, comments);
			} else if (line.has_prefix("c_check_package: ")) {
				return this.addPackage(line.substring(17).strip(),packageType.C_DO_CHECK, automatic, condition, invertCondition, lineNumber, comments);
			} else if (line.has_prefix("vala_source: ")) {
				return this.addSource(line.substring(13).strip(), automatic, condition, invertCondition, lineNumber, comments);
			} else if (line.has_prefix("c_source: ")) {
				return this.addCSource(line.substring(10).strip(), automatic, condition, invertCondition, lineNumber, comments);
			} else if (line.has_prefix("unitest: ")) {
				return this.addUnitest(line.substring(9).strip(), automatic, condition, invertCondition, lineNumber, comments);
			} else if (line.has_prefix("vala_vapi: ")) {
				return this.addVapi(line.substring(11).strip(), automatic, condition, invertCondition, lineNumber, comments);
			} else if (line.has_prefix("dbus_interface: ")) {
				return this.addDBus(line.substring(16).strip(), automatic, condition, invertCondition, lineNumber, comments);
			} else if (line.has_prefix("c_library: ")) {
				return this.setCLibrary(line.substring(11).strip(), automatic, condition, invertCondition, lineNumber, comments);
			} else if (line.has_prefix("h_folder: ")) {
				return this.addHFolder(line.substring(10).strip(), automatic, condition, invertCondition, lineNumber, comments);
			} else if (line.has_prefix("use_gresource: ")) {
				return this.addResource(line.substring(14).strip(), automatic, condition, invertCondition, lineNumber, comments);
			} else if (line.has_prefix("alias: ")) {
				if (this._type != ConfigType.VALA_BINARY) {
					ElementBase.globalData.addError(_("Alias command is valid only inside Vala binaries (line %d)").printf(lineNumber));
					return true;
				}
				return this.addAlias(line.substring(7).strip(), automatic, condition, invertCondition, lineNumber, comments);
			} else {
				var badCommand = line.split(": ")[0];
				ElementBase.globalData.addError(_("Invalid command %s after command %s (line %d)").printf(badCommand,this.command, lineNumber));
				return true;
			}

			var data=line.substring(2+this.command.length).strip();
			return this.configureElement(GLib.Path.get_dirname(data),GLib.Path.get_dirname(data),GLib.Path.get_basename(data),automatic,condition,invertCondition);
		}

		public override void endedCMakeFile() {
			ElementValaBinary.addedValaBinaries=false;
		}

		public override bool generateCMakeHeader(DataOutputStream dataStream) {

			if (this.generateDBus()) {
				return true;
			}

			try {
				if (ElementValaBinary.addedValaBinaries==false) {
					dataStream.put_string("set (DATADIR \"${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_DATAROOTDIR}\")\n");
					dataStream.put_string("set (PKGDATADIR \"${DATADIR}/"+ElementBase.globalData.projectName+"\")\n");
					dataStream.put_string("set (GETTEXT_PACKAGE \""+ElementBase.globalData.projectName+"\")\n");
					dataStream.put_string("set (RELEASE_NAME \""+ElementBase.globalData.projectName+"\")\n");
					dataStream.put_string("set (CMAKE_C_FLAGS \"\")\n");
					dataStream.put_string("set (PREFIX ${CMAKE_INSTALL_PREFIX})\n");
					dataStream.put_string("set (VERSION \""+this.version+"\")\n");
					dataStream.put_string("set (TESTSRCDIR \"${CMAKE_SOURCE_DIR}\")\n");
					dataStream.put_string("set (DOLLAR \"$\")\n\n");
					if (this._path!="") {
						dataStream.put_string("configure_file (${CMAKE_SOURCE_DIR}/"+this._path+"/Config.vala.base ${CMAKE_BINARY_DIR}/"+this._path+"/Config.vala)\n");
					} else {
						dataStream.put_string("configure_file (${CMAKE_SOURCE_DIR}/Config.vala.base ${CMAKE_BINARY_DIR}/Config.vala)\n");
					}
					dataStream.put_string("add_definitions(-DGETTEXT_PACKAGE=\\\"${GETTEXT_PACKAGE}\\\")\n");
				}
				ElementValaBinary.addedValaBinaries=true;
			} catch (GLib.Error e) {
				ElementBase.globalData.addError(_("Failed to write the header for binary file %s").printf(this.fullPath));
				return true;
			}
			return false;
		}

		public override bool generateMesonHeader(ConditionalText dataStream, MesonCommon mesonCommon) {

			return this.generateDBus();
		}

		private bool generateDBus() {

			int retval;

			// Delete the dbus_generated folder and recreate all the dbus interfaces
			var pathDbus=GLib.Path.build_filename(ElementBase.globalData.projectFolder,this._fullPath,"dbus_generated");
			var path = File.new_for_path(pathDbus);
			if(path.query_exists()) {
				try {
					Process.spawn_command_line_sync("rm -rf "+pathDbus);
				} catch (GLib.SpawnError e) {
					ElementBase.globalData.addWarning(_("Failed to delete the path %s").printf(pathDbus));
				}
			}
			if (this._dbusElements.size != 0) {
				foreach (var element in this._dbusElements) {
					var elementPathS=GLib.Path.build_filename(pathDbus,element.elementName,element.obj);
					var elementPath=File.new_for_path(elementPathS);
					try{
						elementPath.make_directory_with_parents();
					} catch (GLib.Error e) {
						ElementBase.globalData.addWarning(_("Failed to create the path %s").printf(elementPathS));
						continue;
					}
					string command="";
					string output="";
					string errorMsg="";
					int exitStatus;

					try {
						command = "dbus-send --%s --type=method_call --print-reply=literal --dest=%s %s org.freedesktop.DBus.Introspectable.Introspect".printf(element.systemBus ? "system" : "session",element.elementName,element.obj);
						if (!GLib.Process.spawn_command_line_sync(command,out output,out errorMsg,out exitStatus)) {
							ElementBase.globalData.addError(_("Can't find dbus-send command"));
							return true;
						}
						if (exitStatus!=0) {
							ElementBase.globalData.addWarning(_("Failed to execute '%s' with error message '%s'").printf(command,errorMsg.strip()));
							continue;
						}
					} catch (GLib.SpawnError e) {
						ElementBase.globalData.addError(_("Can't find dbus-send command"));
						return true;
					}

					FileOutputStream outputStream;
					try {
						GLib.File dbusFile=GLib.File.new_for_path("/tmp/dbus_data.xml");
						if (dbusFile.query_exists()) {
							dbusFile.delete();
						}
						outputStream = dbusFile.create(GLib.FileCreateFlags.NONE);
					} catch (GLib.Error e) {
						ElementBase.globalData.addWarning(_("Failed to check temporary file /tmp/dbus_data.xml"));
						continue;
					}

					try {
						outputStream.write(output.data);
					} catch (GLib.IOError e) {
						ElementBase.globalData.addWarning(_("IOError: %s\n").printf(e.message));
						return false;
					}


					if (element.GDBus) {
						command = "vala-dbus-binding-tool --gdbus --api-path=/tmp/dbus_data.xml --directory=%s".printf(elementPathS);
					} else {
						command = "vala-dbus-binding-tool --api-path=/tmp/dbus_data.xml --directory=%s".printf(elementPathS);
					}

					try {
						if (!Process.spawn_command_line_sync(command, null, null, out retval)) {
							ElementBase.globalData.addError(_("Can't find vala-dbus-binding-tool command"));
							return true;
						}
						if (retval!=0) {
							ElementBase.globalData.addWarning(_("Failed to generate the DBus interface for the object %s (%s) at the bus '%s'\n").printf(element.obj,element.elementName,element.systemBus ? "system" : "session"));
							continue;
						}
					} catch (GLib.SpawnError e) {
						ElementBase.globalData.addError(_("Can't find vala-dbus-binding-tool command"));
						return true;
					}

					var files = ElementBase.getFilesFromFolder(GLib.Path.build_filename(this._path,"dbus_generated"),{".vala"},true,true);
					foreach (var iface in files) {
						this.addSource(GLib.Path.build_filename("dbus_generated",iface),true,null,false,-1,null);
					}
				}
			}
			return false;
		}

		public override bool generateCMakePostData(DataOutputStream dataStream,DataOutputStream dataStreamGlobal) {

			if (ElementValaBinary.addedLibraryWarning == false) {
				ElementValaBinary.addedLibraryWarning = true;
				foreach(var element in ElementBase.globalData.globalElements) {
					if (element.eType == ConfigType.VALA_LIBRARY) {
						try {
							dataStream.put_string("\ninstall(CODE \"MESSAGE (\\\"\n************************************************\n* Run 'sudo ldconfig' to complete installation *\n************************************************\n\n\\\") \" )");
							dataStream.put_string("\n\n");
						} catch(GLib.Error e) {
							ElementBase.globalData.addError(_("Failed to append the 'run sudo ldconfig' message"));
							return true;
						}
						break;
					}
				}
			}
			return false;
		}

		private bool generateConfigBase(string libFilename) {
			var fname = File.new_for_path(Path.build_filename(ElementBase.globalData.projectFolder,this._path,"Config.vala.base"));
			try {
				if (fname.query_exists()) {
					fname.delete();
				}
				var dis = fname.create(FileCreateFlags.NONE);
				var dataStream2 = new DataOutputStream(dis);
				if ((this._type == ConfigType.VALA_LIBRARY) && (this._currentNamespace!=null)) {
					dataStream2.put_string("namespace "+libFilename+"Constants {\n");
				} else {
					dataStream2.put_string("namespace Constants {\n");
				}
				dataStream2.put_string("\tpublic const string DATADIR = \"@DATADIR@\";\n");
				dataStream2.put_string("\tpublic const string PKGDATADIR = \"@PKGDATADIR@\";\n");
				dataStream2.put_string("\tpublic const string GETTEXT_PACKAGE = \"@GETTEXT_PACKAGE@\";\n");
				dataStream2.put_string("\tpublic const string RELEASE_NAME = \"@RELEASE_NAME@\";\n");
				dataStream2.put_string("\tpublic const string VERSION = \"@VERSION@\";\n");
				dataStream2.put_string("#if UNITEST\n\tpublic const string TESTSRCDIR = \"@TESTSRCDIR@\";\n#endif\n");
				dataStream2.put_string("}\n");
				dataStream2.close();
			} catch (GLib.Error e) {
				ElementBase.globalData.addError(_("Failed to create the Config.vala.base file"));
				return true;
			}
			return false;
		}

		private bool createDepsFile(string depsFilename) {

			var fname = File.new_for_path(Path.build_filename(ElementBase.globalData.projectFolder,this._path,depsFilename));
			if (fname.query_exists()) {
				try {
					fname.delete();
				} catch (GLib.Error e) {
					ElementBase.globalData.addError(_("Failed to delete the old .DEPS file"));
					return true;
				}
			}
			try {
				var dis = fname.create(FileCreateFlags.NONE);
				var dataStream2 = new DataOutputStream(dis);
				foreach(var module in this._packages) {
					if ((module.type == packageType.C_DO_CHECK)) {
						continue;
					}
					dataStream2.put_string("%s\n".printf(module.elementName));
				}
				dataStream2.close();
			} catch (GLib.Error e) {
				ElementBase.globalData.addError(_("Failed to create the .DEPS file"));
				return true;
			}
			return false;
		}

		private void setMesonVar(ConditionalText dataStream, string variable, string var_value) throws GLib.IOError {
			bool exists = this._meson_arrays.contains(variable);
			dataStream.put_string("%s_%s %s= [%s]\n".printf(this.name.replace("-","_"),variable,exists ? "+" : "",var_value));
			this._meson_arrays.add(variable);
		}

		private void setMesonPrecondition(ConditionalText datastream,string? condition, string variable) throws GLib.IOError {
			if ((condition != null) && (false == this._meson_arrays.contains(variable))) {
				this.setMesonVar(datastream,variable,"");
			}
		}

		private string splitInStrings(string input) {

			var elements = input.split(" ");
			var output = "";
			foreach(var e in elements) {
				if (output != "") {
					output += ", ";
				}
				output += "'%s'".printf(e);
			}
			return output;
		}

		public override bool generateMeson(ConditionalText dataStream, MesonCommon mesonCommon) {

			this._meson_arrays = new Gee.HashSet<string>();

			string girFilename = "";
			string libFilename = this.name.replace("-","_");
			if (this._currentNamespace != null) {
				// Build the GIR filename
				girFilename = this._currentNamespace + "-" + this.version.split(".")[0] + ".0.gir";
				libFilename = this._currentNamespace;
			}
			string depsFilename = libFilename+".deps";

			try {
				if (this._type == ConfigType.VALA_LIBRARY) {
					this.remove_self_package();
				}

				if (this.generateConfigBase(libFilename)) {
					return true;
				}

				dataStream.put_string("cfg_%s = configuration_data()\n".printf(this.name.replace("-","_")));
				dataStream.put_string("cfg_%s.set('DATADIR', join_paths(get_option('prefix'),get_option('datadir')))\n".printf(this.name.replace("-","_")));
				dataStream.put_string("cfg_%s.set('PKGDATADIR', join_paths(get_option('prefix'),get_option('datadir'),'%s'))\n".printf(this.name.replace("-","_"),ElementBase.globalData.projectName));
				dataStream.put_string("cfg_%s.set('GETTEXT_PACKAGE', '%s')\n".printf(this.name.replace("-","_"),ElementBase.globalData.projectName));
				dataStream.put_string("cfg_%s.set('RELEASE_NAME', '%s')\n".printf(this.name.replace("-","_"),ElementBase.globalData.projectName));
				dataStream.put_string("cfg_%s.set('PREFIX', get_option('prefix'))\n".printf(this.name.replace("-","_")));
				dataStream.put_string("cfg_%s.set('VERSION', '%s')\n".printf(this.name.replace("-","_"),this.version));
				dataStream.put_string("cfg_%s.set('TESTSRCDIR', meson.source_root())\n\n".printf(this.name.replace("-","_")));

				var counter = Globals.counter;
				var input_file = "Config.vala.base";
				var output_file = Path.build_filename("Config.vala");
				dataStream.put_string("cfgfile_%d = configure_file(input: '%s',output: '%s',configuration: cfg_%s)\n\n".printf(counter,input_file,output_file,this.name.replace("-","_")));


				var printConditions = new ConditionalText(dataStream.dataStream, ConditionalType.MESON, dataStream.tabs);
				foreach(var module in this.packages) {
					if ((module.type==packageType.DO_CHECK)||(module.type==packageType.C_DO_CHECK)) {
						this.setMesonPrecondition(dataStream,module.condition,"deps");
						printConditions.printCondition(module.condition,module.invertCondition);
						this.setMesonVar(dataStream,"deps","%s_dep".printf(module.elementName.replace("-","_").replace("+","").replace(".","_")));
					}
				}
				printConditions.printTail();

				this.setMesonVar(dataStream,"sources","cfgfile_%d".printf(counter));
				foreach(var source in this._sources) {
					printConditions.printCondition(source.condition,source.invertCondition);
					this.setMesonVar(dataStream,"sources","'%s'".printf(source.elementName));
				}
				printConditions.printTail();

				foreach(var source in this._cSources) {
					printConditions.printCondition(source.condition,source.invertCondition);
					this.setMesonVar(dataStream,"sources","'%s'".printf(source.elementName));
				}
				printConditions.printTail();

				foreach (var resource in this._resources) {
					foreach(var element in ElementBase.globalData.globalElements) {
						if (element.eType==ConfigType.GRESOURCE) {
							var gresource = element as ElementGResource;
							if (gresource.identifier == resource.elementName) {
								printConditions.printCondition(element.condition, element.invertCondition);
								this.setMesonVar(dataStream,"sources","%s_file_c".printf(gresource.name.replace(".","_")));
							}
						}
					}
				}
				printConditions.printTail();

				foreach (var filename in this._vapis) {
					printConditions.printCondition(filename.condition,filename.invertCondition);
					this.setMesonVar(dataStream,"sources","join_paths(meson.source_root(),'%s')".printf(filename.elementName));
				}
				printConditions.printTail();

				foreach(var module in this.packages) {
					if ((module.type==packageType.DO_CHECK)||(module.type==packageType.C_DO_CHECK)||(module.type==packageType.LOCAL)) {
						continue;
					}
					this.setMesonPrecondition(dataStream,module.condition,"vala_args");
					printConditions.printCondition(module.condition,module.invertCondition);
					this.setMesonVar(dataStream,"vala_args","'--pkg','%s'".printf(module.elementName));
				}
				printConditions.printTail();

				foreach(var element in ElementBase.globalData.globalElements) {
					if (element.eType==ConfigType.VAPIDIR) {
						this.setMesonPrecondition(dataStream,element.condition,"vala_args");
						printConditions.printCondition(element.condition, element.invertCondition);
						if (element.fullPath[0] == GLib.Path.DIR_SEPARATOR) {
							// should check if it exists...
							this.setMesonVar(dataStream,"vala_args","'--vapidir='+join_paths(meson.source_root(),'%s')".printf(element.fullPath));
						} else {
							this.setMesonVar(dataStream,"vala_args","'--vapidir='+join_paths(meson.source_root(),'%s')".printf(element.fullPath));
						}
					}
				}
				printConditions.printTail();

				foreach (var resource in this._resources) {
					foreach(var element in ElementBase.globalData.globalElements) {
						if (element.eType==ConfigType.GRESOURCE) {
							var gresource = element as ElementGResource;
							if (gresource.identifier == resource.elementName) {
								this.setMesonPrecondition(dataStream,element.condition,"vala_args");
								printConditions.printCondition(element.condition, element.invertCondition);
								this.setMesonVar(dataStream,"vala_args","'--gresources='+join_paths(meson.source_root(),'%s')".printf(element.fullPath));
							}
						}
					}
				}
				printConditions.printTail();

				foreach(var option in this._compileOptions) {
					this.setMesonPrecondition(dataStream,option.condition,"vala_args");
					printConditions.printCondition(option.condition,option.invertCondition);
					this.setMesonVar(dataStream,"vala_args",this.splitInStrings(option.elementName));
				}
				printConditions.printTail();

				foreach(var package in this.packages) {
					if (package.type == packageType.LOCAL) {
						this.setMesonPrecondition(dataStream,package.condition,"dependencies");
						printConditions.printCondition(package.condition,package.invertCondition);
						this.setMesonVar(dataStream,"dependencies","%s_library".printf(package.elementName));
					}
				}
				printConditions.printTail();

				foreach(var option in this._compileCOptions) {
					this.setMesonPrecondition(dataStream,option.condition,"c_args");
					printConditions.printCondition(option.condition,option.invertCondition);
					this.setMesonVar(dataStream,"c_args",this.splitInStrings(option.elementName));
				}
				printConditions.printTail();

				foreach(var element in globalData.globalElements) {
					if (element.eType != ConfigType.DEFINE) {
						continue;
					}
					this.setMesonPrecondition(dataStream,"","vala_args");
					this.setMesonPrecondition(dataStream,"","c_args");
					dataStream.put_string("if %s\n  ".printf(element.name));
					this.setMesonVar(dataStream,"vala_args","'-D', '%s'".printf(element.name));
					dataStream.put_string("  ");
					this.setMesonVar(dataStream,"c_args","'-D%s'".printf(element.name));
					dataStream.put_string("endif\n");
				}

				foreach(var llibrary in this._link_libraries) {

					if ((llibrary.elementName == "threads") || (llibrary.elementName == "pthreads")) {
						this.setMesonPrecondition(dataStream,llibrary.condition,"dependencies");
						printConditions.printCondition(llibrary.condition,llibrary.invertCondition);
						dataStream.put_string("%s_thread_dep = dependency('threads')\n".printf(this.name.replace("-","_")));
						this.setMesonVar(dataStream,"dependencies","'%s_thread_dep'".printf(this.name.replace("-","_")));
						continue;
					}
					if (llibrary.elementName == "m") {
						/*dataStream.put_string("cc_%d = meson.get_compiler('c')\n");
						dataStream.put_string("m_dep = cc.find_library('m', required : false)\n");*/
						this.setMesonPrecondition(dataStream,llibrary.condition,"deps");
						printConditions.printCondition(llibrary.condition,llibrary.invertCondition);
						this.setMesonVar(dataStream,"deps","meson.get_compiler('c').find_library('m', required : false)");
						continue;
					}
					this.setMesonPrecondition(dataStream,llibrary.condition,"link_args");
					printConditions.printCondition(llibrary.condition,llibrary.invertCondition);
					this.setMesonVar(dataStream,"link_args","'-l%s'".printf(llibrary.elementName));
				}
				printConditions.printTail();

				foreach(var element in this._hFolders) {
					this.setMesonPrecondition(dataStream,element.condition,"hfolders");
					printConditions.printCondition(element.condition, element.invertCondition);
					this.setMesonVar(dataStream,"hfolders","'%s'".printf(element.elementName));
				}
				printConditions.printTail();

				var names = new Gee.HashMap<string, ElementValaBinary>();
				foreach(var tbinary in ElementBase.globalData.globalElements) {
					if ((tbinary.eType != ConfigType.VALA_BINARY) && (tbinary.eType != ConfigType.VALA_LIBRARY)) {
						continue;
					}
					var binary = tbinary as ElementValaBinary;
					string name;
					if (binary.currentNamespace == null) {
						name = binary.name;
					} else {
						name = binary.currentNamespace;
					}
					if (!names.has_key(name)) {
						names.set(name, binary);
					}
				}

				bool found_hfolders = false;
				foreach(var element in this._packages) {
					if (element.type != packageType.LOCAL) {
						continue;
					}
					if (!names.has_key(element.elementName)) {
						ElementBase.globalData.addError(_("Failed to find the local dependency '%s' for '%s'").printf(element.elementName,this.name));
						continue;
					}
					var dependency = names.get(element.elementName);
					var relpath = this.getRelativePath(this._path, dependency.path);
					if (relpath != null) {
						this.setMesonVar(dataStream,"hfolders","'%s'".printf(relpath));
						found_hfolders = true;
					}
				}

				if (this._type == ConfigType.VALA_BINARY) {
					dataStream.put_string("\nexecutable");
					dataStream.put_string("('%s',%s_sources".printf(this.name,this.name.replace("-","_")));
				} else {
					if (girFilename != "") {
						this.setMesonVar(dataStream,"vala_args","'--gir=%s'".printf(girFilename));
						dataStream.put_string("\n");
					}
					if (this._currentNamespace == null) {
						dataStream.put_string("\nshared_library");
					} else {
						dataStream.put_string("\n%s_library = shared_library".printf(this._currentNamespace));
					}
					dataStream.put_string("('%s',%s_sources".printf(libFilename,this.name.replace("-","_")));
					if (this.createDepsFile(depsFilename)) {
						return true;
					}
				}

				if (this._meson_arrays.contains("deps")) {
					dataStream.put_string(",dependencies: %s_deps".printf(this.name.replace("-","_")));
				}
				if (this._meson_arrays.contains("vala_args")) {
					dataStream.put_string(",vala_args: %s_vala_args".printf(this.name.replace("-","_")));
				}
				if (this._meson_arrays.contains("c_args")) {
					dataStream.put_string(",c_args: %s_c_args".printf(this.name.replace("-","_")));
				}
				if (this._meson_arrays.contains("link_args")) {
					dataStream.put_string(",link_args: %s_link_args".printf(this.name.replace("-","_")));
				}
				if (this._meson_arrays.contains("dependencies")) {
					dataStream.put_string(",link_with: %s_dependencies".printf(this.name.replace("-","_")));
				}
				if ((this._meson_arrays.contains("hfolders")) || found_hfolders) {
					dataStream.put_string(",include_directories: include_directories(%s_hfolders)".printf(this.name.replace("-","_")));
				}
				if (this._type == ConfigType.VALA_LIBRARY) {
					dataStream.put_string(",version: '%s'".printf(this.version));
					dataStream.put_string(",soversion: '%s'".printf(this.version.split(".")[0]));
				}
				dataStream.put_string(",install: true");
				dataStream.put_string(")\n\n");

				foreach(var alias in this._aliases) {
					printConditions.printCondition(alias.condition, alias.invertCondition);
					dataStream.put_string("meson.add_install_script('sh', '-c', 'ln -sf %s ${DESTDIR}/${MESON_INSTALL_PREFIX}/bin/%s')\n".printf(this.name, alias.elementName));
				}
				printConditions.printTail();

				if ((this._type == ConfigType.VALA_LIBRARY) && (this._currentNamespace != null)) {
					dataStream.put_string("%s_requires = []\n".printf(this.name.replace("-","_")));
					foreach(var module in this._packages) {
						if ((module.type != packageType.DO_CHECK) && (module.type != packageType.LOCAL)){
							continue;
						}
						dataStream.put_string("%s_requires += ['%s']\n".printf(this.name.replace("-","_"),module.elementName));
					}
					dataStream.put_string("pkg_mod = import('pkgconfig')\n");
					dataStream.put_string("pkg_mod.generate(libraries : %s_library,\n\tversion : '%s',\n\tname : '%s',\n\tfilebase : '%s',\n\tdescription : '%s',\n\trequires : %s_requires)\n\n".printf(this._currentNamespace,this.version,libFilename,libFilename,libFilename,this.name.replace("-","_")));
				}

				if (this._type == ConfigType.VALA_LIBRARY) {
					dataStream.put_string("install_data(join_paths(meson.current_source_dir(),'%s'),install_dir: join_paths(get_option('prefix'),'share','vala','vapi'))\n".printf(depsFilename));

					mesonCommon.create_install_library_script();
					dataStream.put_string("meson.add_install_script(join_paths(meson.source_root(),'meson_scripts','install_library.sh'),'%s','%s','%s')\n\n".printf(this.path, libFilename, girFilename));
				}


				// unitary tests
				if (this._unitests.size != 0) {
					dataStream.put_string("%s_tests_vala_args = ".printf(this.name.replace("-","_")));
					if (this._meson_arrays.contains("vala_args")) {
						dataStream.put_string("%s_vala_args + ".printf(this.name.replace("-","_")));
					}
					dataStream.put_string("['-D','UNITEST']\n");
					dataStream.put_string("%s_tests_c_args = ".printf(this.name.replace("-","_")));
					if (this._meson_arrays.contains("c_args")) {
						dataStream.put_string("%s_c_args + ".printf(this.name.replace("-","_")));
					}
					dataStream.put_string("['-DUNITEST']\n");

					foreach (var unitest in this._unitests) {

						dataStream.put_string("\n%s_test%d_exec = executable".printf(this.name.replace("-","_"),ElementValaBinary.counter));
						dataStream.put_string("('%s_test%d',%s_sources + [join_paths(meson.source_root(),'%s')]".printf(this.name,ElementValaBinary.counter,this.name.replace("-","_"),unitest.elementName));

						if (this._meson_arrays.contains("deps")) {
							dataStream.put_string(",dependencies: %s_deps".printf(this.name.replace("-","_")));
						}
						dataStream.put_string(",vala_args: %s_tests_vala_args".printf(this.name.replace("-","_")));
						dataStream.put_string(",c_args: %s_tests_c_args".printf(this.name.replace("-","_")));
						if (this._meson_arrays.contains("link_args")) {
							dataStream.put_string(",link_args: %s_link_args".printf(this.name.replace("-","_")));
						}
						if (this._meson_arrays.contains("dependencies")) {
							dataStream.put_string(",link_with: %s_dependencies".printf(this.name.replace("-","_")));
						}
						if (this._meson_arrays.contains("hfolders")) {
							dataStream.put_string(",include_directories: %s_hfolders".printf(this.name.replace("-","_")));
						}
						dataStream.put_string(",install: false");
						dataStream.put_string(")\n");

						dataStream.put_string("test('%s_test%d', %s_test%d_exec)\n\n".printf(this.name.replace("-","_"),ElementValaBinary.counter,this.name.replace("-","_"),ElementValaBinary.counter));

						dataStream.put_string("\n");
						ElementValaBinary.counter++;
					}
				}

			} catch(GLib.Error e) {
				ElementBase.globalData.addError(_("Failed to write to meson.build at '%s' element, at '%s' path: %s").printf(this.command,this._path,e.message));
				return true;
			}

			return false;
		}

		public override bool generateCMake(DataOutputStream dataStream) {

			this.has_dependencies = false;
			string girFilename="";
			string libFilename=this.name;
			if (this._currentNamespace!=null) {
				// Build the GIR filename
				girFilename=this._currentNamespace+"-"+this.version.split(".")[0]+".0.gir";
				libFilename=this._currentNamespace;
			}

			if (this._type == ConfigType.VALA_LIBRARY) {
				this.remove_self_package();
			}

			if (this.generateConfigBase(libFilename)) {
				return true;
			}

			try {
				string pcFilename=libFilename+".pc";
				string depsFilename=libFilename+".deps";

				if (this._type == ConfigType.VALA_LIBRARY) {
					var fname=File.new_for_path(Path.build_filename(ElementBase.globalData.projectFolder,this._path,pcFilename));
					if (fname.query_exists()) {
						fname.delete();
					}
					try {
						var dis = fname.create(FileCreateFlags.NONE);
						var dataStream2 = new DataOutputStream(dis);
						dataStream2.put_string("prefix=@CMAKE_INSTALL_PREFIX@\n");
						dataStream2.put_string("libdir=@DOLLAR@{prefix}/${CMAKE_INSTALL_LIBDIR}\n");
						dataStream2.put_string("includedir=@DOLLAR@{prefix}/${CMAKE_INSTALL_INCLUDEDIR}\n\n");
						dataStream2.put_string("Name: "+libFilename+"\n");
						dataStream2.put_string("Description: "+libFilename+"\n");
						dataStream2.put_string("Version: "+this.version+"\n");
						dataStream2.put_string("Libs: -L@DOLLAR@{libdir} -l"+libFilename+"\n");
						dataStream2.put_string("Cflags: -I@DOLLAR@{includedir}\n");

						bool first = true;
						foreach(var module in this._packages) {
							if ((module.type != packageType.DO_CHECK) && (module.type != packageType.LOCAL)){
								continue;
							}
							if (first) {
								dataStream2.put_string("Requires:");
								first = false;
							}
							dataStream2.put_string(" %s".printf(module.elementName));
						}
						if (!first) {
							dataStream2.put_string("\n");
						}
						dataStream2.close();
					} catch (GLib.Error e) {
						ElementBase.globalData.addError(_("Failed to create the .PC file"));
						return true;
					}
					dataStream.put_string("configure_file (${CMAKE_CURRENT_SOURCE_DIR}/"+pcFilename+" ${CMAKE_CURRENT_BINARY_DIR}/"+pcFilename+")\n");

					if (this.createDepsFile(depsFilename)) {
						return true;
					}

					dataStream.put_string("configure_file (${CMAKE_CURRENT_SOURCE_DIR}/"+depsFilename+" ${CMAKE_CURRENT_BINARY_DIR}/"+depsFilename+")\n");
				}

				dataStream.put_string("set (VERSION \""+this.version+"\")\n");

				dataStream.put_string("add_definitions (${DEPS_CFLAGS})\n");

				bool addedPrefix=false;
				foreach(var module in this._packages) {
					if (module.type==packageType.LOCAL) {
						if (ElementBase.globalData.localModules.has_key(module.elementName)) {
							if (addedPrefix==false) {
								dataStream.put_string("include_directories ( ");
								addedPrefix=true;
							}
							dataStream.put_string("${CMAKE_BINARY_DIR}/"+ElementBase.globalData.localModules.get(module.elementName)+" ");
						} else {
							ElementBase.globalData.addWarning(_("Can't set package %s for binary %s").printf(module.elementName,this.name));
						}
					}
				}
				if (addedPrefix) {
					dataStream.put_string(")\n");
				}

				dataStream.put_string("link_libraries ( ${DEPS_LIBRARIES} ");
				foreach(var module in this._packages) {
					if ((module.type==packageType.LOCAL)&&(ElementBase.globalData.localModules.has_key(module.elementName))) {
						dataStream.put_string("-l"+module.elementName+" ");
					}
				}
				dataStream.put_string(")\n");
				dataStream.put_string("link_directories ( ${DEPS_LIBRARY_DIRS} ");
				foreach(var module in this._packages) {
					if ((module.type==packageType.LOCAL)&&(ElementBase.globalData.localModules.has_key(module.elementName))) {
						dataStream.put_string("${CMAKE_BINARY_DIR}/"+ElementBase.globalData.localModules.get(module.elementName)+" ");
					}
				}
				dataStream.put_string(")\n");
				dataStream.put_string("find_package (Vala REQUIRED)\n");
				dataStream.put_string("include (ValaVersion)\n");
				dataStream.put_string("ensure_vala_version (\"%d.%d\" MINIMUM)\n".printf(ElementBase.globalData.valaVersionMajor,ElementBase.globalData.valaVersionMinor));
				dataStream.put_string("include (ValaPrecompile)\n\n");

				var printConditions=new ConditionalText(dataStream,ConditionalType.CMAKE);

				bool found_local=false;
				foreach(var module in this._packages) {
					if (module.type==packageType.C_DO_CHECK) {
						continue;
					}
					if (module.type==packageType.LOCAL) {
						found_local=true;
						continue;
					}
					printConditions.printCondition(module.condition,module.invertCondition);
					dataStream.put_string("set (VALA_PACKAGES ${VALA_PACKAGES} %s)\n".printf(module.elementName));
				}
				printConditions.printTail();
				dataStream.put_string("\n");

				if ((this._type != ConfigType.VALA_LIBRARY)||(this._currentNamespace!="")) {
					dataStream.put_string("set (APP_SOURCES ${APP_SOURCES} ${CMAKE_CURRENT_BINARY_DIR}/Config.vala)\n");
				}
				foreach(var module in this._sources) {
					printConditions.printCondition(module.condition,module.invertCondition);
					dataStream.put_string("set (APP_SOURCES ${APP_SOURCES} %s)\n".printf(module.elementName));
				}
				printConditions.printTail();
				dataStream.put_string("\n");

				bool has_custom_VAPIs=false;
				if ((this._vapis.size!=0)||(found_local==true)) {
					foreach (var filename in this._vapis) {
						printConditions.printCondition(filename.condition,filename.invertCondition);
						dataStream.put_string("set (CUSTOM_VAPIS_LIST ${CUSTOM_VAPIS_LIST} ${CMAKE_SOURCE_DIR}/%s)\n".printf(Path.build_filename(this._path,filename.elementName)));
						has_custom_VAPIs=true;
					}
					printConditions.printTail();
					foreach(var module in this._packages) {
						if (module.type==packageType.LOCAL) {
							if (ElementBase.globalData.localModules.has_key(module.elementName)) {
								printConditions.printCondition(module.condition,module.invertCondition);
								dataStream.put_string("set (CUSTOM_VAPIS_LIST ${CUSTOM_VAPIS_LIST} ${CMAKE_BINARY_DIR}/%s)\n".printf(Path.build_filename(ElementBase.globalData.localModules.get(module.elementName), module.elementName +".vapi")));
								has_custom_VAPIs=true;
							}
						}
					}
					printConditions.printTail();
					dataStream.put_string("\n");
				}

				// Add all the DEFINEs set both in the code and the configuration file
				bool addDefines=false;
				foreach(var element in ElementBase.globalData.globalElements) {
					if (element.eType==ConfigType.DEFINE) {
						addDefines=true;
						dataStream.put_string("if (%s)\n".printf(element.name));
						dataStream.put_string("\tset (COMPILE_OPTIONS ${COMPILE_OPTIONS} -D %s)\n".printf(element.name));
						dataStream.put_string("\tset (CMAKE_C_FLAGS \"${CMAKE_C_FLAGS} -D%s \" )\n".printf(element.name));
						dataStream.put_string("\tset (CMAKE_CXX_FLAGS \"${CMAKE_CXX_FLAGS} -D%s \" )\n".printf(element.name));
						dataStream.put_string("endif ()\n");
					}
				}

				foreach(var element in ElementBase.globalData.globalElements) {
					if (element.eType==ConfigType.VAPIDIR) {
						addDefines=true;
						printConditions.printCondition(element.condition, element.invertCondition);
						if (element.fullPath[0] == GLib.Path.DIR_SEPARATOR) {
							dataStream.put_string("if (EXISTS %s)\n".printf(element.fullPath));
							dataStream.put_string("\tset (COMPILE_OPTIONS ${COMPILE_OPTIONS} --vapidir=%s )\n".printf(element.fullPath));
							dataStream.put_string("endif (EXISTS %s)\n".printf(element.fullPath));
						} else {
							dataStream.put_string("set (COMPILE_OPTIONS ${COMPILE_OPTIONS} --vapidir=${CMAKE_SOURCE_DIR}/%s )\n".printf(element.fullPath));
						}
					}
				}

				dataStream.put_string("\nif ((${CMAKE_BUILD_TYPE} STREQUAL \"Debug\") OR (${CMAKE_BUILD_TYPE} STREQUAL \"RelWithDebInfo\"))\n");
				dataStream.put_string("\tset(COMPILE_OPTIONS ${COMPILE_OPTIONS} \"-g\")\n");
				dataStream.put_string("endif()\n\n");

				if (this._type == ConfigType.VALA_LIBRARY) {
					addDefines=true;
					// If it is a library, generate the Gobject Introspection file
					var finalOptions="--library="+libFilename;
					if (girFilename!="") {
						finalOptions+=" --gir "+girFilename;
					} else {
						ElementBase.globalData.addWarning(_("No namespace specified in library %s; GIR file will not be generated").printf(this.name));
					}
					dataStream.put_string("set (COMPILE_OPTIONS ${COMPILE_OPTIONS} %s )\n".printf(finalOptions));
				}

				foreach(var element in this._compileOptions) {
					addDefines=true;
					printConditions.printCondition(element.condition, element.invertCondition);
					if (element.elementName.strip()[0] == '@') {
						var pos = element.elementName.index_of_char(' ');
						if (pos == -1) {
							ElementBase.globalData.addWarning(_("There are no compile options in %s").printf(element.elementName));
							continue;
						}
						var build_type = element.elementName.substring(1,pos - 1).strip();
						var options = element.elementName.substring(pos).strip();
						dataStream.put_string("if (${CMAKE_BUILD_TYPE} STREQUAL \"%s\" )\n".printf(build_type));
						dataStream.put_string("\tset (COMPILE_OPTIONS ${COMPILE_OPTIONS} %s )\n".printf(options));
						dataStream.put_string("endif()\n");
					} else {
						dataStream.put_string("set (COMPILE_OPTIONS ${COMPILE_OPTIONS} %s )\n".printf(element.elementName));
					}
				}
				printConditions.printTail();

				foreach (var resource in this._resources) {
					foreach(var element in ElementBase.globalData.globalElements) {
						if (element.eType==ConfigType.GRESOURCE) {
							var gresource = element as ElementGResource;
							if (gresource.identifier == resource.elementName) {
								dataStream.put_string("set (COMPILE_OPTIONS ${COMPILE_OPTIONS} --gresources=${CMAKE_SOURCE_DIR}/%s )\n".printf(element.fullPath));
							}
						}
					}
				}

				if (addDefines) {
					dataStream.put_string("\n");
				}

				bool addedCFlags=false;
				foreach(var element in this._compileCOptions) {
					addedCFlags=true;
					printConditions.printCondition(element.condition, element.invertCondition);
					if (element.elementName.strip()[0] == '@') {
						var pos = element.elementName.index_of_char(' ');
						if (pos == -1) {
							ElementBase.globalData.addWarning(_("There are no C compile options in %s").printf(element.elementName));
							continue;
						}
						var build_type = element.elementName.substring(1,pos - 1).strip().up();
						var options = element.elementName.substring(pos).strip();
						dataStream.put_string("set (CMAKE_C_FLAGS_%s \"${CMAKE_C_FLAGS_%s} %s\" )\n".printf(build_type,build_type,options));
					} else {
						dataStream.put_string("set (CMAKE_C_FLAGS \"${CMAKE_C_FLAGS} %s\" )\n".printf(element.elementName));
					}
				}
				printConditions.printTail();

				foreach(var element in this._hFolders) {
					addedCFlags=true;
					printConditions.printCondition(element.condition, element.invertCondition);
					dataStream.put_string("include_directories (AFTER %s )\n".printf(element.elementName));
				}
				if (addedCFlags) {
					printConditions.printTail();
					dataStream.put_string("\n");
				}

				dataStream.put_string("vala_precompile(VALA_C "+libFilename+"\n");
				dataStream.put_string("\t${APP_SOURCES}\n");
				dataStream.put_string("PACKAGES\n");
				dataStream.put_string("\t${VALA_PACKAGES}\n");
				if (has_custom_VAPIs) {
					dataStream.put_string("CUSTOM_VAPIS\n");
					dataStream.put_string("\t${CUSTOM_VAPIS_LIST}\n");
				}

				if (addDefines) {
					dataStream.put_string("OPTIONS\n");
					dataStream.put_string("\t${COMPILE_OPTIONS}\n");
				}

				if (this._type == ConfigType.VALA_LIBRARY) {
					// Generate both VAPI and headers
					dataStream.put_string("GENERATE_VAPI\n");
					dataStream.put_string("\t"+libFilename+"\n");
					dataStream.put_string("GENERATE_HEADER\n");
					dataStream.put_string("\t"+libFilename+"\n");
				}

				dataStream.put_string(")\n\n");

				bool hasCFiles=false;
				foreach(var module in this._cSources) {
					hasCFiles=true;
					printConditions.printCondition(module.condition,module.invertCondition);
					dataStream.put_string("set (VALA_C ${VALA_C} %s)\n".printf(module.elementName));
				}
				printConditions.printTail();
				if (hasCFiles) {
					dataStream.put_string("\n");
				}

				foreach (var resource in this._resources) {
					//dataStream.put_string("add_dependencies (%s %s)\n".printf(libFilename,resource.elementName));
					dataStream.put_string("SET (VALA_C ${VALA_C} ${%s_C_FILE})\n".printf(resource.elementName));
				}

				if (this._type == ConfigType.VALA_LIBRARY) {
					dataStream.put_string("add_library("+libFilename+" SHARED ${VALA_C})\n\n");
					foreach (var resource in this._resources) {
						this.has_dependencies = true;
						dataStream.put_string("set ( %s_DEPENDENCIES ${%s_DEPENDENCIES} %s )\n".printf(libFilename, libFilename, resource.elementName));
						//dataStream.put_string("SET (VALA_C ${VALA_C} ${%s_C_FILE})\n".printf(resource.elementName));
					}

					this.add_other_dependencies(dataStream, printConditions, libFilename);

					foreach (var element in this._link_libraries) {
						printConditions.printCondition(element.condition, element.invertCondition);
						dataStream.put_string("target_link_libraries( "+libFilename+" "+element.elementName+" )\n");
					}
					printConditions.printTail();

					// Set library version number
					dataStream.put_string("set_target_properties( "+libFilename+" PROPERTIES\n");
					dataStream.put_string("VERSION\n");
					dataStream.put_string("\t"+this.version+"\n");
					dataStream.put_string("SOVERSION\n");
					dataStream.put_string("\t"+this.version.split(".")[0]+" )\n\n");

					// Install library
					bool cond_dest = false;
						if (this._destination.size != 0) {
							cond_dest = true;
						foreach(var element in this._destination) {
							printConditions.printCondition(element.condition, element.invertCondition);
							dataStream.put_string("set (INSTALL_LIBRARY_%s \"%s\" )\n".printf(libFilename,element.elementName));
							dataStream.put_string("set (INSTALL_INCLUDE_%s \"%s\" )\n".printf(libFilename,element.elementName));
							dataStream.put_string("set (INSTALL_VAPI_%s \"%s\" )\n".printf(libFilename,element.elementName));
							dataStream.put_string("set (INSTALL_GIR_%s \"%s\" )\n".printf(libFilename,element.elementName));
							dataStream.put_string("set (INSTALL_PKGCONFIG_%s \"%s\" )\n".printf(libFilename,element.elementName));
						}
						printConditions.printTail();
					}

					dataStream.put_string("\ninstall(TARGETS\n");
					dataStream.put_string("\t"+libFilename+"\n");
					dataStream.put_string("LIBRARY DESTINATION\n");

					if (cond_dest) {
						dataStream.put_string("\t${INSTALL_LIBRARY_%s}/\n)\n".printf(libFilename));
					} else {
						dataStream.put_string("\t${CMAKE_INSTALL_LIBDIR}/\n)\n");
					}

					// Install headers
					dataStream.put_string("install(FILES\n");
					dataStream.put_string("\t${CMAKE_CURRENT_BINARY_DIR}/"+libFilename+".h\n");
					dataStream.put_string("DESTINATION\n");
					if (cond_dest) {
						dataStream.put_string("\t${INSTALL_INCLUDE_%s}/\n)\n".printf(libFilename));
					} else {
						dataStream.put_string("\t${CMAKE_INSTALL_INCLUDEDIR}/\n)\n");
					}

					// Install VAPI
					dataStream.put_string("install(FILES\n");
					dataStream.put_string("\t${CMAKE_CURRENT_BINARY_DIR}/"+libFilename+".vapi\n");
					dataStream.put_string("DESTINATION\n");
					if (cond_dest) {
						dataStream.put_string("\t${INSTALL_VAPI_%s}/\n)\n".printf(libFilename));
					} else {
						dataStream.put_string("\t${CMAKE_INSTALL_DATAROOTDIR}/vala/vapi/\n)\n");
					}

					// Install DEPS
					dataStream.put_string("install(FILES\n");
					dataStream.put_string("\t${CMAKE_CURRENT_BINARY_DIR}/"+libFilename+".deps\n");
					dataStream.put_string("DESTINATION\n");
					if (cond_dest) {
						dataStream.put_string("\t${INSTALL_VAPI_%s}/\n)\n".printf(libFilename));
					} else {
						dataStream.put_string("\t${CMAKE_INSTALL_DATAROOTDIR}/vala/vapi/\n)\n");
					}

					// Install GIR
					if (girFilename!="") {
						dataStream.put_string("install(FILES\n");
						dataStream.put_string("\t${CMAKE_CURRENT_BINARY_DIR}/"+girFilename+"\n");
						dataStream.put_string("DESTINATION\n");
						if (cond_dest) {
							dataStream.put_string("\t${INSTALL_GIR_%s}/\n)\n".printf(libFilename));
						} else {
							dataStream.put_string("\t${CMAKE_INSTALL_DATAROOTDIR}/gir-1.0/\n)\n");
						}
					}

					// Install PC
					dataStream.put_string("install(FILES\n");
					dataStream.put_string("\t${CMAKE_CURRENT_BINARY_DIR}/"+pcFilename+"\n");
					dataStream.put_string("DESTINATION\n");
					if (cond_dest) {
						dataStream.put_string("\t${INSTALL_PKGCONFIG_%s}/\n)\n".printf(libFilename));
					} else {
						dataStream.put_string("\t${CMAKE_INSTALL_LIBDIR}/pkgconfig/\n)\n");
					}

				} else {
					// Install executable
					dataStream.put_string("add_executable("+libFilename+" ${VALA_C})\n");
					foreach (var resource in this._resources) {
						this.has_dependencies = true;
						dataStream.put_string("set ( %s_DEPENDENCIES ${%s_DEPENDENCIES} %s )\n".printf(libFilename, libFilename, resource.elementName));
					}

					this.add_other_dependencies(dataStream, printConditions, libFilename);

					foreach (var element in this._link_libraries) {
						printConditions.printCondition(element.condition, element.invertCondition);
						dataStream.put_string("target_link_libraries( "+libFilename+" "+element.elementName+" )\n");
					}
					printConditions.printTail();
					dataStream.put_string("\n");
					bool cond_dest = false;
					if (this._destination.size != 0) {
						cond_dest = true;
						foreach(var element in this._destination) {
							printConditions.printCondition(element.condition, element.invertCondition);
							dataStream.put_string("set (INSTALL_BINARYPATH_%s \"%s\" )\n".printf(libFilename,element.elementName));
						}
						printConditions.printTail();
					}
					dataStream.put_string("\ninstall(TARGETS\n");
					dataStream.put_string("\t"+libFilename+"\n");
					dataStream.put_string("RUNTIME DESTINATION\n");
					if (cond_dest) {
						dataStream.put_string("\t${INSTALL_BINARYPATH_%s}\n)\n\n".printf(libFilename));
					} else {
						dataStream.put_string("\t${CMAKE_INSTALL_BINDIR}\n)\n");
					}

					foreach(var alias in this._aliases) {
						printConditions.printCondition(alias.condition, alias.invertCondition);
						dataStream.put_string("if (INSTALL_BINARYPATH_%s)\n".printf(libFilename));
						dataStream.put_string("\tset(ALIAS_DESTINATION_PATH ${INSTALL_BINARYPATH_%s})\n".printf(libFilename));
						dataStream.put_string("else()\n");
						dataStream.put_string("\tset(ALIAS_DESTINATION_PATH ${CMAKE_INSTALL_BINDIR})\n");
						dataStream.put_string("endif()\n");
						dataStream.put_string("install(CODE \"execute_process(COMMAND ln -sf %s \\$ENV{DESTDIR}/${PREFIX}/${ALIAS_DESTINATION_PATH}/%s )\")\n".printf(this.name, alias.elementName));
					}
					printConditions.printTail();
				}

				// unitary tests
				if (this._unitests.size != 0) {
					dataStream.put_string("set (COMPILE_OPTIONS_UTEST ${COMPILE_OPTIONS} -D UNITEST)\n\n");
					foreach (var unitest in this._unitests) {
						dataStream.put_string("set (APP_SOURCES_%d ${APP_SOURCES} %s)\n".printf(ElementValaBinary.counter,unitest.elementName));
						dataStream.put_string("vala_precompile(VALA_C_%d %s\n".printf(ElementValaBinary.counter,libFilename));
						dataStream.put_string("\t${APP_SOURCES_%d}\n".printf(ElementValaBinary.counter));
						dataStream.put_string("PACKAGES\n");
						dataStream.put_string("\t${VALA_PACKAGES}\n");
						if (has_custom_VAPIs) {
							dataStream.put_string("CUSTOM_VAPIS\n");
							dataStream.put_string("\t${CUSTOM_VAPIS_LIST}\n");
						}

						dataStream.put_string("OPTIONS\n");
						dataStream.put_string("\t${COMPILE_OPTIONS_UTEST}\n");

						dataStream.put_string("DIRECTORY\n");
						dataStream.put_string("\t${CMAKE_CURRENT_BINARY_DIR}/unitests/test%d\n".printf(ElementValaBinary.counter));

						dataStream.put_string(")\n\n");
						dataStream.put_string("add_executable( test%d ${VALA_C_%d})\n".printf(ElementValaBinary.counter,ElementValaBinary.counter));
						foreach (var element in this._link_libraries) {
							printConditions.printCondition(element.condition, element.invertCondition);
							dataStream.put_string("target_link_libraries( test%d %s)\n".printf(ElementValaBinary.counter,element.elementName));
						}
						printConditions.printTail();
						dataStream.put_string("add_test(NAME test%d COMMAND test%d)\n".printf(ElementValaBinary.counter,ElementValaBinary.counter));
						dataStream.put_string("\n");
						ElementValaBinary.counter++;
					}
				}

				dataStream.put_string("if(HAVE_VALADOC)\n");
				dataStream.put_string("\tvaladoc("+libFilename+"\n");
				dataStream.put_string("\t\t${CMAKE_BINARY_DIR}/"+Path.build_filename("valadoc",libFilename)+"\n");
				dataStream.put_string("\t\t${APP_SOURCES}\n");
				dataStream.put_string("\tPACKAGES\n");
				dataStream.put_string("\t\t${VALA_PACKAGES}\n");
				dataStream.put_string("\tCUSTOM_VAPIS\n");
				dataStream.put_string("\t\t${CUSTOM_VAPIS_LIST}\n");
				dataStream.put_string("\t)\n");

				dataStream.put_string("\tinstall(DIRECTORY\n");
				dataStream.put_string("\t\t${CMAKE_BINARY_DIR}/valadoc\n");
				dataStream.put_string("\tDESTINATION\n");
				dataStream.put_string("\t\t"+Path.build_filename("${CMAKE_INSTALL_DATAROOTDIR}/doc",ElementBase.globalData.projectName)+"\n");
				dataStream.put_string("\t)\n");
				dataStream.put_string("endif()\n");
			} catch (GLib.Error e) {
				ElementBase.globalData.addError(_("Failed to write the CMakeLists file for binary %s").printf(libFilename));
				return true;
			}
			return false;
		}

		private void add_other_dependencies(DataOutputStream dataStream, ConditionalText printConditions, string libFilename) {

			foreach(var dependency in this._packages) {
				if (dependency.type != packageType.LOCAL) {
					continue;
				}
				this.has_dependencies = true;
				printConditions.printCondition(dependency.condition, dependency.invertCondition);
				dataStream.put_string("set ( %s_DEPENDENCIES ${%s_DEPENDENCIES} %s )\n".printf(libFilename, libFilename, dependency.elementName));
			}
			printConditions.printTail();
			if (this.has_dependencies) {
				dataStream.put_string("add_dependencies( %s ${%s_DEPENDENCIES} )\n".printf(libFilename, libFilename));
			}
		}

		public override bool storeConfig(DataOutputStream dataStream, ConditionalText printConditions) {

			if (this._type == ConfigType.VALA_LIBRARY) {
				this.remove_self_package();
			}

			try {
				if (this._automatic) {
					dataStream.put_string("*");
				}
				if (this._type == ConfigType.VALA_BINARY) {
					dataStream.put_string("vala_binary: %s\n".printf(Path.build_filename(this._path,this._name)));
				} else {
					dataStream.put_string("vala_library: %s\n".printf(Path.build_filename(this._path,this._name)));
				}
				if (this.versionSet) {
					if (this.versionAutomatic) {
						dataStream.put_string("*");
					}
					dataStream.put_string("version: %s\n".printf(this.version));
				} else {
					dataStream.put_string("*version: %s\n".printf(ElementBase.globalData.global_version));
				}
				if ((this._currentNamespace!=null) && (this._type==ConfigType.VALA_LIBRARY)) {
					if (this.namespaceAutomatic) {
						dataStream.put_string("*");
					}
					dataStream.put_string("namespace: %s\n".printf(this._currentNamespace));
				}

				foreach(var element in this._destination) {
					printConditions.printCondition(element.condition, element.invertCondition);
					if (element.comments != null) {
						foreach(var comment in element.comments) {
							dataStream.put_string("%s\n".printf(comment));
						}
					}
					if (element.automatic) {
						dataStream.put_string("*");
					}
					dataStream.put_string("vala_destination: %s\n".printf(element.elementName));
				}
				printConditions.printTail();

				foreach(var element in this._aliases) {
					printConditions.printCondition(element.condition, element.invertCondition);
					if (element.comments != null) {
						foreach(var comment in element.comments) {
							dataStream.put_string("%s\n".printf(comment));
						}
					}
					if (element.automatic) {
						dataStream.put_string("*");
					}
					dataStream.put_string("alias: %s\n".printf(element.elementName));
				}
				printConditions.printTail();

				foreach(var element in this._compileOptions) {
					printConditions.printCondition(element.condition, element.invertCondition);
					if (element.comments != null) {
						foreach(var comment in element.comments) {
							dataStream.put_string("%s\n".printf(comment));
						}
					}
					if (element.automatic) {
						dataStream.put_string("*");
					}
					dataStream.put_string("compile_options: %s\n".printf(element.elementName));
				}
				printConditions.printTail();

				foreach(var element in this._compileCOptions) {
					printConditions.printCondition(element.condition, element.invertCondition);
					if (element.comments != null) {
						foreach(var comment in element.comments) {
							dataStream.put_string("%s\n".printf(comment));
						}
					}
					if (element.automatic) {
						dataStream.put_string("*");
					}
					dataStream.put_string("compile_c_options: %s\n".printf(element.elementName));
				}
				printConditions.printTail();

				foreach(var element in this._resources) {
					printConditions.printCondition(element.condition, element.invertCondition);
					if (element.comments != null) {
						foreach(var comment in element.comments) {
							dataStream.put_string("%s\n".printf(comment));
						}
					}
					if (element.automatic) {
						dataStream.put_string("*");
					}
					dataStream.put_string("use_gresource: %s\n".printf(element.elementName));
				}
				printConditions.printTail();

				foreach(var element in this._packages) {
					if (element.type == packageType.LOCAL) {
						printConditions.printCondition(element.condition, element.invertCondition);
						if (element.comments != null) {
							foreach(var comment in element.comments) {
								dataStream.put_string("%s\n".printf(comment));
							}
						}
						if (element.automatic) {
							dataStream.put_string("*");
						}
						dataStream.put_string("vala_local_package: %s\n".printf(element.elementName));
					}
				}
				printConditions.printTail();

				foreach(var element in this._vapis) {
					printConditions.printCondition(element.condition, element.invertCondition);
					if (element.comments != null) {
						foreach(var comment in element.comments) {
							dataStream.put_string("%s\n".printf(comment));
						}
					}
					if (element.automatic) {
						dataStream.put_string("*");
					}
					dataStream.put_string("vala_vapi: %s\n".printf(element.elementName));
				}
				printConditions.printTail();

				foreach(var element in this._packages) {
					if (element.type == packageType.C_DO_CHECK) {
						printConditions.printCondition(element.condition, element.invertCondition);
						if (element.comments != null) {
							foreach(var comment in element.comments) {
								dataStream.put_string("%s\n".printf(comment));
							}
						}
						if (element.automatic) {
							dataStream.put_string("*");
						}
						dataStream.put_string("c_check_package: %s\n".printf(element.elementName));
					}
				}
				printConditions.printTail();

				foreach(var element in this._packages) {
					if (element.type == packageType.NO_CHECK) {
						printConditions.printCondition(element.condition, element.invertCondition);
						if (element.comments != null) {
							foreach(var comment in element.comments) {
								dataStream.put_string("%s\n".printf(comment));
							}
						}
						if (element.automatic) {
							dataStream.put_string("*");
						}
						dataStream.put_string("vala_package: %s\n".printf(element.elementName));
					}
				}
				printConditions.printTail();

				foreach(var element in this._packages) {
					if (element.type == packageType.DO_CHECK) {
						printConditions.printCondition(element.condition, element.invertCondition);
						if (element.comments != null) {
							foreach(var comment in element.comments) {
								dataStream.put_string("%s\n".printf(comment));
							}
						}
						if (element.automatic) {
							dataStream.put_string("*");
						}
						dataStream.put_string("vala_check_package: %s\n".printf(element.elementName));
					}
				}
				printConditions.printTail();

				foreach(var element in this._link_libraries) {
					printConditions.printCondition(element.condition, element.invertCondition);
					if (element.comments != null) {
						foreach(var comment in element.comments) {
							dataStream.put_string("%s\n".printf(comment));
						}
					}
					if (element.automatic) {
						dataStream.put_string("*");
					}
					dataStream.put_string("c_library: %s\n".printf(element.elementName));
				}
				printConditions.printTail();

				foreach(var element in this._sources) {
					printConditions.printCondition(element.condition, element.invertCondition);
					if (element.comments != null) {
						foreach(var comment in element.comments) {
							dataStream.put_string("%s\n".printf(comment));
						}
					}
					if (element.automatic) {
						dataStream.put_string("*");
					}
					dataStream.put_string("vala_source: %s\n".printf(element.elementName));
				}
				printConditions.printTail();

				foreach(var element in this._unitests) {
					printConditions.printCondition(element.condition, element.invertCondition);
					if (element.comments != null) {
						foreach(var comment in element.comments) {
							dataStream.put_string("%s\n".printf(comment));
						}
					}
					if (element.automatic) {
						dataStream.put_string("*");
					}
					dataStream.put_string("unitest: %s\n".printf(element.elementName));
				}
				printConditions.printTail();

				foreach(var element in this._dbusElements) {
					printConditions.printCondition(element.condition, element.invertCondition);
					if (element.comments != null) {
						foreach(var comment in element.comments) {
							dataStream.put_string("%s\n".printf(comment));
						}
					}
					if (element.automatic) {
						dataStream.put_string("*");
					}
					dataStream.put_string("dbus_interface: %s %s %s %s\n".printf(element.elementName,element.obj,element.systemBus ? "system" : "session", element.GDBus ? "gdbus" : "dbus-glib"));
				}
				printConditions.printTail();

				foreach(var element in this._cSources) {
					printConditions.printCondition(element.condition, element.invertCondition);
					if (element.comments != null) {
						foreach(var comment in element.comments) {
							dataStream.put_string("%s\n".printf(comment));
						}
					}
					if (element.automatic) {
						dataStream.put_string("*");
					}
					dataStream.put_string("c_source: %s\n".printf(element.elementName));
				}
				printConditions.printTail();

				foreach(var element in this._hFolders) {
					printConditions.printCondition(element.condition, element.invertCondition);
					if (element.comments != null) {
						foreach(var comment in element.comments) {
							dataStream.put_string("%s\n".printf(comment));
						}
					}
					if (element.automatic) {
						dataStream.put_string("*");
					}
					dataStream.put_string("h_folder: %s\n".printf(element.elementName));
				}
				printConditions.printTail();
				dataStream.put_string("\n");
			} catch (GLib.Error e) {
				ElementBase.globalData.addError(_("Failed to store ': %s' at config").printf(this.fullPath));
				return true;
			}
			return false;
		}

/* Not needed
		public string[]? getSubFiles() {
			string[] subFileList = {};
			foreach (var element in this._sources) {
				subFileList += element.elementName;
			}
			return subFileList;
		}

*/

/* Not needed
		public string[]? getCSubFiles() {
			string[] subFileList = {};
			foreach (var element in this._cSources) {
				subFileList += element.elementName;
			}
			return subFileList;
		}
*/
	}
}
