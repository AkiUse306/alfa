using Alfa.Server.Filters;
using Alfa.Server.Services;
using Alfa.Shared.Models;
using Microsoft.AspNetCore.Mvc;

namespace Alfa.Server.Controllers;

[ApiController]
[Route("api/devices")]
public class DeviceController : ControllerBase
{
    private readonly ControlPlaneStore _store;

    public DeviceController(ControlPlaneStore store)
    {
        _store = store;
    }

    [HttpGet]
    public IActionResult GetDevices()
    {
        return Ok(_store.GetDevices());
    }

    [HttpPost("pair")]
    [RequireApiKey]
    public IActionResult PairDevice([FromBody] DeviceMetadata metadata)
    {
        var device = _store.AddDevice(metadata);
        return Created($"/api/devices/{device.DeviceId}", device);
    }
}
