using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Alfa.Cli;
using Spectre.Console;

static string GeneratePairingCode()
{
    const string charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    Span<char> buffer = stackalloc char[19];
    using var rng = RandomNumberGenerator.Create();
    Span<byte> bytes = stackalloc byte[12];
    rng.GetBytes(bytes);

    int pos = 0;
    for (int group = 0; group < 4; group++)
    {
        for (int i = 0; i < 4; i++)
        {
            buffer[pos++] = charset[bytes[group * 3 + i % 3] % charset.Length];
        }
        if (group < 3) buffer[pos++] = '-';
    }

    return new string(buffer);
}

static void ShowHeader()
{
    AnsiConsole.Write(new FigletText("ALFA").Centered().Color(Color.MediumPurple));
    AnsiConsole.MarkupLine("[grey]Enterprise protection with secure local core integration[/]\n");
}

static void ShowUsage()
{
    AnsiConsole.MarkupLine("[bold yellow]Usage:[/] [green]alfa --status[/], [green]alfa --code[/], [green]alfa --list-rules[/], [green]alfa --add-rule <id> <target> <condition> <priority>[/], [green]alfa --lock <app>[/], [green]alfa --unlock <app>[/], [green]alfa --sync[/]\n");
}

static void RenderTable(string json)
{
    try
    {
        var table = new Table().Border(TableBorder.Rounded).AddColumn("Rule ID").AddColumn("Target").AddColumn("Condition").AddColumn("Priority").AddColumn("Type");
        using var document = JsonDocument.Parse(json);
        foreach (var element in document.RootElement.EnumerateArray())
        {
            table.AddRow(
                element.GetProperty("RuleId").GetString() ?? string.Empty,
                element.GetProperty("Target").GetString() ?? string.Empty,
                element.GetProperty("Condition").GetString() ?? string.Empty,
                element.GetProperty("Priority").GetInt32().ToString(),
                element.GetProperty("Type").GetString() ?? string.Empty);
        }
        AnsiConsole.Write(table);
    }
    if (args.Contains("--self-update"))
{
    Console.WriteLine("Checking for updates...");
    await Updater.CheckAndInstallAsync();
    return;
}
    catch
    {
        AnsiConsole.MarkupLine("[red]Unable to render rules list.[/]");
        AnsiConsole.WriteLine(json);
    }
}

if (args.Length == 0)
{
    ShowHeader();
    ShowUsage();
    return;
}

ShowHeader();

var client = new CoreClient();
var command = args[0].ToLowerInvariant();
var target = args.Length > 1 ? args[1] : string.Empty;

async Task<int> ExecuteAsync()
{
    try
    {
        switch (command)
        {
            case "--status":
            {
                var response = await client.SendAsync("STATUS");
                AnsiConsole.MarkupLine($"[green]{response}[/]");
                break;
            }
            case "--code":
            {
                var code = GeneratePairingCode();
                AnsiConsole.MarkupLine($"[bold aqua]Pairing code:[/] [white]{code}[/]");
                break;
            }
            case "--list-rules":
            {
                var response = await client.SendAsync("LIST_RULES");
                if (response.StartsWith("OK|"))
                {
                    RenderTable(response[3..]);
                }
                else
                {
                    AnsiConsole.MarkupLine($"[red]{response}[/]");
                }
                break;
            }
            case "--add-rule":
            {
                if (args.Length < 5)
                {
                    AnsiConsole.MarkupLine("[red]Usage: alfa --add-rule <id> <target> <condition> <priority>[/]");
                    return 1;
                }

                var ruleId = args[1];
                var ruleTarget = args[2];
                var condition = args[3];
                if (!int.TryParse(args[4], out var priority))
                {
                    AnsiConsole.MarkupLine("[red]Priority must be a numeric value.[/]");
                    return 1;
                }

                var response = await client.SendAsync("ADD_RULE", string.Empty, $"{ruleId};AlwaysBlock;{ruleTarget};{condition};{priority}");
                AnsiConsole.MarkupLine(response.StartsWith("OK|") ? $"[green]{response[3..]}[/]" : $"[red]{response}[/]");
                break;
            }
            case "--lock":
            {
                if (string.IsNullOrWhiteSpace(target))
                {
                    AnsiConsole.MarkupLine("[red]Usage: alfa --lock <app>[/]");
                    return 1;
                }

                var response = await client.SendAsync("LOCK", target, string.Empty);
                AnsiConsole.MarkupLine(response.StartsWith("OK|") ? $"[green]{response[3..]}[/]" : $"[red]{response}[/]");
                break;
            }
            case "--unlock":
            {
                if (string.IsNullOrWhiteSpace(target))
                {
                    AnsiConsole.MarkupLine("[red]Usage: alfa --unlock <app>[/]");
                    return 1;
                }

                var response = await client.SendAsync("UNLOCK", target, string.Empty);
                AnsiConsole.MarkupLine(response.StartsWith("OK|") ? $"[green]{response[3..]}[/]" : $"[red]{response}[/]");
                break;
            }
            case "--sync":
            {
                var response = await client.SendAsync("SYNC", string.Empty, string.Empty);
                AnsiConsole.MarkupLine(response.StartsWith("OK|") ? $"[green]{response[3..]}[/]" : $"[red]{response}[/]");
                break;
            }
            default:
                ShowUsage();
                return 1;
        }

        return 0;
    }
    catch (System.Exception ex)
    {
        AnsiConsole.MarkupLine($"[red]Error communicating with Alfa core: {ex.Message}[/]");
        return 1;
    }
}

var result = await ExecuteAsync();
Environment.Exit(result);
