/*
 Copyright 2016 (C) Raster Software Vigo (Sergio Costas)

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

namespace AutoVala {

	private class GResourceXML : Object {

		private const MarkupParser parser = {
			visit_start,
			visit_end,
			visit_text,
			visit_passthrough,
			error
		};

		private MarkupParseContext context;
		private int depth;

		public string[] files;

		public GResourceXML(string filename) throws MarkupError {
		
		    string line;
		    string text = "";
		
			this.depth = 0;
			this.files = {};

			context = new MarkupParseContext (parser, 0, this, null);

			var file = File.new_for_path(filename);
			if (!file.query_exists ()) {
				throw new MarkupError.PARSE (error_msg (_("File %s for GResource XML doesn't exist"),filename));
			}

			var dis = new DataInputStream (file.read ());

		    while ((line = dis.read_line (null)) != null) {
		    	text += line + "\n";
		    }
			context.parse(text,-1);
		}

		private string error_msg (string msg, ...) {

			va_list va_list = va_list ();
			int line_number;
			int char_number;

			StringBuilder pos = new StringBuilder ();
			foreach (string lst in context.get_element_stack ()) {
				if (pos.len != 0) {
					pos.append_c ('.');
				}
				pos.append (lst);
			}

			context.get_position (out line_number, out char_number);
			return "%s: %d.%d: %s".printf (pos.str, line_number - 1, char_number, msg.vprintf (va_list));
		}

		private void visit_start (MarkupParseContext context, string name, string[] attr_names, string[] attr_values) throws MarkupError {
			
			if (this.depth == 0 && name != "gresources") {
				throw new MarkupError.PARSE (error_msg (_("Ilegal tag <%s>; should be <gresources>"),name));
			}

			if (this.depth == 1 && name != "gresource") {
				throw new MarkupError.PARSE (error_msg (_("Ilegal tag <%s>; should be <gresource>"),name));
			}

			if (this.depth == 2 && name != "file") {
				throw new MarkupError.PARSE (error_msg (_("Ilegal tag <%s>; should be <file>"),name));
			}
			
			this.depth++;
			if (this.depth > 3) {
				throw new MarkupError.PARSE (error_msg (_("GResource XML can't be deeper than 2")));
			}
		}
		
		private void visit_end (MarkupParseContext context, string name) throws MarkupError {
			this.depth--;

			if ((this.depth == 1 && name != "gresource") || (this.depth == 0 && name != "gresources") || (this.depth == 2 && name != "file")) {
				throw new MarkupError.PARSE (error_msg ("Missing element: `/%s'", name));
			}
		}

		private void visit_text (MarkupParseContext context, string text, size_t text_len) throws MarkupError {
			if (this.depth == 3) {
				this.files += text;
			}
		}

		private void visit_passthrough () {
			// process instructions, comments
		}

		private void error (MarkupParseContext context, Error error) {
		}
	}
}
