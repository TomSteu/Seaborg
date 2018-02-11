using Gtk;

namespace Seaborg {

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