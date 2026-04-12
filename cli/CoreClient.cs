using System.Net.Sockets;
using System.Text;
using Alfa.Shared.Protocol;

namespace Alfa.Cli;

public sealed class CoreClient
{
    private const string DefaultSecret = "alfa-super-secret";
    private const string Host = "127.0.0.1";
    private const int Port = 4712;

    public async Task<string> SendAsync(string command, string target = "", string payload = "")
    {
        using var client = new TcpClient();
        await client.ConnectAsync(Host, Port);
        using var stream = client.GetStream();

        var message = BuildMessage(command, target, payload);
        var bytes = Encoding.UTF8.GetBytes(message + "\n");
        await stream.WriteAsync(bytes);

        using var reader = new StreamReader(stream, Encoding.UTF8);
        return await reader.ReadLineAsync() ?? "No response from core";
    }

    private static string BuildMessage(string command, string target, string payload)
    {
        var header = $"{command}|{target}|{payload}";
        var signature = SignatureHelper.ComputeSignature(DefaultSecret, header);
        return $"{header}|{signature}";
    }
}
