#pragma once

#include <string>
#include <cstdint>
#include <filesystem>

struct AudioFile{
    std::string path = "";
    std::string cover_path = "";
    std::string extension = "";
    std::string title = "";
    std::string artist = "";
    std::string album = "";
    std::int64_t release_year = 0;
    std::int64_t raw_length = 0;
    std::int64_t size = 0;
    std::filesystem::file_time_type last_modified;
};