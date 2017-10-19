/*
 Copyright 2013-2017 (C) Raster Software Vigo (Sergio Costas)

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

//project version = 1.1.2

void help() {

	GLib.stdout.printf(_("""Autovala. Usage:
	autovala help: shows this help.
	autovala version: shows the current version.
	autovala init project_name: initializates a new Vala CMake project and creates an initial project file.
	autovala ginit project_name: initializates a new Genie CMake project and creates an initial project file.
	autovala refresh: tries to guess the type for each file in the folders and adds them to the project file.
	autovala cmake: creates the CMake files from the project file.
	autovala meson: creates the meson.build files from the project file.
	autovala update: the same than 'refresh' + 'cmake' + 'meson'.
	autovala po: updates translatable strings.
	autovala clear: removes the automatic parts in the project file, leaving only the manual ones.
	autovala project_files: lists all the files belonging to the project (with paths relative to the project's root).
	autovala git: adds to git all the project files.
	autovala deb: creates the 'debian' folder for packaging the project as a .deb package.
	autovala rpm: creates the 'rpmbuild' folder for packaging the project as a .rpm package.
	autovala pacman: creates a package for PACMAN package manager.
	autovala valama: exports the project to a VALAMA project file.
	autovala external owner_id: shows the external data of the specified owner.

"""));
}

#if UNITEST
int main2(string[] argv) {
#else
int main(string[] argv) {
#endif

	Intl.bindtextdomain(Constants.GETTEXT_PACKAGE, Path.build_filename(Constants.DATADIR,"locale"));
	Intl.setlocale (LocaleCategory.ALL, "");
	Intl.textdomain(Constants.GETTEXT_PACKAGE);
	Intl.bind_textdomain_codeset(Constants.GETTEXT_PACKAGE, "utf-8" );

	if (argv.length==1) {
		help();
		return 0;
	}

	bool retval;
	switch(argv[1]) {
	case "help":
		help();
		break;
	case "version":
		GLib.stdout.printf("Autovala version: %s\n".printf(Constants.VERSION));
		break;
	case "init":
	case "ginit":
		if (argv.length!=3) {
			help();
			return -1;
		}
		var gen = new AutoVala.ManageProject();
		retval=gen.init(argv[2], argv[1] == "ginit");
		gen.showErrors();
		if (retval) {
			GLib.stderr.printf(_("Aborting\n"));
			return -1;
		}
		GLib.stderr.printf(_("Done\n"));
		break;
	case "cmake":
		if (argv.length!=2) {
			help();
			return -1;
		}
		var gen = new AutoVala.ManageProject();
		retval=gen.cmake();
		gen.showErrors();
		if (retval) {
			GLib.stderr.printf(_("Aborting\n"));
			return -1;
		}
		GLib.stderr.printf(_("Done\n"));
		break;
	case "meson":
		if (argv.length!=2) {
			help();
			return -1;
		}
		var gen = new AutoVala.ManageProject();
		retval = gen.meson();
		gen.showErrors();
		if (retval) {
			GLib.stderr.printf(_("Aborting\n"));
			return -1;
		}
		GLib.stderr.printf(_("Done\n"));
		break;
	case "project_files":
		if (argv.length!=2) {
			help();
			return -1;
		}
		var gen = new AutoVala.ManageProject();
		var retval2 = gen.get_files();
		if (retval2 == null) {
			gen.showErrors();
			GLib.stderr.printf(_("Aborting\n"));
			return -1;
		}
		foreach(var element in retval2) {
			GLib.stdout.printf("%s\n",element);
		}
		break;
	case "git":
		if (argv.length != 2) {
			help();
			return -1;
		}
		var gen = new AutoVala.ManageProject();
		var retval2 = gen.get_files();
		if (retval2 == null) {
			gen.showErrors();
			GLib.stderr.printf(_("Aborting\n"));
			return -1;
		}
		string[] spawn_env = Environ.get();
		string[] spawn_args = {};
		spawn_args += "git";
		spawn_args += "add";
		foreach(var element in retval2) {
			spawn_args += element;
		}
		string output;
		string errput;
		int errval;
		try {
			GLib.Process.spawn_sync(gen.getProjectPath(),spawn_args,spawn_env,GLib.SpawnFlags.SEARCH_PATH,null, out output, out errput,out errval);
		} catch(Error e) {
			print(_("Failed to launch GIT: %s").printf(e.message));
			return -1;
		}
		if (output != "") {
			print(output+"\n");
		}
		if (errput != "") {
			print(errput+"\n");
		}
		if (errval != 0) {
			return errval;
		}
		GLib.stderr.printf(_("Done\n"));
		break;
	case "update":
		if (argv.length != 2) {
			help();
			return -1;
		}
		var gen = new AutoVala.ManageProject();
		GLib.stdout.printf(_("Updating project file\n"));
		retval = gen.refresh();
		gen.showErrors();
		if (retval) {
			GLib.stderr.printf(_("Aborting\n"));
			return -1;
		}
		GLib.stdout.printf(_("Updating CMake files\n"));
		retval = gen.cmake();
		gen.showErrors();
		GLib.stdout.printf(_("Updating Meson files\n"));
		retval |= gen.meson();
		gen.showErrors();
		if (retval) {
			GLib.stderr.printf(_("Aborting\n"));
			return -1;
		}
		GLib.stderr.printf(_("Done\n"));
		break;
	case "refresh":
		if (argv.length!=2) {
			help();
			return -1;
		}
		var gen = new AutoVala.ManageProject();
		GLib.stdout.printf(_("Updating project file\n"));
		retval=gen.refresh();
		gen.showErrors();
		if (retval) {
			GLib.stderr.printf(_("Aborting\n"));
			return -1;
		}
		GLib.stderr.printf(_("Done\n"));
		break;
	case "po":
		if (argv.length!=2) {
			help();
			return -1;
		}
		var gen = new AutoVala.ManageProject();
		retval=gen.gettext();
		gen.showErrors();
		if (retval) {
			GLib.stderr.printf(_("Aborting\n"));
			return -1;
		}
		GLib.stderr.printf(_("Done\n"));
		break;
	case "clear":
		if (argv.length!=2) {
			help();
			return -1;
		}
		var gen = new AutoVala.ManageProject();
		retval=gen.clear();
		gen.showErrors();
		if (retval) {
			GLib.stderr.printf(_("Aborting\n"));
			return -1;
		}
		GLib.stderr.printf(_("Done\n"));
		break;
	case "deb":
		if (argv.length!=2) {
			help();
			return -1;
		}
		var gen = new AutoVala.ManageProject();
		retval = gen.create_deb(true);
		gen.showErrors();
		if (retval) {
			GLib.stderr.printf(_("Aborting\n"));
			return -1;
		}
		GLib.stderr.printf(_("Done\n"));
		break;
	case "rpm":
		if (argv.length!=2) {
			help();
			return -1;
		}
		var gen = new AutoVala.ManageProject();
		retval = gen.create_rpm(true);
		gen.showErrors();
		if (retval) {
			GLib.stderr.printf(_("Aborting\n"));
			return -1;
		}
		GLib.stderr.printf(_("Done\n"));
		break;
	case "pacman":
		if (argv.length!=2) {
			help();
			return -1;
		}
		var gen = new AutoVala.ManageProject();
		retval = gen.create_pacman(true);
		gen.showErrors();
		if (retval) {
			GLib.stderr.printf(_("Aborting\n"));
			return -1;
		}
		GLib.stderr.printf(_("Done\n"));
		break;
	case "valama":
		if (argv.length!=2) {
			help();
			return -1;
		}
		var gen = new AutoVala.ManageProject();
		var data = gen.get_binaries_list();
		gen.showErrors();
		if (data == null) {
			GLib.stderr.printf(_("Aborting\n"));
			return -1;
		}
		foreach(var element in data.binaries) {
			generate_valama(element,data);
		}
		GLib.stderr.printf(_("Done\n"));
		break;
	case "valamang":
		if (argv.length!=2) {
			help();
			return -1;
		}
		var gen = new AutoVala.ManageProject();
		var data = gen.get_binaries_list();
		gen.showErrors();
		if (data == null) {
			GLib.stderr.printf(_("Aborting\n"));
			return -1;
		}
		generate_valamang(data);
		GLib.stderr.printf(_("Done\n"));
		break;
	case "external":
		if (argv.length!=3) {
			help();
			return -1;
		}
		var gen = new AutoVala.ManageProject();
		var project = gen.get_binaries_list(null,argv[2]);
		foreach(var data in project.external) {
			GLib.stdout.printf("%s: %s\n",argv[2],data);
		}
		break;
	default:
		help();
		return -1;
	}
	return 0;
}

bool generate_valamang(AutoVala.ValaProject ?data) {

    return false;
}

bool generate_valama(AutoVala.PublicBinary element, AutoVala.ValaProject data) {

	var tmpdata = GLib.Path.build_filename(data.projectPath,"valama.tmp",element.name);
	var tmpfile = File.new_for_path(tmpdata);
	if (!tmpfile.query_exists()) {
		try {
			tmpfile.make_directory_with_parents();
		} catch (Error e) {
			GLib.stderr.printf(_("Failed to create the folder %s"),tmpdata);
			return true;
		}
	}
	var constant_file = File.new_for_path(GLib.Path.build_filename(tmpdata,"Config.vala"));
	if (constant_file.query_exists()) {
		try {
			constant_file.delete();
		} catch (Error e) {
			GLib.stderr.printf(_("Failed to delete the old valama Config.vala file at %s"),tmpdata);
			return true;
		}
	}
	try {
		var dis = constant_file.create(FileCreateFlags.NONE);
		var data_stream = new DataOutputStream(dis);
		if ((element.type == AutoVala.ConfigType.VALA_BINARY) || (element.library_namespace == null)) {
			data_stream.put_string("namespace Constants {\n");
		} else {
			data_stream.put_string("namespace %sConstants {\n".printf(element.library_namespace));
		}
		data_stream.put_string("\tpublic const string DATADIR = \"\";\n\tpublic const string PKGDATADIR = \"\";\n\tpublic const string GETTEXT_PACKAGE = \"\";\n\tpublic const string RELEASE_NAME = \"\";\n\tpublic const string VERSION = \"\";\n\tpublic const string TESTSRCDIR = \"\";\n}\n");
	} catch (Error e) {
		GLib.stderr.printf(_("Failed to write to valama Config.vala file at %s"),tmpdata);
		return true;
	}

	var path = GLib.Path.build_filename(data.projectPath,element.name+".vlp");

	Gee.List<string> ui_files = new Gee.ArrayList<string>();
	foreach (var ui_element in data.ui) {
		add_directory(null,ui_element.fullPath,ui_files);
	}

	Gee.List<string> sources = new Gee.ArrayList<string>();
	Gee.List<string> packages = new Gee.ArrayList<string>();
	packages.add("glib-2.0");
	packages.add("gobject-2.0");

	get_data_for_binary(element,data,sources,packages);

	var file=File.new_for_path(path);
	if (file.query_exists()) {
		try {
			file.delete();
		} catch (Error e) {
			GLib.stderr.printf(_("Failed to delete the old valama project file %s"),path);
			return true;
		}
	}

	try {
		var dis = file.create(FileCreateFlags.NONE);
		var data_stream = new DataOutputStream(dis);
		data_stream.put_string("<project version=\"0.1\">\n");
		data_stream.put_string("\t<name>%s</name>\n".printf(element.name));
		data_stream.put_string("\t<buildsystem library=\"%s\">valama</buildsystem>\n".printf(element.type == AutoVala.ConfigType.VALA_LIBRARY ? "true" : "false"));
		data_stream.put_string("\t<version>\n");
		data_stream.put_string("\t\t<major>%d</major>\n".printf(element.major));
		data_stream.put_string("\t\t<minor>%d</minor>\n".printf(element.minor));
		data_stream.put_string("\t\t<patch>%d</patch>\n".printf(element.revision));
		data_stream.put_string("\t</version>\n");
		data_stream.put_string("\t<packages>\n");
		foreach (var p in packages) {
			data_stream.put_string("\t\t<package name=\"%s\"/>\n".printf(p));
		}
		data_stream.put_string("\t</packages>\n");
		data_stream.put_string("\t<source-directories>\n");
		foreach (var folder in sources) {
			data_stream.put_string("\t\t<directory>%s</directory>\n".printf(folder));
		}
		data_stream.put_string("\t</source-directories>\n");
		data_stream.put_string("\t<ui-directories>\n");
		foreach (var folder in ui_files) {
			data_stream.put_string("\t\t<directory>%s</directory>\n".printf(folder));
		}
		data_stream.put_string("\t</ui-directories>\n");
		data_stream.put_string("\t<data-files>\n");
		data_stream.put_string("\t\t<file>%s</file>\n".printf(GLib.Path.get_basename(data.projectFile)));
		data_stream.put_string("\t</data-files>\n");
		data_stream.put_string("</project>\n");
	} catch (Error e) {
		GLib.stderr.printf(_("Failed to write to valama project file %s"),path);
		return true;
	}
	return false;
}

void get_data_for_binary(AutoVala.PublicBinary element, AutoVala.ValaProject data, Gee.List<string> sources, Gee.List<string> packages) {

	foreach (var source in element.sources) {
		add_directory(element.fullPath,source.elementName,sources);
	}
	foreach (var source in element.vapis) {
		add_directory(element.fullPath,source.elementName,sources);
	}
	foreach (var source in element.unitests) {
		add_directory(element.fullPath,source.elementName,sources);
	}
	var constants = GLib.Path.build_filename("valama.tmp",element.name);
	if (sources.index_of(constants) == -1) {
		sources.add(constants);
	}

	foreach (var package in element.packages) {
		if (package.type == AutoVala.packageType.LOCAL) {
			foreach (var subelement in data.binaries) {
				if (subelement.library_namespace == package.elementName) {
					get_data_for_binary(subelement,data,sources,packages);
					break;
				}
			}
			continue;
		}
		if ((package.type != AutoVala.packageType.DO_CHECK) && (package.type != AutoVala.packageType.NO_CHECK)) {
			continue;
		}
		if (packages.index_of(package.elementName) == -1) {
			packages.add(package.elementName);
		}
	}
}

void add_directory(string? base_path,string file_path, Gee.List<string> list) {

	string full_path;
	if (base_path != null) {
		full_path = GLib.Path.build_filename(base_path,file_path);
	} else {
		full_path=file_path;
	}
	var only_path = GLib.Path.get_dirname(full_path);
	if (-1 == list.index_of(only_path)) {
		list.add(only_path);
	}
}
