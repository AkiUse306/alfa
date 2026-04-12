using System.Text.RegularExpressions;
using System.Windows;
using Alfa.Desktop.Services;

namespace Alfa.Desktop;

public partial class MainWindow : Window
{
    private readonly CoreClient _coreClient = new();

    public MainWindow()
    {
        InitializeComponent();
    }

    private async void Window_Loaded(object sender, RoutedEventArgs e)
    {
        await RefreshStatusAsync();
    }

    private static int ParseRuleCount(string status)
    {
        var match = Regex.Match(status, @"(?<=Core active, )\d+(?= rules loaded)");
        return match.Success ? int.Parse(match.Value) : 0;
    }

    private async Task RefreshStatusAsync()
    {
        try
        {
            var response = await _coreClient.SendCommandAsync("STATUS");
            StatusText.Text = response;
            RulesCount.Text = ParseRuleCount(response).ToString();
            ViolationCount.Text = "0";
        }
        catch (Exception ex)
        {
            StatusText.Text = $"Core unavailable: {ex.Message}";
            RulesCount.Text = "0";
            ViolationCount.Text = "0";
        }
    }

    private async void RefreshButton_Click(object sender, RoutedEventArgs e)
    {
        await RefreshStatusAsync();
    }

    private async void SyncButton_Click(object sender, RoutedEventArgs e)
    {
        try
        {
            var response = await _coreClient.SendCommandAsync("SYNC");
            StatusText.Text = response;
        }
        catch (Exception ex)
        {
            StatusText.Text = $"Sync failed: {ex.Message}";
        }
    }

    private void PolicyManagerButton_Click(object sender, RoutedEventArgs e)
    {
        var window = new PolicyManagerWindow
        {
            Owner = this
        };
        window.Show();
    }

    private async void LockButton_Click(object sender, RoutedEventArgs e)
    {
        try
        {
            var response = await _coreClient.SendCommandAsync("LOCK", "discord.exe");
            StatusText.Text = response;
        }
        catch (Exception ex)
        {
            StatusText.Text = $"Lock failed: {ex.Message}";
        }
    }

    private async void UnlockButton_Click(object sender, RoutedEventArgs e)
    {
        try
        {
            var response = await _coreClient.SendCommandAsync("UNLOCK", "discord.exe");
            StatusText.Text = response;
        }
        catch (Exception ex)
        {
            StatusText.Text = $"Unlock failed: {ex.Message}";
        }
    }
}
