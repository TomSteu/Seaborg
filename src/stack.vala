using Gtk;
using Pango;
using GLib;

namespace Seaborg {

	public class Stack : Gtk.Stack {

		public signal void child_added(string name, string title);
		public signal void child_removed(string name);
		public signal void child_amended(string old_name, string new_name, string new_title);
	
		public new void add_titled (Gtk.Widget child, string name, string title) {
			base.add_titled(child, name, title);
			base.visible_child = child;
			checksums.insert(name, "");
			child_added(name, title);
		}

		public new void remove_by_name(string name) {

			
			child_removed(name);
			Gtk.Widget? child = base.get_child_by_name(name);
			
			if( child != null) 
				base.remove(child);

			if(checksums.contains(name))
				checksums.remove(name);

		}

		public void child_amend_name_title(string old_name, string new_name, string new_title) {

				child_amended(old_name, new_name, new_title);
				Gtk.Widget? child = base.get_child_by_name(old_name);

				if( child != null) {
					base.child_set_property(child, "name", new_name);
					base.child_set_property(child, "title", new_title);

					if(new_name != old_name) {
						string val = checksums.lookup(old_name);
						checksums.insert(new_name, val);
						checksums.remove(old_name);
					}
				}

		}

		public void child_update_checksum(string name, string hash) {
			checksums.insert(name, hash);
		}

		private GLib.HashTable <string, string> checksums = new GLib.HashTable <string, string>(str_hash, str_equal);


	}

	public class TabSwitcher : Gtk.Box {

		public TabSwitcher(Gtk.Stack? with_stack = null) {

			orientation = Gtk.Orientation.HORIZONTAL;
			spacing = 0;
			homogeneous = false;

			stack = (Seaborg.Stack) (with_stack ?? new Seaborg.Stack());


			stack.child_added.connect((_name, _title) => {
				this.pack_start(new TabSwitcherButton(_name, _title, this));
				show_all();
			});

			stack.child_removed.connect((_name) => {

				foreach ( Gtk.Widget child in this.get_children()) {
					if((child as TabSwitcherButton).stack_name == _name) {
						child.destroy();
					}
				}
				show_all();
			});

			stack.child_amended.connect((old_name, new_name, new_title) => {
				foreach ( Gtk.Widget child in this.get_children()) {
					if((child as TabSwitcherButton).stack_name == old_name) {
						(child as TabSwitcherButton).stack_name = new_name;
						(child as TabSwitcherButton).title = new_title;
					}
				}
				show_all();
			});

			stack.notify["visible-child"].connect((property, sender) => {
				foreach ( Gtk.Widget child in this.get_children()) {
					(child as TabSwitcherButton).active = ((child as TabSwitcherButton).stack_name == stack.visible_child_name); 
				}
				show_all();
			});

			this.show_all();

		}


		public Seaborg.Stack stack {
			get {return _stack;}
			set {
				
				if(_stack == value)
					return;

				get_children().foreach((_widget) => {
					remove(_widget);
				});

				_stack = value;

				string visible_name = _stack.visible_child_name;

				foreach(Gtk.Widget child in _stack.get_children()) {
					_stack.visible_child = child;
					pack_start(new TabSwitcherButton(_stack.visible_child_name, make_file_name(_stack.visible_child_name), this));

				}

				 _stack.visible_child_name = visible_name;

			}
		}

		private Seaborg.Stack _stack;
	}


	public class TabSwitcherButton : Gtk.ToggleButton {

		public TabSwitcherButton(string _name, string _titl, TabSwitcher switcher) {

			tab_switcher = switcher;
			stack_name = _name;
			_title = _titl;


			_label = new Gtk.Label(_titl);
			_label.single_line_mode = true;
			_label.ellipsize = Pango.EllipsizeMode.END;
			this.add(_label);
			this.can_focus = false;
			this.get_style_context().add_class("switcher");

			this.active = true;
			tab_switcher.stack.visible_child_name = stack_name;


			this.toggled.connect(() => {
				if(this.active) {
					tab_switcher.stack.visible_child_name = stack_name;
				}

				this.active = (tab_switcher.stack.visible_child_name == stack_name);
			});
		
		}

		public string title {
			get {return _title;}
			set{
				if(_title != value) {
					_title = value;
					_label.label = value;
					show_all();
				}
			}
		}

		public string stack_name {get; set;}

		private TabSwitcher tab_switcher;
		private Gtk.Label _label;
		private string _title;

	}


}