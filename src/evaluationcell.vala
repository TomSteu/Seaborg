using Gtk;
using Gdk;

namespace Seaborg {

	// Generic cell for evaluation
	public class EvaluationCell : Gtk.Grid, ICell {
		
		public EvaluationCell(ICellContainer* par) {
			this.name = IdGenerator.get_id();
			parent_cell = par;
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
			
 			

 			InputBuffer = new Gtk.SourceBuffer(null);
			InputBuffer.highlight_matching_brackets = true;			

			InputCell = new Gtk.SourceView.with_buffer(InputBuffer);
			InputCell.show_line_numbers = false;
			InputCell.highlight_current_line = false;
			InputCell.auto_indent = true;
			InputCell.indent_on_tab = true;
			InputCell.tab_width = 3;
			InputCell.insert_spaces_instead_of_tabs = false;
			InputCell.smart_backspace = true;
			InputCell.show_line_marks = false;
			InputCell.wrap_mode = Gtk.WrapMode.WORD_CHAR;
			InputCell.monospace = true;
			InputCell.editable = true;
			InputCell.hexpand = true;
			InputCell.halign = Gtk.Align.FILL;
			InputCell.left_margin = 0;
			InputCell.right_margin = 0;
			InputCell.top_margin = 0;
			InputCell.bottom_margin = 0;
			InputCell.button_press_event.connect(untoggle_handler);
			InputCell.key_press_event.connect(key_handler);
			InputCell.get_style_context().add_provider(font_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
			InputBuffer.insert_text.connect(insert_handler);
			InputBuffer.add_selection_clipboard(Gtk.Clipboard.get(Gdk.SELECTION_CLIPBOARD));

			input_search_context = new Gtk.SourceSearchContext(InputBuffer, parent_cell->search_settings);

			

			OutputBuffer = new Gtk.SourceBuffer(null);
			OutputBuffer.highlight_matching_brackets = true;
			OutputBuffer.add_selection_clipboard(Gtk.Clipboard.get(Gdk.SELECTION_CLIPBOARD));

			OutputCell = new Gtk.SourceView.with_buffer(OutputBuffer);
			OutputCell.show_line_numbers = false;
			OutputCell.highlight_current_line = false;
			OutputCell.auto_indent = true;
			OutputCell.indent_on_tab = true;
			OutputCell.tab_width = 3;
			OutputCell.insert_spaces_instead_of_tabs = false;
			OutputCell.smart_backspace = true;
			OutputCell.show_line_marks = false;
			OutputCell.wrap_mode = Gtk.WrapMode.WORD_CHAR;
			OutputCell.monospace = true;
			OutputCell.editable = false;
			OutputCell.hexpand = true;
			OutputCell.halign = Gtk.Align.FILL;
			OutputCell.left_margin = 0;
			OutputCell.right_margin = 0;
			OutputCell.top_margin = 0;
			OutputCell.bottom_margin = 0;
			OutputCell.button_press_event.connect(untoggle_handler);
			OutputCell.get_style_context().add_provider(font_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);

			if(Parameter.dark_theme) {
				InputBuffer.style_scheme = sm.get_scheme("seaborg-dark");
				OutputBuffer.style_scheme = sm.get_scheme("seaborg-dark");
			} else {
				InputBuffer.style_scheme = sm.get_scheme("seaborg-light");
				OutputBuffer.style_scheme = sm.get_scheme("seaborg-light");
			}
			
			if(Parameter.code_highlighting != Highlighting.NONE) {
				
				if(Parameter.code_highlighting == Highlighting.FULL) {
					InputBuffer.language =  lm.get_language("wolfram");
					OutputBuffer.language =  lm.get_language("wolfram");
				}

				if(Parameter.code_highlighting == Highlighting.NOSTDLIB) {
					InputBuffer.language =  lm.get_language("wolfram-nostdlib");
					OutputBuffer.language =  lm.get_language("wolfram-nostdlib");
				}
			}

			

			output_search_context = new Gtk.SourceSearchContext(OutputBuffer, parent_cell->search_settings);


			Marker = new Gtk.ToggleButton();
			Marker.can_focus = false;
			var style_context = Marker.get_style_context();
			style_context.add_provider(css, Gtk.STYLE_PROVIDER_PRIORITY_USER);
			style_context.add_class("cell-marker");
			this.get_style_context().add_class("cell-grid");

			attach(Marker, 0, 0, 1, 1);
			attach(InputCell, 1, 0, 1, 1);

			isExpanded = false;

			Marker.button_press_event.connect(press_handler);
			show_all();

		}

		public void toggle_all() {
			Marker.active = true;

		}

		public void untoggle_all() {
			Marker.active = false;
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
				attach(InputCell, 1, 0, 1, 1);
				attach(OutputCell, 1, 1, 1, 1);
				attach(Marker, 0, 0, 1, 2);
				isExpanded = true;
				show_all();
			}
		}

		public bool lock {
			get {return _lock;}
			set {

				if(value == _lock)
					return;

				InputCell.editable = !value;
				Marker.sensitive = !value;
				_lock = value;
			}
		}

		public bool marker_selected() {
			return Marker.sensitive ? Marker.active : false;
		}

		public void focus_cell() {
			InputCell.grab_focus();
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
				context.popup_at_widget(Marker, Gdk.Gravity.CENTER, Gdk.Gravity.WEST, null);
			}

			return false;
		}

		private bool key_handler(EventKey key) {

			if(key.type == Gdk.EventType.KEY_PRESS && key.keyval == Gdk.Key.Escape) {
				InputCell.buffer.insert_at_cursor("⋮", "⋮".length);
				TextIter iter;
				int pos = InputCell.buffer.get_char_count() -  InputCell.buffer.cursor_position;
				set_text(replace_characters(get_text()));
				InputCell.buffer.get_iter_at_offset(out iter, InputCell.buffer.get_char_count() - pos);
				InputCell.buffer.place_cursor(iter);

			}

			if(InputBuffer.has_selection && key.type == Gdk.EventType.KEY_PRESS && (bool)(key.state & Gdk.ModifierType.CONTROL_MASK) && key.keyval == Gdk.Key.y) {
				
				TextIter start,end;
				if(InputBuffer.get_selection_bounds(out start, out end)) {
					string str = InputBuffer.get_text(start, end, true);
					str = comment_transform(str);
					InputBuffer.delete(ref start, ref end);
					InputBuffer.insert_at_cursor(str, str.length);

				}
			}

			return false;
		}

		public void set_text(string _text) {
			InputBuffer.text = _text;
		}

		public void add_text(string _text) {

			TextIter iter;
			OutputBuffer.get_end_iter(out iter);
			
			// replace all formulas by SVGs
			if(Parameter.output == Form.RENDERED) {
				
				string txt_rep = _text.replace("\n", "");
				
				// file is encoded by hash
				string fn = "tmp/" + 
					GLib.Checksum.compute_for_string(
						GLib.ChecksumType.SHA256, 
						txt_rep,
						txt_rep.length
					) + ".svg" ;

				GLib.FileStream? file = GLib.FileStream.open(fn, "r");
				if(file == null) {
					OutputBuffer.insert(ref iter, _text, _text.length);
					return;
				}

				PlotFrame plot = new PlotFrame(fn, this);
				
				if(! plot.import_success()) {
					OutputBuffer.insert(ref iter, _text, _text.length);
					return;
				}

				// insert line break and formula
				OutputBuffer.insert(ref iter, "\n", 1);
				OutputBuffer.get_end_iter(out iter);
				OutputCell.add_child_at_anchor(plot, OutputBuffer.create_child_anchor(iter));
				this.show_all();

				return;
			}

			OutputBuffer.insert(ref iter, _text, _text.length);

			// replace Graphics with pictures
			if(Parameter.output == Form.INPUTREPLACEGRAPHICS && _text.contains("Graphics")) {

				int pos_end, pos_start = 0;
				int char_end, char_start;
				string output, hash;
				GLib.FileStream file;
				PlotFrame plot;
				TextIter iter1, iter2;

				while(true) {

					OutputBuffer.get_bounds(out iter1, out iter2);
					output = OutputBuffer.get_slice(iter1, iter2, true);

					if(pos_start > output.length - 1)
						break;


					// find next graphics output
					pos_start = output.index_of("Graphics", pos_start);
					if(pos_start < 0)
						break;

					pos_end = find_closing_bracket(output, pos_start);
					if(pos_end < 0 || pos_end >= output.length)
						break;
					
					// try importing picture, file name is encoded by hash
					hash = GLib.Checksum.compute_for_string(
						GLib.ChecksumType.SHA256, 
						output.substring(pos_start, pos_end-pos_start+1), 
						pos_end-pos_start+1
					);

					file = GLib.FileStream.open("tmp/" + hash + ".svg", "r");
					if(file == null) {
						pos_start = pos_end + 1;
						continue;
					}

					plot = new PlotFrame("tmp/" + hash + ".svg", this);


					if(! plot.import_success()) {
						pos_start = pos_end + 1;
						continue;
					}

					// remove graphics output from buffer
					char_start = character_index_at_byte_index(output, pos_start);
					char_end = character_index_at_byte_index(output, pos_end);
					OutputBuffer.get_iter_at_offset(out iter1, char_start);
					OutputBuffer.get_iter_at_offset(out iter2, char_end+1);
					OutputBuffer.delete(ref iter1, ref iter2);

					// insert plot
					OutputBuffer.get_iter_at_offset(out iter1, char_start);
					OutputCell.add_child_at_anchor(plot, OutputBuffer.create_child_anchor(iter1));


				}

				this.show_all();
			}
			
		}

		public string get_text() {
			return InputBuffer.text;
		}

		public void remove_text() {
			OutputBuffer.text = "";
		}

		public string get_output_text() {
			return OutputBuffer.text;
		}

		public void cell_check_resize() {
			InputCell.check_resize();
			OutputCell.check_resize();
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

					InputBuffer.get_start_iter(out origin);
					res = input_search_context.forward2(origin, out start, out end, out has_wrapped_around);
					res = res && (!has_wrapped_around);

					if(res) {
						InputBuffer.select_range(start, end);
						focus_cell();
						recursive_untoggle_all();
						toggle_all();
						return res;
					}

					if(isExpanded) {
						OutputBuffer.get_start_iter(out origin);
						res = output_search_context.forward2(origin, out start, out end, out has_wrapped_around);
						res = res && (!has_wrapped_around);

						if(res) {
							OutputBuffer.select_range(start, end);
							focus_cell();
							recursive_untoggle_all();
							toggle_all();
						}
					}

					return res;

				case SearchType.EndBackwards:

					Gtk.TextIter origin, start, end;
					bool has_wrapped_around, res;

					if(isExpanded) {

						OutputBuffer.get_end_iter(out origin);
						res = output_search_context.backward2(origin, out start, out end, out has_wrapped_around);
						res = res && (!has_wrapped_around);

						if(res) {
							OutputBuffer.select_range(start, end);
							focus_cell();
							recursive_untoggle_all();
							toggle_all();
							return res;
						}
					}

					InputBuffer.get_end_iter(out origin);
					res = input_search_context.backward2(origin, out start, out end, out has_wrapped_around);
					res = res && (!has_wrapped_around);

					if(res) {
						InputBuffer.select_range(start, end);
						focus_cell();
						recursive_untoggle_all();
						toggle_all();
					}

					return res;

				case SearchType.CursorForwards:

					Gtk.TextIter origin, sel_start, sel_end, start, end;
					bool has_wrapped_around, res = false;

					if(InputBuffer.has_selection) {

						InputBuffer.get_selection_bounds(out sel_start, out sel_end);
						res = input_search_context.forward2(sel_end, out start, out end, out has_wrapped_around);
						res = res && (!has_wrapped_around);

						if(res) {
							InputBuffer.select_range(start, end);
							focus_cell();
							recursive_untoggle_all();
							toggle_all();
							return res;
						}

						OutputBuffer.get_start_iter(out origin);
						res = output_search_context.forward2(origin, out start, out end, out has_wrapped_around);
						res = res && (!has_wrapped_around);

						if(res) {
							OutputBuffer.select_range(start, end);
							focus_cell();
							recursive_untoggle_all();
							toggle_all();
						}

						return res;
					}

					if(isExpanded && OutputBuffer.has_selection) {
						OutputBuffer.get_selection_bounds(out sel_start, out sel_end);
						res = output_search_context.forward2(sel_end, out start, out end, out has_wrapped_around);
						res = res && (!has_wrapped_around);

						if(res) {
							OutputBuffer.select_range(start, end);
							focus_cell();
							recursive_untoggle_all();
							toggle_all();
						}

						return res;
					}

					return res;

				case SearchType.CursorBackwards:

					Gtk.TextIter origin, sel_start, sel_end, start, end;
					bool has_wrapped_around, res=false;

					if(isExpanded && OutputBuffer.has_selection) {

						OutputBuffer.get_selection_bounds(out sel_start, out sel_end);
						res = output_search_context.backward2(sel_start, out start, out end, out has_wrapped_around);
						res = res && (!has_wrapped_around);

						if(res) {
							OutputBuffer.select_range(start, end);
							focus_cell();
							recursive_untoggle_all();
							toggle_all();
							return res;
						}

						InputBuffer.get_end_iter(out origin);
						res = input_search_context.backward2(origin, out start, out end, out has_wrapped_around);
						res = res && (!has_wrapped_around);

						if(res) {
							InputBuffer.select_range(start, end);
							focus_cell();
							recursive_untoggle_all();
							toggle_all();
						}

						return res;
					}

					if(InputBuffer.has_selection) {

						InputBuffer.get_selection_bounds(out sel_start, out sel_end);
						res = input_search_context.backward2(sel_start, out start, out end, out has_wrapped_around);
						res = res && (!has_wrapped_around);

						if(res) {
							InputBuffer.select_range(start, end);
							focus_cell();
							recursive_untoggle_all();
							toggle_all();
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

			if(InputBuffer.has_selection || OutputBuffer.has_selection) {
				found_last = true;
				return search(SearchType.CursorForwards);
			}

			return false;
		}

		public bool do_backward_search(ref bool found_last) {
			if(found_last) {
				return search(SearchType.EndBackwards);
			}

			if(InputBuffer.has_selection || OutputBuffer.has_selection) {
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

		public ICellContainer* parent_cell {get; set;}
		private Gtk.SourceView InputCell;
		private Gtk.SourceBuffer InputBuffer;
		private Gtk.SourceView OutputCell;
		private Gtk.SourceBuffer OutputBuffer;
		private Gtk.SourceSearchContext input_search_context;
		private Gtk.SourceSearchContext output_search_context;
		private Gtk.ToggleButton Marker;
		private bool isExpanded;
		private bool _lock;
		private CssProvider css;
		private CssProvider font_provider;

	}

}