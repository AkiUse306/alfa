#pragma once

#include <atomic>
#include <chrono>
#include <memory>
#include <string>

namespace Alfa {

class PolicyStore;
class CommandServer;

class ProtectEngine
{
public:
    ProtectEngine();
    ~ProtectEngine();

    void initialize();
    void poll();
    bool isRunning() const noexcept;
    void stop() noexcept;

private:
    std::string getSecret() const;

    std::atomic<bool> m_running;
    std::chrono::steady_clock::time_point m_lastCheck;
    std::unique_ptr<PolicyStore> m_policyStore;
    std::unique_ptr<CommandServer> m_commandServer;
};

} // namespace Alfa
