using Alfa.Server.Filters;
using Alfa.Server.Services;
using Alfa.Shared.Models;
using Microsoft.AspNetCore.Mvc;

namespace Alfa.Server.Controllers;

[ApiController]
[Route("api/telemetry")]
public class TelemetryController : ControllerBase
{
    private readonly ControlPlaneStore _store;

    public TelemetryController(ControlPlaneStore store)
    {
        _store = store;
    }

    [HttpGet]
    public IActionResult GetTelemetry()
    {
        return Ok(_store.GetTelemetry());
    }

    [HttpPost]
    [RequireApiKey]
    public IActionResult RecordTelemetry([FromBody] AuditEntry entry)
    {
        var stored = _store.AddTelemetry(entry.Command, entry.Target, entry.Success, entry.Timestamp);
        return Created($"/api/telemetry/{stored.Id}", stored);
    }
}
