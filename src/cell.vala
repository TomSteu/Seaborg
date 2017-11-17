using Gtk;
using Gdk;

namespace Seaborg {

	// interface for each cell as well as containers for cells
	public interface ICell : Gtk.Widget {
		public abstract void toggle_all();
		public abstract void untoggle_all();
		public abstract void expand_all();
		public abstract void collapse_all();
		public abstract void schedule_evaluation();
		public abstract void unschedule_evaluation();
		public abstract bool marker_selected();
		public abstract uint get_level();
		public abstract void remove_recursively();
		public abstract void add_before(int pos, ICell[] list);
		public abstract void remove_from(int pos, int number);
		public abstract void focus();
		public abstract ICellContainer* Parent {get; set;}
		public abstract string text {get; set;} 

	}

	public interface ICellContainer : ICell {
		public abstract GLib.Array<ICell> Children {get; set;}
		public abstract GLib.Array<AddButton> AddButtons {get; set;}

	}

	
	public class IdGenerator : GLib.Object {

		public static void reset() {
			id = 0;
		}

		public static string get_id() {
			return (id++).to_string();
		}

  		private static int id;
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
			IdGenerator.reset();
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

			// assemble the container
			attach(Marker, 0, 0, 1, 1);
			AddButtons.append_val(new AddButton(this));
			attach(AddButtons.index(0), 1, 0, 1, 1);
		}

		public void remove_recursively() {
			int i;
			for(i=(int)(Children.length)-1; i >= 0; i--) {
				if(Children.data[i].marker_selected()) {
					remove_from(i,1);
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

			for(int l=0; l<list.length; l++) list[l].Parent = this;
			if(pos < old_len) {
				for(int j=1; j<=2*list.length; j++) insert_row(2*pos+1);
			}

			Children.insert_vals(pos, list, list.length);
			for(int k=0; k < list.length; k++) AddButtons.insert_val(pos+1, new AddButton(this));
			for(int i=0; i<list.length; i++) {
					attach(Children.data[pos+i], 1, 2*(pos+i)+1, 1, 1);
					attach(AddButtons.data[pos+1+i], 1,  2*(pos+i)+2, 1, 1);
			}

			//redraw marker if stuff was attached to the end
			if(pos == old_len) {
				remove_column(0);
				insert_column(0);
				attach(Marker, 0, 0, 1, 2*((int)(Children.length))+1);
			}
			this.show_all();

		}

		public void remove_from(int pos, int number) {
			
			if(pos < 0 || number <= 0)
				return;

			if(pos+number > Children.data.length)
				number = (int)(Children.length) - pos;

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

		public void schedule_evaluation() {
			for(int i=0; i<Children.data.length; i++) {
				Children.data[i].schedule_evaluation();
			}
		}

		public void unschedule_evaluation() {
			for(int i=0; i<Children.data.length; i++) {
				Children.data[i].unschedule_evaluation();
			}
		}

		public bool marker_selected() {
			return Marker.sensitive ? Marker.active : false;
		}

		public uint get_level() {
			return Level;
		}

		public void focus() {
			if(Children.length > 0)
				Children.data[0].focus();
		}

		public string text {
			get {return "";}
			set {}
		}

		public GLib.Array<ICell> Children {get; set;}
		public GLib.Array<AddButton> AddButtons {get; set;}
		public ICellContainer* Parent {get; set;}
		private uint Level;
		private Gtk.ToggleButton Marker;
		private CssProvider css;
	}

	// container class with heading
	public class CellContainer : Gtk.Grid, ICell, ICellContainer {
		public CellContainer(ICellContainer* parent, uint level) {
			this.name = IdGenerator.get_id();
			Parent = parent;
			Level = level;
			Children = new GLib.Array<ICell>();
			AddButtons = new GLib.Array<AddButton>();
			Title = new TextCell(this);
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
			int this_position=0;
			int next_position=0;
			
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
			
			// move elements from parents into this container
			if(next_position < (Parent->Children).data.length && this_position+1 < next_position) {
				
				add_before(0, Parent->Children.data[this_position+1 : next_position]);
				Parent->remove_from(this_position+1, next_position-1 - this_position);
				
			}
		}

		public void remove_recursively() {
			int i;
			for(i=(int)(Children.length)-1; i >= 0; i--) {
				if(Children.index(i).marker_selected()) {
					remove_from(i,1);
				}
			}

			for(i=0; i<Children.data.length; i++) Children.index(i).remove_recursively();

			if(Title.marker_selected() && Parent != null) {
				// hand children back to parent
				int this_position;
				for(this_position=0; this_position<(Parent->Children).data.length; this_position++) {
					if(Parent->Children.data[this_position].name == this.name)
						break;
				}

				// 'this' is a wayward child
				if(this_position >= Parent->Children.data.length)
					return;
				// 'this' is not firstborn
				if(this_position > 0)
				{
					if(Parent->Children.data[this_position-1].get_level() >= Level) {
						
						// hand children to this_position-1 as children 
						if((Parent->Children.data[this_position-1]) is ICellContainer) {
							((ICellContainer)(Parent->Children.data[this_position-1])).add_before(-1, Children.data);
						}
						
						// erase this_position
						Parent->remove_from(this_position, 1);
						show_all();
						return;
					} 
				}

				// hand children back as siblings of 'this'
				Parent->add_before(this_position, Children.data);

				// erase this_position
				Parent->remove_from(this_position, 1);
				show_all();

			}
		}

		public void add_before(int pos, ICell[] list) {
			
			int old_len = (int)(Children.length);
			if(pos < 0 ) pos += old_len + 1;
			if(pos < 0 || pos > old_len)
				return;
			
			for(int l=0; l<list.length; l++) list[l].Parent = this;
			Children.insert_vals(pos, list, list.length);
			AddButtons.set_size(AddButtons.data.length + list.length);
			
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

		public void remove_from(int pos, int number) {
			
			if(pos < 0 || number <= 0)
				return;

			if(pos+number > (int)(Children.length))
				number = (int)(Children.length) - pos;

			Children.remove_range(pos, number);
			AddButtons.remove_range(pos+1, number);
			for(int i=1; i <= 2*number; i++) remove_row(2*pos+2);

		}

		public void toggle_all() {
			Marker.active = true;
			Title.toggle_all();
			for(int i=0; i<Children.data.length; i++) {
				Children.data[i].toggle_all();
			}
		}

		public void untoggle_all() {
			Marker.active = false;
			Title.untoggle_all();
			for(int i=0; i<Children.data.length; i++) {
				Children.data[i].untoggle_all();
			}
		}

		public void expand_all() {
			if(!isExpanded) {
				remove_column(0);
				attach(AddButtons.data[0], 0, 1, 1, 1);
				for(int i=0; i<Children.data.length; i++) {
					attach(Children.data[i], 0, 1+i, 1, 1);
					attach(AddButtons.data[1+i], 0, 2+i, 1, 1);
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

		public void schedule_evaluation() {
			for(int i=0; i<Children.data.length; i++) {
				Children.data[i].schedule_evaluation();
			}
		}

		public void unschedule_evaluation() {
			for(int i=0; i<Children.data.length; i++) {
				Children.data[i].unschedule_evaluation();
			}
		}

		public bool marker_selected() {
			return Marker.sensitive ? Marker.active : false;
		}

		public string text {
			get {return Title.text; }
			set {Title.text = value;}
		}

		public uint get_level() {
			return Level;
		}

		public void focus() {
			Title.focus();
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


		public GLib.Array<ICell> Children {get; set;}
		public GLib.Array<AddButton> AddButtons {get; set;}
		private ICellContainer* Parent {get; set;}
		private uint Level;
		private TextCell Title;
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

			try {

				css.load_from_path("res/seaborg.css");

			} catch(GLib.Error error) {

				css = CssProvider.get_default();
			}

			Gtk.SourceLanguageManager lm = new Gtk.SourceLanguageManager();
			Gtk.SourceStyleSchemeManager sm = new Gtk.SourceStyleSchemeManager();
 			lm.search_path = new string[] {"res/"};
 			sm.search_path = new string[] {"res/"};
			
 			InputBuffer = new Gtk.SourceBuffer(null);
			InputBuffer.highlight_matching_brackets = true;
			InputBuffer.style_scheme = sm.get_scheme("classic");
			InputBuffer.language =  lm.get_language("wolfram");
			InputCell = new Gtk.SourceView.with_buffer(InputBuffer);
			InputCell.show_line_numbers = false;
			InputCell.highlight_current_line = false;
			InputCell.auto_indent = true;
			InputCell.indent_on_tab = true;
			InputCell.tab_width = 3;
			InputCell.insert_spaces_instead_of_tabs = false;
			InputCell.smart_backspace = true;
			InputCell.show_line_marks = false;
			InputCell.wrap_mode = Gtk.WrapMode.WORD;
			InputCell.monospace = true;
			InputCell.editable = true;
			InputCell.hexpand = true;
			InputCell.halign = Gtk.Align.FILL;
			InputCell.left_margin = 0;
			InputCell.right_margin = 0;
			InputCell.top_margin = 0;
			InputCell.bottom_margin = 0;		

			OutputBuffer = new Gtk.SourceBuffer(null);
			OutputBuffer.highlight_matching_brackets = true;
			OutputBuffer.style_scheme = sm.get_scheme("classic");
			OutputBuffer.language = lm.get_language("wolfram");
			OutputCell = new Gtk.SourceView.with_buffer(OutputBuffer);
			OutputCell.show_line_numbers = false;
			OutputCell.highlight_current_line = false;
			OutputCell.auto_indent = true;
			OutputCell.indent_on_tab = true;
			OutputCell.tab_width = 3;
			OutputCell.insert_spaces_instead_of_tabs = false;
			OutputCell.smart_backspace = true;
			OutputCell.show_line_marks = false;
			OutputCell.wrap_mode = Gtk.WrapMode.WORD;
			OutputCell.monospace = true;
			OutputCell.editable = false;
			OutputCell.hexpand = true;
			OutputCell.halign = Gtk.Align.FILL;
			OutputCell.left_margin = 0;
			OutputCell.right_margin = 0;
			OutputCell.top_margin = 0;
			OutputCell.bottom_margin = 0;

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

		public string get_input() {
			return InputBuffer.text;
		}

		public string get_output() {
			return OutputBuffer.text;
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

		public void schedule_evaluation() {
			InputCell.editable = false;
			Marker.sensitive = false;

		}

		public void unschedule_evaluation() {
			InputCell.editable = true;
			Marker.sensitive = true;
		}

		public bool marker_selected() {
			return Marker.sensitive ? Marker.active : false;
		}

		public void focus() {
			InputCell.grab_focus();
		}

		public void remove_recursively() {}

		public void add_before(int pos, ICell[] list) {}
		public void remove_from(int pos, int number) {}

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

		public string text {
			get {return InputBuffer.text.to_string(); }
			set {InputBuffer.text = value; }
		} 

		public ICellContainer* Parent {get; set;}
		private Gtk.SourceView InputCell;
		private Gtk.SourceBuffer InputBuffer;
		private Gtk.SourceView OutputCell;
		private Gtk.SourceBuffer OutputBuffer;
		private Gtk.ToggleButton Marker;
		private bool isExpanded;
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

			Marker = new Gtk.ToggleButton();
			Marker.get_style_context().add_provider(css, Gtk.STYLE_PROVIDER_PRIORITY_USER);
			Marker.get_style_context().add_class("cell-marker");

			attach(Marker, 0, 0, 1, 1);
			attach(Cell, 1, 0, 1, 1);

			Marker.button_press_event.connect(press_handler);
			show_all();

		}

		public string get_text() {
			return Cell.buffer.text;
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

		public void focus() {
			Cell.grab_focus();
		}

		public string text {
			get { return Cell.buffer.text.to_string(); }
			set { Cell.buffer.text = value; }
		} 

		public void remove_recursively() {}
		public void collapse_all() {}
		public void expand_all() {}
		public void schedule_evaluation() {}
		public void unschedule_evaluation() {}
		public void add_before(int pos, ICell[] list) {}
		public void remove_from(int pos, int number) {}
		public ICellContainer* Parent {get; set;}

		private bool press_handler(EventButton event) {

			if(event.type == Gdk.EventType.BUTTON_PRESS && event.button == 3) {
				ContextMenu context = new ContextMenu(this);
				context.popup_at_widget(Marker, Gdk.Gravity.CENTER, Gdk.Gravity.WEST, null);
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
			label = "+";
			Parent = par;

			CssProvider css = new CssProvider();
			get_style_context().add_provider(css, Gtk.STYLE_PROVIDER_PRIORITY_USER);

			try {

				css.load_from_path("res/seaborg.css");

			} catch(GLib.Error error) {

				css = CssProvider.get_default();
			}

			get_style_context().add_class("add-button");

			
			clicked.connect(() => {

				int pos;
				for(pos=0; pos < Parent->AddButtons.data.length; pos++) {
					if(this.name == Parent->AddButtons.data[pos].name)
						break;
				}
				
				if(pos < Parent->AddButtons.data.length)
					Parent->add_before(pos, {new EvaluationCell(Parent)});

			});

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

			EvaluationCellType.toggled.connect(() => {
				if(Cell is EvaluationCell)
					return;
				if(Cell is TextCell) {
					int pos;
					for(pos=0; pos < Cell->Parent->Children.data.length; pos++) {
						if(Cell->Parent->Children.data[pos].name == Cell->name)
							break;
					}

					if(pos >= Cell->Parent->Children.data.length)
						return;

					var newCell = new EvaluationCell(Cell->Parent);
					newCell.text = Cell->text;
					Cell->Parent->add_before(pos, { newCell });
					newCell.focus();
					Cell->Parent->remove_from(pos+1, 1);

					return;
				}
				if(Cell is CellContainer) {
					int pos;
					for(pos=0; pos < Cell->Parent->Children.data.length; pos++) {
						if(Cell->Parent->Children.data[pos].name == Cell->name)
							break;
					}

					if(pos >= Cell->Parent->Children.data.length)
						return;

					//add new cell
					var newCell = new EvaluationCell(Cell->Parent);
					newCell.text = Cell->text;
					Cell->Parent->add_before(pos, { newCell });
					newCell.focus();
						
					if(pos > 0) {
						if(Cell->Parent->Children.data[pos-1].get_level() >= Cell->get_level()) {
							// hand children to older silbling
							Cell->Parent->Children.data[pos-1].add_before(-1, ((ICellContainer*)Cell)->Children.data);
							Cell->Parent->remove_from(pos+1, 1);
							return;
						}
					}
						
					// give children to parent
					Cell->Parent->add_before(pos+1, ((ICellContainer*)Cell)->Children.data);
					Cell->Parent->remove_from(pos+1+((ICellContainer*)Cell)->Children.data.length, 1);
					return;
				}
			});

			TextCellType.toggled.connect(() => {
				if(Cell is TextCell)
					return;
				if(Cell is EvaluationCell) {
					int pos;
					for(pos=0; pos < Cell->Parent->Children.data.length; pos++) {
						if(Cell->Parent->Children.data[pos].name == Cell->name)
							break;
					}

					if(pos >= Cell->Parent->Children.data.length)
						return;

					var newCell = new TextCell(Cell->Parent);
					newCell.text = Cell->text;
					Cell->Parent->add_before(pos, { newCell });
					newCell.focus();
					Cell->Parent->remove_from(pos+1, 1);

					return;
				}
				if(Cell is CellContainer) {
					int pos;
					for(pos=0; pos < Cell->Parent->Children.data.length; pos++) {
						if(Cell->Parent->Children.data[pos].name == Cell->name)
							break;
					}

					if(pos >= Cell->Parent->Children.data.length)
						return;

					//add new cell
					var newCell = new TextCell(Cell->Parent);
					newCell.text = Cell->text;
					Cell->Parent->add_before(pos, { newCell });
					newCell.focus();
						
					if(pos > 0) {
						if(Cell->Parent->Children.data[pos-1].get_level() >= Cell->get_level()) {
							// hand children to older silbling
							Cell->Parent->Children.data[pos-1].add_before(-1, ((ICellContainer*)Cell)->Children.data);
							Cell->Parent->remove_from(pos+1, 1);
							return;
						}
					}
						
					// give children to parent
					Cell->Parent->add_before(pos+1, ((ICellContainer*)Cell)->Children.data);
					Cell->Parent->remove_from(pos+1+((ICellContainer*)Cell)->Children.data.length, 1);
					return;
				}
			});



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

		private void toggled_container(uint toggled_level) {
			if(Cell is EvaluationCell || Cell is TextCell) {
				int pos;
				for(pos=0; pos < Cell->Parent->Children.data.length; pos++) {
					if(Cell->Parent->Children.data[pos].name == Cell->name)
						break;
				}

				if(pos >= Cell->Parent->Children.data.length)
					return;

					
				var newCell = new CellContainer(Cell->Parent, toggled_level);
				newCell.text = Cell->text;
				newCell.focus();
				Cell->Parent->remove_from(pos, 1);
				Cell->Parent->add_before(pos, { newCell });
				((CellContainer)(Cell->Parent->Children.data[pos])).eat_children();

				return;
			}
			if(Cell is CellContainer) {
				if(Cell->get_level() == toggled_level)
					return;
				int pos;
				int previous_pos=-1;
				for(pos=0; pos < Cell->Parent->Children.data.length; pos++) {
					if(Cell->Parent->Children.data[pos].name == Cell->name)
						break;
					if(Cell->Parent->Children.data[pos].get_level() >= Cell->get_level())
						previous_pos = pos;
				}

				if(pos >= Cell->Parent->Children.data.length) {
					return;
				}
						
				// put children out behind cell, convert cell, and eat them again
				Cell->Parent->add_before(pos+1, ((CellContainer*)Cell)->Children.data);
				var newCell = new CellContainer(Cell->Parent, toggled_level);
				newCell.text = Cell->text;
				newCell.focus();
				Cell->Parent->remove_from(pos, 1);
				Cell->Parent->add_before(pos, { newCell });
				((CellContainer)(Cell->Parent->Children.data[pos])).eat_children();

				// the level was downgraded, so some children have to be eaten by an uncle
				if(previous_pos >= 0 && Cell->get_level() > toggled_level)
					((CellContainer)Cell->Parent->Children.data[previous_pos]).eat_children();

				return;

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