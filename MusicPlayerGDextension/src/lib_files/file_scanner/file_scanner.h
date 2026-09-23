#pragma once

#include "godot_cpp/classes/ref_counted.hpp"
#include "godot_cpp/classes/wrapped.hpp"
#include "godot_cpp/variant/variant.hpp"

using namespace godot;
using namespace std;

class FileScanner : public RefCounted {
	GDCLASS(FileScanner, RefCounted)

protected:
	static void _bind_methods();

public:
	FileScanner() = default;
	~FileScanner() override = default;

	const PackedStringArray VALID_EXTENSIONS = {"mp3", "wav", "ogg"};

	static vector<unordered_map<string,string>> scan_dir(const String &path, const bool &scan_subfolders=false);

};
