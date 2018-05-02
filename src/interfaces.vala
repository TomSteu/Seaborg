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
		public abstract bool cell_expanded {get;}
		public abstract uint get_level();
		public abstract void remove_recursively();
		public abstract void add_before(int pos, ICell[] list);
		public abstract void remove_from(int pos, int number, bool trash);
		public abstract void focus_cell(bool grab_selection = true);
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
		public abstract ICell* first_cell();
		public abstract ICell* last_cell();
		public abstract void set_wrap_mode(Gtk.WrapMode wrap);
		public abstract string cell_checksum();
		public signal void cell_focused(Gtk.Widget widget);

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
					// the next line is not a bug but a clever trick
					iter.get_buffer().insert(ref iter, ") ", 1);
					iter.backward_cursor_position();
					iter.get_buffer().place_cursor(iter);
					break;
				case "[":
					iter.get_buffer().insert(ref iter, "] ", 1);
					iter.backward_cursor_position();
					iter.get_buffer().place_cursor(iter);
					break;
				case "{":
					iter.get_buffer().insert(ref iter, "} ", 1);
					iter.backward_cursor_position();
					iter.get_buffer().place_cursor(iter);
					break;
				case ")":
					if(iter.get_char() == ')') {
						Gtk.TextIter iter2 = iter;
						iter2.forward_char();
						iter.get_buffer().delete(ref iter, ref iter2);
					}
					break;
				case "]":
					if(iter.get_char() == ']') {
						Gtk.TextIter iter2 = iter;
						iter2.forward_char();
						iter.get_buffer().delete(ref iter, ref iter2);
					}
					break;
				case "}":
					if(iter.get_char() == '}') {
						Gtk.TextIter iter2 = iter;
						iter2.forward_char();
						iter.get_buffer().delete(ref iter, ref iter2);
					}
					break;
				default:
					return;
			}

			return;
		}

	}

	public interface ICellContainer : ICell {
		public abstract GLib.Array<ICell> children_cells {get; set;}
		public abstract GLib.Array<AddButton> addbutton_list {get; set;}
		public abstract double zoom_factor {get; set;}
		public abstract Gtk.SourceSearchSettings search_settings {get; set;}
		public abstract void prev_cell(string cell_name, bool grab_selection = true);
		public abstract void next_cell(string cell_name, bool grab_selection = true);
		public abstract Gtk.TreeStore tree_model {get; set;}
		
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


		public void marker_selection_recursively(bool status) {
			
			marker_selected = status;

			for(int i=0; i<children_cells.data.length; i++) {
				
				children_cells.data[i].marker_selected = status;
				
				if(children_cells.data[i] is ICellContainer) {
					(children_cells.data[i] as ICellContainer).marker_selection_recursively(status);
				}
			}
		}


		public bool apply_to_children(cell_func func) {

			for(int i=0; i<children_cells.data.length; i++) {
				
				if(! func(children_cells.data[i]))
					return false;
				
				if(children_cells.data[i].get_level() > 0) {
					if(! ((ICellContainer) children_cells.data[i]).apply_to_children(func))
						return false;
				}
			}

			return true;
		}


		public void collapse_children(bool collapse_selected, bool collapse_self) {
			if(collapse_self) {
				if(collapse_selected) {
					if(marker_selected) {
						collapse_all();
						return;
					}
				} else {
					collapse_all();
					return;
				}
			}

			for(int i=0; i<children_cells.data.length; i++) {
				if(children_cells.data[i].get_level() > 0) {
					((ICellContainer) children_cells.data[i]).collapse_children(collapse_selected, true);
					continue;
				}
				if(!collapse_selected || children_cells.data[i].marker_selected) {
					children_cells.data[i].collapse_all();
				}
			}
		}


		public void expand_children(bool expand_selected) {

			if( expand_selected) {
				if(marker_selected) {
					expand_children(false);
					return;
				} else {
					if(!cell_expanded)
						return;
				}
			}

			expand_all();

			for(int i=0; i<children_cells.data.length; i++) {
				if(children_cells.data[i].get_level() > 0) {
					((ICellContainer) children_cells.data[i]).expand_children(expand_selected);
					continue;
				}
				if(!expand_selected || children_cells.data[i].marker_selected) {
					children_cells.data[i].expand_all();
				}
			}
		}


		public ICell? first_selected_child() {
			
			ICell? cell = null; 
			
			for(int i=0; i<children_cells.data.length; i++) {
				
				if(children_cells.data[i].marker_selected) {
					cell = children_cells.data[i];
					break;
				}

				if(children_cells.data[i].get_level() > 0) {
					cell = ((ICellContainer)children_cells.data[i]).first_selected_child();
					if(cell != null)
						break;
				}
			}

			return cell;
		}


		protected void update_tree() {

			// make sure only root container updates tree
			if(parent_cell != null) {
				parent_cell->update_tree();
				return;
			}

			Gtk.TreeStore _tree_model = new Gtk.TreeStore(4, typeof(string), typeof(uint), typeof(string), typeof(ICell));

			update_tree_iteratively(null, this, ref _tree_model);

			// update the tree_model - now notify events can trigger
			tree_model = _tree_model;

			return;

		}
		

		private void update_tree_iteratively(Gtk.TreeIter? iter, ICellContainer container, ref Gtk.TreeStore _tree_model) {

			Gtk.TreeIter child_iter;

			for(int i=0; i<container.children_cells.data.length; i++) {

				_tree_model.append(out child_iter, iter);
				_tree_model.set(child_iter, 0, container.children_cells.data[i].name, 1, container.children_cells.data[i].get_level(), 2, container.children_cells.data[i].get_tree_title(), 3, container.children_cells.data[i], -1);

				if(container.children_cells.data[i].get_level() > 0) {
					update_tree_iteratively(child_iter, (ICellContainer) container.children_cells.data[i], ref _tree_model);
				}
			}
		}
		

	}

	public delegate bool cell_func(ICell cell);

}