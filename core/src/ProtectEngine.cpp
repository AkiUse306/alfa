#include "ProtectEngine.h"
#include "CommandServer.h"
#include "PolicyStore.h"
#include <iostream>

namespace Alfa {

ProtectEngine::ProtectEngine()
    : m_running(true)
    , m_lastCheck(std::chrono::steady_clock::now())
    , m_policyStore(std::make_unique<PolicyStore>("core_state.db"))
    , m_commandServer(std::make_unique<CommandServer>(*m_policyStore, getSecret(), 4712))
{
}

std::string ProtectEngine::getSecret() const
{
    const char* envValue = std::getenv("ALFA_CORE_SECRET");
    return envValue ? std::string(envValue) : "alfa-super-secret";
}

ProtectEngine::~ProtectEngine() = default;

void ProtectEngine::initialize()
{
    std::cout << "[core] Initializing enforcement engine..." << std::endl;
    if (!m_policyStore->initialize()) {
        std::cerr << "[core] Failed to initialize the policy store." << std::endl;
    }
    if (!m_commandServer->start()) {
        std::cerr << "[core] Failed to start the control channel." << std::endl;
    }
    m_lastCheck = std::chrono::steady_clock::now();
}

void ProtectEngine::poll()
{
    auto now = std::chrono::steady_clock::now();
    if (now - m_lastCheck > std::chrono::seconds(5)) {
        std::cout << "[core] Heartbeat: monitoring process and file events..." << std::endl;
        std::cout << "[core] " << m_policyStore->generateStatus() << std::endl;
        m_lastCheck = now;
    }
}

bool ProtectEngine::isRunning() const noexcept
{
    return m_running.load();
}

void ProtectEngine::stop() noexcept
{
    m_running.store(false);
    if (m_commandServer) {
        m_commandServer->stop();
    }
}

} // namespace Alfa
