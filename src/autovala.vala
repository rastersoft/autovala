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

//project version = 0.99.0

void help() {

	GLib.stdout.printf(_("Autovala. Usage:\n\tautovala help: shows this help\n\tautovala version: shows the current version\n\tautovala init project_name: initializates a new Vala CMake project and creates an initial project file\n\tautovala refresh: tries to guess the type for each file in the folders and adds them to the project file\n\tautovala cmake: creates the CMake files from the project file\n\tautovala update: the same than 'refresh'+'cmake'\n\tautovala po: updates translatable strings\n\tautovala clear: removes the automatic parts in the project file, leaving only the manual ones.\n\n"));
}

int main(string[] argv) {

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
		if (argv.length!=3) {
			help();
			return -1;
		}
		var gen = new AutoVala.ManageProject();
		retval=gen.init(argv[2]);
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
	case "project_files":
		if (argv.length!=2) {
			help();
			return -1;
		}
		var gen = new AutoVala.ManageProject();
		var retval2=gen.get_files();
		if (retval2 == null) {
			gen.showErrors();
			GLib.stderr.printf(_("Aborting\n"));
			return -1;
		}
		foreach(var element in retval2) {
			GLib.stdout.printf("%s\n",element);
		}
		break;
	case "update":
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
		} else {
			GLib.stdout.printf(_("Updating CMake files\n"));
			retval=gen.cmake();
			gen.showErrors();
			if (retval) {
				GLib.stderr.printf(_("Aborting\n"));
				return -1;
			}
		}
		GLib.stderr.printf(_("Done\n"));
		break;
	case "refresh":
		if (argv.length!=2) {
			help();
			return -1;
		}
		var gen = new AutoVala.ManageProject();
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
	default:
		help();
		return -1;
	}
	return 0;
}
