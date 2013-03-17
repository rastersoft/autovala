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


void help() {

	GLib.stdout.printf("Autovala. Usage:\n");
	GLib.stdout.printf("\tautovala help: shows this help\n");
	GLib.stdout.printf("\tautovala init project_name: initializates a new Vala CMake project and creates an initial project file\n");
	GLib.stdout.printf("\tautovala cmake: creates the CMake files from the project file\n");
	GLib.stdout.printf("\tautovala autobuild: tries to guess the type for each file in the folders and adds them to the project file\n\n");

}


int main(string[] argv) {

	if (argv.length==1) {
		help();
		return 0;
	}

	switch(argv[1]) {
	case "help":
		help();
		break;
	case "init":
		if (argv.length!=3) {
			help();
			return -1;
		}
		var gen = new autovala.manage_project();
		if (gen.init(argv[2])) {
			gen.show_errors();
			GLib.stdout.printf("Aborting\n");
			return -1;
		}
		GLib.stdout.printf("Done\n");
		break;
	case "cmake":
		if (argv.length!=2) {
			help();
			return -1;
		}
		var gen = new autovala.manage_project();
		if (gen.cmake()) {
			gen.show_errors();
			GLib.stdout.printf("Aborting\n");
			return -1;
		}
		GLib.stdout.printf("Done\n");
		break;
	default:
		help();
		return -1;
	}
	return 0;
}
