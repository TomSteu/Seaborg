using Gtk;
using Gdk;

namespace Seaborg {

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
		public abstract ICellContainer* Parent {get; set;}
		public abstract void set_text(string _text);
		public abstract string get_text();
		public abstract bool lock {get; set;}

		public bool untoggle_handler(EventButton event) {

			if(event.type == Gdk.EventType.BUTTON_PRESS && event.button == 1) {
				
				recursive_untoggle_all();
				toggle_all();

			}

			return false;

		}

		public void recursive_untoggle_all() {
			if(Parent == null) {
				untoggle_all();
			} else {
				ICellContainer* par = Parent;
				while(true) {
					if(par->Parent == null)
						break;
					par = par->Parent;
				}
				par->untoggle_all();
			}
		}

	}

	

	public interface ICellContainer : ICell {
		public abstract GLib.Array<ICell> Children {get; set;}
		public abstract GLib.Array<AddButton> AddButtons {get; set;}
		public ICell* get_child_by_name(string child_name) {
			ICell* child_cell = null;
			for(int i=0; i<Children.data.length; i++) {
				
				if((ICellContainer*) Children.data[i] != null) {
					child_cell = ((ICellContainer*) Children.data[i])->get_child_by_name(child_name);
					if(child_cell != null)
						break;
				}
				
				if(Children.data[i].name == child_name) {
					child_cell = Children.data[i];
					break;
				}
			}
			return child_cell;
		}
	}

	
	public class IdGenerator : GLib.Object {

		public static void reset() {
			id = 0;
		}

		public static string get_id() {
			return (id++).to_string();
		}

  		private static int id = 0;
	}

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

	public class Notebook : Gtk.Grid, ICell, ICellContainer {
		public Notebook() {
			this.name = IdGenerator.get_id();
			Parent = null;
			Level = 7;
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

			Marker = new Gtk.ToggleButton();
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

		public GLib.Array<ICell> Children {get; set;}
		public GLib.Array<AddButton> AddButtons {get; set;}
		public ICellContainer* Parent {get; set;}
		private uint Level;
		private Gtk.ToggleButton Marker;
		private CssProvider css;
		private Gtk.Button Footer;
	}

	// container class with heading
	public class CellContainer : Gtk.Grid, ICell, ICellContainer {
		public CellContainer(ICellContainer* parent, uint level) {
			this.name = IdGenerator.get_id();
			Parent = parent;
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

			Title = new Gtk.TextView();
			Title.get_style_context().add_provider(css, Gtk.STYLE_PROVIDER_PRIORITY_USER);
			Title.wrap_mode = Gtk.WrapMode.WORD;
			Title.monospace = false;
			Title.editable = true;
			Title.hexpand = true;
			Title.halign = Gtk.Align.FILL;
			Title.left_margin = 0;
			Title.right_margin = 0;
			Title.top_margin = 0;
			Title.bottom_margin = 0;
			Title.wrap_mode = Gtk.WrapMode.WORD;
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


			set_level(level);

			Marker = new Gtk.ToggleButton();
			var style_context = Marker.get_style_context();
			style_context.add_provider(css, Gtk.STYLE_PROVIDER_PRIORITY_USER);
			style_context.add_class("cell-marker");
			get_style_context().add_class("view");
			get_style_context().add_class("container-grid");

			// assemble the container
			attach(Marker, 0, 0, 1, 2);
			attach(Title, 1, 0, 1, 1);
			AddButtons.append_val(new AddButton(this));
			attach(AddButtons.index(0), 1, 1, 1);

			Marker.button_press_event.connect(press_handler);
			isExpanded = true;
			show_all();

		}

		public void eat_children() {

			if(Parent == null) return;

			int this_position=-1;

			// eat younger silblings and transfer to parent
			if(Parent->get_level() <= Level) {

				int par_len = Parent->Children.data.length;

				// find out position within parent
				for(this_position=0; this_position < par_len; this_position++) {
					if(this.name == Parent->Children.data[this_position].name)
						break;
				}

				// move elements from parents into this container
				if(this_position < par_len - 1) {
					var cells = Parent->Children.data[this_position+1 : par_len];
					Parent->remove_from(this_position+1, par_len - 1 - this_position, false);
					add_before(-1, cells);					
				}
				
				// put Container from parent into grandparent
				if(Parent->Parent != null) {

					// find position of parent within grandparent
					int parent_position;
					for(parent_position=0; parent_position < Parent->Parent->Children.data.length; parent_position++) {
						if(Parent->name == Parent->Parent->Children.data[parent_position].name)
							break;
					}

					if(parent_position >= Parent->Parent->Children.data.length)
						return;
					
					// move container 
					Parent->remove_from(this_position, 1, false);
					Parent->Parent->add_before(parent_position+1, { this });
					eat_children();

				}

			} else {

				int next_position=-1;
				
				// find out where the next container (e.g. section) of the same or higher level is
				for(int i=0; i<(Parent->Children).data.length; i++) {
					if((Parent->Children).data[i].name == this.name)
						this_position = i;
					if(Parent->Children.data[i].get_level() >= Level && i > this_position)
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
					next_position = (Parent->Children).data.length;

				// next position somewhere behind move elements from parents into this container
				if(next_position > 0 && this_position+1 < next_position) {
					var cells = Parent->Children.data[this_position+1 : next_position];
					Parent->remove_from(this_position+1, next_position-1 - this_position, false);
					add_before(Children.data.length, cells);
					
				}

			}

			show_all();

		}

		public void remove_recursively() {
			int i;
			for(i=(int)(Children.length)-1; i >= 0; i--) {
				if(Children.index(i).marker_selected() && (! Children.index(i).lock)) {
					remove_from(i,1,true);
				}
			}

			for(i=0; i<Children.data.length; i++) Children.index(i).remove_recursively();

		}

		public void add_before(int pos, ICell[] list) {

			int old_len = (int)(Children.length);
			if(pos < 0 ) pos += old_len + 1;
			if(pos < 0 || pos > old_len)
				return;
			
			for(int l=0; l<list.length; l++) list[l].Parent = this;
			Children.insert_vals(pos, list, list.length);
			AddButtons.set_size(AddButtons.data.length + list.length);
			
			if(! isExpanded) return;
			if(pos < old_len) {
					for(int j=1; j<=2*list.length; j++) insert_row(2*pos+2);;
			}
			for(int k=0; k<list.length; k++) AddButtons.insert_val(pos+1, new AddButton(this));
			for(int i=0; i<(int)(list.length); i++) {
					attach(Children.data[pos+i], 1, 2*(pos+i)+2, 1, 1);
					attach(AddButtons.data[pos+1+i], 1, 2*(pos+i)+3, 1, 1);
			}

			//redraw marker if stuff was attached to the end
			if(pos == old_len) {
				remove_column(0);
				insert_column(0);
				attach(Marker, 0, 0, 1, 2*((int)(Children.length)+1));
			}

			show_all();

		}

		public void remove_from(int pos, int number, bool trash) {

			if(pos < 0 || number <= 0)
				return;

			if(pos+number > (int)(Children.length))
				number = (int)(Children.length) - pos;

			// manually remove objects since they are excluded from reference counting
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
			for(int i=1; i <= 2*number; i++) remove_row(2*pos+2);
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
			if(!isExpanded) {
				remove_column(0);
				attach(AddButtons.data[0], 0, 1, 1, 1);
				for(int i=0; i<Children.data.length; i++) {
					attach(Children.data[i], 0, 2+2*i, 1, 1);
					attach(AddButtons.data[1+i], 0, 3+2*i, 1, 1);
				}
				insert_column(0);
				attach(Marker, 0, 0, 1, 2*(Children.data.length+1));
				isExpanded = true;
				show_all();
			}
		}

		public void collapse_all() {
			if(isExpanded) {

				for(int i=0; i<=2*Children.data.length; i++)
					remove_row(1);
				isExpanded = false;
				show_all();
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
			
			Title.get_style_context().remove_class("title-" + Level.to_string());
			Level = level;
			Title.get_style_context().add_class("title-" + Level.to_string());

		}

		public void focus_cell() {
			Title.grab_focus();
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


		public GLib.Array<ICell> Children {get; set;}
		public GLib.Array<AddButton> AddButtons {get; set;}
		public ICellContainer* Parent {get; set;}
		private uint Level;
		private TextView Title;
		private Gtk.ToggleButton Marker;
		private CssProvider css;
		private bool isExpanded;
	}

	// Generic cell for evaluation
	public class EvaluationCell : Gtk.Grid, ICell {
		
		public EvaluationCell(ICellContainer* par) {
			this.name = IdGenerator.get_id();
			Parent = par;
			column_spacing = 4;
			css = new CssProvider();
			this.get_style_context().add_provider(css, Gtk.STYLE_PROVIDER_PRIORITY_USER);
			_lock = false;

			try {

				css.load_from_path("res/seaborg.css");

			} catch(GLib.Error error) {

				css = CssProvider.get_default();
			}

			Gtk.SourceLanguageManager lm = new Gtk.SourceLanguageManager();
			Gtk.SourceStyleSchemeManager sm = new Gtk.SourceStyleSchemeManager();
 			lm.search_path = new string[] {"res/sourceview/"};
 			sm.search_path = new string[] {"res/sourceview/"};
			
 			InputBuffer = new Gtk.SourceBuffer(null);
			InputBuffer.highlight_matching_brackets = true;
			if(Parameter.code_highlighting) {
				InputBuffer.style_scheme = sm.get_scheme("seaborg");
				if(Parameter.stdlib_highlighting){
					InputBuffer.language =  lm.get_language("wolfram");
				}
				else {
					InputBuffer.language =  lm.get_language("wolfram-nostdlib");
				}
			}
			InputCell = new Gtk.SourceView.with_buffer(InputBuffer);
			InputCell.show_line_numbers = false;
			InputCell.highlight_current_line = false;
			InputCell.auto_indent = true;
			InputCell.indent_on_tab = true;
			InputCell.tab_width = 3;
			InputCell.insert_spaces_instead_of_tabs = false;
			InputCell.smart_backspace = true;
			InputCell.show_line_marks = false;
			InputCell.wrap_mode = Gtk.WrapMode.WORD_CHAR;
			InputCell.monospace = true;
			InputCell.editable = true;
			InputCell.hexpand = true;
			InputCell.halign = Gtk.Align.FILL;
			InputCell.left_margin = 0;
			InputCell.right_margin = 0;
			InputCell.top_margin = 0;
			InputCell.bottom_margin = 0;
			InputCell.button_press_event.connect(untoggle_handler);
			InputCell.key_press_event.connect(key_handler);
			InputBuffer.insert_text.connect(insert_handler); 

			OutputBuffer = new Gtk.SourceBuffer(null);
			OutputBuffer.highlight_matching_brackets = true;
			if(Parameter.code_highlighting) {
				OutputBuffer.style_scheme = sm.get_scheme("seaborg");
				if(Parameter.stdlib_highlighting){
					OutputBuffer.language =  lm.get_language("wolfram");
				}
				else {
					OutputBuffer.language =  lm.get_language("wolfram-nostdlib");
				}
			}

			OutputCell = new Gtk.SourceView.with_buffer(OutputBuffer);
			OutputCell.show_line_numbers = false;
			OutputCell.highlight_current_line = false;
			OutputCell.auto_indent = true;
			OutputCell.indent_on_tab = true;
			OutputCell.tab_width = 3;
			OutputCell.insert_spaces_instead_of_tabs = false;
			OutputCell.smart_backspace = true;
			OutputCell.show_line_marks = false;
			OutputCell.wrap_mode = Gtk.WrapMode.WORD_CHAR;
			OutputCell.monospace = true;
			OutputCell.editable = false;
			OutputCell.hexpand = true;
			OutputCell.halign = Gtk.Align.FILL;
			OutputCell.left_margin = 0;
			OutputCell.right_margin = 0;
			OutputCell.top_margin = 0;
			OutputCell.bottom_margin = 0;
			OutputCell.button_press_event.connect(untoggle_handler);


			Marker = new Gtk.ToggleButton();
			var style_context = Marker.get_style_context();
			style_context.add_provider(css, Gtk.STYLE_PROVIDER_PRIORITY_USER);
			style_context.add_class("cell-marker");
			this.get_style_context().add_class("cell-grid");

			attach(Marker, 0, 0, 1, 1);
			attach(InputCell, 1, 0, 1, 1);

			isExpanded = false;

			Marker.button_press_event.connect(press_handler);
			show_all();

		}

		public void toggle_all() {
			Marker.active = true;

		}

		public void untoggle_all() {
			Marker.active = false;
		}

		public void collapse_all() {
			if(isExpanded) {
				remove_row(1);
				isExpanded = false;
				show_all();
			}
		}

		public uint get_level() {
			return 0;
		}

		public void expand_all() {
			if(!isExpanded) {
				remove_row(0);
				attach(InputCell, 1, 0, 1, 1);
				attach(OutputCell, 1, 1, 1, 1);
				attach(Marker, 0, 0, 1, 2);
				isExpanded = true;
				show_all();
			}
		}

		public bool lock {
			get {return _lock;}
			set {

				if(value == _lock)
					return;

				InputCell.editable = !value;
				Marker.sensitive = !value;
				_lock = value;
			}
		}

		public bool marker_selected() {
			return Marker.sensitive ? Marker.active : false;
		}

		public void focus_cell() {
			InputCell.grab_focus();
		}

		public void remove_recursively() {}

		public void add_before(int pos, ICell[] list) {}
		public void remove_from(int pos, int number, bool trash) {}

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

		private bool key_handler(EventKey key) {

			if(key.type == Gdk.EventType.KEY_PRESS && key.keyval == Gdk.Key.Escape) {
				InputCell.buffer.insert_at_cursor("⋮", "⋮".length);
				TextIter iter;
				int pos = InputCell.buffer.get_char_count() -  InputCell.buffer.cursor_position;
				set_text(replace_characters(get_text()));
				InputCell.buffer.get_iter_at_offset(out iter, InputCell.buffer.get_char_count() - pos);
				InputCell.buffer.place_cursor(iter);

			}

			if(InputBuffer.has_selection && key.type == Gdk.EventType.KEY_PRESS && (bool)(key.state & Gdk.ModifierType.CONTROL_MASK) && key.keyval == Gdk.Key.y) {
				
				TextIter start,end;
				if(InputBuffer.get_selection_bounds(out start, out end)) {
					string str = InputBuffer.get_text(start, end, true);
					str = comment_transform(str);
					InputBuffer.delete(ref start, ref end);
					InputBuffer.insert_at_cursor(str, str.length);

				}
			}

			return false;
		}

		private void insert_handler(ref TextIter iter, string txt, int txt_len) {

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
					break;
			}

			iter.backward_cursor_position();
			iter.get_buffer().place_cursor(iter);

			return;
		}

		public void set_text(string _text) {
			InputBuffer.text = _text;
		}

		public void add_text(string _text) {
			OutputBuffer.text = OutputBuffer.text + _text;
		}

		public string get_text() {
			return InputBuffer.text;
		}

		public void remove_text() {
			OutputBuffer.text = "";
		}

		public string get_output_text() {
			return OutputBuffer.text;
		}

		public ICellContainer* Parent {get; set;}
		private Gtk.SourceView InputCell;
		private Gtk.SourceBuffer InputBuffer;
		private Gtk.SourceView OutputCell;
		private Gtk.SourceBuffer OutputBuffer;
		private Gtk.ToggleButton Marker;
		private bool isExpanded;
		private bool _lock;
		private CssProvider css;

	}

	// Generic Cell for text comments
	public class TextCell : Gtk.Grid, ICell {
		public TextCell(ICellContainer* par) {
			this.name = IdGenerator.get_id();
			Parent = par;
			column_spacing = 4;
			CssProvider css = new CssProvider();
			get_style_context().add_provider(css, Gtk.STYLE_PROVIDER_PRIORITY_USER);

			try {

				css.load_from_path("res/seaborg.css");

			} catch(GLib.Error error) {

				css = CssProvider.get_default();
			}

			Cell = new Gtk.TextView();
			Cell.wrap_mode = Gtk.WrapMode.WORD;
			Cell.monospace = false;
			Cell.editable = true;
			Cell.hexpand = true;
			Cell.halign = Gtk.Align.FILL;
			Cell.left_margin = 0;
			Cell.right_margin = 0;
			Cell.top_margin = 0;
			Cell.bottom_margin = 0;
			Cell.button_press_event.connect(untoggle_handler);
			Cell.key_press_event.connect(insert_ellipsis);

			Marker = new Gtk.ToggleButton();
			Marker.get_style_context().add_provider(css, Gtk.STYLE_PROVIDER_PRIORITY_USER);
			Marker.get_style_context().add_class("cell-marker");

			attach(Marker, 0, 0, 1, 1);
			attach(Cell, 1, 0, 1, 1);

			Marker.button_press_event.connect(press_handler);
			show_all();

		}

		public void toggle_all() {
			Marker.active = true;

		}

		public void untoggle_all() {
			Marker.active = false;
		}

		public bool marker_selected() {
			return Marker.sensitive ? Marker.active : false;
		}

		public uint get_level() {
			return 0;
		}

		public void focus_cell() {
			Cell.grab_focus();
		}

		public void set_text(string _text) {
			Cell.buffer.text = _text;
		}

		public string get_text() {
			return Cell.buffer.text;
		}

		public void remove_recursively() {}
		public void collapse_all() {}
		public void expand_all() {}
		public bool lock {
			set {}
			get {return false;}
		}
		public void add_before(int pos, ICell[] list) {}
		public void remove_from(int pos, int number, bool trash) {}
		public ICellContainer* Parent {get; set;}

		private bool press_handler(EventButton event) {

			if(event.type == Gdk.EventType.BUTTON_PRESS && event.button == 3) {
				ContextMenu context = new ContextMenu(this);
				context.popup_at_widget(Marker, Gdk.Gravity.CENTER, Gdk.Gravity.WEST, null);
			}

			return false;
		}

		private bool insert_ellipsis(EventKey key) {

			if(key.type == Gdk.EventType.KEY_PRESS && key.keyval == Gdk.Key.Escape) {
				Cell.buffer.insert_at_cursor("⋮", "⋮".length);
				TextIter iter;
				int pos = Cell.buffer.get_char_count() -  Cell.buffer.cursor_position;
				set_text(replace_characters(get_text()));
				Cell.buffer.get_iter_at_offset(out iter, Cell.buffer.get_char_count() - pos);
				Cell.buffer.place_cursor(iter);

			}

			return false;
		}

		private Gtk.TextView Cell;
		private Gtk.ToggleButton Marker;
	}

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

	// popup context menu
	public class ContextMenu : Gtk.Menu {
		public ContextMenu(ICell* cell) {
			Cell = cell;
			
			EvaluationCellType = new RadioMenuItem.with_label(null, "Evaluation Cell");
			TextCellType = new RadioMenuItem.with_label_from_widget(EvaluationCellType, "Text Cell");
			TitleType = new RadioMenuItem.with_label_from_widget(EvaluationCellType, "Title");
			ChapterType = new RadioMenuItem.with_label_from_widget(EvaluationCellType, "Chapter");
			SubChapterType = new RadioMenuItem.with_label_from_widget(EvaluationCellType, "Subchapter");
			SectionType = new RadioMenuItem.with_label_from_widget(EvaluationCellType, "Section");
			SubSectionType = new RadioMenuItem.with_label_from_widget(EvaluationCellType, "Subsection");
			SubSubSectionType = new RadioMenuItem.with_label_from_widget(EvaluationCellType, "Subsubsection");

			if(Cell is EvaluationCell)
				EvaluationCellType.active = true;
			if(Cell is TextCell)
				TextCellType.active = true;
			if(Cell is CellContainer) {
				switch(((CellContainer*)Cell)->get_level()) {
					case 1:
						SubSubSectionType.active = true;
						break;
					case 2:
						SubSectionType.active = true;
						break;
					case 3:
						SectionType.active = true;
						break;
					case 4:
						SubChapterType.active = true;
						break;
					case 5:
						ChapterType.active = true;
						break;
					case 6:
						TitleType.active = true;
						break;
				}
			}

			EvaluationCellType.toggled.connect(() => {toggled_evaluation_cell();});
			TextCellType.toggled.connect(() => {toggled_text_cell();});
			TitleType.toggled.connect(() => { toggled_container(6); });
			ChapterType.toggled.connect(() => { toggled_container(5); });
			SubChapterType.toggled.connect(() => { toggled_container(4); });
			SectionType.toggled.connect(() => { toggled_container(3); });
			SubSectionType.toggled.connect(() => { toggled_container(2); });
			SubSubSectionType.toggled.connect(() => { toggled_container(1); });

			this.add(EvaluationCellType);
			this.add(TextCellType);
			this.add(new Gtk.SeparatorMenuItem());
			this.add(TitleType);
			this.add(ChapterType);
			this.add(SubChapterType);
			this.add(SectionType);
			this.add(SubSectionType);
			this.add(SubSubSectionType);

			show_all();

		}

		private void toggled_evaluation_cell() {

			if(Cell is EvaluationCell) 
				return;


			int pos;
			ICellContainer* parent = Cell->Parent;
			if(parent == null) 
				return;

			if(Cell is TextCell) {
				for(pos=0; pos < parent->Children.data.length; pos++) {
					if(parent->Children.data[pos].name == Cell->name)
						break;
				}

				if(pos >= parent->Children.data.length)
					return;

				EvaluationCell* newCell = new EvaluationCell(Cell->Parent);
				newCell->set_text(Cell->get_text());
				parent->add_before(pos, { newCell });
				newCell->focus_cell();
				newCell->recursive_untoggle_all();
				newCell->toggle_all();
				parent->remove_from(pos+1, 1, true);

				return;
			}
			if(Cell is CellContainer) {

				uint level = Cell->get_level();
				if(level<=0)
					return;
				if(level > 1) {
					toggled_container(1);
				}

				parent = Cell->Parent;
				if(parent == null)
					return;

				for(pos=0; pos < parent->Children.data.length; pos++) {
					if(parent->Children.data[pos].name == Cell->name)
						break;
				}

				if(pos >= parent->Children.data.length)
					return;

				//add new cell
				EvaluationCell* newCell = new EvaluationCell(parent);
				var offspring = ((ICellContainer*)Cell)->Children.data;
				((ICellContainer*)Cell)->remove_from(0, offspring.length, false); 
				newCell->set_text(Cell->get_text());
				parent->remove_from(pos, 1, true);
				parent->add_before(pos, { newCell });
				parent->add_before(pos+1, offspring);
				newCell->focus_cell();
				newCell->recursive_untoggle_all();
				newCell->toggle_all();
						
				if(pos > 0) {
					if(parent->Children.data[pos-1].get_level() >= 0 && parent->Children.data[pos-1] is CellContainer) {
						((CellContainer)(parent->Children.data[pos-1])).eat_children();
					}
				}
						
				return;

			}
		}

		private void toggled_text_cell() {
			if(Cell is TextCell)
				return;

			int pos;
			
			ICellContainer* parent = Cell->Parent;
			if(parent == null)
				return;

			if(Cell is EvaluationCell) {
				for(pos=0; pos < parent->Children.data.length; pos++) {
					if(parent->Children.data[pos].name == Cell->name)
						break;
				}

				if(pos >= parent->Children.data.length)
					return;

				TextCell* newCell = new TextCell(parent);
				newCell->set_text(Cell->get_text());
				parent->add_before(pos, { newCell });
				newCell->focus_cell();
				newCell->recursive_untoggle_all();
				newCell->toggle_all();
				parent->remove_from(pos+1, 1, true);

				return;
			}
			if(Cell is CellContainer) {

				uint level = Cell->get_level();
				if(level<=0)
					return;
				if(level > 1) {
					toggled_container(1);
				}

				parent = Cell->Parent;
				if(parent == null)
					return;

				for(pos=0; pos < parent->Children.data.length; pos++) {
					if(parent->Children.data[pos].name == Cell->name)
						break;
				}

				if(pos >= parent->Children.data.length)
					return;

				//add new cell
				EvaluationCell* newCell = new TextCell(parent);
				var offspring = ((ICellContainer*)Cell)->Children.data;
				((ICellContainer*)Cell)->remove_from(0, offspring.length, false); 
				newCell->set_text(Cell->get_text());
				parent->remove_from(pos, 1, true);
				parent->add_before(pos, { newCell });
				parent->add_before(pos+1, offspring);
				newCell->focus_cell();
				newCell->recursive_untoggle_all();
				newCell->toggle_all();
						
				if(pos > 0) {
					if(parent->Children.data[pos-1].get_level() >= 0 && parent->Children.data[pos-1] is CellContainer) {
						((CellContainer)(parent->Children.data[pos-1])).eat_children();
					}
				}

				return;

			}
		}

		private void toggled_container(uint toggled_level) {
			ICellContainer* parent = Cell->Parent;
			if(parent == null)
				return;

			int pos;
			
			if(Cell is EvaluationCell || Cell is TextCell) {
				for(pos=0; pos < parent->Children.data.length; pos++) {
					if(parent->Children.data[pos].name == Cell->name)
						break;
				}

				if(pos >= parent->Children.data.length)
					return;


				CellContainer* newCell = new CellContainer(parent, toggled_level);	
				newCell->set_text(Cell->get_text());	
				parent->remove_from(pos, 1, true);
				parent->add_before(pos, { newCell });
				((CellContainer)(parent->Children.data[pos])).eat_children();
				newCell->focus_cell();
				newCell->recursive_untoggle_all();
				newCell->toggle_all();

				return;
			}
			if(Cell is CellContainer) {

				uint old_level = Cell->get_level();
				
				if(old_level == toggled_level)
					return;

				// this is an level-up -- just eat a couple of more children
				if(old_level<toggled_level) {
					((CellContainer*)Cell)->set_level(toggled_level);
					((CellContainer*)Cell)->eat_children();
					return;
				}

				// downgrade - throw up some children
				if(old_level > toggled_level) {

					// gradually lower level, so there is no need for nested eating silblings
					((CellContainer*)Cell)->set_level(old_level-1);
					parent = Cell->Parent;

					// find cell within parent
					for(pos=0; pos < parent->Children.data.length; pos++) {
						if(parent->Children.data[pos].name == Cell->name)
							break;
					}

					//find out first child to throw up
					int internal_pos;
					var offspring = ((CellContainer*)Cell)->Children.data;
					for(internal_pos=0; internal_pos<offspring.length; internal_pos++) {
						if(offspring[internal_pos].get_level() >= toggled_level)
							break;
					}

					// no need to throw up children
					if(internal_pos < offspring.length) {

						// transfer to parent
						offspring = offspring[internal_pos : offspring.length];
						((CellContainer*)Cell)->remove_from(internal_pos, offspring.length, false);
						parent->add_before(pos+1, offspring);

						// let last released child eat former uncle
						if(pos+offspring.length+1 < parent->Children.data.length) {
							if(parent->Children.data[pos+offspring.length+1].get_level() < parent->Children.data[pos+offspring.length].get_level()) {
								((CellContainer)parent->Children.data[pos+offspring.length]).eat_children();
							}
						}

						// let next oldest silbling of Cell eat children now
						if(pos > 0) {
							if(parent->Children.data[pos-1].get_level() > parent->Children.data[pos].get_level())
								((CellContainer)parent->Children.data[pos-1]).eat_children();
						}
					}

					//next recursion step
					toggled_container(toggled_level);


				}

			}
		}

		private ICell* Cell;
		private RadioMenuItem EvaluationCellType;
		private RadioMenuItem TextCellType;
		private RadioMenuItem TitleType;
		private RadioMenuItem ChapterType;
		private RadioMenuItem SubChapterType;
		private RadioMenuItem SectionType;
		private RadioMenuItem SubSectionType;
		private RadioMenuItem SubSubSectionType;
	}
}