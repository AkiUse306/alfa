#pragma once

#include <string>

namespace Alfa::Protocol {

struct CommandMessage
{
    std::string command;
    std::string payload;
    std::string signature;
};

} // namespace Alfa::Protocol
