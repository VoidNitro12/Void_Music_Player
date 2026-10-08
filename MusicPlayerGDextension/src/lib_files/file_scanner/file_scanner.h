#pragma once

#include "godot_cpp/classes/ref_counted.hpp"
#include "godot_cpp/variant/typed_array.hpp"
#include "godot_cpp/variant/packed_string_array.hpp"
#include "godot_cpp/variant/variant.hpp"
#include "godot_cpp/variant/string.hpp"

#include "lib_files/audio_file.h"
#include "lib_files/error_logger/error_logger.h"

#include <filesystem>
#include <unordered_set>
#include <vector>
#include <string>

// thirdparty tag reader (taglib-2.3.2)
#include <taglib/fileref.h>

// Json
#include <json.hpp>

class FileScanner : public godot::RefCounted {
	GDCLASS(FileScanner, godot::RefCounted)

protected:
	static void _bind_methods();

public:
	FileScanner() = default;
	~FileScanner() override = default;

	godot::TypedArray<godot::Dictionary> scan_dir(
		const godot::String p_path, 
		const bool p_scan_sub_directories=false
	);

	// Returns all valid extensions as a PackedstringArray for GDscript
	static godot::PackedStringArray get_gd_valid_extensions();

	// Checks if the given extension is supported by the app
	static bool is_valid_audio_type(const std::string &p_ext);

	void set_error_logger(const godot::Ref<ErrorLogger> &p_logger);

	static std::string get_song_cover_path();

    static godot::String get_gd_song_cover_path();

	static std::string get_meta_data_cache_path();

	static godot::String get_gd_meta_data_cache_path();

	AudioFile get_audio_file_from_path(std::string p_path);

	godot::Dictionary get_gd_audio_file_from_path(godot::String p_path);

	std::int64_t get_valid_files_num_from_path(godot::String p_path, bool p_recursive);

private:
	// Valid audio file types the app accepts to be accesed by GDextension classes
	inline static const std::unordered_set<std::string> valid_extensions{".mp3", ".wav", ".ogg"};

	inline static fs::path song_cover_path;

	inline static fs::path metadata_cache_path;

	inline static nlohmann::json meta_data_cache;

	godot::Ref<ErrorLogger> logger;
	
	std::vector<AudioFile> scan_impl(
		const std::filesystem::path &p_path,
		const bool p_recursive
	);

	void process_entry(
		const std::filesystem::directory_entry &p_entry, 
		std::vector<AudioFile> &r_results
	);

	std::string extract_cover(TagLib::FileRef ref, std::string p_path);

	static void clean_string(std::string &text);

	nlohmann::json &load_meta_data();

	void save_meta_data();
};
