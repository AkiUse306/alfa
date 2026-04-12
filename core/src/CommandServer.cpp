#include "CommandServer.h"
#include "Crypto.h"
#include "PolicyStore.h"
#include <iostream>
#include <sstream>
#include <vector>

#ifdef _WIN32
#include <winsock2.h>
#include <ws2tcpip.h>
#pragma comment(lib, "ws2_32")
using socket_t = SOCKET;
using socklen_type = int;
#else
#include <arpa/inet.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <unistd.h>
using socket_t = int;
using socklen_type = socklen_t;
#endif

namespace Alfa {

namespace {

void closeSocket(socket_t socket)
{
#ifdef _WIN32
    closesocket(socket);
#else
    close(socket);
#endif
}

std::vector<std::string> splitLine(const std::string& value, char separator)
{
    std::vector<std::string> tokens;
    std::string temp;
    std::istringstream stream(value);
    while (std::getline(stream, temp, separator)) {
        tokens.push_back(temp);
    }
    return tokens;
}

} // namespace

CommandServer::CommandServer(PolicyStore& policyStore, std::string secret, unsigned short port)
    : m_policyStore(policyStore)
    , m_secret(std::move(secret))
    , m_port(port)
    , m_running(false)
    , m_socket(-1)
{
}

CommandServer::~CommandServer()
{
    stop();
}

bool CommandServer::start()
{
#ifdef _WIN32
    WSADATA wsaData;
    if (WSAStartup(MAKEWORD(2, 2), &wsaData) != 0) {
        std::cerr << "[core] Failed to initialize WinSock." << std::endl;
        return false;
    }
#endif

    m_socket = static_cast<int>(socket(AF_INET, SOCK_STREAM, IPPROTO_TCP));
    if (m_socket < 0) {
        std::cerr << "[core] Unable to create socket." << std::endl;
        return false;
    }

    sockaddr_in serverAddress;
    serverAddress.sin_family = AF_INET;
    serverAddress.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    serverAddress.sin_port = htons(m_port);

    int opt = 1;
    setsockopt(m_socket, SOL_SOCKET, SO_REUSEADDR, reinterpret_cast<char*>(&opt), sizeof(opt));

    if (bind(m_socket, reinterpret_cast<sockaddr*>(&serverAddress), sizeof(serverAddress)) < 0) {
        std::cerr << "[core] Failed to bind control socket." << std::endl;
        closeSocket(m_socket);
        return false;
    }

    if (listen(m_socket, 4) < 0) {
        std::cerr << "[core] Failed to listen on control socket." << std::endl;
        closeSocket(m_socket);
        return false;
    }

    m_running = true;
    m_thread = std::thread(&CommandServer::run, this);
    return true;
}

void CommandServer::stop() noexcept
{
    if (!m_running) {
        return;
    }

    m_running = false;
    closeSocket(m_socket);
    if (m_thread.joinable()) {
        m_thread.join();
    }
#ifdef _WIN32
    WSACleanup();
#endif
}

void CommandServer::run()
{
    std::cout << "[core] Control server listening on 127.0.0.1:" << m_port << std::endl;

    while (m_running) {
        sockaddr_in clientAddress;
        socklen_type clientLength = sizeof(clientAddress);
        const int clientSocket = accept(m_socket, reinterpret_cast<sockaddr*>(&clientAddress), &clientLength);
        if (clientSocket < 0) {
            continue;
        }

        handleClient(clientSocket);
    }
}

void CommandServer::handleClient(int clientSocket)
{
    constexpr size_t bufferSize = 4096;
    char buffer[bufferSize];
    std::string message;

    while (true) {
        const int received = static_cast<int>(recv(clientSocket, buffer, bufferSize, 0));
        if (received <= 0) {
            break;
        }

        message.append(buffer, received);
        if (message.find('\n') != std::string::npos) {
            break;
        }
    }

    if (!message.empty()) {
        const auto trimmed = message.substr(0, message.find('\n'));
        const std::string response = processCommand(trimmed);
        send(clientSocket, response.c_str(), static_cast<int>(response.size()), 0);
    }

    closeSocket(clientSocket);
}

std::string CommandServer::processCommand(const std::string& payload)
{
    const auto parts = splitLine(payload, '|');
    if (parts.size() != 4) {
        return "ERR|Malformed command\n";
    }

    const auto& command = parts[0];
    const auto& target = parts[1];
    const auto& body = parts[2];
    const auto& signature = parts[3];
    if (!validateSignature(command, target, body, signature)) {
        m_policyStore.recordAudit(command, target, false);
        return "ERR|Invalid signature\n";
    }

    std::string result;
    if (command == "STATUS") {
        result = m_policyStore.generateStatus();
        m_policyStore.recordAudit(command, target, true);
    } else if (command == "LOCK") {
        m_policyStore.recordAudit(command, target, true);
        result = "Locked " + target;
    } else if (command == "UNLOCK") {
        m_policyStore.recordAudit(command, target, true);
        result = "Unlocked " + target;
    } else if (command == "SYNC") {
        m_policyStore.recordAudit(command, target, true);
        result = "Policies synchronized.";
    } else if (command == "LIST_RULES") {
        result = m_policyStore.listRulesJson();
        m_policyStore.recordAudit(command, target, true);
    } else if (command == "ADD_RULE") {
        const auto ruleParts = splitLine(body, ';');
        if (ruleParts.size() != 5) {
            m_policyStore.recordAudit(command, target, false);
            return "ERR|ADD_RULE requires ruleId;type;target;condition;priority\n";
        }

        int priority = 0;
        try {
            priority = std::stoi(ruleParts[4]);
        } catch (const std::exception&) {
            m_policyStore.recordAudit(command, target, false);
            return "ERR|Invalid priority value\n";
        }

        if (!m_policyStore.addRule(ruleParts[0], ruleParts[1], ruleParts[2], ruleParts[3], priority)) {
            m_policyStore.recordAudit(command, target, false);
            return "ERR|Failed to add rule\n";
        }

        m_policyStore.recordAudit(command, ruleParts[2], true);
        result = "Rule added: " + ruleParts[0];
    } else {
        m_policyStore.recordAudit(command, target, false);
        result = "ERR|Unsupported command";
    }

    return "OK|" + result + "\n";
}

bool CommandServer::validateSignature(const std::string& command, const std::string& target, const std::string& body, const std::string& signature) const
{
    const std::string message = command + "|" + target + "|" + body;
    const std::string expected = Crypto::toHex(Crypto::hmacSha256(m_secret, message));
    return expected == signature;
}

} // namespace Alfa
