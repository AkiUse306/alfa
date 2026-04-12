#include "Database.h"
#include <iostream>

namespace Alfa {

Database::Database(const std::string& path)
    : m_db(nullptr)
{
    if (sqlite3_open(path.c_str(), &m_db) != SQLITE_OK) {
        std::cerr << "[core] Failed to open database: " << sqlite3_errmsg(m_db) << std::endl;
        sqlite3_close(m_db);
        m_db = nullptr;
    }
}

Database::~Database()
{
    if (m_db) {
        sqlite3_close(m_db);
    }
}

bool Database::execute(const std::string& sql)
{
    if (!m_db) {
        return false;
    }
    char* error = nullptr;
    const int result = sqlite3_exec(m_db, sql.c_str(), nullptr, nullptr, &error);
    if (result != SQLITE_OK) {
        std::cerr << "[core] SQLite error: " << (error ? error : "unknown") << std::endl;
        sqlite3_free(error);
        return false;
    }
    return true;
}

bool Database::initialize()
{
    if (!m_db) {
        return false;
    }

    const std::string createRules = R"(
        CREATE TABLE IF NOT EXISTS rules (
            id TEXT PRIMARY KEY,
            type TEXT NOT NULL,
            target TEXT NOT NULL,
            condition TEXT NOT NULL,
            priority INTEGER NOT NULL,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        );
    )";

    const std::string createAudit = R"(
        CREATE TABLE IF NOT EXISTS audit (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            command TEXT NOT NULL,
            target TEXT,
            success INTEGER NOT NULL,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
        );
    )";

    return execute(createRules) && execute(createAudit);
}

sqlite3* Database::connection() const noexcept
{
    return m_db;
}

} // namespace Alfa
