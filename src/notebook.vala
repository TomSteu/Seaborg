using Gtk;

namespace Seaborg {
	
	public class Notebook : Gtk.Grid, ICell, ICellContainer {
		public Notebook() {
			this.name = IdGenerator.get_id();
			parent_cell = null;
			level = 7;
			zoom_factor = 1;
			children_cells = new GLib.Array<ICell>();
			addbutton_list = new GLib.Array<AddButton>();
			
			hexpand = true;
			halign = Gtk.Align.FILL;
			column_spacing = 4;
			row_spacing = 4;
			css = new CssProvider();
			this.get_style_context().add_provider(css, Gtk.STYLE_PROVIDER_PRIORITY_USER);

			try {

				css.load_from_path("res/seaborg.css");

			} catch(GLib.Error error) {

				css = CssProvider.get_default();
			}

			search_settings = new Gtk.SourceSearchSettings();
			search_settings.wrap_around = false;

			marker = new Gtk.ToggleButton();
			marker.can_focus = false;
			var style_context = marker.get_style_context();
			style_context.add_provider(css, Gtk.STYLE_PROVIDER_PRIORITY_USER);
			style_context.add_class("cell-marker");
			get_style_context().add_class("view");
			get_style_context().add_class("container-grid");

			// final Addbutton to fill the bottom of the window
			footer = new AddButton(this);
			footer.name = IdGenerator.get_id();
			footer.can_focus = false;
			footer.focus_on_click = false;
			footer.get_style_context().add_class("add-button");
			footer.vexpand = true;
			footer.valign = Gtk.Align.FILL;
			footer.clicked.connect(() => { addbutton_list.data[addbutton_list.data.length-1].insert_child();});

			// assemble the container
			attach(marker, 0, 0, 1, 2);
			addbutton_list.append_val(new AddButton(this));
			attach(addbutton_list.index(0), 1, 0, 1, 1);
			attach(footer, 0, 2, 2, 1);

		}

		public void remove_recursively() {
			int i;
			for(i=(int)(children_cells.length)-1; i >= 0; i--) {
				if((children_cells.data[i].marker_selected || this.marker_selected) && (! children_cells.data[i].lock)) {
					remove_from(i,1,true);
				}
			}

			for(i=0; i<(int)(children_cells.length); i++) children_cells.index(i).remove_recursively();
			show_all();
		}

		public void add_before(int pos, ICell[] list) {

			int old_len = (int)(children_cells.length);
			if(pos < 0 ) pos += old_len + 1;
			if(pos < 0 || pos > old_len)
				return;

			for(int l=0; l<list.length; l++) 
				list[l].parent_cell = this;

			for(int j=1; j<=2*list.length; j++) 
				insert_row(2*pos+1);

			children_cells.insert_vals(pos, list, list.length);
			for(int k=0; k < list.length; k++) addbutton_list.insert_val(pos+1, new AddButton(this));
			for(int i=0; i<list.length; i++) {
					attach(children_cells.data[pos+i], 1, 2*(pos+i)+1, 1, 1);
					attach(addbutton_list.data[pos+1+i], 1,  2*(pos+i)+2, 1, 1);
			}

			update_tree();
			this.show_all();

		}

		public void remove_from(int pos, int number, bool trash) {

			if(pos < 0 || number <= 0)
				return;

			if(pos+number > children_cells.data.length)
				number = (int)(children_cells.length) - pos;

			// manually remove objects since they are exluded from reference counting
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
			for(int i=1; i <= 2*number; i++) remove_row(2*pos+1);

			update_tree();
		}

		public void toggle_all() {
			marker.active = true;
			for(int i=0; i<children_cells.data.length; i++) {
				children_cells.data[i].toggle_all();
			}
		}

		public void untoggle_all() {
			marker.active = false;
			for(int i=0; i<children_cells.data.length; i++) {
				children_cells.data[i].untoggle_all();
			}
		}

		public void expand_all() {
			for(int i=0; i<children_cells.data.length; i++) {
				children_cells.data[i].expand_all();
			}
		}

		public void collapse_all() {
			for(int i=0; i<children_cells.data.length; i++) {
				children_cells.data[i].collapse_all();
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
		
		public bool marker_selected {
			get {return marker.sensitive ? marker.active : false; }
			set { if(marker.sensitive) { marker.active = value; } }
		}

		public uint get_level() {
			return level;
		}

		public void focus_cell(bool grab_selection = true) {
			if(children_cells.length > 0){
				children_cells.data[0].focus_cell(grab_selection);
			}
		}

		public void set_text(string _text) {}
		public string get_text() { return ""; }

		public void cell_check_resize() {

			for(int i=0; i<children_cells.data.length; i++) {
				children_cells.data[i].cell_check_resize();
			}
		}

		public void zoom_font(double factor) {
			zoom_factor = factor;

			for(int i=0; i<children_cells.data.length; i++) {
				children_cells.data[i].zoom_font(factor);
			}
		}

		public bool search(SearchType type) {

			return false;
		}

		public void replace_all(string rep) {

			for(int i=0; i<children_cells.data.length; i++) {
				children_cells.data[i].replace_all(rep);
			}
		}

		public bool do_forward_search(ref bool last_found) {
			for(int i=0; i<children_cells.data.length; i++) {
				if(children_cells.data[i].do_forward_search(ref last_found))
					return true;
			}

			return false;
		}

		public bool do_backward_search(ref bool last_found) {
			for(int i=children_cells.data.length-1; i>=0; i--) {
				if(children_cells.data[i].do_backward_search(ref last_found))
					return true;
			}

			return false;
		}

		public string get_tree_title() {
			return "Notebook";
		}

		public void next_cell(string _name, bool grab_selection = true) {

			int i;
			for(i=0; i<children_cells.data.length; i++) {
				if(children_cells.data[i].name == _name)
					break;
			}

			if(i+1 < children_cells.data.length) {
				children_cells.data[i+1].focus_cell(grab_selection);
				return;
			}

			if(parent_cell != null) {
				parent_cell->next_cell(this.name, grab_selection);
			}

			return;
		}

		public void prev_cell(string _name, bool grab_selection = true) {

			int i;
			for(i=0; i<children_cells.data.length; i++) {
				if(children_cells.data[i].name == _name)
					break;
			}

			if(i-1 >= 0) {
				children_cells.data[i-1].focus_cell(grab_selection);
				return;
			}

			if(parent_cell != null) {
				parent_cell->prev_cell(this.name, grab_selection);
			}

			return;
		}

		public GLib.Array<ICell> children_cells {get; set;}
		public GLib.Array<AddButton> addbutton_list {get; set;}
		public ICellContainer* parent_cell {get; set;}
		public double zoom_factor {get; set;}
		public bool cell_expanded { get { return true; } }
		public Gtk.TreeStore tree_model {get; set;}
		public Gtk.SourceSearchSettings search_settings {get; set;}
		private uint level;
		private Gtk.ToggleButton marker;
		private CssProvider css;
		private Gtk.Button footer;
	}


}