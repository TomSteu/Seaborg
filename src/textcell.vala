using Gtk;
using Gdk;

namespace Seaborg {

	// Generic Cell for text comments
	public class TextCell : Gtk.Grid, ICell {
		public TextCell(ICellContainer* par) {
			this.name = IdGenerator.get_id();
			Parent = par;
			column_spacing = 4;
			CssProvider css = new CssProvider();
			font_provider = new CssProvider();
			get_style_context().add_provider(css, Gtk.STYLE_PROVIDER_PRIORITY_USER);

			try {

				string font_string = "* { font-size: " + Parent->zoom_factor.to_string() + "em; } ";
				css.load_from_path("res/seaborg.css");
				font_provider.load_from_data(font_string, font_string.length);

			} catch(GLib.Error error) {

				css = CssProvider.get_default();
			}

			CellBuffer = new Gtk.SourceBuffer(null);
			CellBuffer.highlight_matching_brackets = true;
			Cell = new Gtk.SourceView.with_buffer(CellBuffer);
			Cell.show_line_numbers = false;
			Cell.highlight_current_line = false;
			Cell.auto_indent = true;
			Cell.indent_on_tab = true;
			Cell.tab_width = 3;
			Cell.insert_spaces_instead_of_tabs = false;
			Cell.smart_backspace = true;
			Cell.show_line_marks = false;
			Cell.wrap_mode = Gtk.WrapMode.WORD_CHAR;
			Cell.monospace = false;
			Cell.editable = true;
			Cell.hexpand = true;
			Cell.halign = Gtk.Align.FILL;
			Cell.left_margin = 0;
			Cell.right_margin = 0;
			Cell.top_margin = 0;
			Cell.bottom_margin = 0;
			Cell.button_press_event.connect(untoggle_handler);
			Cell.key_press_event.connect(insert_ellipsis);
			Cell.get_style_context().add_provider(font_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
			CellBuffer.insert_text.connect(insert_handler);
			CellBuffer.add_selection_clipboard(Gtk.Clipboard.get(Gdk.SELECTION_CLIPBOARD));

			search_context = new Gtk.SourceSearchContext(CellBuffer, Parent->search_settings);

			Marker = new Gtk.ToggleButton();
			Marker.can_focus = false;
			Marker.get_style_context().add_provider(css, Gtk.STYLE_PROVIDER_PRIORITY_USER);
			Marker.get_style_context().add_class("cell-marker");

			attach(Marker, 0, 0, 1, 1);
			attach(Cell, 1, 0, 1, 1);

			Marker.button_press_event.connect(press_handler);
			show_all();

		}

		public void toggle_all() {
			Marker.active = true;

		}

		public void untoggle_all() {
			Marker.active = false;
		}

		public bool marker_selected() {
			return Marker.sensitive ? Marker.active : false;
		}

		public uint get_level() {
			return 0;
		}

		public void focus_cell() {
			Cell.grab_focus();
		}

		public void set_text(string _text) {
			Cell.buffer.text = _text;
		}

		public string get_text() {
			return Cell.buffer.text;
		}

		public void cell_check_resize() {
			Cell.check_resize();
		}

		public void zoom_font(double factor) {
			string zoom_string = "* { font-size: " + factor.to_string() + "em; }";
			try {
				font_provider.load_from_data(zoom_string, zoom_string.length);
			} catch (GLib.Error err) {}
		}

		public void remove_recursively() {}
		public void collapse_all() {}
		public void expand_all() {}
		public bool lock {
			set {}
			get {return false;}
		}
		public void add_before(int pos, ICell[] list) {}
		public void remove_from(int pos, int number, bool trash) {}
		public ICellContainer* Parent {get; set;}

		public bool search(SearchType type) {
			

			switch (type) {
				
				case SearchType.StartForwards:

					Gtk.TextIter origin, start, end;
					bool has_wrapped_around, res;

					CellBuffer.get_start_iter(out origin);
					res = search_context.forward2(origin, out start, out end, out has_wrapped_around);
					res = res && (!has_wrapped_around);

					if(res) {
						CellBuffer.select_range(start, end);
						focus_cell();
					}

					return res;

				case SearchType.EndBackwards:

					Gtk.TextIter origin, start, end;
					bool has_wrapped_around, res;

					CellBuffer.get_end_iter(out origin);
					res = search_context.backward2(origin, out start, out end, out has_wrapped_around);
					res = res && (!has_wrapped_around);

					if(res) {
						CellBuffer.select_range(start, end);
						focus_cell();
					}

					return res;

				case SearchType.CursorForwards:

					Gtk.TextIter origin, start, end;
					bool has_wrapped_around, res;

					CellBuffer.get_iter_at_mark(out origin, CellBuffer.get_insert());
					res = search_context.forward2(origin, out start, out end, out has_wrapped_around);
					res = res && (!has_wrapped_around);

					if(res) {
						CellBuffer.select_range(start, end);
						focus_cell();
					}

					return res;

				case SearchType.CursorBackwards:

					Gtk.TextIter origin, start, end;
					bool has_wrapped_around, res;

					CellBuffer.get_iter_at_mark(out origin, CellBuffer.get_insert());
					res = search_context.backward2(origin, out start, out end, out has_wrapped_around);
					res = res && (!has_wrapped_around);

					if(res) {
						CellBuffer.select_range(start, end);
						focus_cell();
					}

					return res;

			}

			return false;
		}

		private bool press_handler(EventButton event) {

			if(event.type == Gdk.EventType.BUTTON_PRESS && event.button == 3) {
				ContextMenu context = new ContextMenu(this);
				context.popup_at_widget(Marker, Gdk.Gravity.CENTER, Gdk.Gravity.WEST, null);
			}

			return false;
		}

		private bool insert_ellipsis(EventKey key) {

			if(key.type == Gdk.EventType.KEY_PRESS && key.keyval == Gdk.Key.Escape) {
				Cell.buffer.insert_at_cursor("⋮", "⋮".length);
				TextIter iter;
				int pos = Cell.buffer.get_char_count() -  Cell.buffer.cursor_position;
				set_text(replace_characters(get_text()));
				Cell.buffer.get_iter_at_offset(out iter, Cell.buffer.get_char_count() - pos);
				Cell.buffer.place_cursor(iter);

			}

			return false;
		}

		public void replace_all(string rep) {

			try {
				search_context.replace_all(rep, rep.length);
			} catch (GLib.Error err) {}

		}

		private Gtk.SourceView Cell;
		private Gtk.SourceBuffer CellBuffer;
		private Gtk.SourceSearchContext search_context;
		private Gtk.ToggleButton Marker;
		private Gtk.CssProvider font_provider;
	}

}