#pragma once

#include <string>
#include <thread>

namespace Alfa {

class PolicyStore;

class CommandServer
{
public:
    CommandServer(PolicyStore& policyStore, std::string secret, unsigned short port = 4712);
    ~CommandServer();

    bool start();
    void stop() noexcept;

private:
    void run();
    void handleClient(int socket);
    std::string processCommand(const std::string& payload);
    bool validateSignature(const std::string& command, const std::string& target, const std::string& body, const std::string& signature) const;

private:
    PolicyStore& m_policyStore;
    std::string m_secret;
    unsigned short m_port;
    bool m_running;
    int m_socket;
    std::thread m_thread;
};

} // namespace Alfa
