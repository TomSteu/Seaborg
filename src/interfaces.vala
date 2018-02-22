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
		public abstract bool marker_selected();
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

		// implement TreeModel
		// TreeIter:
		// 	int stamp 			- copy of stamp_iter
		// 	void* user_data 	- GLib.List<int> as the path
		// 	void* user_data2	- ICell cell with iterator
		
		public int seaborg_get_n_columns() { return 3; }

		public Type seaborg_get_column_type (int index_) {
			switch (index_) {
				// name
				case 0:
					return typeof(string);
				// level
				case 1:
					return typeof(uint);
				// title
				case 2:
					return typeof(string);
				default:
					return Type.INVALID;
			}			
		}

		public Gtk.TreeModelFlags seaborg_get_flags () {
			return 0;
		}

		public bool seaborg_get_iter (out Gtk.TreeIter iter, Gtk.TreePath path) {
			
			GLib.List<int> user_data = new GLib.List<int>();
			iter = Gtk.TreeIter();

			// check index structure
			int[] indices = path.get_indices();
			ICell child = this;
			for(int index=0; index < indices.length; index++) {
				if(((ICellContainer) child) != null) {
					if(((ICellContainer) child).children_cells.data.length < indices[index]) {
						child = ((ICellContainer) child).children_cells.data[indices[index]];
						user_data.append(indices[index]);
						continue;
					}
				}

				// the index structure is not correct
				
				iter.stamp = -1;
				return false;
			}

			iter.stamp = iter_stamp;
			iter.user_data = (void*) user_data;
			iter.user_data2 = (void*) child;
			return true;
			
		}

		public void seaborg_get_value(Gtk.TreeIter iter, int column, out Value val) {
			if(iter.stamp == iter_stamp) {
				switch (column) {

					case 0:
						val = Value(typeof(string));
						val.set_string(((ICell)iter.user_data2).name);
						break;
					case 1:
						val = Value(typeof(uint));
						val.set_uint(((ICell)iter.user_data2).get_level());
						break;
					case 2:
						val = Value(typeof(string));
						val.set_string(((ICell)iter.user_data2).get_tree_title());
						break;
					default:
						val = Value (Type.INVALID);
						break;
				}
			} else {
				val = Value (Type.INVALID);
			} 

			return;
		}

		public Gtk.TreePath? seaborg_get_path(Gtk.TreeIter iter) {
			
			if(iter.stamp == iter_stamp) {

				Gtk.TreePath path = new Gtk.TreePath();
				foreach (int index in ((GLib.List<int>)iter.user_data)) {
					path.append_index(index);
				}

				return path;
			}

			return null;
		}

		public bool seaborg_iter_has_child(Gtk.TreeIter iter) {
			return (seaborg_iter_n_children(iter) > 0);
		}

		public int seaborg_iter_n_children(Gtk.TreeIter? iter) {
			if(iter != null && iter.stamp != iter_stamp)
				return -1;

			if(iter == null)
				return children_cells.data.length;

			if(((ICellContainer) iter.user_data2) == null)
				return 0;

			return ((ICellContainer) iter.user_data2).children_cells.data.length;

		}

		public bool seaborg_iter_next(ref Gtk.TreeIter iter) {
			if(iter.stamp == iter_stamp) {

				GLib.List<int> list = ((GLib.List<int>)iter.user_data).copy();
				int pos = list.last().data + 1;
				
				if(pos >= ((ICell)iter.user_data2).parent_cell->children_cells.data.length)
					return false;

				list.remove_link(list.last());
				list.append(pos); 
				iter.user_data = (void*) list;
				iter.user_data2 = (void*) ((ICell)iter.user_data2).parent_cell->children_cells.data[pos];
				return true;

			}

			return false;
		}

		public bool seaborg_iter_previous(ref Gtk.TreeIter iter) {
			if(iter.stamp == iter_stamp) {

				GLib.List<int> list = ((GLib.List<int>)iter.user_data).copy();
				int pos = list.last().data - 1;
				
				if(pos < 0)
					return false;

				list.remove_link(list.last());
				list.append(pos); 
				iter.user_data = (void*) list;
				iter.user_data2 = (void*) ((ICell)iter.user_data2).parent_cell->children_cells.data[pos];
				return true;

			}

			return false;
		}

		public bool seaborg_iter_nth_child(out Gtk.TreeIter iter, Gtk.TreeIter? parent, int n) {
			
			iter = Gtk.TreeIter();
			
			if(n < seaborg_iter_n_children(parent)) {

				if(parent == null) {

					iter.stamp = iter_stamp;

					GLib.List<int> user_data = new GLib.List<int>();
					user_data.append(n);
					iter.user_data = (void*) user_data;
					iter.user_data2 = ((void*) (children_cells.data[n]));

					return true;
				}
				
				if(parent != null &&  parent.stamp == iter_stamp) {
					
					iter.stamp = iter_stamp;
					
					GLib.List<int> user_data = ((GLib.List<int>)parent.user_data).copy();
					user_data.append(n);
					iter.user_data = (void*) user_data;
					iter.user_data2 = ((void*) (((ICellContainer) parent.user_data2).children_cells.data[n]));

					return true;

				}
			}

			iter.stamp = -1;
			return false;
		}

		public bool seaborg_iter_children(out Gtk.TreeIter iter, Gtk.TreeIter? parent) {
			return seaborg_iter_nth_child(out iter, parent, 0);
		}

		public bool seaborg_iter_parent(out Gtk.TreeIter iter, Gtk.TreeIter child) {
			
			iter = Gtk.TreeIter();

			if(child.stamp == iter_stamp) {
				
				ICell cell = ((ICell) child.user_data2);
				
				if(cell.parent_cell != null) {

					GLib.List<int> list = ((GLib.List<int>)iter.user_data).copy();
					list.remove_link(list.last());

					iter.stamp = iter_stamp;
					iter.user_data = (void*) list;
					iter.user_data2 = (void*) cell.parent_cell;
					
					return true;

				}
			}

			iter.stamp = -1;
			return false;
		}

		protected void update_tree() {
			iter_stamp++;
		}

		protected abstract int iter_stamp {get; set;}

	}

}