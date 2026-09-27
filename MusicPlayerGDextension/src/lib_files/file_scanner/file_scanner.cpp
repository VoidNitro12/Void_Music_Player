#include "file_scanner.h"
#include "lib_files/error_logger/error_logger.h"

#include "godot_cpp/variant/string.hpp"
#include "godot_cpp/classes/ref_counted.hpp"
#include "godot_cpp/classes/os.hpp"

#include <string>
#include <vector>
#include <unordered_set>
#include <filesystem>
#include <system_error>
#include <format>
#include <fstream>
#include <algorithm>

// thirdparty tag reader (taglib-2.3.2)
#include <taglib/tag.h>
#include <taglib/fileref.h>
#include <taglib/audioproperties.h>
#include <taglib/tvariant.h>
#include <taglib/tbytevector.h>


using namespace godot;

namespace fs = std::filesystem;


// Bindings for GDscript
void FileScanner::_bind_methods(){
    ClassDB::bind_method(D_METHOD("scan_dir", "path", "scan_sub_directories"), &FileScanner::scan_dir, DEFVAL(false));

    ClassDB::bind_method(D_METHOD("set_error_logger", "error_logger"), &FileScanner::set_error_logger);

    ClassDB::bind_static_method("FileScanner", D_METHOD("get_valid_extensions"), &FileScanner::get_gd_valid_extensions);

    ClassDB::bind_static_method("FileScanner", D_METHOD("get_song_cover_path"), &FileScanner::get_gd_song_cover_path);
}

// Function Definitions

void FileScanner::set_error_logger(const godot::Ref<ErrorLogger> &p_logger){
    FileScanner::logger = p_logger;
}

String FileScanner::get_gd_song_cover_path(){
    std::string path;

    path = FileScanner::get_song_cover_path();

    return String::utf8(path.c_str());
}

std::string FileScanner::get_song_cover_path(){
    if (FileScanner::song_cover_path.empty()){
        fs::path user_dir = OS::get_singleton()->get_user_data_dir().utf8().get_data();
        fs::path dir_path = user_dir / "app_data" / "song_covers";
        FileScanner::song_cover_path = dir_path;
    }
    return song_cover_path;
}

std::vector<AudioFile> FileScanner::scan_impl(const fs::path &p_path, const bool p_recursive){
    std::vector<AudioFile>results;
    std::error_code ec;


    if (!fs::exists(p_path, ec) || ec){
        logger->log_error(
            ErrorLogger::LogLevel::WARN, 
            godot::String::utf8("Path given to FileScanner is not a valid path")
        );
        return results;
    }

    if (!fs::is_directory(p_path, ec) || ec){
        logger->log_error(
            ErrorLogger::LogLevel::ERROR, 
            godot::String::utf8("Path given to FileScanner is not a directory")
        );
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

void FileScanner::process_entry(
    const fs::directory_entry &p_entry, 
    std::vector<AudioFile> &r_results)
{
    std::error_code ec;

    if (!p_entry.is_regular_file(ec) || ec){
        return;
    }

    std::string ext = p_entry.path().extension().string();
    if (!is_valid_audio_type(ext)){
        return;
    }


    AudioFile file;
    file.path = p_entry.path().string();
    file.extension = ext;
    file.size = p_entry.file_size(ec); //Soley meant for comparisons
    if (ec){
        logger->log_error(
            ErrorLogger::LogLevel::WARN, 
            godot::String::utf8(std::format("Could not read file size from {}",file.path).c_str())
        );
        file.size = 0;
    }
    file.last_modified = p_entry.last_write_time(ec); //Soley meant for comparisons
    if (ec){
        logger->log_error(
            ErrorLogger::LogLevel::WARN, 
            godot::String::utf8(std::format("Could not read file last write time from {}",file.path).c_str())
        );
    }

    // Add audio file cache

    TagLib::FileRef ref(file.path.c_str());

    if (!ref.isNull() && ref.tag() != nullptr && ref.audioProperties() != nullptr){
        file.title = ref.tag()->title().to8Bit(true);
        file.artist = ref.tag()->artist().to8Bit(true);
        file.album = ref.tag()->album().to8Bit(true);

        FileScanner::clean_string(file.title);
        FileScanner::clean_string(file.artist);
        FileScanner::clean_string(file.album);

        file.cover_path = extract_cover(ref, file.title, file.artist);
        file.release_year = ref.tag()->year();
        file.raw_length = ref.audioProperties()->lengthInSeconds();
    }else{
        logger->log_error(
            ErrorLogger::LogLevel::WARN, 
            godot::String::utf8(std::format("Could not extracts tags from {}",file.path).c_str())
        );
    }

    r_results.push_back(std::move(file));
}

void FileScanner::clean_string(std::string &text)
{
    text.erase(
        std::remove_if(text.begin(), text.end(),
            [](char c) {
                return c == '\n' ||   // newline
                       c == '\r' ||   // carriage return
                       c == '"';      // double quote
            }),
        text.end()
    );
}

std::string FileScanner::extract_cover(TagLib::FileRef ref, std::string p_title, std::string p_artist){
    // Gets only the first picture

    const auto pictures = ref.complexProperties("PICTURE");
    const std::string song_title = p_title;

    if (pictures.isEmpty()){
        logger->log_error(
            ErrorLogger::LogLevel::ERROR, 
            godot::String::utf8(std::format("No cover image found for {}", song_title).c_str())
        );
        return "";
    }

    const auto &picture = pictures.front();
    const auto image = picture.find("data");

    if (image == picture.end()){
        logger->log_error(
            ErrorLogger::LogLevel::ERROR, 
            godot::String::utf8(std::format("cover image found for {}, has no image data", song_title).c_str())
        );
        return "";
    }

    const auto mime = picture.find("mimeType");

    if (mime == picture.end()){
        logger->log_error(
            ErrorLogger::LogLevel::ERROR, 
            godot::String::utf8(std::format("Could not get cover image type for {}", song_title).c_str())
        );
        return "";
    }

    std::string extension;

    const std::string mime_type = mime->second.toString().to8Bit();

    if (mime_type == "image/png"){
        extension = ".png";
    } 
    else if (mime_type == "image/gif"){
        extension = ".gif";
    }
    else {
        extension = ".jpg";
    };

    std::string cover_name = song_title + "_by_" + p_artist + extension;

    const TagLib::ByteVector data = image->second.value<TagLib::ByteVector>();

    fs::path path = get_song_cover_path();
    path = path / cover_name;

    std::ofstream output(path, std::ios::binary);

    if (!output){
        logger->log_error(
            ErrorLogger::LogLevel::ERROR, 
            godot::String::utf8(std::format("Could not create cover image for {} at {}", song_title, path.string()).c_str())
        );
        return "";
    }

    output.write(data.data(), static_cast<std::streamsize>(data.size()));

    return path;
}

TypedArray<Dictionary> FileScanner::scan_dir(const String p_path, const bool p_scan_sub_directories){
    TypedArray<Dictionary> results;

    if (!logger.is_valid()){
        UtilityFunctions::push_error("FileScaner requires a valid ErrorLogger set via set_error_logger()");
        return results;
    }

    std::vector<AudioFile> native = FileScanner::scan_impl(
        fs::path(p_path.utf8().get_data()),p_scan_sub_directories
    );

    results.resize(native.size());

    for (size_t i = 0; i < native.size(); i++){
        const AudioFile &file = native[i];
        Dictionary dict;
        dict["path"] = String::utf8(file.path.c_str());
        dict["cover_path"] = String::utf8(file.cover_path.c_str());
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