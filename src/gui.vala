using Gtk;
using GLib;
using Xml;

namespace Seaborg {



	public struct EvaluationData {
		public void* cell;
		public string input;
		
	}

	public class SeaborgApplication : Gtk.Application {

		public static ulong global_stamp = 0;

		protected override void activate() {

			this.set_resource_base_path("/tst/seaborg/./res/");

			IdGenerator.reset();
			
			// widgets
			main_window = new Gtk.ApplicationWindow(this);
			main_headerbar = new Gtk.HeaderBar();
			tab_switcher = new Gtk.StackSwitcher();
			notebook_stack = new Gtk.Stack();
			notebook_scroll = new Gtk.ScrolledWindow(null,null);
			string shortcut_builder_string = 
				"<?xml version=\"1.0\" encoding=\"UTF-8\"?>"+
				"<interface>"+
				  "<object class=\"GtkShortcutsWindow\" id=\"shortcuts\">"+
				    "<property name=\"modal\">1</property>"+
				    "<child>"+
				      "<object class=\"GtkShortcutsSection\">"+
				        "<property name=\"visible\">1</property>"+
				        "<property name=\"section-name\">shortcuts</property>"+
				        "<property name=\"max-height\">12</property>"+
				        "<child>"+
				          "<object class=\"GtkShortcutsGroup\">"+
				            "<property name=\"visible\">1</property>"+
				            "<property name=\"title\" translatable=\"yes\">Window</property>"+
				            "<child>"+
				              "<object class=\"GtkShortcutsShortcut\">"+
				                "<property name=\"visible\">1</property>"+
				                "<property name=\"accelerator\">&lt;ctrl&gt;N</property>"+
				                "<property name=\"title\" translatable=\"yes\">Create new notebook</property>"+
				              "</object>"+
				            "</child>"+
				            "<child>"+
				              "<object class=\"GtkShortcutsShortcut\">"+
				                "<property name=\"visible\">1</property>"+
				                "<property name=\"accelerator\">&lt;ctrl&gt;O</property>"+
				                "<property name=\"title\" translatable=\"yes\">Open a notebook</property>"+
				              "</object>"+
				            "</child>"+
				            "<child>"+
				              "<object class=\"GtkShortcutsShortcut\">"+
				                "<property name=\"visible\">1</property>"+
				                "<property name=\"accelerator\">&lt;ctrl&gt;S</property>"+
				                "<property name=\"title\" translatable=\"yes\">Save the notebook</property>"+
				              "</object>"+
				            "</child>"+
				            "<child>"+
				              "<object class=\"GtkShortcutsShortcut\">"+
				                "<property name=\"visible\">1</property>"+
				                "<property name=\"accelerator\">&lt;Primary&gt;question &lt;Primary&gt;F1</property>"+
				                "<property name=\"title\" translatable=\"yes\">Show shortcuts</property>"+
				              "</object>"+
				            "</child>"+
				    	  "</object>"+
				    	"</child>"+
				    	"<child>"+
				    	  "<object class=\"GtkShortcutsGroup\">"+
				            "<property name=\"visible\">1</property>"+
				            "<property name=\"title\" translatable=\"yes\">Cells</property>"+
				            "<child>"+
				              "<object class=\"GtkShortcutsShortcut\">"+
				                "<property name=\"visible\">1</property>"+
				                "<property name=\"accelerator\">&lt;ctrl&gt;D &lt;ctrl&gt;Delete</property>"+
				                "<property name=\"title\" translatable=\"yes\">Delete selected cells</property>"+
				              "</object>"+
				            "</child>"+
				            "<child>"+
				              "<object class=\"GtkShortcutsShortcut\">"+
				                "<property name=\"visible\">1</property>"+
				                "<property name=\"accelerator\">&lt;ctrl&gt;Return</property>"+
				                "<property name=\"title\" translatable=\"yes\">Evaluate cells</property>"+
				              "</object>"+
				            "</child>"+
				            "<child>"+
				              "<object class=\"GtkShortcutsShortcut\">"+
				                "<property name=\"visible\">1</property>"+
				                "<property name=\"accelerator\">&lt;ctrl&gt;period</property>"+
				                "<property name=\"title\" translatable=\"yes\">Abort evaluation</property>"+
				              "</object>"+
				            "</child>"+
				          "</object>"+
				        "</child>"+
				      "</object>"+
				    "</child>"+
				  "</object>"+
				"</interface>";
			Gtk.Builder shortcut_builder = new Gtk.Builder.from_string(shortcut_builder_string, shortcut_builder_string.length);
			shortcuts = shortcut_builder.get_object("shortcuts") as Gtk.ShortcutsWindow;



			tab_switcher.stack = notebook_stack;
			
			main_headerbar.show_close_button = true;
			main_headerbar.custom_title = tab_switcher;
			notebook_scroll.add(notebook_stack);
			
			main_window.title = "Gtk Notebook";
			main_window.set_titlebar(main_headerbar);
			main_window.add(notebook_scroll);
			main_window.set_help_overlay(shortcuts);
			this.add_window(main_window);

			main_window.set_default_size(800, 600);
			main_window.show_all();

			new_notebook();

		}

		protected override void startup() {
			base.startup();

			main_menu = new GLib.Menu();
			main_menu.append("New", "app.new");
			main_menu.append("Open", "app.open");
			main_menu.append("Save", "app.save");
			main_menu.append("Keyboard Shortcuts", "win.show-help-overlay");
			main_menu.append("Quit", "app.quit");

			this.app_menu = main_menu;

			var new_action = new GLib.SimpleAction("new", null);
			var open_action = new GLib.SimpleAction("open", null);
			var save_action = new GLib.SimpleAction("save", null);
			var remove_action = new GLib.SimpleAction("rm", null);
			var quit_action = new GLib.SimpleAction("quit", null);
			var eval_action = new GLib.SimpleAction("eval", null);
			var stop_eval_action = new GLib.SimpleAction("stop", null);

			new_action.activate.connect(() => {
			});

			open_action.activate.connect(() => {
				load_dialog();
			});

			save_action.activate.connect(() => {
				save_dialog();
			});

			quit_action.activate.connect(() => {
				this.quit();
			});

			remove_action.activate.connect(() => {
				((Seaborg.Notebook)notebook_stack.get_visible_child()).remove_recursively();
			});

			eval_action.activate.connect(() => {

				schedule_evaluation((Seaborg.Notebook)notebook_stack.get_visible_child());

			});

			stop_eval_action.activate.connect(() => {
				
				try_abort(kernel_connection);
			
			});


			this.add_action(new_action);
			this.add_action(open_action);
			this.add_action(save_action);
			this.add_action(remove_action);
			this.add_action(eval_action);
			this.add_action(stop_eval_action);
			this.add_action(quit_action);


			const string[] new_accels = {"<Control>N", null};
			const string[] open_accels = {"<Control>O", null};
			const string[] save_accels = {"<Control>S", null};
			const string[] rm_accels = {"<Control>Delete","<Control>D", null};
			const string[] shortcut_accels = {"<Control>F1", "<Control>question", null};
			const string[] eval_accels = {"<Control>Return", "<Control>E", null};
			const string[] stop_eval_accels = {"<Control>period", "<Control>S", null};
			const string[] quit_accels = {"<Control>Q", null};

			this.set_accels_for_action("app.new", new_accels);
			this.set_accels_for_action("app.open", open_accels);
			this.set_accels_for_action("app.save", save_accels);
			this.set_accels_for_action("app.rm", rm_accels);
			this.set_accels_for_action("app.quit", quit_accels);
			this.set_accels_for_action("win.show-help-overlay", shortcut_accels);
			this.set_accels_for_action("app.eval", eval_accels);
			this.set_accels_for_action("app.stop", stop_eval_accels);
			
			// connecting kernel
			reset_kernel();
			eval_queue = new Queue<EvaluationData?>();


		}

		public void schedule_evaluation(ICellContainer container) {
			lock(eval_queue) {

				// add evalutation cells to be evaluated
				for(int i=0; i<container.Children.data.length; i++) {
					
					if(container.Children.data[i] is ICellContainer)
						schedule_evaluation((ICellContainer) container.Children.data[i]);

					if(container.Children.data[i].marker_selected() && (! container.Children.data[i].lock) && container.Children.data[i] is EvaluationCell) {
						if(Seaborg.check_input_packet(((EvaluationCell) container.Children.data[i]).get_text())) {
							((EvaluationCell)container.Children.data[i]).lock = true;
							((EvaluationCell) container.Children.data[i]).remove_text();
							eval_queue.push_tail( EvaluationData() { 
								cell = (void*) container.Children.data[i],
								input = "ToString[InputForm[" + replace_characters(((EvaluationCell) container.Children.data[i]).get_text()) + "]]"
							});

						}
					}
				}
			}

			start_evalutation_thread();
		}
			
			// start evaluation thread, if not already running
		public void start_evalutation_thread() {

			if(listener_thread != null && (!listener_thread_is_running))
				listener_thread.join();

			if(! listener_thread_is_running) {

				listener_thread = new GLib.Thread<void*>("seaborg-listener", () => {

					listener_thread_is_running = true;
					current_cell = EvaluationData();
					while(true) {

						//get next cell data
						lock(eval_queue) {
								
							if(eval_queue.length <= 0)
								break;

							current_cell = eval_queue.pop_head();
						}

						// wait for fist packet
						lock(global_stamp) {
							global_stamp = 1;
						}

						// something is wrong
						if(check_connection(kernel_connection) != 1) {
							GLib.Idle.add( () => {
								abort_eval();
								return false;
							});
							return null;
						}

						evaluate(kernel_connection, current_cell.input, write_to_evaluation_cell, current_cell.cell);

						// something is wrong
						if(check_connection(kernel_connection) != 1) {

   								GLib.Idle.add( () => {
									abort_eval();
									return false;
								});
							return null;
						}

						while(true) {
							lock(global_stamp) {
								if(global_stamp == 0)
									break;
							}
							GLib.Thread.usleep(200);
						}

							
					}

					listener_thread_is_running = false;
					return null;
				});
			}
		}

		// aborts current evaluation and reset everything
		private void abort_eval() {

			// no new packets to be written
			lock(global_stamp) {
				global_stamp = 0;
			}

			// remove locks
			EvaluationCell* cell = (EvaluationCell*)current_cell.cell;

			if(cell != null) cell->lock = false;
			lock(eval_queue) {
				while(true) {
					
					if(eval_queue.length <= 0)
						break;

					cell = (EvaluationCell*) eval_queue.pop_head().cell;
					if(cell != null) cell->lock = false;
				}

			}

			// reset connection and check sanity
			int res = check_connection(kernel_connection);
			if(res != 1) {
				if(res == 2) {

					try_reset_after_abort(kernel_connection);
					if(check_connection(kernel_connection) != 1)
						kernel_msg("Kernel connection lost");

				} else {
					kernel_msg("Kernel connection lost");
				}
			}

			listener_thread_is_running = false;

		}


		private void reset_kernel() {

			if(kernel_connection != null) {
				if(check_connection(kernel_connection) != -1) {
					close_connection(kernel_connection);
				}
			}

			
			kernel_connection = init_connection(Parameter.kernel_init);
			if(check_connection(kernel_connection) != 1) {
				kernel_msg("Error resetting connection");
			}
		}

		public void kernel_msg(string error) {
			stderr.printf("\n" + error + "\n");
		}

		private static delegate void callback_str(char* string_to_write, void* callback_data, ulong stamp, int break_after);

		private static  callback_str write_to_evaluation_cell = (_string_to_write, cell_ptr, _stamp, _break) => {
			string string_to_write;

			if(_string_to_write == null) {
				string_to_write = "";
			} else {
				string_to_write = (string) _string_to_write;
			}

			//append to GLib main loop
			GLib.Idle.add( () => {

				lock(global_stamp) {

					// get packet with right stamp
					if(global_stamp != _stamp) {

						// abort has been sent already, throw away packet
						if(global_stamp == 0)
							return false;
						return true;
					}
				
					Seaborg.EvaluationCell* cell_to_write = (Seaborg.EvaluationCell*) cell_ptr;
					
					if( cell_to_write != null) {

						if(string_to_write != "") {
							cell_to_write->add_text("\n"+ string_to_write);
							cell_to_write->expand_all();
						}

						if(_break != 0) {
							cell_to_write->lock=false;
							global_stamp = 0;
							return false;
						}
					}

					global_stamp++;

					return false;
				}
			});

			return;
		};

		private void save_dialog() {
			Gtk.FileChooserDialog saver = new Gtk.FileChooserDialog(
				"Save Notebook",
				main_window,
				Gtk.FileChooserAction.SAVE,
				"_Cancel",
				Gtk.ResponseType.CANCEL,
				"_Save",
				Gtk.ResponseType.ACCEPT
			);
			saver.select_multiple = false;
			saver.set_filename(notebook_stack.get_visible_child_name());

			
			if(saver.run() == Gtk.ResponseType.ACCEPT ) {
				GLib.SList<string> filenames = saver.get_filenames();
				foreach (string fn in filenames) {
					save_notebook(fn);	
				}
			}

			saver.close();
		}

		private void load_dialog() {
			Gtk.FileChooserDialog loader = new Gtk.FileChooserDialog(
				"Load Notebooks",
				main_window,
				Gtk.FileChooserAction.OPEN,
				"_Cancel",
				Gtk.ResponseType.CANCEL,
				"_Load",
				Gtk.ResponseType.ACCEPT
			);
			loader.select_multiple = true;
			loader.set_filename(notebook_stack.get_visible_child_name());
			

			
			if(loader.run() == Gtk.ResponseType.ACCEPT ) {
				GLib.SList<string> filenames = loader.get_filenames();
				foreach (string fn in filenames) {
					load_notebook(fn);	
				}
			}

			loader.close();
		}

		private void save_notebook(string fn) {
			GLib.FileStream save_file = GLib.FileStream.open(fn, "w");
			if(save_file == null) {
				kernel_msg("Error saving file: " + fn);
				return;
			}

			string identation="	"; // this is a tab
			save_file.printf("<?xml version=\"1.0\" encoding=\"utf-8\"?>\n\n<notebook version=\"1.0\">\n");
			for(int i = 0; i<((Seaborg.Notebook)notebook_stack.get_visible_child()).Children.data.length; i++) {
				write_recursively(((Seaborg.Notebook)notebook_stack.get_visible_child()).Children.data[i], save_file, identation);
			}
			save_file.printf("</notebook>");
			save_file.flush();

			if(notebook_stack.get_visible_child_name() != fn) {
				
				notebook_stack.child_set_property(notebook_stack.get_visible_child(), "name", fn);
				notebook_stack.child_set_property(notebook_stack.get_visible_child(), "title", make_file_name(fn));

			}

			return;
		}

		private void write_recursively(ICell cell, FileStream file, string identation) {
			if(cell is TextCell) {
				TextCell textcell = (TextCell) cell;
				
				file.printf(identation + "<cell type=\"text\">\n");
				file.printf(identation + "	<level>0</level>\n");
				file.printf(identation + "	<content>%s</content>\n", save_replacement(textcell.get_text()));
				file.printf(identation + "	<results></results>\n");
				file.printf(identation + "	<children></children>\n");
				file.printf(identation + "</cell>\n");
			}
			if(cell is EvaluationCell) {
				EvaluationCell evalcell = (EvaluationCell) cell;

				file.printf(identation + "<cell type=\"evaluation\">\n");
				file.printf(identation + "	<level>0</level>\n");
				file.printf(identation + "	<content>%s</content>\n", save_replacement(evalcell.get_text()));
				file.printf(identation + "	<results>\n" + identation + "		<result type=\"text\">%s</result>\n" + identation + "	</results>\n", save_replacement(evalcell.get_output_text()));
				file.printf(identation + "	<children></children>\n");
				file.printf(identation + "</cell>\n");
			}
			if(cell is CellContainer) {
				CellContainer cellcontainer = (CellContainer)cell;
				
				file.printf(identation + "<cell type=\"container\">\n");
				file.printf(identation + "	<level>%i</level>\n", cellcontainer.get_level());
				file.printf(identation + "	<content>%s</content>\n", save_replacement(cellcontainer.get_text()));
				file.printf(identation + "	<results></results>\n");
				file.printf(identation + "	<children>\n");

				for(int i=0; i<cellcontainer.Children.data.length; i++)
					write_recursively(cellcontainer.Children.data[i], file, identation + "		");


				file.printf(identation + "	</children>\n");
				file.printf(identation + "</cell>\n");
			}
		}

		private void load_notebook(string fn) {

			string? version;

			// parse file 
			Xml.Doc* doc = Xml.Parser.parse_file(fn);
			if(doc == null) {
				kernel_msg("Error opening file: " + fn);
				return;
			}

			// get root node
			Xml.Node* root = doc->get_root_element ();
			if(root == null) {
				kernel_msg("Error parsing file: " + fn);
				delete doc;
				return;
			}
			if(root->name != "notebook") {
				kernel_msg("Error parsing file: " + fn);
				delete doc;
				return;
			}

			// get property
			version = root->get_prop("version");
			if(version == null) {
				kernel_msg("Error parsing file: " + fn);
				delete doc;
				return;
			}
			if(double.parse(version) > 1.0) {
				kernel_msg("Warning: file was saved in newer version");
			}

			Seaborg.Notebook* notebook = new Seaborg.Notebook();
			assemble_recursively(root, (ICellContainer*)notebook);
			notebook_stack.add_titled(notebook, fn, make_file_name(fn));
			notebook_stack.set_visible_child(notebook);
			main_window.show_all();

			delete doc;
			return;
		}

		private void assemble_recursively(Xml.Node* root, ICellContainer* container) {
			
			string? type;
			Seaborg.TextCell* tcell;
			Seaborg.EvaluationCell* ecell;
			Seaborg.CellContainer* ccell;


			for(Xml.Node* iter = root->children; iter != null; iter = iter->next) {
				if(iter->type == Xml.ElementType.ELEMENT_NODE) {
					if(iter->name == "cell") {
						
						type = iter->get_prop("type");
						if(type == null) continue;

						switch (type) {
							case "evaluation":
								ecell = new EvaluationCell(container);
								for(Xml.Node* iter2 = iter->children; iter2 != null; iter2 = iter2->next) {

									if(iter2->name == "content") {
										ecell->set_text(load_replacement(iter2->get_content()));
									} else {
										if(iter2->name == "results") {
											for(Xml.Node* iter3 = iter2->children; iter3 != null; iter3 = iter3->next) {
												if(iter3->name == "result") {
													switch (iter3->get_prop("type")) {
														case null: 
															break;
														case "text":
															ecell->add_text("\n" + load_replacement(iter3->get_content()));
															ecell->expand_all();
															break;							
													}
												}
											}
										}
									}
								}
								container->add_before(-1, {ecell});
								break;
							case "text":
								for(Xml.Node* iter2 = iter->children; iter2 != null; iter2 = iter2->next) {
									if(iter2->name == "content") {
										tcell = new Seaborg.TextCell(container);
										tcell->set_text(load_replacement(iter2->get_content()));
										container->add_before(-1, {tcell});
									}	
								}
								break;
							case "container":
								ccell = new CellContainer(container, 1);
								for(Xml.Node* iter2 = iter->children; iter2 != null; iter2 = iter2->next) {
									if(iter2->name == "content") {
										ccell->set_text(load_replacement(iter2->get_content()));
									} else {
										if(iter2->name == "level") {
											ccell->set_level((uint) int.parse(iter2->get_content()));
										} else {
											if(iter2->name == "children") { 
												assemble_recursively(iter2, (ICellContainer*)ccell);
												ccell->expand_all();
											}
										}
									}
								}
								container->add_before(-1, {ccell});
								break;

						}
					}
				}
			}
		}

		private void new_notebook() {

			Seaborg.Notebook notebook = new Seaborg.Notebook();
			EvaluationCell* cell = new EvaluationCell(notebook);
			notebook.add_before(0, {cell});

			notebook_stack.add_titled(notebook, "~/Documents/New Notebook.xml", "New Notebook");

		}


		private EvaluationData current_cell; 

		[CCode(cname = "init_connection", cheader_filename = "wstp_connection.h")]
		private extern static void* init_connection(char* path);

		[CCode(cname = "close_connection", cheader_filename = "wstp_connection.h")]
		private extern static void close_connection(void* connection);

		[CCode(cname = "evaluate", cheader_filename = "wstp_connection.h")]
		private extern static void evaluate(void* con, char* input, callback_str callback, void* callback_data);

		[CCode(cname = "check_connection", cheader_filename = "wstp_connection.h")]
		private extern static int check_connection(void* con);

		[CCode(cname = "try_abort", cheader_filename = "wstp_connection.h")]
		private extern static int try_abort(void* con);

		[CCode(cname = "try_reset_after_abort", cheader_filename = "wstp_connection.h")]
		private extern static int try_reset_after_abort(void* con);

		private Gtk.ApplicationWindow main_window;
		private Gtk.HeaderBar main_headerbar;
		private Gtk.StackSwitcher tab_switcher;
		private Gtk.Stack notebook_stack;
		private GLib.Menu main_menu;
		private Gtk.ScrolledWindow notebook_scroll;
		private Gtk.ShortcutsWindow shortcuts;
		private void* kernel_connection;
		private GLib.Queue<EvaluationData?> eval_queue;
		private GLib.Thread<void*> listener_thread;
		private bool listener_thread_is_running=false;
	}


	int main(string[] args) {

		return new SeaborgApplication().run(args);
	}
}