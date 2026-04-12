using System.Collections.Generic;
using System.Text.Json;
using System.Windows;
using Alfa.Desktop.Services;
using Alfa.Shared.Models;

namespace Alfa.Desktop;

public partial class PolicyManagerWindow : Window
{
    private readonly CoreClient _coreClient = new();
    private readonly List<PolicyRule> _rules = new();

    public PolicyManagerWindow()
    {
        InitializeComponent();
    }

    private async void Window_Loaded(object sender, RoutedEventArgs e)
    {
        await LoadRulesAsync();
    }

    private async Task LoadRulesAsync()
    {
        try
        {
            var rules = await _coreClient.ListRulesAsync();
            _rules.Clear();
            _rules.AddRange(rules);
            RulesList.ItemsSource = null;
            RulesList.ItemsSource = _rules;
            StatusText.Text = $"Loaded {_rules.Count} policy rule(s).";
        }
        catch (Exception ex)
        {
            StatusText.Text = $"Unable to load rules: {ex.Message}";
        }
    }

    private async void RefreshButton_Click(object sender, RoutedEventArgs e)
    {
        await LoadRulesAsync();
    }

    private async void AddRuleButton_Click(object sender, RoutedEventArgs e)
    {
        var ruleId = RuleIdText.Text.Trim();
        var target = TargetText.Text.Trim();
        var condition = ConditionText.Text.Trim();
        var priorityText = PriorityText.Text.Trim();

        if (string.IsNullOrWhiteSpace(ruleId) || string.IsNullOrWhiteSpace(target) || string.IsNullOrWhiteSpace(condition))
        {
            StatusText.Text = "Rule ID, target, and condition are required.";
            return;
        }

        if (!int.TryParse(priorityText, out var priority))
        {
            StatusText.Text = "Priority must be a number.";
            return;
        }

        try
        {
            var response = await _coreClient.AddRuleAsync(ruleId, "AlwaysBlock", target, condition, priority);
            StatusText.Text = response;
            await LoadRulesAsync();
        }
        catch (Exception ex)
        {
            StatusText.Text = $"Failed to add rule: {ex.Message}";
        }
    }
}
