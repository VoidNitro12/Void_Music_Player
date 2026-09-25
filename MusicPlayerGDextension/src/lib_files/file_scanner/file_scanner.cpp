#include "file_scanner.h"

#include "godot_cpp/variant/string.hpp"

#include <string>
#include <vector>
#include <unordered_set>
#include <filesystem>
#include <system_error>

// thirdparty tag reader (taglib-2.3.2)
#include <taglib/tag.h>
#include <taglib/fileref.h>
#include <taglib/audioproperties.h>


using namespace godot;

namespace fs = std::filesystem;


// Bind methods for GDscript
void FileScanner::_bind_methods(){
    godot::ClassDB::bind_method(D_METHOD("scan_dir", "path", "scan_sub_directories"), &FileScanner::scan_dir, DEFVAL(false));

    godot::ClassDB::bind_static_method("FileScanner", D_METHOD("get_valid_extensions"), &FileScanner::get_gd_valid_extensions);
}

// Function Definitions

std::vector<AudioFile> FileScanner::scan_impl(const fs::path &p_path, const bool p_recursive){
    std::vector<AudioFile>results;
    std::error_code ec;

    if (!fs::exists(p_path, ec) || ec){
        // Add an error after ErrorLogger has been ported
        return results;
    }

    if (!fs::is_directory(p_path, ec) || ec){
         // Add an error after ErrorLogger has been ported
        return results;
    }

    if(p_recursive){
        for (const fs::directory_entry &entry: fs::recursive_directory_iterator(
            p_path,fs::directory_options::skip_permission_denied, ec)){
            FileScanner::process_entry(entry, results);
        }
    }else{
        for (const fs::directory_entry &entry: fs::directory_iterator(
            p_path,fs::directory_options::skip_permission_denied, ec)){
            FileScanner::process_entry(entry, results);
        }
    }

    return results;
}

PackedStringArray FileScanner::get_gd_valid_extensions(){
    PackedStringArray gd_valid_extensions;
    
    for(const std::string &ext: valid_extensions){
        gd_valid_extensions.append(String::utf8(ext.c_str()));
    }
    
    return gd_valid_extensions;
}

bool FileScanner::is_valid_audio_type(const std::string &p_ext){
    return valid_extensions.count(p_ext) != 0;
}

void FileScanner::process_entry(const fs::directory_entry &p_entry, std::vector<AudioFile> &r_results){
    std::error_code ec;

    if (!p_entry.is_regular_file(ec) || ec){
        // Add an error after ErrorLogger has been ported
        return;
    }

    std::string ext = p_entry.path().extension().string();
    if (!is_valid_audio_type(ext)){
        // Add an error after ErrorLogger has been ported
        return;
    }


    AudioFile file;
    file.path = p_entry.path().string();
    file.extension = ext;
    file.size = p_entry.file_size(ec); //Soley meant for comparisons
    if (ec){
        // Add an error after ErrorLogger has been ported
        file.size = 0;
    }
    file.last_modified = p_entry.last_write_time(ec); //Soley meant for comparisons
    if (ec){
        // Add an error after ErrorLogger has been ported
    }

    TagLib::FileRef ref(file.path.c_str());

    if (!ref.isNull() && ref.tag() != nullptr && ref.audioProperties() != nullptr){
        file.title = ref.tag()->title().to8Bit(true);
        file.artist = ref.tag()->artist().to8Bit(true);
        file.album = ref.tag()->album().to8Bit(true);
        file.release_year = ref.tag()->year();
        file.raw_length = ref.audioProperties()->lengthInSeconds();
    }else{
        // Add an error after ErrorLogger has been ported
    }

    r_results.push_back(std::move(file));
}

TypedArray<Dictionary> FileScanner::scan_dir(const String p_path, const bool p_scan_sub_directories){
    std::vector<AudioFile> native = FileScanner::scan_impl(
        fs::path(p_path.utf8().get_data()),p_scan_sub_directories
    );

    TypedArray<Dictionary> results;

    results.resize(native.size());

    for (size_t i = 0; i < native.size(); i++){
        const AudioFile &file = native[i];
        Dictionary dict;
        dict["path"] = String::utf8(file.path.c_str());
        dict["title"] = String::utf8(file.title.c_str());
        dict["artist"] = String::utf8(file.artist.c_str());
        dict["album"] = String::utf8(file.album.c_str());
        dict["release_year"] = file.release_year;
        dict["raw_length"] = file.raw_length;
        // last modified, size and extension are not needed by the audio player

        results[i] = dict;
    }

    return results;
}