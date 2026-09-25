#pragma once

#include "godot_cpp/classes/ref_counted.hpp"
#include "log_file.h"

#include <cstdint>
#include <unordered_set>
#include <filesystem>
#include <string>


using LogFileSet = std::unordered_set<LogFile,LogFileHash>;

namespace fs = std::filesystem;

class ErrorLogger: public godot::RefCounted{
    GDCLASS(ErrorLogger, godot::RefCounted)

protected:
	static void _bind_methods();

public:
    ErrorLogger() = default;
	~ErrorLogger() override = default;

    enum LogLevel{
    INFO,
    DEBUG,
    WARN,
    ERROR,
    };

    void log_error(LogLevel p_level, godot::String p_message, godot::String p_session_id);

    static std::string error_level_to_string(LogLevel p_level);

    static std::string get_error_log_path();

    static godot::String get_gd_error_log_path();

private:
    const int64_t max_log_files = 10;

    inline static fs::path error_log_path;

    LogFileSet get_logs();

    void create_log(LogFile &p_log, const std::string &p_message, const std::string &p_session_id);

    void append_to_log(LogFile &p_log, const std::string &p_message);

    void clear_oldest_log(LogFileSet &prev_logs);
};


VARIANT_ENUM_CAST(ErrorLogger::LogLevel)