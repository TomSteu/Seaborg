using Gtk;
using Gdk;

namespace Seaborg {

	/* Cell Levels:
	 * 
	 *   0 - Evaluation/Text
	 *   1 - Subsubsection
	 *   2 - Subsection
	 *   3 - Section
	 *   4 - Subchapter
	 *   5 - Chapter 
	 *   6 - Title
	 *   7 - Notebook
	 *
	 */

	// interface for each cell as well as containers for cells
	public interface ICell : Gtk.Widget {
		public abstract void toggle_all();
		public abstract void untoggle_all();
		public abstract void expand_all();
		public abstract void collapse_all();
		public abstract bool marker_selected {get; set;}
		public abstract uint get_level();
		public abstract void remove_recursively();
		public abstract void add_before(int pos, ICell[] list);
		public abstract void remove_from(int pos, int number, bool trash);
		public abstract void focus_cell();
		public abstract ICellContainer* parent_cell {get; set;}
		public abstract void set_text(string _text);
		public abstract string get_text();
		public abstract bool lock {get; set;}
		public abstract void cell_check_resize();
		public abstract void zoom_font(double factor);
		public abstract bool search(SearchType type);
		public abstract void replace_all(string rep);
		public abstract bool do_forward_search(ref bool last_found);
		public abstract bool do_backward_search(ref bool last_found);
		public abstract string get_tree_title();

		public bool untoggle_handler(EventButton event) {

			if(event.type == Gdk.EventType.BUTTON_PRESS && event.button == 1) {
				
				recursive_untoggle_all();
				toggle_all();

			}

			return false;

		}

		public void recursive_untoggle_all() {
			if(parent_cell == null) {
				untoggle_all();
			} else {
				ICellContainer* par = parent_cell;
				while(true) {
					if(par->parent_cell == null)
						break;
					par = par->parent_cell;
				}
				par->untoggle_all();
			}
		}

		protected void insert_handler(ref TextIter iter, string txt, int txt_len) {

			switch (txt) {
				case "(":
					iter.get_buffer().insert(ref iter, ")", 1);
					break;
				case "[":
					iter.get_buffer().insert(ref iter, "]", 1);
					break;
				case "{":
					iter.get_buffer().insert(ref iter, "}", 1);
					break;
				default:
					return;
			}

			iter.backward_cursor_position();
			iter.get_buffer().place_cursor(iter);

			return;
		}

	}

	public interface ICellContainer : ICell {
		public abstract GLib.Array<ICell> children_cells {get; set;}
		public abstract GLib.Array<AddButton> addbutton_list {get; set;}
		public abstract double zoom_factor {get; set;}
		public abstract Gtk.SourceSearchSettings search_settings {get; set;}
		public abstract  Gtk.TreeStore tree_model {get; set;}
		public ICell* get_child_by_name(string child_name) {
			ICell* child_cell = null;
			for(int i=0; i<children_cells.data.length; i++) {
				
				if((ICellContainer*) children_cells.data[i] != null) {
					child_cell = ((ICellContainer*) children_cells.data[i])->get_child_by_name(child_name);
					if(child_cell != null)
						break;
				}
				
				if(children_cells.data[i].name == child_name) {
					child_cell = children_cells.data[i];
					break;
				}
			}
			return child_cell;
		}

		protected void update_tree(Gtk.TreeIter? iter = null, ICellContainer container = this) {
			
			Gtk.TreeIter child_iter;
			
			// root node
			if(iter == null) {
				
				// wipe tree store first
				tree_model = new Gtk.TreeStore(4, typeof(string), typeof(uint), typeof(string), typeof(ICell));
				
			}

			for(int i=0; i<container.children_cells.data.length; i++) {

				tree_model.append(out child_iter, iter);
				tree_model.set(child_iter, 0, container.children_cells.data[i].name, 1, container.children_cells.data[i].get_level(), 2, container.children_cells.data[i].get_tree_title(), 3, container.children_cells.data[i], -1);

				if(container.children_cells.data[i].get_level() > 0) {
					update_tree(child_iter, (ICellContainer) container.children_cells.data[i]);
				}
			}

			return;

		}


	}

}