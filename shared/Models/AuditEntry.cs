namespace Alfa.Shared.Models;

public record AuditEntry
(
    int Id,
    string Command,
    string Target,
    bool Success,
    DateTime Timestamp
);
