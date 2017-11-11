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

	}

	public class Notebook : Gtk.Grid, ICell {
		public Notebook(uint level) {
			Level = level;
			Children = new ICell[] {};


			css = new CssProvider();
			this.get_style_context().add_provider(css, Gtk.STYLE_PROVIDER_PRIORITY_USER);

			try {

				css.load_from_path("res/seaborg.css");

			} catch(GLib.Error error) {

				css = CssProvider.get_default();
			}

			Marker = Marker = new Gtk.ToggleButton();
			var style_context = Marker.get_style_context();
			style_context.add_provider(css, Gtk.STYLE_PROVIDER_PRIORITY_USER);
			style_context.add_class("cell-marker");
			get_style_context().add_class("view");
			get_style_context().add_class("container-grid");

			// assemble the container
			attach(Marker, 0, 0, 1, 2*Children.length + 1);
			//attach(add_button);
			for(int i=0; i<Children.length; i++) {
				attach(Children[i], 1, i+1, 1, 1);
				//attach(add_button);
			}

		}

		public void remove_recursively() {
			for(int i=0; i<Children.length;){
				if(Children[i].marker_selected()) {
					if(i != Children.length - 1) {
						Children.move(i+1, i, Children.length-i);
					}
					Children.resize(Children.length-1);
					remove_row(2*i+2);
					remove_row(2*i+1);
				}

				i++;
			}

			foreach (var child in Children)
				child.remove_recursively();
		}

		public void add_before(int pos, ICell[] list) {
			
			int old_len = Children.length;
			if(pos < 0 || pos > old_len)
				return;
			
			Children.resize(old_len + list.length);
			if(pos < old_len) {
					Children.move(pos, pos + list.length, old_len - pos);
					for(int j=1; j<=2*list.length; j++) insert_row(pos);
			}
			for(int i=0; i<list.length; i++) {
					Children[pos+i] = list[i];
					attach(Children[pos+i], 1, 2*(pos+i)+1, 1, 1);
					//attach(add_button, 1,  2*(pos+i)+2, 1, 1);
			}

			//redraw marker if stuff was attached to the end
			if(pos == old_len) {
				remove_column(0);
				insert_column(0);
				attach(Marker, 0, 0, 1, 2*(Children.length+1));
			}

		}

		public void toggle_all() {
			foreach (var child in Children)
				child.toggle_all();
		}

		public void untoggle_all() {
			foreach (var child in Children)
				child.untoggle_all();
		}

		public void expand_all() {
			foreach (var child in Children)
				child.expand_all();
		}

		public void collapse_all() {
			foreach (var child in Children)
				child.collapse_all();
		}

		public void schedule_evaluation() {
			foreach (var child in Children)
				child.schedule_evaluation();
		}

		public void unschedule_evaluation() {
			foreach (var child in Children)
				child.unschedule_evaluation();
		}

		public bool marker_selected() {
			return Marker.sensitive ? Marker.active : false;
		}

		public uint get_level() {
			return Level;
		}


		private uint Level;
		public ICell[] Children;
		private Gtk.ToggleButton Marker;
		private CssProvider css;
	}

	// container class with heading
	public class CellContainer : Gtk.Grid, ICell {
		public CellContainer(CellContainer* parent, uint level) {
			Parent = parent;
			Level = level;
			Children = new ICell[] {};
			Title = new TextCell();

			css = new CssProvider();
			this.get_style_context().add_provider(css, Gtk.STYLE_PROVIDER_PRIORITY_USER);

			try {

				css.load_from_path("res/seaborg.css");

			} catch(GLib.Error error) {

				css = CssProvider.get_default();
			}

			Marker = Marker = new Gtk.ToggleButton();
			var style_context = Marker.get_style_context();
			style_context.add_provider(css, Gtk.STYLE_PROVIDER_PRIORITY_USER);
			style_context.add_class("cell-marker");
			get_style_context().add_class("view");
			get_style_context().add_class("container-grid");
			
			int this_position=0;
			int next_position=0;
			
			// find out where the next container (e.g. section) of the same level is
			for(int i=0; i<(Parent->Children).length; i++) {
				if(&((Parent->Children)[i]) == &this)
					this_position = i;
				if(Parent->Children[i].get_level() == Level && i > this_position)
					{
						next_position = i;
						break;
					}
			}

			int copy_position=this_position+1;

			// move elements from parents into this container
			if(next_position < (Parent->Children).length && copy_position  < next_position) {

				while(copy_position < (Parent->Children).length)
				{
					Children.resize(Children.length+1);
					Children[Children.length-1] = Parent->Children[copy_position];

					parent->remove_row(this_position*2+5);
					parent->remove_row(this_position*2+4);
					copy_position++;
				}
				if(next_position !=Parent->Children.length-1) {
					Parent->Children.move(next_position, this_position+1, next_position-Parent->Children.length);
				}
				Parent->Children.resize(Parent->Children.length-next_position+this_position+1);
			}

			// assemble the container
			attach(Marker, 0, 0, 1, 2*Children.length + 2);
			attach(Title, 1, 0, 1, 1);
			//attach(add_button);
			for(int i=0; i<Children.length; i++) {
				attach(Children[i], 1, i+2, 1, 1);
				//attach(add_button);
			}

		}

		public void remove_recursively() {
			for(int i=0; i<Children.length;){
				if(Children[i].marker_selected()) {
					if(i != Children.length - 1) {
						Children.move(i+1, i, Children.length-i);
					}
					Children.resize(Children.length-1);
					remove_row(2*i+3);
					remove_row(2*i+2);
				}

				i++;
			}

			foreach (var child in Children)
				child.remove_recursively();

			if(Title.marker_selected()) {
				// hand children back to parent
				int this_position;
				for(this_position=0; this_position<(Parent->Children).length; this_position++) {
					if(&((Parent->Children)[this_position]) == &this)
						break;
				}

				// 'this' is a wayward child
				if(this_position >= Parent->Children.length)
					return;
				// 'this' is not firstborn
				if(this_position != 0)
				{
					if(Parent->Children[this_position-1].get_level() >= Level){
						
						// hand children to this_position-1 as children 
						Parent->Children[this_position-1].add_before(0, Children);
						
						// erase this_position
						if(this_position < Parent->Children.length-1)
							Parent->Children.move(this_position+1, this_position, Parent->Children.length - this_position - 1);
						Parent->Children.resize(Parent->Children.length-1);
						Parent->remove_row(2*this_position+3);
						Parent->remove_row(2*this_position+2);
						return;
					} 
				}

				// hand children back as siblings of 'this'
				Parent->add_before(this_position, Children);

				// erase this_position
				if(this_position < Parent->Children.length-1)
					Parent->Children.move(this_position+1, this_position, Parent->Children.length - this_position - 1);
				Parent->Children.resize(Parent->Children.length-1);
				Parent->remove_row(2*this_position+3);
				Parent->remove_row(2*this_position+2);

			}
		}

		public void add_before(int pos, ICell[] list) {
			
			int old_len = Children.length;
			if(pos < 0 || pos > old_len)
				return;
			
			Children.resize(old_len + list.length);
			if(pos < old_len) {
					Children.move(pos, pos + list.length, old_len - pos);
					for(int j=1; j<=2*list.length; j++) insert_row(pos);
			}
			for(int i=0; i<list.length; i++) {
					Children[pos+i] = list[i];
					attach(Children[pos+i], 1, 2*(pos+i)+2, 1, 1);
					//attach(add_button, 1,  2*(pos+i)+3, 1, 1);
			}

			//redraw marker if stuff was attached to the end
			if(pos == old_len) {
				remove_column(0);
				insert_column(0);
				attach(Marker, 0, 0, 1, 2*(Children.length+1));
			}

		}

		public void toggle_all() {
			foreach (var child in Children)
				child.toggle_all();
		}

		public void untoggle_all() {
			foreach (var child in Children)
				child.untoggle_all();
		}

		public void expand_all() {
			foreach (var child in Children)
				child.expand_all();
		}

		public void collapse_all() {
			foreach (var child in Children)
				child.collapse_all();
		}

		public void schedule_evaluation() {
			foreach (var child in Children)
				child.schedule_evaluation();
		}

		public void unschedule_evaluation() {
			foreach (var child in Children)
				child.unschedule_evaluation();
		}

		public bool marker_selected() {
			return Marker.sensitive ? Marker.active : false;
		}

		public uint get_level() {
			return Level;
		}


		private uint Level;
		private TextCell Title;
		public ICell[] Children;
		private CellContainer* Parent;
		private Gtk.ToggleButton Marker;
		private CssProvider css;
	}

	// Generic cell for evaluation
	public class EvaluationCell : Gtk.Grid, ICell {
		
		public EvaluationCell() {

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

		private Gtk.TextView Cell;
		private Gtk.ToggleButton Marker;
	}

	public class AddButton : Gtk.Button {
		public AddButton() {
			label = "+";
		}
	}

}