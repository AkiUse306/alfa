namespace Alfa.Shared.Protocol;

public sealed record CommandMessage(string Command, string Target, string Payload, string Signature);
