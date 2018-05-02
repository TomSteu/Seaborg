using Gtk;
using Gdk;

namespace Seaborg {

	// Generic cell for evaluation
	public class EvaluationCell : Gtk.Grid, ICell {
		
		public EvaluationCell(ICellContainer* par) {
			this.name = IdGenerator.get_id();
			parent_cell = par;

			hexpand = true;
			halign = Gtk.Align.FILL;
			column_spacing = 4;
			css = new CssProvider();
			font_provider = new CssProvider();
			this.get_style_context().add_provider(css, Gtk.STYLE_PROVIDER_PRIORITY_USER);
			_lock = false;

			try {

				string font_string = "* { font-size: " + parent_cell->zoom_factor.to_string() + "em; }";
				font_provider.load_from_data(font_string, font_string.length);
				css.load_from_path("res/seaborg.css");

			} catch(GLib.Error error) {

				css = CssProvider.get_default();
			}

			Gtk.SourceLanguageManager lm = new Gtk.SourceLanguageManager();
			Gtk.SourceStyleSchemeManager sm = new Gtk.SourceStyleSchemeManager();
 			lm.search_path = new string[] {"res/sourceview/"};
 			sm.search_path = new string[] {"res/sourceview/"};
			
 			

 			input_buffer = new Gtk.SourceBuffer(null);
			input_buffer.highlight_matching_brackets = true;	

			input_cell = new Gtk.SourceView.with_buffer(input_buffer);
			input_cell.show_line_numbers = false;
			input_cell.highlight_current_line = false;
			input_cell.auto_indent = true;
			input_cell.indent_on_tab = true;
			input_cell.tab_width = 3;
			input_cell.insert_spaces_instead_of_tabs = false;
			input_cell.smart_backspace = true;
			input_cell.show_line_marks = false;
			input_cell.wrap_mode = Parameter.wrap_mode;
			input_cell.monospace = true;
			input_cell.editable = true;
			input_cell.hexpand = true;
			input_cell.halign = Gtk.Align.FILL;
			input_cell.left_margin = 0;
			input_cell.right_margin = 0;
			input_cell.top_margin = 0;
			input_cell.bottom_margin = 0;
			input_cell.button_press_event.connect(untoggle_handler);
			input_cell.key_press_event.connect(key_handler);
			input_cell.get_style_context().add_provider(font_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
			input_buffer.insert_text.connect(insert_handler);
			input_buffer.add_selection_clipboard(Gtk.Clipboard.get(Gdk.SELECTION_CLIPBOARD));

			input_search_context = new Gtk.SourceSearchContext(input_buffer, parent_cell->search_settings);

			

			output_buffer = new Gtk.SourceBuffer(null);
			output_buffer.highlight_matching_brackets = true;
			output_buffer.add_selection_clipboard(Gtk.Clipboard.get(Gdk.SELECTION_CLIPBOARD));
			output_buffer.max_undo_levels = 0;

			output_cell = new Gtk.SourceView.with_buffer(output_buffer);
			output_cell.show_line_numbers = false;
			output_cell.highlight_current_line = false;
			output_cell.auto_indent = true;
			output_cell.indent_on_tab = true;
			output_cell.tab_width = 3;
			output_cell.insert_spaces_instead_of_tabs = false;
			output_cell.smart_backspace = true;
			output_cell.show_line_marks = false;
			output_cell.wrap_mode = Parameter.wrap_mode;
			output_cell.monospace = true;
			output_cell.editable = false;
			output_cell.hexpand = true;
			output_cell.halign = Gtk.Align.FILL;
			output_cell.left_margin = 0;
			output_cell.right_margin = 0;
			output_cell.top_margin = 0;
			output_cell.bottom_margin = 0;
			output_cell.button_press_event.connect(untoggle_handler);
			output_cell.key_press_event.connect(output_key_handler);
			output_cell.get_style_context().add_provider(font_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);

			if(Parameter.dark_theme) {
				input_buffer.style_scheme = sm.get_scheme("seaborg-dark");
				output_buffer.style_scheme = sm.get_scheme("seaborg-dark");
			} else {
				input_buffer.style_scheme = sm.get_scheme("seaborg-light");
				output_buffer.style_scheme = sm.get_scheme("seaborg-light");
			}
			
			if(Parameter.code_highlighting != Highlighting.NONE) {
				
				if(Parameter.code_highlighting == Highlighting.FULL) {
					input_buffer.language =  lm.get_language("wolfram");
					output_buffer.language =  lm.get_language("wolfram");
				}

				if(Parameter.code_highlighting == Highlighting.NOSTDLIB) {
					input_buffer.language =  lm.get_language("wolfram-nostdlib");
					output_buffer.language =  lm.get_language("wolfram-nostdlib");
				}
			}

			

			output_search_context = new Gtk.SourceSearchContext(output_buffer, parent_cell->search_settings);


			marker = new Gtk.ToggleButton();
			marker.can_focus = false;
			var style_context = marker.get_style_context();
			style_context.add_provider(css, Gtk.STYLE_PROVIDER_PRIORITY_USER);
			style_context.add_class("cell-marker");
			this.get_style_context().add_class("cell-grid");

			attach(marker, 0, 0, 1, 1);
			attach(input_cell, 1, 0, 1, 1);

			isExpanded = false;

			marker.button_press_event.connect(press_handler);
			show_all();

		}

		public void toggle_all() {

				marker.active = true;
		}

		public void untoggle_all() {

				marker.active = false;
		}

		public void collapse_all() {
			if(isExpanded) {
				remove_row(1);
				isExpanded = false;
				show_all();
			}
		}

		public uint get_level() {
			return 0;
		}

		public void expand_all() {
			if(!isExpanded) {
				remove_row(0);
				attach(input_cell, 1, 0, 1, 1);
				attach(output_cell, 1, 1, 1, 1);
				attach(marker, 0, 0, 1, 2);
				isExpanded = true;
				show_all();
			}
		}

		public bool lock {
			get {return _lock;}
			set {

				if(value == _lock)
					return;

				input_cell.editable = !value;
				if(value) {
					marker.get_style_context().add_class("locked-cell-marker");
					marker.get_style_context().remove_class("cell-marker");
				} else {
					marker.get_style_context().add_class("cell-marker");
					marker.get_style_context().remove_class("locked-cell-marker");
				} 
					
				_lock = value;
			}
		}

		public bool marker_selected {

			get { return marker.active; }
			set { marker.active = value; } 
		}

		public void focus_cell(bool grab_selection = true) {
			
			input_cell.grab_focus();
			if(grab_selection)
				recursive_untoggle_all();
			toggle_all();
			
			// emit signal that cell was toggled
			ICellContainer* par = parent_cell;
			while(par->parent_cell != null) {
				par = par->parent_cell;
			}
			par->cell_focused(input_cell);
		}

		public void remove_recursively() {}

		public void add_before(int pos, ICell[] list) {}
		public void remove_from(int pos, int number, bool trash) {}

		private bool press_handler(EventButton event) {
			if(event.type == Gdk.EventType.DOUBLE_BUTTON_PRESS && event.button == 1) {
				if(isExpanded) 
					collapse_all(); 
				else  
					expand_all();
			}

			if(event.type == Gdk.EventType.BUTTON_PRESS && event.button == 3) {
				ContextMenu context = new ContextMenu(this);
				context.popup_at_widget(marker, Gdk.Gravity.CENTER, Gdk.Gravity.WEST, null);
			}

			return false;
		}

		private bool key_handler(EventKey key) {

			if(!lock && key.type == Gdk.EventType.KEY_PRESS && key.keyval == Gdk.Key.Escape && !(key.state == (key.state | Gdk.ModifierType.CONTROL_MASK))) {
				input_cell.buffer.insert_at_cursor("⋮", "⋮".length);
				TextIter iter;
				int pos = input_cell.buffer.get_char_count() -  input_cell.buffer.cursor_position;
				
				replace_characters(ref input_buffer);
				input_cell.buffer.get_iter_at_offset(out iter, input_cell.buffer.get_char_count() - pos);
				input_cell.buffer.place_cursor(iter);

			}

			if(!lock && input_buffer.has_selection && key.type == Gdk.EventType.KEY_PRESS && (bool)(key.state & Gdk.ModifierType.CONTROL_MASK) && key.keyval == Gdk.Key.y) {
				
				TextIter start,end;
				if(input_buffer.get_selection_bounds(out start, out end)) {
					string str = input_buffer.get_text(start, end, true);
					str = comment_transform(str);
					input_buffer.delete(ref start, ref end);
					input_buffer.insert_at_cursor(str, str.length);

				}
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
						if(!lock) {
							ContextMenu context = new ContextMenu(this);
							context.popup_at_widget(marker, Gdk.Gravity.CENTER, Gdk.Gravity.WEST, null);
							context.grab_focus();
						}
						break;
					
				}
			}

			return false;
		}

		private bool output_key_handler(EventKey key) {

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
						if(!lock) {
							ContextMenu context = new ContextMenu(this);
							context.popup_at_widget(marker, Gdk.Gravity.CENTER, Gdk.Gravity.WEST, null);
							context.grab_focus();
						}
						break;
					
				}
			}

			return false;
		}

		public void set_text(string _text) {
			input_buffer.text = _text;
		}

		public void add_text(string _text) {

			TextIter iter;
			output_buffer.get_end_iter(out iter);
			
			if(_text.char_count() > Parameter.max_chars) {
				
				Placeholder more = new Placeholder();
				more.buffer = output_buffer;

				more.hold_expression = _text;

				output_buffer.insert(ref iter, "\n", 1);
				output_buffer.get_end_iter(out iter);
				more.anchor = output_buffer.create_child_anchor(iter);
				output_cell.add_child_at_anchor(more, more.anchor);
				this.show_all();
				this.check_resize();
				
				return;
			}
			
			// replace all formulas by SVGs
			if(Parameter.output == Form.RENDERED) {
				
				string txt_rep = _text.replace("\n", "").replace(" ", "");
				if(txt_rep.length < 81 || txt_rep.substring(0, 15) != "SeaborgOutput[\"") {
					output_buffer.insert(ref iter, _text, _text.length);
					this.show_all();
					this.check_resize();
					return;
				}


				string fn = "tmp/" + txt_rep.substring(15, 64) + ".svg";
				string data = "tmp/" + txt_rep.substring(15, 64) + ".txt";
				GLib.FileStream? file = GLib.FileStream.open(fn, "r");

				if(file == null) {
					output_buffer.insert(ref iter, _text, _text.length);
					this.show_all();
					this.check_resize();
					return;
				}

				PlotFrame plot = new PlotFrame(fn, this);
				
				if(! plot.import_success()) {
					output_buffer.insert(ref iter, _text, _text.length);
					this.show_all();
					this.check_resize();
					return;
				}

				plot.data_file = data;

				// insert line break and formula
				output_buffer.insert(ref iter, "\n", 1);
				output_buffer.get_end_iter(out iter);
				output_cell.add_child_at_anchor(plot, output_buffer.create_child_anchor(iter));
				this.show_all();
				this.check_resize();
				return;
			}

			if(Parameter.wrap_mode == Gtk.WrapMode.NONE) {
				int length = Parameter.chars_per_line > 0 ? Parameter.chars_per_line : 80;
				int char_count = _text.char_count();
				int pos1 = 0;
				int pos2 = 0;
				int pos3 = 0;
				string insert_string = "";

				while(pos1 < char_count) {

					pos2 = _text.index_of_char('\n', pos1);
					
					// line break not found
					if(pos2 < pos1) {
						
						while(pos1 < char_count) {
							
							pos2 = pos1 + length;
							if(pos2 > char_count)
								pos2 = char_count;

							insert_string = _text.slice( _text.index_of_nth_char(pos1), _text.index_of_nth_char(pos2)) + "\n";
							output_buffer.insert(ref iter, insert_string, insert_string.length);
							output_buffer.get_end_iter(out iter);
							pos1 = pos2;


						} break;
					}

					// test if line fits into one notebook line
					if(pos2 - pos1 < length) {
						pos2++;
						insert_string = _text.slice( _text.index_of_nth_char(pos1), _text.index_of_nth_char(pos2));
						output_buffer.insert(ref iter, insert_string, insert_string.length);
						output_buffer.get_end_iter(out iter);
						pos1 = pos2;
					
					} else {

						while(pos1 < pos2) {
							pos3 = pos1 + length;
							if(pos3 > pos2)
								pos3 = pos2;

							insert_string = _text.slice( _text.index_of_nth_char(pos1), _text.index_of_nth_char(pos3)) + "\n";
							output_buffer.insert(ref iter, insert_string, insert_string.length);
							output_buffer.get_end_iter(out iter);
							pos1 = pos3;
						}
					}
				}

				this.show_all();
				this.check_resize();
				return;
			}

			output_buffer.insert(ref iter, _text, _text.length);
			this.show_all();
			this.check_resize();

			
		}

		public string get_text() {
			return input_buffer.text;
		}

		public void remove_text() {
			output_buffer.text = "";
		}

		public string get_output_text() {
			return output_buffer.text;
		}

		public void cell_check_resize() {
			input_cell.check_resize();
			output_cell.check_resize();
		}

		public void zoom_font(double factor) {
			string zoom_string = "* { font-size: " + factor.to_string() + "em; }";
			try {
				font_provider.load_from_data(zoom_string, zoom_string.length);
			} catch (GLib.Error err) {}
		}

		public bool search(SearchType type) {
			

			switch (type) {
				
				case SearchType.StartForwards:

					Gtk.TextIter origin, start, end;
					bool has_wrapped_around, res;

					input_buffer.get_start_iter(out origin);
					res = input_search_context.forward2(origin, out start, out end, out has_wrapped_around);
					res = res && (!has_wrapped_around);

					if(res) {
						input_buffer.select_range(start, end);
						focus_cell();
						return res;
					}

					if(isExpanded) {
						output_buffer.get_start_iter(out origin);
						res = output_search_context.forward2(origin, out start, out end, out has_wrapped_around);
						res = res && (!has_wrapped_around);

						if(res) {
							output_buffer.select_range(start, end);
							focus_cell();
						}
					}

					return res;

				case SearchType.EndBackwards:

					Gtk.TextIter origin, start, end;
					bool has_wrapped_around, res;

					if(isExpanded) {

						output_buffer.get_end_iter(out origin);
						res = output_search_context.backward2(origin, out start, out end, out has_wrapped_around);
						res = res && (!has_wrapped_around);

						if(res) {
							output_buffer.select_range(start, end);
							focus_cell();
							return res;
						}
					}

					input_buffer.get_end_iter(out origin);
					res = input_search_context.backward2(origin, out start, out end, out has_wrapped_around);
					res = res && (!has_wrapped_around);

					if(res) {
						input_buffer.select_range(start, end);
						focus_cell();
					}

					return res;

				case SearchType.CursorForwards:

					Gtk.TextIter origin, sel_start, sel_end, start, end;
					bool has_wrapped_around, res = false;

					if(input_buffer.has_selection) {

						input_buffer.get_selection_bounds(out sel_start, out sel_end);
						res = input_search_context.forward2(sel_end, out start, out end, out has_wrapped_around);
						res = res && (!has_wrapped_around);

						if(res) {
							input_buffer.select_range(start, end);
							focus_cell();
							return res;
						}

						output_buffer.get_start_iter(out origin);
						res = output_search_context.forward2(origin, out start, out end, out has_wrapped_around);
						res = res && (!has_wrapped_around);

						if(res) {
							output_buffer.select_range(start, end);
							focus_cell();
						}

						return res;
					}

					if(isExpanded && output_buffer.has_selection) {
						output_buffer.get_selection_bounds(out sel_start, out sel_end);
						res = output_search_context.forward2(sel_end, out start, out end, out has_wrapped_around);
						res = res && (!has_wrapped_around);

						if(res) {
							output_buffer.select_range(start, end);
							focus_cell();
						}

						return res;
					}

					return res;

				case SearchType.CursorBackwards:

					Gtk.TextIter origin, sel_start, sel_end, start, end;
					bool has_wrapped_around, res=false;

					if(isExpanded && output_buffer.has_selection) {

						output_buffer.get_selection_bounds(out sel_start, out sel_end);
						res = output_search_context.backward2(sel_start, out start, out end, out has_wrapped_around);
						res = res && (!has_wrapped_around);

						if(res) {
							output_buffer.select_range(start, end);
							focus_cell();
							return res;
						}

						input_buffer.get_end_iter(out origin);
						res = input_search_context.backward2(origin, out start, out end, out has_wrapped_around);
						res = res && (!has_wrapped_around);

						if(res) {
							input_buffer.select_range(start, end);
							focus_cell();
						}

						return res;
					}

					if(input_buffer.has_selection) {

						input_buffer.get_selection_bounds(out sel_start, out sel_end);
						res = input_search_context.backward2(sel_start, out start, out end, out has_wrapped_around);
						res = res && (!has_wrapped_around);

						if(res) {
							input_buffer.select_range(start, end);
							focus_cell();
						}

						return res;
					}

					return res;

			}

			return false;
		}

		public bool do_forward_search(ref bool found_last) {
			if(found_last) {
				return search(SearchType.StartForwards);
			}

			if(input_buffer.has_selection || output_buffer.has_selection) {
				found_last = true;
				return search(SearchType.CursorForwards);
			}

			return false;
		}

		public bool do_backward_search(ref bool found_last) {
			if(found_last) {
				return search(SearchType.EndBackwards);
			}

			if(input_buffer.has_selection || output_buffer.has_selection) {
				found_last = true;
				return search(SearchType.CursorBackwards);
			}

			return false;
		}

		public void replace_all(string rep) {

			try {
				input_search_context.replace_all(rep, rep.length);
			} catch (GLib.Error err) {}

		}

		public string get_tree_title() {
			return "Evaluation Cell";
		}

		public void set_wrap_mode(Gtk.WrapMode wrap) {
			input_cell.wrap_mode = wrap;
			output_cell.wrap_mode = wrap;
		}

		public string cell_checksum() {
			return GLib.Checksum.compute_for_string(GLib.ChecksumType.SHA256, input_buffer.text + output_buffer.text);
		}

		public ICell* first_cell() { return this; }
		public ICell* last_cell() { return this; }

		public ICellContainer* parent_cell {get; set;}
		public bool cell_expanded { get { return isExpanded; } }
		private Gtk.SourceView input_cell;
		private Gtk.SourceBuffer input_buffer;
		private Gtk.SourceView output_cell;
		private Gtk.SourceBuffer output_buffer;
		private Gtk.SourceSearchContext input_search_context;
		private Gtk.SourceSearchContext output_search_context;
		private Gtk.ToggleButton marker;
		private bool isExpanded;
		private bool _lock;
		private CssProvider css;
		private CssProvider font_provider;

	}

}