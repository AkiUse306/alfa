using System.Security.Cryptography;
using System.Text;

namespace Alfa.Shared.Protocol;

public static class SignatureHelper
{
    public static string ComputeSignature(string secret, string message)
    {
        using var hmac = new HMACSHA256(Encoding.UTF8.GetBytes(secret));
        var bytes = hmac.ComputeHash(Encoding.UTF8.GetBytes(message));
        return Convert.ToHexString(bytes).ToLowerInvariant();
    }
}
