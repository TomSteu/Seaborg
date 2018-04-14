using Gtk;

namespace Seaborg {
	
	public class PlotFrame : Gtk.Grid {
		
		public PlotFrame(string file, EvaluationCell* _parent) {

			parent_cell = _parent;
			svg_file = file;

			try {

				css = new CssProvider();

				try {

					css.load_from_path("res/seaborg.css");

				} catch(GLib.Error error) {

					css = CssProvider.get_default();
				}

				
				handle = new Rsvg.Handle.from_file(file);
				handle.close();

				this.get_style_context().add_provider(css, Gtk.STYLE_PROVIDER_PRIORITY_USER);
				this.get_style_context().add_class("transparent-widget");
				this.set_row_homogeneous(false);
				this.set_column_homogeneous(false);
				
				plot = new Gtk.Image();
				plot.get_style_context().add_provider(css, Gtk.STYLE_PROVIDER_PRIORITY_USER);
				plot.get_style_context().add_class("plot-frame");

				zoom_factor = 1;
				draw_image();
				
				toolbar = new Gtk.Grid();
				toolbar.get_style_context().add_provider(css, Gtk.STYLE_PROVIDER_PRIORITY_USER);
				toolbar.get_style_context().add_class("transparent-widget");
				toolbar.set_row_homogeneous(false);
				toolbar.set_column_homogeneous(false);

				zoom_in = new Gtk.Button.with_label("+");
				zoom_in.get_style_context().add_provider(css, Gtk.STYLE_PROVIDER_PRIORITY_USER);
				zoom_in.get_style_context().add_class("zoom-button");
				zoom_in.clicked.connect(do_zoom_in);
				zoom_in.has_tooltip = true;
				zoom_in.tooltip_text = "zoom in";
				
				zoom_out = new Gtk.Button.with_label("-");
				zoom_out.get_style_context().add_provider(css, Gtk.STYLE_PROVIDER_PRIORITY_USER);
				zoom_out.get_style_context().add_class("zoom-button");
				zoom_out.clicked.connect(do_zoom_out);
				zoom_out.has_tooltip = true;
				zoom_out.tooltip_text = "zoom in";

				copy_button = new Gtk.Button.with_label("⎘");
				copy_button.get_style_context().add_provider(css, Gtk.STYLE_PROVIDER_PRIORITY_USER);
				copy_button.get_style_context().add_class("zoom-button");
				copy_button.clicked.connect(do_copy_to_clipboard);
				copy_button.has_tooltip = true;
				copy_button.tooltip_text = "copy to clipboard";
				
				toolbar.attach(zoom_in, 0, 0, 1, 1);
				toolbar.attach(copy_button, 0, 1, 1, 1);
				toolbar.attach(zoom_out, 0, 2, 1, 1);
				

				this.attach(toolbar, 0, 0, 1, 1);
				this.attach(plot, 1, 0, 1, 1);

			} catch (GLib.Error err) {
				handle = null;
			}
		}

		public bool import_success() {
			return (handle == null)? false : true;
		}

		private void do_zoom_in() {

			zoom_factor++;
			draw_image();
			parent_cell->cell_check_resize();
		
		}

		private void do_zoom_out() {

			zoom_factor--;
			draw_image();
			parent_cell->cell_check_resize();

		}

		private void do_copy_to_clipboard() {
			
			FileStream? fs = FileStream.open(data_file, "r");
			if(fs != null) {
				
				string content = fs.read_line();
				
				while(! fs.eof()) {
					content = content + "\n" + fs.read_line();
				}

				Gtk.Clipboard.get(Gdk.SELECTION_CLIPBOARD).set_text(content, content.length);

			} 
		}

		private void draw_image() {
			
			if(handle == null)
				return;

			double factor = GLib.Math.pow((1.2), zoom_factor);

			if(int.min((int)(factor*handle.width), (int)(factor*handle.height)) < 1) {
				zoom_factor++;
				return;
			}

			Cairo.ImageSurface surface = new Cairo.ImageSurface(
				Cairo.Format.ARGB32,
				(int) (factor*handle.width),
				(int) (factor*handle.height)
			);

			Cairo.Context context = new Cairo.Context(surface);
			context.scale(factor, factor);
			handle.render_cairo(context);

			plot.clear();
			plot.set_from_surface(surface);

		}



		private Gtk.Image plot;
		private Rsvg.Handle handle;
		private Gtk.Button zoom_in;
		private Gtk.Button zoom_out;
		private Gtk.Button copy_button;
		private Gtk.Grid toolbar;
		private int zoom_factor;
		private CssProvider css;
		private EvaluationCell* parent_cell;
		public string svg_file {get; set;}
		public string data_file {get; set;}
	}

}