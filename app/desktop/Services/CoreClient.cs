using System.Net.Sockets;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Alfa.Shared.Models;

namespace Alfa.Desktop.Services;

public sealed class CoreClient
{
    private const string Host = "127.0.0.1";
    private const int Port = 4712;
    private const string Secret = "alfa-super-secret";

    public async Task<string> SendCommandAsync(string command, string target = "", string body = "")
    {
        using var tcpClient = new TcpClient();
        await tcpClient.ConnectAsync(Host, Port);
        using var stream = tcpClient.GetStream();
        using var writer = new StreamWriter(stream, Encoding.UTF8, leaveOpen: true) { AutoFlush = true };
        using var reader = new StreamReader(stream, Encoding.UTF8, detectEncodingFromByteOrderMarks: false);

        var message = BuildMessage(command, target, body);
        await writer.WriteLineAsync(message);

        var response = await reader.ReadLineAsync();
        return response ?? "No response from core.";
    }

    public async Task<List<PolicyRule>> ListRulesAsync()
    {
        var response = await SendCommandAsync("LIST_RULES");
        if (!response.StartsWith("OK|", StringComparison.OrdinalIgnoreCase))
        {
            return new List<PolicyRule>();
        }

        var payload = response[3..];
        try
        {
            return JsonSerializer.Deserialize<List<PolicyRule>>(payload) ?? new List<PolicyRule>();
        }
        catch
        {
            return new List<PolicyRule>();
        }
    }

    public Task<string> AddRuleAsync(string ruleId, string type, string target, string condition, int priority)
    {
        var body = $"{ruleId};{type};{target};{condition};{priority}";
        return SendCommandAsync("ADD_RULE", string.Empty, body);
    }

    private static string BuildMessage(string command, string target, string payload)
    {
        var header = $"{command}|{target}|{payload}";
        var signature = ComputeSignature(header);
        return $"{header}|{signature}";
    }

    private static string ComputeSignature(string message)
    {
        using var hmac = new HMACSHA256(Encoding.UTF8.GetBytes(Secret));
        var hash = hmac.ComputeHash(Encoding.UTF8.GetBytes(message));
        return Convert.ToHexString(hash).ToLowerInvariant();
    }
}
