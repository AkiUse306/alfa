using Alfa.Shared.Models;
using Microsoft.Data.Sqlite;

namespace Alfa.Server.Services;

public sealed class ControlPlaneStore
{
    private readonly string _databasePath = "controlplane.db";

    public ControlPlaneStore()
    {
        InitializeDatabase();
        SeedDefaults();
    }

    public IReadOnlyList<DeviceMetadata> GetDevices() => QueryDevices();

    public DeviceMetadata AddDevice(DeviceMetadata metadata)
    {
        using var connection = CreateConnection();
        connection.Open();

        var command = connection.CreateCommand();
        command.CommandText = @"INSERT OR REPLACE INTO devices (device_id, hostname, os_version, pairing_code)
                                VALUES ($deviceId, $hostname, $osVersion, $pairingCode);";
        command.Parameters.AddWithValue("$deviceId", metadata.DeviceId);
        command.Parameters.AddWithValue("$hostname", metadata.Hostname);
        command.Parameters.AddWithValue("$osVersion", metadata.OsVersion);
        command.Parameters.AddWithValue("$pairingCode", metadata.PairingCode);
        command.ExecuteNonQuery();

        return metadata;
    }

    public IReadOnlyList<PolicyRule> GetRules() => QueryRules();

    public PolicyRule AddRule(PolicyRule rule)
    {
        using var connection = CreateConnection();
        connection.Open();

        var command = connection.CreateCommand();
        command.CommandText = @"INSERT OR REPLACE INTO rules (id, type, target, condition, priority)
                                VALUES ($id, $type, $target, $condition, $priority);";
        command.Parameters.AddWithValue("$id", rule.RuleId);
        command.Parameters.AddWithValue("$type", rule.Type.ToString());
        command.Parameters.AddWithValue("$target", rule.Target);
        command.Parameters.AddWithValue("$condition", rule.Condition);
        command.Parameters.AddWithValue("$priority", rule.Priority);
        command.ExecuteNonQuery();

        AddTelemetry("ADD_RULE", rule.Target, true, DateTime.UtcNow);
        return rule;
    }

    public IReadOnlyList<AuditEntry> GetTelemetry() => QueryTelemetry();

    public AuditEntry AddTelemetry(string command, string target, bool success, DateTime? timestamp = null)
    {
        using var connection = CreateConnection();
        connection.Open();

        var commandText = connection.CreateCommand();
        commandText.CommandText = @"INSERT INTO telemetry (command, target, success, timestamp)
                                    VALUES ($command, $target, $success, $timestamp);";
        commandText.Parameters.AddWithValue("$command", command);
        commandText.Parameters.AddWithValue("$target", target);
        commandText.Parameters.AddWithValue("$success", success ? 1 : 0);
        commandText.Parameters.AddWithValue("$timestamp", (timestamp ?? DateTime.UtcNow).ToUniversalTime());
        commandText.ExecuteNonQuery();

        return QueryTelemetry().Last();
    }

    private SqliteConnection CreateConnection() => new SqliteConnection($"Data Source={_databasePath}");

    private void InitializeDatabase()
    {
        using var connection = CreateConnection();
        connection.Open();

        var createDevices = connection.CreateCommand();
        createDevices.CommandText = @"CREATE TABLE IF NOT EXISTS devices (
                                        device_id TEXT PRIMARY KEY,
                                        hostname TEXT NOT NULL,
                                        os_version TEXT NOT NULL,
                                        pairing_code TEXT NOT NULL
                                     );";
        createDevices.ExecuteNonQuery();

        var createRules = connection.CreateCommand();
        createRules.CommandText = @"CREATE TABLE IF NOT EXISTS rules (
                                        id TEXT PRIMARY KEY,
                                        type TEXT NOT NULL,
                                        target TEXT NOT NULL,
                                        condition TEXT NOT NULL,
                                        priority INTEGER NOT NULL
                                     );";
        createRules.ExecuteNonQuery();

        var createTelemetry = connection.CreateCommand();
        createTelemetry.CommandText = @"CREATE TABLE IF NOT EXISTS telemetry (
                                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                                        command TEXT NOT NULL,
                                        target TEXT,
                                        success INTEGER NOT NULL,
                                        timestamp TEXT NOT NULL
                                     );";
        createTelemetry.ExecuteNonQuery();
    }

    private void SeedDefaults()
    {
        if (!QueryDevices().Any())
        {
            AddDevice(new DeviceMetadata("device-001", "alfa-workstation", "Windows 11", "X7F2-K9Q1-LA8Z-3MNP"));
        }

        if (!QueryRules().Any())
        {
            AddRule(new PolicyRule("rule-1", RuleType.AlwaysBlock, "discord.exe", "after:22:00", 100));
        }

        if (!QueryTelemetry().Any())
        {
            AddTelemetry("STATUS", string.Empty, true, DateTime.UtcNow.AddMinutes(-12));
            AddTelemetry("LOCK", "discord.exe", true, DateTime.UtcNow.AddMinutes(-8));
            AddTelemetry("UNLOCK", "discord.exe", true, DateTime.UtcNow.AddMinutes(-5));
        }
    }

    private List<DeviceMetadata> QueryDevices()
    {
        using var connection = CreateConnection();
        connection.Open();

        var command = connection.CreateCommand();
        command.CommandText = @"SELECT device_id, hostname, os_version, pairing_code FROM devices;";

        var devices = new List<DeviceMetadata>();
        using var reader = command.ExecuteReader();
        while (reader.Read())
        {
            devices.Add(new DeviceMetadata(
                reader.GetString(0),
                reader.GetString(1),
                reader.GetString(2),
                reader.GetString(3)));
        }

        return devices;
    }

    private List<PolicyRule> QueryRules()
    {
        using var connection = CreateConnection();
        connection.Open();

        var command = connection.CreateCommand();
        command.CommandText = @"SELECT id, type, target, condition, priority FROM rules ORDER BY priority DESC;";

        var rules = new List<PolicyRule>();
        using var reader = command.ExecuteReader();
        while (reader.Read())
        {
            Enum.TryParse<RuleType>(reader.GetString(1), out var type);
            rules.Add(new PolicyRule(
                reader.GetString(0),
                type,
                reader.GetString(2),
                reader.GetString(3),
                reader.GetInt32(4)));
        }

        return rules;
    }

    private List<AuditEntry> QueryTelemetry()
    {
        using var connection = CreateConnection();
        connection.Open();

        var command = connection.CreateCommand();
        command.CommandText = @"SELECT id, command, target, success, timestamp FROM telemetry ORDER BY id DESC;";

        var telemetry = new List<AuditEntry>();
        using var reader = command.ExecuteReader();
        while (reader.Read())
        {
            telemetry.Add(new AuditEntry(
                reader.GetInt32(0),
                reader.GetString(1),
                reader.IsDBNull(2) ? string.Empty : reader.GetString(2),
                reader.GetInt32(3) == 1,
                DateTime.Parse(reader.GetString(4)).ToUniversalTime()));
        }

        return telemetry;
    }
}
