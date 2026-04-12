#include "PolicyStore.h"
#include "Database.h"
#include <iostream>
#include <sqlite3.h>
#include <sstream>

namespace Alfa {

namespace {

std::string escapeJson(const std::string& value)
{
    std::string escaped;
    escaped.reserve(value.size() * 2);

    for (char c : value) {
        switch (c) {
            case '\\': escaped += "\\\\"; break;
            case '"': escaped += "\\\""; break;
            case '\b': escaped += "\\b"; break;
            case '\f': escaped += "\\f"; break;
            case '\n': escaped += "\\n"; break;
            case '\r': escaped += "\\r"; break;
            case '\t': escaped += "\\t"; break;
            default: escaped.push_back(c);
        }
    }

    return escaped;
}

} // namespace

struct PolicyStore::Impl
{
    Database database;

    explicit Impl(std::string path)
        : database(std::move(path))
    {
    }
};

PolicyStore::PolicyStore(std::string databasePath)
    : m_impl(new Impl(std::move(databasePath)))
{
}

PolicyStore::~PolicyStore()
{
    delete m_impl;
}

bool PolicyStore::initialize()
{
    if (!m_impl->database.initialize()) {
        return false;
    }

    // Ensure a default rule set exists for demonstration.
    addRule("rule-1", "AlwaysBlock", "discord.exe", "after:22:00", 100);
    return true;
}

bool PolicyStore::addRule(std::string id, std::string type, std::string target, std::string condition, int priority)
{
    const std::string sql = "INSERT OR REPLACE INTO rules (id, type, target, condition, priority) VALUES ('" +
        id + "', '" + type + "', '" + target + "', '" + condition + "', " + std::to_string(priority) + ");";
    return m_impl->database.execute(sql);
}

std::vector<PolicyRule> PolicyStore::listRules() const
{
    std::vector<PolicyRule> rules;
    sqlite3* db = m_impl->database.connection();
    if (!db) {
        return rules;
    }

    const char* sql = "SELECT id, type, target, condition, priority FROM rules ORDER BY priority DESC;";
    sqlite3_stmt* stmt = nullptr;
    if (sqlite3_prepare_v2(db, sql, -1, &stmt, nullptr) != SQLITE_OK) {
        return rules;
    }

    while (sqlite3_step(stmt) == SQLITE_ROW) {
        rules.push_back(PolicyRule{
            reinterpret_cast<const char*>(sqlite3_column_text(stmt, 0)),
            reinterpret_cast<const char*>(sqlite3_column_text(stmt, 1)),
            reinterpret_cast<const char*>(sqlite3_column_text(stmt, 2)),
            reinterpret_cast<const char*>(sqlite3_column_text(stmt, 3)),
            sqlite3_column_int(stmt, 4)
        });
    }
    sqlite3_finalize(stmt);
    return rules;
}

std::string PolicyStore::listRulesJson() const
{
    const auto rules = listRules();
    std::ostringstream builder;
    builder << "[";
    bool first = true;

    for (const auto& rule : rules) {
        if (!first) {
            builder << ",";
        }
        first = false;
        builder << "{"
                << "\"RuleId\":\"" << escapeJson(rule.id) << "\",";
        builder << "\"Type\":\"" << escapeJson(rule.type) << "\",";
        builder << "\"Target\":\"" << escapeJson(rule.target) << "\",";
        builder << "\"Condition\":\"" << escapeJson(rule.condition) << "\",";
        builder << "\"Priority\":" << rule.priority;
        builder << "}";
    }

    builder << "]";
    return builder.str();
}

bool PolicyStore::recordAudit(const std::string& command, const std::string& target, bool success) const
{
    const std::string sql = "INSERT INTO audit (command, target, success) VALUES ('" +
        command + "', '" + target + "', " + (success ? "1" : "0") + ");";
    return m_impl->database.execute(sql);
}

std::string PolicyStore::generateStatus() const
{
    const auto rules = listRules();
    const auto ruleCount = rules.size();
    return "Core active, " + std::to_string(ruleCount) + " rules loaded.";
}

} // namespace Alfa
