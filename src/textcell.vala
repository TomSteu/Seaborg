using Gtk;
using Gdk;

namespace Seaborg {

	// Generic cell for text comments
	public class TextCell : Gtk.Grid, ICell {
		public TextCell(ICellContainer* par) {
			this.name = IdGenerator.get_id();
			parent_cell = par;

			text_scroll = new Gtk.ScrolledWindow(null, null);
			text_scroll.halign = Gtk.Align.FILL;
			text_scroll.hexpand = true;
			text_scroll.vscrollbar_policy = Gtk.PolicyType.NEVER;
			text_scroll.hscrollbar_policy = Gtk.PolicyType.AUTOMATIC;


			hexpand = true;
			halign = Gtk.Align.FILL;
			column_spacing = 4;
			CssProvider css = new CssProvider();
			font_provider = new CssProvider();
			get_style_context().add_provider(css, Gtk.STYLE_PROVIDER_PRIORITY_USER);

			try {

				string font_string = "* { font-size: " + parent_cell->zoom_factor.to_string() + "em; } ";
				css.load_from_path("res/seaborg.css");
				font_provider.load_from_data(font_string, font_string.length);

			} catch(GLib.Error error) {

				css = CssProvider.get_default();
			}

			cell_buffer = new Gtk.SourceBuffer(null);
			cell_buffer.highlight_matching_brackets = true;
			cell = new Gtk.SourceView.with_buffer(cell_buffer);
			cell.show_line_numbers = false;
			cell.highlight_current_line = false;
			cell.auto_indent = true;
			cell.indent_on_tab = true;
			cell.tab_width = 3;
			cell.insert_spaces_instead_of_tabs = false;
			cell.smart_backspace = true;
			cell.show_line_marks = false;
			cell.wrap_mode = Parameter.wrap_mode;
			cell.monospace = false;
			cell.editable = true;
			cell.hexpand = true;
			cell.halign = Gtk.Align.FILL;
			cell.left_margin = 0;
			cell.right_margin = 0;
			cell.top_margin = 0;
			cell.bottom_margin = 0;
			cell.button_press_event.connect(untoggle_handler);
			cell.key_press_event.connect(key_handler);
			cell.get_style_context().add_provider(font_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
			cell_buffer.insert_text.connect(insert_handler);
			cell_buffer.add_selection_clipboard(Gtk.Clipboard.get(Gdk.SELECTION_CLIPBOARD));

			Gtk.SourceStyleSchemeManager sm = new Gtk.SourceStyleSchemeManager();
 			sm.search_path = new string[] {"res/sourceview/"};

			if(Parameter.dark_theme) {
				cell_buffer.style_scheme = sm.get_scheme("seaborg-dark");
			} else {
				cell_buffer.style_scheme = sm.get_scheme("seaborg-light");
			}

			search_context = new Gtk.SourceSearchContext(cell_buffer, parent_cell->search_settings);

			marker = new Gtk.ToggleButton();
			marker.can_focus = false;
			marker.get_style_context().add_provider(css, Gtk.STYLE_PROVIDER_PRIORITY_USER);
			marker.get_style_context().add_class("cell-marker");

			attach(marker, 0, 0, 1, 1);
			text_scroll.add(cell);
			attach(text_scroll, 1, 0, 1, 1);

			marker.button_press_event.connect(press_handler);
			show_all();

		}

		public void toggle_all() {
			marker.active = true;

		}

		public void untoggle_all() {
			marker.active = false;
		}

		public bool marker_selected {
			get {return marker.sensitive ? marker.active : false; }
			set { if(marker.sensitive) { marker.active = value; } }
		}

		public uint get_level() {
			return 0;
		}

		public void focus_cell(bool grab_selection = true) {
			cell.grab_focus();
			if(grab_selection)
				recursive_untoggle_all();
			toggle_all();

			// emit signal that cell was toggled
			ICellContainer* par = parent_cell;
			while(par->parent_cell != null) {
				par = par->parent_cell;
			}
			par->cell_focused(cell);
		}

		public void set_text(string _text) {
			cell.buffer.text = _text;
		}

		public string get_text() {
			return cell.buffer.text;
		}

		public void cell_check_resize() {
			cell.check_resize();
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
		public ICellContainer* parent_cell {get; set;}

		public bool search(SearchType type) {
			

			switch (type) {
				
				case SearchType.StartForwards:

					Gtk.TextIter origin, start, end;
					bool has_wrapped_around, res;

					cell_buffer.get_start_iter(out origin);
					res = search_context.forward2(origin, out start, out end, out has_wrapped_around);
					res = res && (!has_wrapped_around);

					if(res) {
						cell_buffer.select_range(start, end);
						focus_cell();
					}

					return res;

				case SearchType.EndBackwards:

					Gtk.TextIter origin, start, end;
					bool has_wrapped_around, res;

					cell_buffer.get_end_iter(out origin);
					res = search_context.backward2(origin, out start, out end, out has_wrapped_around);
					res = res && (!has_wrapped_around);

					if(res) {
						cell_buffer.select_range(start, end);
						focus_cell();
					}

					return res;

				case SearchType.CursorForwards:

					Gtk.TextIter sel_start, sel_end, start, end;
					bool has_wrapped_around, res;

					cell_buffer.get_selection_bounds(out sel_start, out sel_end);
					res = search_context.forward2(sel_end, out start, out end, out has_wrapped_around);
					res = res && (!has_wrapped_around);

					if(res) {
						cell_buffer.select_range(start, end);
						focus_cell();
					}

					return res;

				case SearchType.CursorBackwards:

					Gtk.TextIter sel_start, sel_end, start, end;
					bool has_wrapped_around, res;

					cell_buffer.get_selection_bounds(out sel_start, out sel_end);
					res = search_context.backward2(sel_start, out start, out end, out has_wrapped_around);
					res = res && (!has_wrapped_around);

					if(res) {
						cell_buffer.select_range(start, end);
						focus_cell();
					}

					return res;

			}

			return false;
		}

		public bool do_forward_search(ref bool found_last) {
			if(found_last) {
				return search(SearchType.StartForwards);
			}

			if(cell_buffer.has_selection) {
				found_last = true;
				return search(SearchType.CursorForwards);
			}

			return false;
		}

		public bool do_backward_search(ref bool found_last) {
			if(found_last) {
				return search(SearchType.EndBackwards);
			}

			if(cell_buffer.has_selection) {
				found_last = true;
				return search(SearchType.CursorBackwards);
			}

			return false;
		}

		private bool press_handler(EventButton event) {

			if(event.type == Gdk.EventType.BUTTON_PRESS && event.button == 3) {
				ContextMenu context = new ContextMenu(this);
				context.popup_at_widget(marker, Gdk.Gravity.CENTER, Gdk.Gravity.WEST, null);
			}

			return false;
		}

		private bool key_handler(EventKey key) {

			if(key.type == Gdk.EventType.KEY_PRESS && key.keyval == Gdk.Key.Escape && !(key.state == (key.state | Gdk.ModifierType.CONTROL_MASK))) {
				cell.buffer.insert_at_cursor("⋮", "⋮".length);
				TextIter iter;
				int pos = cell.buffer.get_char_count() -  cell.buffer.cursor_position;
				replace_characters(ref cell_buffer);
				cell.buffer.get_iter_at_offset(out iter, cell.buffer.get_char_count() - pos);
				cell.buffer.place_cursor(iter);

			}

			if(key.type == Gdk.EventType.KEY_PRESS && (bool)(key.state & Gdk.ModifierType.CONTROL_MASK)) {
				
				bool grab_selection = !(bool)(key.state & Gdk.ModifierType.SHIFT_MASK);

				switch (key.keyval) {
					case Gdk.Key.Up:
						if(parent != null)
							parent_cell->prev_cell(this.name, grab_selection);
						break;
					case Gdk.Key.Down:
						if(parent != null)
							parent_cell->next_cell(this.name, grab_selection);
						break;
					case Gdk.Key.m:
						ContextMenu context = new ContextMenu(this);
						context.popup_at_widget(marker, Gdk.Gravity.CENTER, Gdk.Gravity.WEST, null);
						context.grab_focus();
						break;
				}				
			}

			return false;
		}

		public void replace_all(string rep) {

			try {
				search_context.replace_all(rep, rep.length);
			} catch (GLib.Error err) {}

		}

		public string get_tree_title() {
			return "Text Cell";
		}

		public void set_wrap_mode(Gtk.WrapMode wrap) {
			cell.wrap_mode = wrap;
		}

		public string cell_checksum() {
			return GLib.Checksum.compute_for_string(GLib.ChecksumType.SHA256, cell_buffer.text);
		}

		public ICell* first_cell() { return this; }
		public ICell* last_cell() { return this; }

		public bool cell_expanded { get { return true; } }
		private Gtk.ScrolledWindow text_scroll;
		private Gtk.SourceView cell;
		private Gtk.SourceBuffer cell_buffer;
		private Gtk.SourceSearchContext search_context;
		private Gtk.ToggleButton marker;
		private Gtk.CssProvider font_provider;
	}

}