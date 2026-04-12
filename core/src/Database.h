#pragma once

#include <string>
#include <sqlite3.h>

namespace Alfa {

class Database
{
public:
    explicit Database(const std::string& path);
    ~Database();

    bool execute(const std::string& sql);
    bool initialize();
    sqlite3* connection() const noexcept;

private:
    sqlite3* m_db;
};

} // namespace Alfa
