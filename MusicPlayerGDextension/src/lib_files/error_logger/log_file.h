#pragma once

#include <filesystem>
#include <string>
#include <unordered_set>

struct LogFile{
    std::filesystem::path path;
    std::string file_name;
    std::filesystem::file_time_type last_modified;

    bool operator == (const LogFile &other) const{
        return path == other.path;
    }
};

struct LogFileHash{
    std::size_t operator() (const LogFile &other) const noexcept{
        return std::filesystem::hash_value(other.path);
    }
};

