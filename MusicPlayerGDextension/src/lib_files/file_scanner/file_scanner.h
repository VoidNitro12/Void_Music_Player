#pragma once

#include "godot_cpp/classes/ref_counted.hpp"
#include "godot_cpp/variant/typed_array.hpp"
#include "godot_cpp/variant/packed_string_array.hpp"
#include "godot_cpp/variant/variant.hpp"
#include "godot_cpp/variant/string.hpp"

#include "lib_files/audio_file.h"

#include <filesystem>
#include <unordered_set>
#include <vector>
#include <string>

class FileScanner : public godot::RefCounted {
	GDCLASS(FileScanner, godot::RefCounted)

protected:
	static void _bind_methods();

public:
	FileScanner() = default;
	~FileScanner() override = default;

	godot::TypedArray<godot::Dictionary> scan_dir(const godot::String p_path, const bool p_scan_sub_directories=false);

	// Returns all valid extensions as a PackedstringArray for GDscript
	static godot::PackedStringArray get_gd_valid_extensions();

	static bool is_valid_audio_type(const std::string &p_ext);

private:
	// Valid audio file types the app accepts to be accesed by GDextension classes
	inline static const std::unordered_set<std::string> valid_extensions{".mp3", ".wav", ".ogg"};
	
	static std::vector<AudioFile> scan_impl(const std::filesystem::path &p_path, const bool p_recursive);

	static void process_entry(const std::filesystem::directory_entry &p_entry, std::vector<AudioFile> &r_results);
};
