using Gtk;

namespace Seaborg {

	// popup context menu
	public class ContextMenu : Gtk.Menu {
		public ContextMenu(ICell* _cell) {
			cell = _cell;
			
			evaluation_cell_type = new RadioMenuItem.with_label(null, "Evaluation cell");
			text_cell_type = new RadioMenuItem.with_label_from_widget(evaluation_cell_type, "Text cell");
			title_type = new RadioMenuItem.with_label_from_widget(evaluation_cell_type, "Title");
			chapter_type = new RadioMenuItem.with_label_from_widget(evaluation_cell_type, "Chapter");
			subchapter_type = new RadioMenuItem.with_label_from_widget(evaluation_cell_type, "Subchapter");
			section_type = new RadioMenuItem.with_label_from_widget(evaluation_cell_type, "Section");
			subsection_type = new RadioMenuItem.with_label_from_widget(evaluation_cell_type, "Subsection");
			subsubsection_type = new RadioMenuItem.with_label_from_widget(evaluation_cell_type, "Subsubsection");

			if(cell is EvaluationCell)
				evaluation_cell_type.active = true;
			if(cell is TextCell)
				text_cell_type.active = true;
			if(cell is CellContainer) {
				switch(((CellContainer*)cell)->get_level()) {
					case 1:
						subsubsection_type.active = true;
						break;
					case 2:
						subsection_type.active = true;
						break;
					case 3:
						section_type.active = true;
						break;
					case 4:
						subchapter_type.active = true;
						break;
					case 5:
						chapter_type.active = true;
						break;
					case 6:
						title_type.active = true;
						break;
				}
			}

			evaluation_cell_type.toggled.connect(() => {toggled_evaluation_cell();});
			text_cell_type.toggled.connect(() => {toggled_text_cell();});
			title_type.toggled.connect(() => { toggled_container(6); });
			chapter_type.toggled.connect(() => { toggled_container(5); });
			subchapter_type.toggled.connect(() => { toggled_container(4); });
			section_type.toggled.connect(() => { toggled_container(3); });
			subsection_type.toggled.connect(() => { toggled_container(2); });
			subsubsection_type.toggled.connect(() => { toggled_container(1); });

			this.add(evaluation_cell_type);
			this.add(text_cell_type);
			this.add(new Gtk.SeparatorMenuItem());
			this.add(title_type);
			this.add(chapter_type);
			this.add(subchapter_type);
			this.add(section_type);
			this.add(subsection_type);
			this.add(subsubsection_type);

			show_all();

		}

		private void toggled_evaluation_cell() {

			if(cell is EvaluationCell) 
				return;


			int pos;
			ICellContainer* parent = cell->parent_cell;
			if(parent == null) 
				return;

			if(cell is TextCell) {
				for(pos=0; pos < parent->children_cells.data.length; pos++) {
					if(parent->children_cells.data[pos].name == cell->name)
						break;
				}

				if(pos >= parent->children_cells.data.length)
					return;

				EvaluationCell* newCell = new EvaluationCell(cell->parent_cell);
				newCell->set_text(cell->get_text());
				parent->add_before(pos, { newCell });
				newCell->focus_cell();
				parent->remove_from(pos+1, 1, true);

				return;
			}
			if(cell is CellContainer) {

				uint level = cell->get_level();
				if(level<=0)
					return;
				if(level > 1) {
					toggled_container(1);
				}

				parent = cell->parent_cell;
				if(parent == null)
					return;

				for(pos=0; pos < parent->children_cells.data.length; pos++) {
					if(parent->children_cells.data[pos].name == cell->name)
						break;
				}

				if(pos >= parent->children_cells.data.length)
					return;

				//add new cell
				EvaluationCell* newCell = new EvaluationCell(parent);
				var offspring = ((ICellContainer*)cell)->children_cells.data;
				((ICellContainer*)cell)->remove_from(0, offspring.length, false); 
				newCell->set_text(cell->get_text());
				parent->remove_from(pos, 1, true);
				parent->add_before(pos, { newCell });
				parent->add_before(pos+1, offspring);
				newCell->focus_cell();
						
				if(pos > 0) {
					if(parent->children_cells.data[pos-1].get_level() >= 0 && parent->children_cells.data[pos-1] is CellContainer) {
						((CellContainer)(parent->children_cells.data[pos-1])).eat_children();
					}
				}
						
				return;

			}
		}

		private void toggled_text_cell() {
			if(cell is TextCell)
				return;

			int pos;
			
			ICellContainer* parent = cell->parent_cell;
			if(parent == null)
				return;

			if(cell is EvaluationCell) {

				if(((EvaluationCell*) cell)->lock)
					return;

				for(pos=0; pos < parent->children_cells.data.length; pos++) {
					if(parent->children_cells.data[pos].name == cell->name)
						break;
				}

				if(pos >= parent->children_cells.data.length)
					return;

				TextCell* newCell = new TextCell(parent);
				newCell->set_text(cell->get_text());
				parent->add_before(pos, { newCell });
				newCell->focus_cell();
				parent->remove_from(pos+1, 1, true);

				return;
			}
			if(cell is CellContainer) {

				uint level = cell->get_level();
				if(level<=0)
					return;
				if(level > 1) {
					toggled_container(1);
				}

				parent = cell->parent_cell;
				if(parent == null)
					return;

				for(pos=0; pos < parent->children_cells.data.length; pos++) {
					if(parent->children_cells.data[pos].name == cell->name)
						break;
				}

				if(pos >= parent->children_cells.data.length)
					return;

				//add new cell
				EvaluationCell* newCell = new TextCell(parent);
				var offspring = ((ICellContainer*)cell)->children_cells.data;
				((ICellContainer*)cell)->remove_from(0, offspring.length, false); 
				newCell->set_text(cell->get_text());
				parent->remove_from(pos, 1, true);
				parent->add_before(pos, { newCell });
				parent->add_before(pos+1, offspring);
				newCell->focus_cell();
						
				if(pos > 0) {
					if(parent->children_cells.data[pos-1].get_level() >= 0 && parent->children_cells.data[pos-1] is CellContainer) {
						((CellContainer)(parent->children_cells.data[pos-1])).eat_children();
					}
				}

				return;

			}
		}

		private void toggled_container(uint toggled_level) {
			ICellContainer* parent = cell->parent_cell;
			if(parent == null)
				return;

			int pos;
			
			if(cell is EvaluationCell || cell is TextCell) {

				if(cell is EvaluationCell && ((EvaluationCell*) cell)->lock)
					return;

				for(pos=0; pos < parent->children_cells.data.length; pos++) {
					if(parent->children_cells.data[pos].name == cell->name)
						break;
				}

				if(pos >= parent->children_cells.data.length)
					return;


				CellContainer* newCell = new CellContainer(parent, toggled_level);	
				newCell->set_text(cell->get_text());	
				parent->remove_from(pos, 1, true);
				parent->add_before(pos, { newCell });
				((CellContainer)(parent->children_cells.data[pos])).eat_children();
				newCell->focus_cell();

				return;
			}
			if(cell is CellContainer) {

				uint old_level = cell->get_level();
				
				if(old_level == toggled_level)
					return;

				// this is an level-up -- just eat a couple of more children
				if(old_level<toggled_level) {
					((CellContainer*)cell)->set_level(toggled_level);
					((CellContainer*)cell)->eat_children();
					return;
				}

				// downgrade - throw up some children
				if(old_level > toggled_level) {

					// gradually lower level, so there is no need for nested eating silblings
					((CellContainer*)cell)->set_level(old_level-1);
					parent = cell->parent_cell;

					// find cell within parent
					for(pos=0; pos < parent->children_cells.data.length; pos++) {
						if(parent->children_cells.data[pos].name == cell->name)
							break;
					}

					//find out first child to throw up
					int internal_pos;
					var offspring = ((CellContainer*)cell)->children_cells.data;
					for(internal_pos=0; internal_pos<offspring.length; internal_pos++) {
						if(offspring[internal_pos].get_level() >= toggled_level)
							break;
					}

					// no need to throw up children
					if(internal_pos < offspring.length) {

						// transfer to parent
						offspring = offspring[internal_pos : offspring.length];
						((CellContainer*)cell)->remove_from(internal_pos, offspring.length, false);
						parent->add_before(pos+1, offspring);

						// let last released child eat former uncle
						if(pos+offspring.length+1 < parent->children_cells.data.length) {
							if(parent->children_cells.data[pos+offspring.length+1].get_level() < parent->children_cells.data[pos+offspring.length].get_level()) {
								((CellContainer)parent->children_cells.data[pos+offspring.length]).eat_children();
							}
						}

						// let next oldest silbling of cell eat children now
						if(pos > 0) {
							if(parent->children_cells.data[pos-1].get_level() > parent->children_cells.data[pos].get_level())
								((CellContainer)parent->children_cells.data[pos-1]).eat_children();
						}
					}

					//next recursion step
					toggled_container(toggled_level);


				}

			}
		}

		private ICell* cell;
		private RadioMenuItem evaluation_cell_type;
		private RadioMenuItem text_cell_type;
		private RadioMenuItem title_type;
		private RadioMenuItem chapter_type;
		private RadioMenuItem subchapter_type;
		private RadioMenuItem section_type;
		private RadioMenuItem subsection_type;
		private RadioMenuItem subsubsection_type;
	}

}