namespace Alfa.Shared.Models;

public record DeviceMetadata
(
    string DeviceId,
    string Hostname,
    string OsVersion,
    string PairingCode
);
