using Gtk;

namespace Seaborg {
	
	public class Notebook : Gtk.Grid, ICell, ICellContainer {
		public Notebook() {
			this.name = IdGenerator.get_id();
			Parent = null;
			Level = 7;
			zoom_factor = 1;
			Children = new GLib.Array<ICell>();
			AddButtons = new GLib.Array<AddButton>();
			
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

			Marker = new Gtk.ToggleButton();
			Marker.can_focus = false;
			var style_context = Marker.get_style_context();
			style_context.add_provider(css, Gtk.STYLE_PROVIDER_PRIORITY_USER);
			style_context.add_class("cell-marker");
			get_style_context().add_class("view");
			get_style_context().add_class("container-grid");

			// final Addbutton to fill the bottom of the window
			Footer = new AddButton(this);
			Footer.name = IdGenerator.get_id();
			Footer.can_focus = false;
			Footer.focus_on_click = false;
			Footer.get_style_context().add_class("add-button");
			Footer.vexpand = true;
			Footer.valign = Gtk.Align.FILL;
			Footer.clicked.connect(() => { AddButtons.data[AddButtons.data.length-1].insert_child();});

			// assemble the container
			attach(Marker, 0, 0, 1, 2);
			AddButtons.append_val(new AddButton(this));
			attach(AddButtons.index(0), 1, 0, 1, 1);
			attach(Footer, 0, 2, 2, 1);
		}

		public void remove_recursively() {
			int i;
			for(i=(int)(Children.length)-1; i >= 0; i--) {
				if(Children.data[i].marker_selected() && (! Children.data[i].lock)) {
					remove_from(i,1,true);
				}
			}

			for(i=0; i<(int)(Children.length); i++) Children.index(i).remove_recursively();
			show_all();
		}

		public void add_before(int pos, ICell[] list) {

			int old_len = (int)(Children.length);
			if(pos < 0 ) pos += old_len + 1;
			if(pos < 0 || pos > old_len)
				return;

			for(int l=0; l<list.length; l++) 
				list[l].Parent = this;

			for(int j=1; j<=2*list.length; j++) 
				insert_row(2*pos+1);

			Children.insert_vals(pos, list, list.length);
			for(int k=0; k < list.length; k++) AddButtons.insert_val(pos+1, new AddButton(this));
			for(int i=0; i<list.length; i++) {
					attach(Children.data[pos+i], 1, 2*(pos+i)+1, 1, 1);
					attach(AddButtons.data[pos+1+i], 1,  2*(pos+i)+2, 1, 1);
			}

			this.show_all();

		}

		public void remove_from(int pos, int number, bool trash) {

			if(pos < 0 || number <= 0)
				return;

			if(pos+number > Children.data.length)
				number = (int)(Children.length) - pos;

			// manually remove objects since they are exluded from reference counting
			if(trash) {
				ICell* ref_child;
				AddButton* ref_button;
				for(int j=0; j<number; j++) {
					ref_child =  Children.data[pos+j];
					ref_button = AddButtons.data[pos+1+j];
					delete ref_child;
					delete ref_button;
				}
			}


			Children.remove_range(pos, number);
			AddButtons.remove_range(pos+1, number);
			for(int i=1; i <= 2*number; i++) remove_row(2*pos+1);

		}

		public void toggle_all() {
			Marker.active = true;
			for(int i=0; i<Children.data.length; i++) {
				Children.data[i].toggle_all();
			}
		}

		public void untoggle_all() {
			Marker.active = false;
			for(int i=0; i<Children.data.length; i++) {
				Children.data[i].untoggle_all();
			}
		}

		public void expand_all() {
			for(int i=0; i<Children.data.length; i++) {
				Children.data[i].expand_all();
			}
		}

		public void collapse_all() {
			for(int i=0; i<Children.data.length; i++) {
				Children.data[i].collapse_all();
			}
		}

		public bool lock {
			set {
				for(int i=0; i<Children.data.length; i++) {
					Children.data[i].lock = value;
				}
			}

			get {
				for(int i=0; i<Children.data.length; i++) {
					if(Children.data[i].lock)
						return true;
				}
				 return false;
			}
		}
		

		public bool marker_selected() {
			return Marker.sensitive ? Marker.active : false;
		}

		public uint get_level() {
			return Level;
		}

		public void focus_cell() {
			if(Children.length > 0)
				Children.data[0].focus_cell();
		}

		public void set_text(string _text) {}
		public string get_text() { return ""; }

		public void cell_check_resize() {

			for(int i=0; i<Children.data.length; i++) {
				Children.data[i].cell_check_resize();
			}
		}

		public void zoom_font(double factor) {
			zoom_factor = factor;

			for(int i=0; i<Children.data.length; i++) {
				Children.data[i].zoom_font(factor);
			}
		}

		public bool search(SearchType type) {

			for(int i=0; i<Children.data.length; i++) {
				if(Children.data[i].search(type))
					return true;
			}

			return false;
		}

		public void replace_all(string rep) {

			for(int i=0; i<Children.data.length; i++) {
				Children.data[i].replace_all(rep);
			}
		}

		public GLib.Array<ICell> Children {get; set;}
		public GLib.Array<AddButton> AddButtons {get; set;}
		public ICellContainer* Parent {get; set;}
		public double zoom_factor {get; set;}
		public Gtk.SourceSearchSettings search_settings {get; set;}
		private uint Level;
		private Gtk.ToggleButton Marker;
		private CssProvider css;
		private Gtk.Button Footer;
	}


}