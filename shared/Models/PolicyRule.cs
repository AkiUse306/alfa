namespace Alfa.Shared.Models;

public enum RuleType
{
    AlwaysAllow,
    AlwaysBlock,
    TimeRestriction,
    PasswordLock,
    UsageQuota
}

public record PolicyRule
(
    string RuleId,
    RuleType Type,
    string Target,
    string Condition,
    int Priority
);
