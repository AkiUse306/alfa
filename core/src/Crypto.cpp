#include "Crypto.h"
#include "Sha256.h"
#include <string>
#include <vector>

namespace Alfa::Crypto {

std::string toHex(const std::string& bytes)
{
    static const char* hexChars = "0123456789abcdef";
    std::string hex;
    hex.reserve(bytes.size() * 2);

    for (unsigned char c : bytes) {
        hex.push_back(hexChars[(c >> 4) & 0x0F]);
        hex.push_back(hexChars[c & 0x0F]);
    }

    return hex;
}

std::string hmacSha256(const std::string& key, const std::string& message)
{
    const size_t blockSize = 64;
    std::string keyBlock = key;

    if (keyBlock.size() > blockSize) {
        keyBlock = sha256(keyBlock);
    }
    if (keyBlock.size() < blockSize) {
        keyBlock.append(blockSize - keyBlock.size(), '\0');
    }

    std::string oKey(blockSize, '\0');
    std::string iKey(blockSize, '\0');
    for (size_t i = 0; i < blockSize; ++i) {
        oKey[i] = keyBlock[i] ^ 0x5c;
        iKey[i] = keyBlock[i] ^ 0x36;
    }

    std::string inner = iKey + message;
    std::string innerHash = sha256(inner);
    std::string outer = oKey + innerHash;
    return sha256(outer);
}

} // namespace Alfa::Crypto
