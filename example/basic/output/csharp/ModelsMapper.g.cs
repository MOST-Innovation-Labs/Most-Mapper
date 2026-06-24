// GENERATED CODE - DO NOT MODIFY BY HAND.
#nullable enable

using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text.Json;

internal static class MostMapperJson
{
    public static JsonElement? Optional(JsonElement json, string name)
    {
        return json.TryGetProperty(name, out var value) && value.ValueKind != JsonValueKind.Null ? value : null;
    }
}

public enum PaymentStatus
{
    Pending,
    Captured,
    Failed,
}

public static class PaymentStatusConversions
{
    public static string ToStringValue(PaymentStatus value) => value switch
    {
        PaymentStatus.Pending => "pending",
        PaymentStatus.Captured => "captured",
        PaymentStatus.Failed => "failed",
        _ => throw new ArgumentOutOfRangeException(nameof(value)),
    };

    public static PaymentStatus FromStringValue(string value) => value switch
    {
        "pending" => PaymentStatus.Pending,
        "captured" => PaymentStatus.Captured,
        "failed" => PaymentStatus.Failed,
        _ => throw new ArgumentOutOfRangeException(nameof(value), value, "Unknown PaymentStatus string"),
    };

    public static int ToIntValue(PaymentStatus value) => value switch
    {
        PaymentStatus.Pending => 0,
        PaymentStatus.Captured => 1,
        PaymentStatus.Failed => 2,
        _ => throw new ArgumentOutOfRangeException(nameof(value)),
    };

    public static PaymentStatus FromIntValue(int value) => value switch
    {
        0 => PaymentStatus.Pending,
        1 => PaymentStatus.Captured,
        2 => PaymentStatus.Failed,
        _ => throw new ArgumentOutOfRangeException(nameof(value), value, "Unknown PaymentStatus int"),
    };
}

/// <summary>
/// Monetary amount stored as minor units.
/// </summary>
public class Money
{
    public string Code { get; set; } = "";
    public int FractionalUnits { get; set; }
    public int Value { get; set; }

    public Dictionary<string, object?> ToJsonMap()
    {
        return new Dictionary<string, object?>
        {
            ["code"] = Code,
            ["fractionalUnits"] = FractionalUnits,
            ["value"] = Value,
        };
    }

    public string ToJson() => JsonSerializer.Serialize(ToJsonMap());

    public static Money FromJson(string json)
    {
        using var document = JsonDocument.Parse(json);
        return FromJsonElement(document.RootElement);
    }

    public static Money FromJsonElement(JsonElement json)
    {
        return new Money
        {
            Code = json.GetProperty("code").GetString()!,
            FractionalUnits = json.GetProperty("fractionalUnits").GetInt32(),
            Value = json.GetProperty("value").GetInt32(),
        };
    }

    private static decimal MoneyToDecimal(Money source)
    {
        return ((decimal)source.Value / (decimal)Math.Pow(10, source.FractionalUnits));
    }

    private static string OffsetDateTimeToString(System.DateTime source)
    {
        return (new DateTimeOffset(source).ToString("yyyy-MM-dd'T'HH:mm:sszzz", CultureInfo.InvariantCulture));
    }

    private static System.DateTime OffsetStringToDateTime(string source)
    {
        return (
            DateTimeOffset.ParseExact(
                source,
                "yyyy-MM-dd'T'HH:mm:sszzz",
                CultureInfo.InvariantCulture
            ).UtcDateTime
        );
    }

}

/// <summary>
/// Domain model.
/// </summary>
public class ModelA
{
    public string? JsonFieldName { get; set; }
    public Money Amount { get; set; } = default!;
    public PaymentStatus Status { get; set; }
    public List<ModelB> Bs { get; set; } = new List<ModelB>();
    public System.DateTime? CreatedAt { get; set; }

    public Dictionary<string, object?> ToJsonMap()
    {
        return new Dictionary<string, object?>
        {
            ["JsonFieldName"] = JsonFieldName == null ? null : JsonFieldName,
            ["amount"] = Amount.ToJsonMap(),
            ["status"] = PaymentStatusConversions.ToStringValue(Status),
            ["bs"] = Bs.Select(item => item.ToJsonMap()).ToList(),
            ["createdAt"] = CreatedAt == null ? null : OffsetDateTimeToString(CreatedAt.Value),
        };
    }

    public string ToJson() => JsonSerializer.Serialize(ToJsonMap());

    public static ModelA FromJson(string json)
    {
        using var document = JsonDocument.Parse(json);
        return FromJsonElement(document.RootElement);
    }

    public static ModelA FromJsonElement(JsonElement json)
    {
        return new ModelA
        {
            JsonFieldName = MostMapperJson.Optional(json, "JsonFieldName") is JsonElement jsonFieldNameJson ? jsonFieldNameJson.GetString()! : null,
            Amount = Money.FromJsonElement(json.GetProperty("amount")),
            Status = PaymentStatusConversions.FromStringValue(json.GetProperty("status").GetString()!),
            Bs = json.GetProperty("bs").EnumerateArray().Select(item => ModelB.FromJsonElement(item)).ToList(),
            CreatedAt = MostMapperJson.Optional(json, "createdAt") is JsonElement createdAtJson ? OffsetStringToDateTime(createdAtJson.GetString()!) : null,
        };
    }

    private static decimal MoneyToDecimal(Money source)
    {
        return ((decimal)source.Value / (decimal)Math.Pow(10, source.FractionalUnits));
    }

    private static string OffsetDateTimeToString(System.DateTime source)
    {
        return (new DateTimeOffset(source).ToString("yyyy-MM-dd'T'HH:mm:sszzz", CultureInfo.InvariantCulture));
    }

    private static System.DateTime OffsetStringToDateTime(string source)
    {
        return (
            DateTimeOffset.ParseExact(
                source,
                "yyyy-MM-dd'T'HH:mm:sszzz",
                CultureInfo.InvariantCulture
            ).UtcDateTime
        );
    }

}

/// <summary>
/// Wire model.
/// </summary>
public class ModelAWire
{
    public string? Id { get; set; }
    public decimal Amount { get; set; }
    public string Status { get; set; } = "";
    public int StatusCode { get; set; }
    public List<ModelBWire> Bs { get; set; } = new List<ModelBWire>();
    public string? CreatedAt { get; set; }
    public string? SomeField { get; set; }

    public Dictionary<string, object?> ToJsonMap()
    {
        return new Dictionary<string, object?>
        {
            ["Id"] = Id == null ? null : Id,
            ["amount"] = Amount,
            ["status"] = Status,
            ["statusCode"] = StatusCode,
            ["bs"] = Bs.Select(item => item.ToJsonMap()).ToList(),
            ["createdAt"] = CreatedAt == null ? null : CreatedAt,
            ["SomeField"] = SomeField == null ? null : SomeField,
        };
    }

    public string ToJson() => JsonSerializer.Serialize(ToJsonMap());

    public static ModelAWire FromJson(string json)
    {
        using var document = JsonDocument.Parse(json);
        return FromJsonElement(document.RootElement);
    }

    public static ModelAWire FromJsonElement(JsonElement json)
    {
        return new ModelAWire
        {
            Id = MostMapperJson.Optional(json, "Id") is JsonElement idJson ? idJson.GetString()! : null,
            Amount = json.GetProperty("amount").GetDecimal(),
            Status = json.GetProperty("status").GetString()!,
            StatusCode = json.GetProperty("statusCode").GetInt32(),
            Bs = json.GetProperty("bs").EnumerateArray().Select(item => ModelBWire.FromJsonElement(item)).ToList(),
            CreatedAt = MostMapperJson.Optional(json, "createdAt") is JsonElement createdAtJson ? createdAtJson.GetString()! : null,
            SomeField = MostMapperJson.Optional(json, "SomeField") is JsonElement someFieldJson ? someFieldJson.GetString()! : null,
        };
    }

    private static decimal MoneyToDecimal(Money source)
    {
        return ((decimal)source.Value / (decimal)Math.Pow(10, source.FractionalUnits));
    }

    private static string OffsetDateTimeToString(System.DateTime source)
    {
        return (new DateTimeOffset(source).ToString("yyyy-MM-dd'T'HH:mm:sszzz", CultureInfo.InvariantCulture));
    }

    private static System.DateTime OffsetStringToDateTime(string source)
    {
        return (
            DateTimeOffset.ParseExact(
                source,
                "yyyy-MM-dd'T'HH:mm:sszzz",
                CultureInfo.InvariantCulture
            ).UtcDateTime
        );
    }

}

/// <summary>
/// Domain child model.
/// </summary>
public class ModelB
{
    public string Id { get; set; } = "";
    public System.DateTime Datetime { get; set; }

    public Dictionary<string, object?> ToJsonMap()
    {
        return new Dictionary<string, object?>
        {
            ["Id"] = Id,
            ["Datetime"] = OffsetDateTimeToString(Datetime),
        };
    }

    public string ToJson() => JsonSerializer.Serialize(ToJsonMap());

    public static ModelB FromJson(string json)
    {
        using var document = JsonDocument.Parse(json);
        return FromJsonElement(document.RootElement);
    }

    public static ModelB FromJsonElement(JsonElement json)
    {
        return new ModelB
        {
            Id = json.GetProperty("Id").GetString()!,
            Datetime = OffsetStringToDateTime(json.GetProperty("Datetime").GetString()!),
        };
    }

    private static decimal MoneyToDecimal(Money source)
    {
        return ((decimal)source.Value / (decimal)Math.Pow(10, source.FractionalUnits));
    }

    private static string OffsetDateTimeToString(System.DateTime source)
    {
        return (new DateTimeOffset(source).ToString("yyyy-MM-dd'T'HH:mm:sszzz", CultureInfo.InvariantCulture));
    }

    private static System.DateTime OffsetStringToDateTime(string source)
    {
        return (
            DateTimeOffset.ParseExact(
                source,
                "yyyy-MM-dd'T'HH:mm:sszzz",
                CultureInfo.InvariantCulture
            ).UtcDateTime
        );
    }

}

/// <summary>
/// Wire child model.
/// </summary>
public class ModelBWire
{
    public string Id { get; set; } = "";
    public string Datetime { get; set; } = "";

    public Dictionary<string, object?> ToJsonMap()
    {
        return new Dictionary<string, object?>
        {
            ["Id"] = Id,
            ["Datetime"] = Datetime,
        };
    }

    public string ToJson() => JsonSerializer.Serialize(ToJsonMap());

    public static ModelBWire FromJson(string json)
    {
        using var document = JsonDocument.Parse(json);
        return FromJsonElement(document.RootElement);
    }

    public static ModelBWire FromJsonElement(JsonElement json)
    {
        return new ModelBWire
        {
            Id = json.GetProperty("Id").GetString()!,
            Datetime = json.GetProperty("Datetime").GetString()!,
        };
    }

    private static decimal MoneyToDecimal(Money source)
    {
        return ((decimal)source.Value / (decimal)Math.Pow(10, source.FractionalUnits));
    }

    private static string OffsetDateTimeToString(System.DateTime source)
    {
        return (new DateTimeOffset(source).ToString("yyyy-MM-dd'T'HH:mm:sszzz", CultureInfo.InvariantCulture));
    }

    private static System.DateTime OffsetStringToDateTime(string source)
    {
        return (
            DateTimeOffset.ParseExact(
                source,
                "yyyy-MM-dd'T'HH:mm:sszzz",
                CultureInfo.InvariantCulture
            ).UtcDateTime
        );
    }

}

public static class MostMapperMappings
{
    public static ModelBWire ToModelBWire(
        this ModelB source)
    {
        return new ModelBWire
        {
            Id = source.Id,
            Datetime = OffsetDateTimeToString(source.Datetime),
        };
    }

    public static ModelB ToModelB(
        this ModelBWire source)
    {
        return new ModelB
        {
            Id = source.Id,
            Datetime = OffsetStringToDateTime(source.Datetime),
        };
    }

    public static ModelAWire ToModelAWire(
        this ModelA source)
    {
        return new ModelAWire
        {
            Id = source.JsonFieldName,
            Amount = MoneyToDecimal(source.Amount),
            Status = PaymentStatusConversions.ToStringValue(source.Status),
            StatusCode = PaymentStatusConversions.ToIntValue(source.Status),
            Bs = source.Bs.Select(item => item.ToModelBWire()).ToList(),
            CreatedAt = source.CreatedAt == null ? null : DateTimeToString(source.CreatedAt.Value),
            SomeField = null,
        };
    }


    private static string DateTimeToString(System.DateTime source)
    {
        return (source.ToUniversalTime().ToString("yyyy-MM-dd'T'HH:mm:ss'Z'", System.Globalization.CultureInfo.InvariantCulture));
    }

    private static decimal MoneyToDecimal(Money source)
    {
        return ((decimal)source.Value / (decimal)Math.Pow(10, source.FractionalUnits));
    }

    private static string OffsetDateTimeToString(System.DateTime source)
    {
        return (new DateTimeOffset(source).ToString("yyyy-MM-dd'T'HH:mm:sszzz", CultureInfo.InvariantCulture));
    }

    private static System.DateTime OffsetStringToDateTime(string source)
    {
        return (
            DateTimeOffset.ParseExact(
                source,
                "yyyy-MM-dd'T'HH:mm:sszzz",
                CultureInfo.InvariantCulture
            ).UtcDateTime
        );
    }

}

