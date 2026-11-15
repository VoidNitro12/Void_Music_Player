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
#include <charconv> // for number->text conversion

// thirdparty tag reader (taglib-2.3.2)
#include <taglib/tag.h>
#include <taglib/fileref.h>
#include <taglib/audioproperties.h>
#include <taglib/tvariant.h>
#include <taglib/tbytevector.h>

// Json
#include <json.hpp>

// xxHash-0.8.4
#include <xxhash.h>

// miniaudio 0.11.25
#include <miniaudio.h>
#include <lib_files/m4a_extension_miniaudio/m4a_decoder.h>

using namespace godot;

namespace fs = std::filesystem;

using json = nlohmann::json;


// Bindings for GDscript
void FileScanner::_bind_methods(){
    ClassDB::bind_method(D_METHOD("scan_dir", "path", "scan_sub_directories"), &FileScanner::scan_dir, DEFVAL(false));

    ClassDB::bind_method(D_METHOD("set_error_logger", "error_logger"), &FileScanner::set_error_logger);

    ClassDB::bind_method(D_METHOD("get_audio_dict_from_path", "path"), &FileScanner::get_gd_audio_file_from_path);

    ClassDB::bind_method(D_METHOD("get_valid_audio_files_num", "path", "recursive"), &FileScanner::get_valid_files_num_from_path);

    ClassDB::bind_method(D_METHOD("save_meta_data_cache"), &FileScanner::save_meta_data);

    ClassDB::bind_static_method("FileScanner", D_METHOD("get_valid_extensions"), &FileScanner::get_gd_valid_extensions);

    ClassDB::bind_static_method("FileScanner", D_METHOD("get_song_cover_path"), &FileScanner::get_gd_song_cover_path);

    ClassDB::bind_static_method("FileScanner", D_METHOD("get_meta_data_cache_path"), &FileScanner::get_gd_meta_data_cache_path);
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
    // this runs once on the first call, not need for a mutex
    std::call_once(song_cover_path_init, [] {
        if (FileScanner::song_cover_path.empty()){
        fs::path user_dir = OS::get_singleton()->get_user_data_dir().utf8().get_data();
        fs::path dir_path = user_dir / "app_data" / "song_covers";
        FileScanner::song_cover_path = dir_path;
    }
    });
    
    return song_cover_path.string();
}

String FileScanner::get_gd_meta_data_cache_path(){
    std::string path;

    path = FileScanner::get_meta_data_cache_path();

    return String::utf8(path.c_str());
}

std::string FileScanner::get_meta_data_cache_path(){
    // this runs once on the first call, not need for a mutex
    std::call_once(meta_data_cache_path_init, [] {
        if (FileScanner::metadata_cache_path.empty()){
        fs::path user_dir = OS::get_singleton()->get_user_data_dir().utf8().get_data();
        fs::path dir_path = user_dir / "app_data" / "meta_data_cache.json";
        FileScanner::metadata_cache_path = dir_path;
    }
    });
    
    return metadata_cache_path.string();
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
    AudioFile file = get_audio_file_from_path(p_entry.path().string());

    if (file.is_empty()){
        return;
    }

    r_results.push_back(std::move(file));
}

void FileScanner::clean_string(std::string &text)
{
    text.erase(
        std::remove_if(text.begin(), text.end(),
            [](char c) {
                return c == '\n' ||     
                       c == '\t' ||
                       c == '\r';
            }),
        text.end()
    );
}

std::string FileScanner::extract_cover(TagLib::FileRef ref, std::string p_uuid){
    // Gets only the first picture

    const auto pictures = ref.complexProperties("PICTURE");

    if (pictures.isEmpty()){
        logger->log_error(
            ErrorLogger::LogLevel::WARN, 
            godot::String::utf8(std::format("No cover image found for file:  {}", p_uuid).c_str())
        );
        return "";
    }

    const auto &picture = pictures.front();
    const auto image = picture.find("data");

    if (image == picture.end()){
        logger->log_error(
            ErrorLogger::LogLevel::ERROR, 
            godot::String::utf8(std::format("The cover image found for file: {}, has no image data", p_uuid).c_str())
        );
        return "";
    }

    const auto mime = picture.find("mimeType");

    if (mime == picture.end()){
        logger->log_error(
            ErrorLogger::LogLevel::ERROR, 
            godot::String::utf8(std::format("Could not get cover image type for file: {}", p_uuid).c_str())
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

    std::string cover_name = p_uuid + extension;

    const TagLib::ByteVector data = image->second.value<TagLib::ByteVector>();

    fs::path cover_path = get_song_cover_path();
    cover_path = cover_path / cover_name;

    std::ofstream output(cover_path, std::ios::binary);

    if (!output){
        logger->log_error(
            ErrorLogger::LogLevel::ERROR, 
            godot::String::utf8(std::format("Could not create cover image for file: {} at {}", p_uuid, cover_path.string()).c_str())
        );
        return "";
    }

    output.write(data.data(), static_cast<std::streamsize>(data.size()));

    return cover_path.string();
}

AudioFile FileScanner::get_audio_file_from_path(std::string p_path){
    fs::directory_entry entry(p_path);

    std::error_code ec;

    if (!entry.is_regular_file(ec) || ec){
        return AudioFile{};
    }

    std::string ext = entry.path().extension().string();
    if (!is_valid_audio_type(ext)){
        return AudioFile{};
    }

    AudioFile file;
    file.path = entry.path().string();
    file.extension = ext;
    file.size = entry.file_size(ec); //Soley meant for comparisons
    if (ec){
        logger->log_error(
            ErrorLogger::LogLevel::WARN, 
            godot::String::utf8(std::format("Could not read file size from {}",file.path).c_str())
        );
        file.size = 0;
    }
    file.last_modified = entry.last_write_time(ec); //Soley meant for comparisons
    if (ec){
        logger->log_error(
            ErrorLogger::LogLevel::WARN, 
            godot::String::utf8(std::format("Could not read file last write time from {}",file.path).c_str())
        );
    }

    json &cache = load_meta_data();

    if (cache["paths"].contains(file.path)){

        std::string uuid = cache["paths"][file.path];

        json &data = cache["uuids"][uuid];

        if (
            data["file_size"] == file.size && 
            data["last_mod"] == file.last_modified.time_since_epoch().count()
        ){
            file.uuid = uuid;
            file.title = data["title"];
            file.artist = data["artist"];
            file.album = data["album"];
            file.cover_path = data["cover_path"];
            file.release_year = data["release_year"];
            file.raw_length = data["raw_length"];

            return file;
        }
    }

    TagLib::FileRef ref(file.path.c_str());

    if (!ref.isNull() && ref.tag() != nullptr && ref.audioProperties() != nullptr){
        file.title = ref.tag()->title().to8Bit(true);
        file.artist = ref.tag()->artist().to8Bit(true);
        file.album = ref.tag()->album().to8Bit(true);

        FileScanner::clean_string(file.title);
        FileScanner::clean_string(file.artist);
        FileScanner::clean_string(file.album);

        file.release_year = ref.tag()->year();
        file.raw_length = ref.audioProperties()->lengthInSeconds();

        XXH64_hash_t hash = get_hash_of_audio_file(p_path);
        if (hash == 0){
            return AudioFile{};
        }
        
        // turning the hash into a hex
        char h_buf[16];
        auto [ptr, ec] = std::to_chars(h_buf, h_buf + 16, hash, 16);
        // to_chars does NOT zero-pad:
        std::string s;
        s.append(16 - (ptr - h_buf), '0');
        s.append(h_buf, ptr);
        file.uuid = s;

        // Store the cover with the songs uuid
        file.cover_path = extract_cover(ref, file.uuid);

        // check if the meta data has this exact uuid (we've already scanned it so just update the path
        //  and overwrite regardless)
        if (cache["uuids"].contains(file.uuid)) {
            std::string old_path = cache["uuids"][file.uuid]["path"];
            cache["paths"].erase(old_path);
        }

        cache["paths"][file.path] = file.uuid;

        // create cache
        json &data = cache["uuids"][file.uuid];

        data = json::object();
        data["title"] = file.title;
        data["artist"] = file.artist;
        data["album"] = file.album;
        data["cover_path"] = file.cover_path;
        data["release_year"] = file.release_year;
        data["raw_length"] = file.raw_length;
        data["file_size"] = file.size;
        data["last_mod"] = file.last_modified.time_since_epoch().count();
        data["path"] = file.path;
    }else{
        logger->log_error(
            ErrorLogger::LogLevel::WARN, 
            godot::String::utf8(std::format("Could not extracts tags from {}",file.path).c_str())
        );
    }

    return file;
}

XXH64_hash_t FileScanner::get_hash_of_audio_file(const std::string &p_path){
    //this hash matches for byte-identical decodes which is fine if more is needed ill get a public library

    static ma_decoding_backend_vtable *custom_backends[] = {
        ma_decoding_backend_ffmpeg
    };

    ma_decoder_config config = ma_decoder_config_init_default();
    config.format     = ma_format_f32;  // Output format: 32-bit float
    config.channels   = 2;  // Output channels: 2 (stereo)
    config.sampleRate = 44100;  // Output sample rate: 44100 Hz
    config.ppCustomBackendVTables = custom_backends;
    config.customBackendCount = 1;


    ma_decoder decoder;
    ma_result result = ma_decoder_init_file(p_path.c_str(), &config, &decoder);

    if (result != MA_SUCCESS) {
        logger->log_error(
            ErrorLogger::LogLevel::WARN, 
            godot::String::utf8(std::format("Could not initialise decoder for {}. result: {}", p_path, ma_result_description(result)).c_str())
        );
        // A hash of just 0 is an error, handle it
        ma_decoder_uninit(&decoder);
        return 0;
    }

    // confirm the decoder actually honored the requested format
    if (decoder.outputFormat     != ma_format_f32 ||
        decoder.outputChannels   != 2             ||
        decoder.outputSampleRate != 44100) {
        logger->log_error(ErrorLogger::LogLevel::WARN,
            godot::String::utf8(std::format(
                "Decoder ignored requested format for {}", p_path).c_str()));
        ma_decoder_uninit(&decoder);
        return 0;
    }

    ma_format format;
    ma_uint32 channels, sampleRate;
    ma_data_source_get_data_format(&decoder, &format, &channels, &sampleRate, NULL, 0);
    

    std::vector<std::uint8_t> pcm_buf;
    const ma_uint64 frames_per_chunck = 4096;
    const ma_uint32 bytes_per_frame = ma_get_bytes_per_frame(format, channels);
    pcm_buf.resize(frames_per_chunck * bytes_per_frame);

    XXH3_state_t* state = XXH3_createState();
    if (!state) {
        ma_decoder_uninit(&decoder);
        return 0;
    }
    XXH3_64bits_reset(state);

    ma_uint64 max_frames_to_hash = static_cast<ma_uint64>(decoder.outputSampleRate) * 30; // 30 seconds to reduce time spent hashing
    ma_uint64 frames_hashed = 0;

    while (frames_hashed < max_frames_to_hash) {
        ma_uint64 frames_read = 0;
        ma_result r = ma_decoder_read_pcm_frames(
            &decoder,
            pcm_buf.data(),
            frames_per_chunck,
            &frames_read
        );

        if (r == MA_AT_END || frames_read == 0) break;
        if (r != MA_SUCCESS) {
            logger->log_error(ErrorLogger::LogLevel::WARN,
                godot::String::utf8(std::format(
                    "Decode error for {}: {}", p_path,
                    ma_result_description(r)).c_str()));
            ma_decoder_uninit(&decoder);
            XXH3_freeState(state);
            return 0;
        }

        ma_uint64 frames_this_chunk = frames_read;
        // so it doesnt end up reading any more than it has to and cuts off the current chunk
        if (frames_hashed + frames_this_chunk > max_frames_to_hash) {
            frames_this_chunk = max_frames_to_hash - frames_hashed;  // trim to land exactly on the limit
        }

        std::size_t bytesRead = frames_this_chunk * bytes_per_frame;
        XXH3_64bits_update(state, pcm_buf.data(), bytesRead);

        frames_hashed += frames_this_chunk;
    }

    XXH64_hash_t hash = XXH3_64bits_digest(state);
    XXH3_freeState(state);

    ma_decoder_uninit(&decoder);

    return hash;
}

nlohmann::json &FileScanner::load_meta_data(){
    if (!meta_data_cache.is_null()){
        return meta_data_cache;
    }

    std::ifstream data(get_meta_data_cache_path());

    if (!data){
        meta_data_cache = json::object();
    }else{
        meta_data_cache = json::parse(data);
    }

    if (meta_data_cache.empty()){
        meta_data_cache["uuids"] = json::object();
        meta_data_cache["paths"] = json::object();
    }

    return meta_data_cache;
}

void FileScanner::save_meta_data(){
    std::ofstream output(get_meta_data_cache_path());
    output << meta_data_cache.dump(4);
}

std::int64_t FileScanner::get_valid_files_num_from_path(godot::String p_path, bool p_recursive){
    fs::path path = p_path.utf8().get_data();

    std::int64_t result = 0;
    std::error_code ec;


    if (!fs::exists(path, ec) || ec){
        logger->log_error(
            ErrorLogger::LogLevel::WARN, 
            godot::String::utf8("Path given to FileScanner is not a valid path")
        );
        return result;
    }

    if (!fs::is_directory(path, ec) || ec){
        logger->log_error(
            ErrorLogger::LogLevel::ERROR, 
            godot::String::utf8("Path given to FileScanner is not a directory")
        );
        return result;
    }

    if(p_recursive){
        for (const fs::directory_entry &entry: fs::recursive_directory_iterator(
            path,fs::directory_options::skip_permission_denied, ec)){
            if (is_valid_audio_type(entry.path().extension().string())){
                result += 1;
            }
        }
    }else{
        for (const fs::directory_entry &entry: fs::directory_iterator(
            path,fs::directory_options::skip_permission_denied, ec)){
            if (is_valid_audio_type(entry.path().extension().string())){
                result += 1;
            }
        }
    }

    return result;
}

// for headache avoiding reasons this doesnt handle saving the changed cache incase of calling this in a loop,
// manually call save after your'e done
godot::Dictionary FileScanner::get_gd_audio_file_from_path(godot::String p_path){
    godot::Dictionary dict;

    AudioFile file = get_audio_file_from_path(p_path.utf8().get_data());

    if (file.is_empty()){
        return dict;
    }

    dict["uuid"] = String::utf8(file.uuid.c_str());
    dict["path"] = String::utf8(file.path.c_str());
    dict["cover_path"] = String::utf8(file.cover_path.c_str());
    dict["title"] = String::utf8(file.title.c_str());
    dict["artist"] = String::utf8(file.artist.c_str());
    dict["album"] = String::utf8(file.album.c_str());
    dict["release_year"] = file.release_year;
    dict["raw_length"] = file.raw_length;

    return dict;
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

    save_meta_data();

    results.resize(native.size());

    for (size_t i = 0; i < native.size(); i++){
        const AudioFile &file = native[i];
        Dictionary dict;
        dict["uuid"] = String::utf8(file.uuid.c_str());
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