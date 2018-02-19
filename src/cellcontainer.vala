using Gtk;
using Gdk;

namespace Seaborg {

	// container class with heading
	public class CellContainer : Gtk.Grid, ICell, ICellContainer {
		public CellContainer(ICellContainer* parent, uint level) {
			this.name = IdGenerator.get_id();
			parent_cell = parent;
			children_cells = new GLib.Array<ICell>();
			addbutton_list = new GLib.Array<AddButton>();
			column_spacing = 4;
			row_spacing = 4;
			zoom_factor = parent_cell->zoom_factor;
			search_settings = parent_cell->search_settings;

			css = new CssProvider();
			font_provider = new CssProvider();
			this.get_style_context().add_provider(css, Gtk.STYLE_PROVIDER_PRIORITY_USER);

			try {

				css.load_from_path("res/seaborg.css");

			} catch(GLib.Error error) {

				css = CssProvider.get_default();
			}

			TitleBuffer = new Gtk.SourceBuffer(null);
			TitleBuffer.highlight_matching_brackets = true;
			Title = new Gtk.SourceView.with_buffer(TitleBuffer);
			Title.show_line_numbers = false;
			Title.highlight_current_line = false;
			Title.auto_indent = true;
			Title.indent_on_tab = true;
			Title.tab_width = 3;
			Title.insert_spaces_instead_of_tabs = false;
			Title.smart_backspace = true;
			Title.show_line_marks = false;
			Title.wrap_mode = Gtk.WrapMode.WORD_CHAR;
			Title.monospace = false;
			Title.editable = true;
			Title.hexpand = true;
			Title.halign = Gtk.Align.FILL;
			Title.left_margin = 0;
			Title.right_margin = 0;
			Title.top_margin = 0;
			Title.bottom_margin = 0;
			Title.button_press_event.connect(untoggle_handler);
			Title.key_press_event.connect(insert_ellipsis);
			Title.get_style_context().add_provider(font_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
			TitleBuffer.insert_text.connect(insert_handler);
			TitleBuffer.add_selection_clipboard(Gtk.Clipboard.get(Gdk.SELECTION_CLIPBOARD));

			Gtk.SourceStyleSchemeManager sm = new Gtk.SourceStyleSchemeManager();
 			sm.search_path = new string[] {"res/sourceview/"};

			if(Parameter.dark_theme) {
				TitleBuffer.style_scheme = sm.get_scheme("seaborg-dark");
			} else {
				TitleBuffer.style_scheme = sm.get_scheme("seaborg-light");
			}

			search_context = new Gtk.SourceSearchContext(TitleBuffer, parent_cell->search_settings);

			set_level(level);

			Marker = new Gtk.ToggleButton();
			Marker.can_focus = false;
			var style_context = Marker.get_style_context();
			style_context.add_provider(css, Gtk.STYLE_PROVIDER_PRIORITY_USER);
			style_context.add_class("cell-marker");
			get_style_context().add_class("view");
			get_style_context().add_class("container-grid");

			// assemble the container
			attach(Marker, 0, 0, 1, 2);
			attach(Title, 1, 0, 1, 1);
			addbutton_list.append_val(new AddButton(this));
			attach(addbutton_list.index(0), 1, 1, 1);

			Marker.button_press_event.connect(press_handler);
			isExpanded = true;

			this.notify["children-cells"].connect((property, sender) => {
				stderr.printf("chidren changed");
			});

			show_all();

		}

		public void eat_children() {

			if(parent_cell == null) return;

			int this_position=-1;

			// eat younger silblings and transfer to parent
			if(parent_cell->get_level() <= Level) {

				int par_len = parent_cell->children_cells.data.length;

				// find out position within parent
				for(this_position=0; this_position < par_len; this_position++) {
					if(this.name == parent_cell->children_cells.data[this_position].name)
						break;
				}

				// move elements from parents into this container
				if(this_position < par_len - 1) {
					var cells = parent_cell->children_cells.data[this_position+1 : par_len];
					parent_cell->remove_from(this_position+1, par_len - 1 - this_position, false);
					add_before(-1, cells);					
				}
				
				// put Container from parent into grandparent
				if(parent_cell->parent_cell != null) {

					// find position of parent within grandparent
					int parent_position;
					for(parent_position=0; parent_position < parent_cell->parent_cell->children_cells.data.length; parent_position++) {
						if(parent_cell->name == parent_cell->parent_cell->children_cells.data[parent_position].name)
							break;
					}

					if(parent_position >= parent_cell->parent_cell->children_cells.data.length)
						return;
					
					// move container 
					parent_cell->remove_from(this_position, 1, false);
					parent_cell->parent_cell->add_before(parent_position+1, { this });
					eat_children();

				}

			} else {

				int next_position=-1;
				
				// find out where the next container (e.g. section) of the same or higher level is
				for(int i=0; i<(parent_cell->children_cells).data.length; i++) {
					if((parent_cell->children_cells).data[i].name == this.name)
						this_position = i;
					if(parent_cell->children_cells.data[i].get_level() >= Level && i > this_position)
					{
						next_position = i;
						break;
					}
				}

				// weird error
				if(this_position < 0)
					return;

				// no next  position among children - eat them all !
				if(next_position < 0 && this_position >= 0)
					next_position = (parent_cell->children_cells).data.length;

				// next position somewhere behind move elements from parents into this container
				if(next_position > 0 && this_position+1 < next_position) {
					var cells = parent_cell->children_cells.data[this_position+1 : next_position];
					parent_cell->remove_from(this_position+1, next_position-1 - this_position, false);
					add_before(children_cells.data.length, cells);
					
				}

			}

			show_all();

		}

		public void remove_recursively() {
			int i;
			for(i=(int)(children_cells.length)-1; i >= 0; i--) {
				if(children_cells.index(i).marker_selected() && (! children_cells.index(i).lock)) {
					remove_from(i,1,true);
				}
			}

			for(i=0; i<children_cells.data.length; i++) children_cells.index(i).remove_recursively();

		}

		public void add_before(int pos, ICell[] list) {

			int old_len = (int)(children_cells.length);
			if(pos < 0 ) pos += old_len + 1;
			if(pos < 0 || pos > old_len)
				return;
			
			for(int l=0; l<list.length; l++) list[l].parent_cell = this;
			children_cells.insert_vals(pos, list, list.length);
			addbutton_list.set_size(addbutton_list.data.length + list.length);
			
			if(! isExpanded) return;
			if(pos < old_len) {
					for(int j=1; j<=2*list.length; j++) insert_row(2*pos+2);;
			}
			for(int k=0; k<list.length; k++) addbutton_list.insert_val(pos+1, new AddButton(this));
			for(int i=0; i<(int)(list.length); i++) {
					attach(children_cells.data[pos+i], 1, 2*(pos+i)+2, 1, 1);
					attach(addbutton_list.data[pos+1+i], 1, 2*(pos+i)+3, 1, 1);
			}

			//redraw marker if stuff was attached to the end
			if(pos == old_len) {
				remove_column(0);
				insert_column(0);
				attach(Marker, 0, 0, 1, 2*((int)(children_cells.length)+1));
			}

			show_all();

		}

		public void remove_from(int pos, int number, bool trash) {

			if(pos < 0 || number <= 0)
				return;

			if(pos+number > (int)(children_cells.length))
				number = (int)(children_cells.length) - pos;

			// manually remove objects since they are excluded from reference counting
			if(trash) {
				ICell* ref_child;
				AddButton* ref_button;
				for(int j=0; j<number; j++) {
					ref_child =  children_cells.data[pos+j];
					ref_button = addbutton_list.data[pos+1+j];
					delete ref_child;
					delete ref_button;
				}
			}

			children_cells.remove_range(pos, number);
			addbutton_list.remove_range(pos+1, number);
			for(int i=1; i <= 2*number; i++) remove_row(2*pos+2);
		}

		public void toggle_all() {
			Marker.active = true;
			for(int i=0; i<children_cells.data.length; i++) {
				children_cells.data[i].toggle_all();
			}
		}

		public void untoggle_all() {
			Marker.active = false;
			for(int i=0; i<children_cells.data.length; i++) {
				children_cells.data[i].untoggle_all();
			}
		}

		public void expand_all() {
			if(!isExpanded) {
				remove_column(0);
				attach(addbutton_list.data[0], 0, 1, 1, 1);
				for(int i=0; i<children_cells.data.length; i++) {
					attach(children_cells.data[i], 0, 2+2*i, 1, 1);
					attach(addbutton_list.data[1+i], 0, 3+2*i, 1, 1);
				}
				insert_column(0);
				attach(Marker, 0, 0, 1, 2*(children_cells.data.length+1));
				isExpanded = true;
				show_all();
			}
		}

		public void collapse_all() {
			if(isExpanded) {

				for(int i=0; i<=2*children_cells.data.length; i++)
					remove_row(1);
				isExpanded = false;
				show_all();
			}
		}

		public bool lock {
			set {
				for(int i=0; i<children_cells.data.length; i++) {
					children_cells.data[i].lock = value;
				}
			}

			get {
				for(int i=0; i<children_cells.data.length; i++) {
					if(children_cells.data[i].lock)
						return true;
				}
				 return false;
			}
		}

		public bool marker_selected() {
			return Marker.sensitive ? Marker.active : false;
		}

		public void set_text(string _text) {
			Title.buffer.text = _text;
		}

		public string get_text() {
			return Title.buffer.text;
		}

		public uint get_level() {
			return Level;
		}

		public void set_level(uint level) {
			if(Level == level)
				return;
			

			Level = level;
			string zoom_string = 
				"* { font-size: " + 
				((0.2 * get_level() + 1.0)* zoom_factor).to_string() + 
				"em; font-weight: bold; }";

			try {
				font_provider.load_from_data(zoom_string, zoom_string.length);
			} catch (GLib.Error err) {}


		}

		public void zoom_font(double factor) {
			zoom_factor = factor;
			string zoom_string = 
				"* { font-size: " + 
				((0.2 * get_level() + 1.0)* zoom_factor).to_string() + 
				"em; font-weight: bold; }";
			try {
				font_provider.load_from_data(zoom_string, zoom_string.length);
			} catch (GLib.Error err) {}

			for(int i=0; i<children_cells.data.length; i++) {
				children_cells.data[i].zoom_font(factor);
			}
		}

		public void focus_cell() {
			Title.grab_focus();
		}

		public void cell_check_resize() {

			Title.check_resize();

			for(int i=0; i<children_cells.data.length; i++) {
				children_cells.data[i].cell_check_resize();
			}
		}

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

		private bool insert_ellipsis(EventKey key) {

			if(key.type == Gdk.EventType.KEY_PRESS && key.keyval == Gdk.Key.Escape) {
				Title.buffer.insert_at_cursor("⋮", "⋮".length);
				TextIter iter;
				int pos = Title.buffer.get_char_count() -  Title.buffer.cursor_position;
				set_text(replace_characters(get_text()));
				Title.buffer.get_iter_at_offset(out iter, Title.buffer.get_char_count() - pos);
				Title.buffer.place_cursor(iter);

			}

			return false;
		}

		public bool search(SearchType type) {
			
			bool res = false;

			switch (type) {

				case SearchType.StartForwards:

					Gtk.TextIter origin, start, end;
					bool has_wrapped_around;

					TitleBuffer.get_start_iter(out origin);
					res = search_context.forward2(origin, out start, out end, out has_wrapped_around);
					res = res && (!has_wrapped_around);

					if(res) {
						TitleBuffer.select_range(start, end);
						focus_cell();
						recursive_untoggle_all();
						toggle_all();
						return res;
					}

					break;

				case SearchType.EndBackwards:

					Gtk.TextIter origin, start, end;
					bool has_wrapped_around;

					TitleBuffer.get_end_iter(out origin);
					res = search_context.backward2(origin, out start, out end, out has_wrapped_around);
					res = res && (!has_wrapped_around);

					if(res) {
						TitleBuffer.select_range(start, end);
						focus_cell();
						recursive_untoggle_all();
						toggle_all();
						return res;
					}

					break;

				case SearchType.CursorForwards:

					Gtk.TextIter sel_start, sel_end, start, end;
					bool has_wrapped_around;

					TitleBuffer.get_selection_bounds(out sel_start, out sel_end);
					res = search_context.forward2(sel_end, out start, out end, out has_wrapped_around);
					res = res && (!has_wrapped_around);

					if(res) {
						TitleBuffer.select_range(start, end);
						focus_cell();
						recursive_untoggle_all();
						toggle_all();
						return res;
					}

					break;

					

				case SearchType.CursorBackwards:

					Gtk.TextIter sel_start, sel_end, start, end;
					bool has_wrapped_around;

					TitleBuffer.get_selection_bounds(out sel_start, out sel_end);
					res = search_context.backward2(sel_start, out start, out end, out has_wrapped_around);
					res = res && (!has_wrapped_around);

					if(res) {
						TitleBuffer.select_range(start, end);
						focus_cell();
						recursive_untoggle_all();
						toggle_all();
						return res;
					}

					break;	
			}

			if(! res) {
				for(int i=0; i<children_cells.data.length; i++) {
					if(children_cells.data[i].search(type))
						return true;
				}
			}

			return false;
		}

		public void replace_all(string rep) {

			try {
				search_context.replace_all(rep, rep.length);
			} catch (GLib.Error err) {}

			for(int i=0; i<children_cells.data.length; i++) {
				children_cells.data[i].replace_all(rep);
			}
		}

		public bool do_forward_search(ref bool found_last) {
			
			if(found_last) {

				if(search(SearchType.StartForwards))
					return true;

			} else {

				if(TitleBuffer.has_selection) {
					
					found_last = true;
					if(search(SearchType.CursorForwards))
						return true;

				}
			}

			for(int i=0; i<children_cells.data.length; i++) {
				if(children_cells.data[i].do_forward_search(ref found_last))
					return true;
			}

			return false;
		}

		public bool do_backward_search(ref bool found_last) {
			
			for(int i=children_cells.data.length-1; i >= 0; i--) {
					if(children_cells.data[i].do_backward_search(ref found_last))
						return true;
			}

			if(found_last) {

				if(search(SearchType.EndBackwards))
					return true;

			} else {

				if(TitleBuffer.has_selection) {
					
					found_last = true;
					if(search(SearchType.CursorBackwards))
						return true;
				}
			}

			return false;
		}

		public Gtk.TreeStore tree_model {get; set;} 
		public GLib.Array<ICell> children_cells {get; set;}
		public GLib.Array<AddButton> addbutton_list {get; set;}
		public ICellContainer* parent_cell {get; set;}
		public double zoom_factor {get; set;}
		public Gtk.SourceSearchSettings search_settings {get; set;}
		private Gtk.SourceSearchContext search_context;
		private uint Level;
		private SourceView Title;
		private SourceBuffer TitleBuffer;
		private Gtk.ToggleButton Marker;
		private CssProvider css;
		private CssProvider font_provider;
		private bool isExpanded;
	}

}