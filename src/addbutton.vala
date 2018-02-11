using Gtk;

namespace Seaborg {

	// add buttons to insert cell
	public class AddButton : Gtk.Button {
		public AddButton(ICellContainer* par) {
			this.name = IdGenerator.get_id();
			this.can_focus = false;
			this.focus_on_click = false;
			Parent = par;

			CssProvider css = new CssProvider();
			get_style_context().add_provider(css, Gtk.STYLE_PROVIDER_PRIORITY_USER);

			try {

				css.load_from_path("res/seaborg.css");

			} catch(GLib.Error error) {

				css = CssProvider.get_default();
			}

			get_style_context().add_class("add-button");

			
			clicked.connect(insert_child);

		}

		public void insert_child() {
			int pos;

			for(pos=0; pos < Parent->AddButtons.data.length; pos++) {
				if(this.name == Parent->AddButtons.data[pos].name)
					break;
			}
				
			if(pos < Parent->AddButtons.data.length) {
					
				// if this button is right after container create one with same level
				if(pos > 0) {
					uint lev = Parent->Children.data[pos-1].get_level();
					if(lev > 0) {
						CellContainer* newCell = new CellContainer(Parent, lev);
						Parent->add_before(pos, {newCell});
						newCell->eat_children();
						newCell->focus_cell();
						newCell->recursive_untoggle_all();
						newCell->toggle_all();
						return;
					}
				}
					
				// add evaluation cell as default behaviour
				EvaluationCell* newCell = new EvaluationCell(Parent);
				Parent->add_before(pos, {newCell});
				newCell->focus_cell();
				newCell->recursive_untoggle_all();
				newCell->toggle_all();
			}
		}

		private ICellContainer* Parent;

	}

}