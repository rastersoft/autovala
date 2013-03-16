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


int main(string[] argv) {

	var tmp=new autovala.configuration();

	bool retval;

	if (argv.length>1) {
		retval=tmp.read_configuration(argv[1]);
	} else {
		retval=tmp.read_configuration();
	}

	if(retval) {
		GLib.stdout.printf("Incorrecto:\n");
		foreach (var v in tmp.error_list) {
			GLib.stdout.printf("\t"+v+"\n");
		}
	} else {
		GLib.stdout.printf("Correcto\n");
		tmp.list_all();
	
		var tmp2=new autovala.cmake(tmp);

		retval=tmp2.create_cmake();

		if(retval==false) {
			GLib.stdout.printf("Correcto\n");
		} else {
			GLib.stdout.printf("Incorrecto\n");
		}
	}
	return 0;
}
