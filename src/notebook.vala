using Gtk;

namespace Seaborg {
	
	public class Notebook : Gtk.Grid, ICell, ICellContainer, Gtk.TreeModel {
		public Notebook() {
			this.name = IdGenerator.get_id();
			parent_cell = null;
			level = 7;
			zoom_factor = 1;
			children_cells = new GLib.Array<ICell>();
			addbutton_list = new GLib.Array<AddButton>();
			
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
				if(children_cells.data[i].marker_selected() && (! children_cells.data[i].lock)) {
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
		

		public bool marker_selected() {
			return marker.sensitive ? marker.active : false;
		}

		public uint get_level() {
			return level;
		}

		public void focus_cell() {
			if(children_cells.length > 0){
				children_cells.data[0].focus_cell();
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

			for(int i=0; i<children_cells.data.length; i++) {
				if(children_cells.data[i].search(type))
					return true;
			}

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

		// implement TreeModel
		public int get_n_columns() { return seaborg_get_n_columns(); }
		public Type get_column_type (int index_) { return seaborg_get_column_type(index_); }		
		public Gtk.TreeModelFlags get_flags() { return seaborg_get_flags(); }	
		public bool get_iter (out Gtk.TreeIter iter, Gtk.TreePath path) { return  seaborg_get_iter(out iter, path); }
		public void get_value(Gtk.TreeIter iter, int column, out Value val) { seaborg_get_value(iter, column, out val); }
		public new  Gtk.TreePath? get_path(Gtk.TreeIter iter) { return seaborg_get_path(iter); }
		public bool iter_has_child(Gtk.TreeIter iter) { return seaborg_iter_has_child(iter); }
		public int iter_n_children(Gtk.TreeIter? iter) { return seaborg_iter_n_children(iter); }
		public bool iter_next(ref Gtk.TreeIter iter) { return seaborg_iter_next(ref iter); }
		public bool iter_previous(ref Gtk.TreeIter iter) { return seaborg_iter_previous(ref iter); }
		public bool iter_nth_child(out Gtk.TreeIter iter, Gtk.TreeIter? parent, int n) { return seaborg_iter_nth_child(out iter, parent, n); }
		public bool iter_children(out Gtk.TreeIter iter, Gtk.TreeIter? parent) { return seaborg_iter_children(out iter, parent); }
		public bool iter_parent(out Gtk.TreeIter iter, Gtk.TreeIter child) { return seaborg_iter_parent(out iter, child);}

		public GLib.Array<ICell> children_cells {get; set;}
		public GLib.Array<AddButton> addbutton_list {get; set;}
		public ICellContainer* parent_cell {get; set;}
		public double zoom_factor {get; set;}
		public Gtk.SourceSearchSettings search_settings {get; set;}
		protected int iter_stamp {get; set;}
		private uint level;
		private Gtk.ToggleButton marker;
		private CssProvider css;
		private Gtk.Button footer;
	}


}