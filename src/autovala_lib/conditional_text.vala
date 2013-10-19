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

// project version=0.24

namespace AutoVala {

	class conditional_text: GLib.Object {

		string? current_condition;
		bool inverted_condition;
		DataOutputStream data_stream;
		bool cmake_format;

		public conditional_text(DataOutputStream stream,bool cmake) {
			this.data_stream=stream;
			this.cmake_format=cmake;
			this.reset();
		}

		public void reset() {
			this.current_condition=null;
			inverted_condition=false;
		}

		public void print_condition(string? condition, bool inverted) {
			if (condition==this.current_condition) {
				if ((condition!=null) && (inverted!=this.inverted_condition)) {
					if (this.cmake_format) {
						this.data_stream.put_string("ELSE()\n");
					} else {
						this.data_stream.put_string("else\n");
					}
					this.inverted_condition=inverted;
				}
			} else {
				this.inverted_condition=false;
				if(this.current_condition!=null) {
					if (this.cmake_format) {
						this.data_stream.put_string("ENDIF()\n");
					} else {
						this.data_stream.put_string("endif\n");
					}
				}
				if(condition!=null) {
					if (inverted==false) {
						if (this.cmake_format) {
							this.data_stream.put_string("IF (%s)\n".printf(condition));
						} else {
							this.data_stream.put_string("if %s\n".printf(condition));
						}
					} else {
						if (this.cmake_format) {
							this.data_stream.put_string("IF (NOT(%s))\n".printf(condition));
						} else {
							this.data_stream.put_string("if %s\nelse\n".printf(condition));
						}
						this.inverted_condition=true;
					}
				}
				this.current_condition=condition;
			}
		}

		public void print_tail() {
			if (this.current_condition!=null) {
				if (this.cmake_format) {
					this.data_stream.put_string("ENDIF()\n\n");
				} else {
					this.data_stream.put_string("endif\n");
				}
			}
			this.reset();
		}
	}
}
