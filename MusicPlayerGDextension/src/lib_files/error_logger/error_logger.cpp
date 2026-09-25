#include "error_logger.h"
#include "log_file.h"

#include "godot_cpp/classes/time.hpp"
#include "godot_cpp/classes/os.hpp"
#include "godot_cpp/variant/string.hpp"
#include "godot_cpp/classes/project_settings.hpp"


#include <string>
#include <cstdint>
#include <format>
#include <filesystem>
#include <system_error>
#include <unordered_set>
#include <fstream>

using namespace godot;

namespace fs = std::filesystem;

// Bindings for GDscript
void ErrorLogger::_bind_methods(){
    ClassDB::bind_integer_constant(
        get_class_static(),
        "LogLevel",
        "INFO",
        static_cast<int64_t>(INFO)
    );
    ClassDB::bind_integer_constant(
        get_class_static(),
        "LogLevel",
        "DEBUG",
        static_cast<int64_t>(DEBUG)
    );
    ClassDB::bind_integer_constant(
        get_class_static(),
        "LogLevel",
        "WARN",
        static_cast<int64_t>(WARN)
    );
    ClassDB::bind_integer_constant(
        get_class_static(),
        "LogLevel",
        "ERROR",
        static_cast<int64_t>(ERROR)
    );
    
    godot::ClassDB::bind_method(D_METHOD("log_error", "level", "message"), &ErrorLogger::log_error);
    godot::ClassDB::bind_method(D_METHOD("set_session_id", "session_id"), &ErrorLogger::set_session_id);
    godot::ClassDB::bind_static_method("ErrorLogger", D_METHOD("get_error_logs_path"), &ErrorLogger::get_gd_error_log_path);
}


// Function Defintions

std::string ErrorLogger::error_level_to_string(ErrorLogger::LogLevel p_level){
    switch (p_level)
    {
    case LogLevel::INFO:
        return "INFO";
    
    case LogLevel::DEBUG:
        return "DEBUG";
    
    case LogLevel::WARN:
        return "WARN";
    
    case LogLevel::ERROR:
        return "ERROR";

    default:
        return "Invalid LogLevel";
    }
}

void ErrorLogger::set_session_id(godot::String p_session_id){
    session_id = p_session_id.utf8().get_data();
}

String ErrorLogger::get_gd_error_log_path(){
    std::string path;

    path = ErrorLogger::get_error_log_path();

    return String::utf8(path.c_str());
}

std::string ErrorLogger::get_error_log_path(){
    if (ErrorLogger::error_log_path.empty()){
        fs::path user_dir = OS::get_singleton()->get_user_data_dir().utf8().get_data();
        fs::path dir_path = user_dir / "app_data" / "logs";
        ErrorLogger::error_log_path = dir_path;
    }
    return error_log_path;
}

LogFileSet ErrorLogger::get_logs(){
    LogFileSet logs;
    std::error_code ec;

    fs::path path = error_log_path;

    if (!fs::exists(path, ec) || ec){
        // Add an error 
        return logs;
    }

    if (!fs::is_directory(path, ec) || ec){
        // Add an error 
        return logs;
    }

    for (const fs::directory_entry &entry: fs::directory_iterator(
        path,fs::directory_options::skip_permission_denied, ec)){

        if (!entry.is_regular_file(ec) || ec){
            continue;
        }

        if (!(entry.path().extension() == ".txt")){
            continue;
        }

        LogFile file;
        file.path = entry.path();
        file.file_name = entry.path().filename();
        file.last_modified = entry.last_write_time(ec); 
        if (ec){
            // Add an error 
        }
        logs.insert(std::move(file));
    }
    
    return logs;
}

void ErrorLogger::create_log(LogFile &p_log, const std::string &p_message){
    std::ofstream file(p_log.path);

    if (!file){
        // add error
        return;
    }

    String version_info = ProjectSettings::get_singleton()->get_setting("application/config/version","0.0.0");

    std::string new_log_content = std::format("version: {} \nsession_id: {} \n\t----LOGS----\n{}", 
        version_info.utf8().get_data(), session_id, p_message);
    
    file << new_log_content;
    file.close();
}

void ErrorLogger::append_to_log(LogFile &p_log, const std::string &p_message){
    std::ofstream file(p_log.path, std::ios::app);

    if (!file.is_open()){
        // add error
        return;
    }

    file <<"\n";
    file << p_message; 

    if (!file){
        // error writing
    }
}

void ErrorLogger::clear_oldest_log(LogFileSet &prev_logs){
    std::error_code ec;

    LogFile oldest_log;
    bool has_oldest = false;

    for (const LogFile &log: prev_logs ){
        if (!has_oldest || (log.last_modified < oldest_log.last_modified)){
            oldest_log = log;
            has_oldest = true;
        }
    }

    if (oldest_log.path.empty()){
        return;
    }

    bool remove = fs::remove(oldest_log.path, ec);

    if (ec){
        // add error

    }else if (!remove){
        // add error
    }

}

void ErrorLogger::log_error(ErrorLogger::LogLevel p_level, String p_message){
    if (session_id.empty()){
        // add error
        return;
    }

    std::string timestamp = Time::get_singleton()->get_datetime_string_from_system(true,true).utf8().get_data();

    std::string message = std::format("[{}] : {} -- {}", ErrorLogger::error_level_to_string(p_level), timestamp, p_message.utf8().get_data());

    std::string log_file_name = std::format("{}.txt", session_id);

    LogFileSet logs = ErrorLogger::get_logs();

    fs::path path = ErrorLogger::get_error_log_path();
    path = path / log_file_name;

    LogFile needed_log;
    needed_log.path = path;

    if(!logs.contains(needed_log)){
        ErrorLogger::create_log(needed_log, p_message.utf8().get_data());
        if(logs.size() >= max_log_files){
            ErrorLogger::clear_oldest_log(logs);
        }
        
        return;
    }

    ErrorLogger::append_to_log(needed_log, p_message.utf8().get_data());
}