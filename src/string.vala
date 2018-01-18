namespace Seaborg {

	static bool check_input_packet(string _str) {
		
		string str = _str.replace(" ", "").replace("\n", "");
		
		if(str == "") return false;
		if(str.replace("[","").length != str.replace("]","").length) return false;
		if(str.replace("(","").length != str.replace(")","").length) return false;
		if(str.replace("{","").length != str.replace("}","").length) return false;
		
		return true;
	}

}