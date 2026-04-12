#pragma once

#include <string>
#include <vector>

namespace Alfa {

struct PolicyRule
{
    std::string id;
    std::string type;
    std::string target;
    std::string condition;
    int priority;
};

class PolicyStore
{
public:
    explicit PolicyStore(std::string databasePath);
    ~PolicyStore();

    bool initialize();
    bool addRule(std::string id, std::string type, std::string target, std::string condition, int priority);
    std::vector<PolicyRule> listRules() const;
    std::string listRulesJson() const;
    bool recordAudit(const std::string& command, const std::string& target, bool success) const;
    std::string generateStatus() const;

private:
    class Impl;
    Impl* m_impl;
};

} // namespace Alfa
