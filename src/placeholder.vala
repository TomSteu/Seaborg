using Gtk;

namespace Seaborg { 

	public class Placeholder : Gtk.Button {
		public Placeholder() {

			CssProvider css = new CssProvider();

				try {

					css.load_from_path("res/seaborg.css");

				} catch(GLib.Error error) {

					css = CssProvider.get_default();
				}

			add(new Gtk.Label("..."));
			get_style_context().add_provider(css, Gtk.STYLE_PROVIDER_PRIORITY_USER);
			get_style_context().add_class("zoom-button");
			has_tooltip = true;
			tooltip_text = "insert long expression";

			this.clicked.connect(() => {
				if( buffer != null && anchor != null) {
					
					TextIter iter;
					buffer.get_iter_at_child_anchor(out iter, anchor);
					buffer.insert(ref iter, hold_expression, hold_expression.length);
					buffer.get_iter_at_child_anchor(out iter, anchor);
					TextIter iter2 = iter;
					iter2.forward_char();
					buffer.delete(ref iter, ref iter2);

				}
			});
		}

		public string hold_expression {get; set;}
		public weak TextBuffer buffer {get; set;}
		public TextChildAnchor anchor {get; set;}
	}
}