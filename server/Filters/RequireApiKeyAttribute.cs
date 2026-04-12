using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.Extensions.Configuration;

namespace Alfa.Server.Filters;

[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method)]
public sealed class RequireApiKeyAttribute : Attribute, IAsyncActionFilter
{
    private const string ApiKeyHeaderName = "X-Alfa-Api-Key";

    public async Task OnActionExecutionAsync(ActionExecutingContext context, ActionExecutionDelegate next)
    {
        var configuration = context.HttpContext.RequestServices.GetService<IConfiguration>();
        var expectedApiKey = Environment.GetEnvironmentVariable("ALFA_API_KEY")
            ?? configuration?.GetValue<string>("ApiKey");

        if (string.IsNullOrWhiteSpace(expectedApiKey) ||
            !context.HttpContext.Request.Headers.TryGetValue(ApiKeyHeaderName, out var actualApiKey) ||
            !string.Equals(expectedApiKey, actualApiKey, StringComparison.Ordinal))
        {
            context.Result = new UnauthorizedResult();
            return;
        }

        await next();
    }
}
