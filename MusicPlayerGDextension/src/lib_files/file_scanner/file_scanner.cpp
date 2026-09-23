#include "file_scanner.h"

// thirdparty tag reader (taglib-2.3.2)
#include <taglib/tag.h>
#include <taglib/fileref.h>

using namespace godot;
using namespace std;

namespace fs = filesystem;

void FileScanner::_bind_methods(){
    godot::ClassDB::bind_method(D_METHOD("scan_dir", "path"), &FileScanner::scan_dir, DEFVAL(false));

}

// Function Declarations
vector<unordered_map<string,string>> FileScanner::scan_dir(const String &path, const bool &scan_subfolders=false){
    vector<unordered_map<string,string>> results;
    error_code ec;
}