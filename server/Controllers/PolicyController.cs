using Alfa.Server.Filters;
using Alfa.Server.Services;
using Alfa.Shared.Models;
using Microsoft.AspNetCore.Mvc;

namespace Alfa.Server.Controllers;

[ApiController]
[Route("api/rules")]
public class PolicyController : ControllerBase
{
    private readonly ControlPlaneStore _store;

    public PolicyController(ControlPlaneStore store)
    {
        _store = store;
    }

    [HttpGet]
    public IActionResult GetRules()
    {
        return Ok(_store.GetRules());
    }

    [HttpPost]
    [RequireApiKey]
    public IActionResult AddRule([FromBody] PolicyRule rule)
    {
        var added = _store.AddRule(rule);
        return Created($"/api/rules/{added.RuleId}", added);
    }
}
