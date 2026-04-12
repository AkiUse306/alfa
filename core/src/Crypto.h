#pragma once

#include <string>

namespace Alfa::Crypto {

std::string hmacSha256(const std::string& key, const std::string& message);
std::string toHex(const std::string& bytes);

} // namespace Alfa::Crypto
