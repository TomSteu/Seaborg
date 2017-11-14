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

	public class Notebook : Gtk.Grid, ICell, ICellContainer {
		public Notebook(uint level) {
			this.name = IdGenerator.get_id();
			Level = level;
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
		}

		public void add_before(int pos, ICell[] list) {
			
			int old_len = (int)(Children.length);
			if(pos < 0 ) pos += old_len + 1;
			if(pos < 0 || pos > old_len)
				return;
			
			
			if(pos < old_len) {
				for(int j=1; j<=2*list.length; j++) insert_row(pos);
			}

			Children.insert_vals(pos, list, list.length);
			AddButtons.set_size(AddButtons.data.length + list.length + 1);
			for(int i=0; i<list.length; i++) {
					AddButtons.data[pos+1+i] = new AddButton(this);
					attach(Children.data[pos+i], 1, 2*(pos+i)+1, 1, 1);
					attach(AddButtons.data[pos+1+i], 1,  2*(pos+i)+2, 1, 1);
			}

			//redraw marker if stuff was attached to the end
			if(pos == old_len) {
				remove_column(0);
				insert_column(0);
				attach(Marker, 0, 0, 1, 2*((int)(Children.length)+1));
			}

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
			for(int i=0; i<Children.data.length; i++) {
				Children.data[i].toggle_all();
			}
		}

		public void untoggle_all() {
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


		public GLib.Array<ICell> Children {get; set;}
		public GLib.Array<AddButton> AddButtons {get; set;}
		private uint Level;
		private Gtk.ToggleButton Marker;
		private CssProvider css;
	}

	// container class with heading
	public class CellContainer : Gtk.Grid, ICell, ICellContainer {
		public CellContainer(CellContainer* parent, uint level) {
			this.name = IdGenerator.get_id();
			Parent = parent;
			Level = level;
			Children = new GLib.Array<ICell>();
			AddButtons = new GLib.Array<AddButton>();
			Title = new TextCell();
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

			if(Title.marker_selected()) {
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
					if(Parent->Children.data[this_position-1].get_level() >= Level){
						
						// hand children to this_position-1 as children 
						if((Parent->Children.data[this_position-1]) is CellContainer) {
							((CellContainer)(Parent->Children.data[this_position-1])).add_before(-1, Children.data);
						} else if((Parent->Children.data[this_position-1]) is Notebook) {
							((Notebook)(Parent->Children.data[this_position-1])).add_before(-1, Children.data);
						}
						
						// erase this_position
						Parent->remove_from(this_position, 1);
						return;
					} 
				}

				// hand children back as siblings of 'this'
				Parent->add_before(this_position, Children.data);

				// erase this_position
				Parent->remove_from(this_position, 1);

			}
		}

		public void add_before(int pos, ICell[] list) {
			
			int old_len = (int)(Children.length);
			if(pos < 0 ) pos += old_len + 1;
			if(pos < 0 || pos > old_len)
				return;
			
			Children.insert_vals(pos, list, list.length);
			AddButtons.set_size(AddButtons.data.length + list.length);
			
			if(pos < old_len) {
					for(int j=1; j<=2*list.length; j++) insert_row(pos);
			}
			for(int i=0; i<(int)(list.length); i++) {
					AddButtons.data[pos+1+i] = new AddButton(this);
					attach(Children.data[pos+i], 1, 2*(pos+i)+2, 1, 1);
					attach(AddButtons.data[pos+1+i], 1, 2*(pos+i)+3, 1, 1);
			}

			//redraw marker if stuff was attached to the end
			if(pos == old_len) {
				remove_column(0);
				insert_column(0);
				attach(Marker, 0, 0, 1, 2*((int)(Children.length)+1));
			}

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
			for(int i=0; i<Children.data.length; i++) {
				Children.data[i].toggle_all();
			}
		}

		public void untoggle_all() {
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


		public GLib.Array<ICell> Children {get; set;}
		public GLib.Array<AddButton> AddButtons {get; set;}
		private uint Level;
		private TextCell Title;
		private ICellContainer* Parent;
		private Gtk.ToggleButton Marker;
		private CssProvider css;
	}

	// Generic cell for evaluation
	public class EvaluationCell : Gtk.Grid, ICell {
		
		public EvaluationCell() {
			this.name = IdGenerator.get_id();
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

			attach(Marker, 0, 0, 1, 2);
			attach(InputCell, 1, 0, 1, 1);
			attach(OutputCell, 1, 1, 1, 1);

			isExpanded = true;

			Marker.button_press_event.connect(expand_handler);

		}

		public static EvaluationCell from_TextCell(TextCell* textCell) {
			EvaluationCell res = new EvaluationCell();
			res.InputBuffer.text = textCell->get_text();
			return res;
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

		public void remove_recursively() {}

		public void add_before(int pos, ICell[] list) {}
		public void remove_from(int pos, int number) {}

		private bool expand_handler(EventButton event) {
			if(event.type == Gdk.EventType.DOUBLE_BUTTON_PRESS ) {
				if(isExpanded) 
					collapse_all(); 
				else  
					expand_all();
			}
			return false;
		}

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
		public TextCell() {
			this.name = IdGenerator.get_id();
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

		}

		public static TextCell from_EvaluationCell(EvaluationCell* eval) {
			TextCell res = new TextCell();
			res.Cell.buffer.text = eval->get_input();
			return res;
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

		public void remove_recursively() {}
		public void collapse_all() {}
		public void expand_all() {}
		public void schedule_evaluation() {}
		public void unschedule_evaluation() {}
		public void add_before(int pos, ICell[] list) {}
		public void remove_from(int pos, int number) {}

		private Gtk.TextView Cell;
		private Gtk.ToggleButton Marker;
	}

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

				stderr.printf(pos.to_string() + "/" + Parent->AddButtons.data.length.to_string());

				Parent->add_before(pos, {new EvaluationCell()});

			});

		}

		private ICellContainer* Parent;

	}

}