// GENERATED CODE - DO NOT MODIFY BY HAND.
#nullable enable

using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text.Json;

public static class MappingConverters
{
    public static string DateTimeToString(System.DateTime source)
    {
        return (source.ToUniversalTime().ToString("yyyy-MM-dd'T'HH:mm:ss'Z'", System.Globalization.CultureInfo.InvariantCulture));
    }

    public static decimal MeasurementToDecimal(Measurement source)
    {
        return ((decimal)source.Value / (decimal)Math.Pow(10, source.Scale));
    }

    public static string OffsetDateTimeToString(System.DateTime source)
    {
        return (new DateTimeOffset(source).ToString("yyyy-MM-dd'T'HH:mm:sszzz", CultureInfo.InvariantCulture));
    }

    public static System.DateTime OffsetStringToDateTime(string source)
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

internal static class MappingJson
{
    public static JsonElement? Optional(JsonElement json, string name)
    {
        return json.TryGetProperty(name, out var value) && value.ValueKind != JsonValueKind.Null ? value : null;
    }
}

public enum OrderStatus
{
    Pending,
    Captured,
    Failed,
}

public static class OrderStatusConversions
{
    public static string ToStringValue(OrderStatus value) => value switch
    {
        OrderStatus.Pending => "pending",
        OrderStatus.Captured => "captured",
        OrderStatus.Failed => "failed",
        _ => throw new ArgumentOutOfRangeException(nameof(value)),
    };

    public static OrderStatus FromStringValue(string value) => value switch
    {
        "pending" => OrderStatus.Pending,
        "captured" => OrderStatus.Captured,
        "failed" => OrderStatus.Failed,
        _ => throw new ArgumentOutOfRangeException(nameof(value), value, "Unknown OrderStatus string"),
    };

    public static int ToIntValue(OrderStatus value) => value switch
    {
        OrderStatus.Pending => 0,
        OrderStatus.Captured => 1,
        OrderStatus.Failed => 2,
        _ => throw new ArgumentOutOfRangeException(nameof(value)),
    };

    public static OrderStatus FromIntValue(int value) => value switch
    {
        0 => OrderStatus.Pending,
        1 => OrderStatus.Captured,
        2 => OrderStatus.Failed,
        _ => throw new ArgumentOutOfRangeException(nameof(value), value, "Unknown OrderStatus int"),
    };
}

/// <summary>
/// Sample scaled numeric value.
/// </summary>
public class Measurement
{
    public string Code { get; set; } = "";
    public int Scale { get; set; }
    public int Value { get; set; }

    public Dictionary<string, object?> ToJsonMap()
    {
        return new Dictionary<string, object?>
        {
            ["code"] = Code,
            ["scale"] = Scale,
            ["value"] = Value,
        };
    }

    public string ToJson() => JsonSerializer.Serialize(ToJsonMap());

    public static Measurement FromJson(string json)
    {
        using var document = JsonDocument.Parse(json);
        return FromJsonElement(document.RootElement);
    }

    public static Measurement FromJsonElement(JsonElement json)
    {
        return new Measurement
        {
            Code = json.GetProperty("code").GetString()!,
            Scale = json.GetProperty("scale").GetInt32(),
            Value = json.GetProperty("value").GetInt32(),
        };
    }
}

/// <summary>
/// Domain model.
/// </summary>
public class ModelA
{
    public string? JsonFieldName { get; set; }
    public Measurement Reading { get; set; } = default!;
    public OrderStatus Status { get; set; }
    public List<ModelB> Bs { get; set; } = new List<ModelB>();
    public System.DateTime? CreatedAt { get; set; }

    public Dictionary<string, object?> ToJsonMap()
    {
        return new Dictionary<string, object?>
        {
            ["JsonFieldName"] = JsonFieldName == null ? null : JsonFieldName,
            ["reading"] = Reading.ToJsonMap(),
            ["status"] = OrderStatusConversions.ToStringValue(Status),
            ["bs"] = Bs.Select(item => item.ToJsonMap()).ToList(),
            ["createdAt"] = CreatedAt == null ? null : MappingConverters.OffsetDateTimeToString(CreatedAt.Value),
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
            JsonFieldName = MappingJson.Optional(json, "JsonFieldName") is JsonElement jsonFieldNameJson ? jsonFieldNameJson.GetString()! : null,
            Reading = Measurement.FromJsonElement(json.GetProperty("reading")),
            Status = OrderStatusConversions.FromStringValue(json.GetProperty("status").GetString()!),
            Bs = json.GetProperty("bs").EnumerateArray().Select(item => ModelB.FromJsonElement(item)).ToList(),
            CreatedAt = MappingJson.Optional(json, "createdAt") is JsonElement createdAtJson ? MappingConverters.OffsetStringToDateTime(createdAtJson.GetString()!) : null,
        };
    }
}

/// <summary>
/// Wire model.
/// </summary>
public class ModelAWire
{
    public string? Id { get; set; }
    public decimal Reading { get; set; }
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
            ["reading"] = Reading,
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
            Id = MappingJson.Optional(json, "Id") is JsonElement idJson ? idJson.GetString()! : null,
            Reading = json.GetProperty("reading").GetDecimal(),
            Status = json.GetProperty("status").GetString()!,
            StatusCode = json.GetProperty("statusCode").GetInt32(),
            Bs = json.GetProperty("bs").EnumerateArray().Select(item => ModelBWire.FromJsonElement(item)).ToList(),
            CreatedAt = MappingJson.Optional(json, "createdAt") is JsonElement createdAtJson ? createdAtJson.GetString()! : null,
            SomeField = MappingJson.Optional(json, "SomeField") is JsonElement someFieldJson ? someFieldJson.GetString()! : null,
        };
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
            ["Datetime"] = MappingConverters.OffsetDateTimeToString(Datetime),
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
            Datetime = MappingConverters.OffsetStringToDateTime(json.GetProperty("Datetime").GetString()!),
        };
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
}

public static class MappingExtensions
{
    public static ModelBWire ToModelBWire(
        this ModelB source)
    {
        return new ModelBWire
        {
            Id = source.Id,
            Datetime = MappingConverters.OffsetDateTimeToString(source.Datetime),
        };
    }

    public static ModelB ToModelB(
        this ModelBWire source)
    {
        return new ModelB
        {
            Id = source.Id,
            Datetime = MappingConverters.OffsetStringToDateTime(source.Datetime),
        };
    }

    public static ModelAWire ToModelAWire(
        this ModelA source)
    {
        return new ModelAWire
        {
            Id = source.JsonFieldName,
            Reading = MappingConverters.MeasurementToDecimal(source.Reading),
            Status = OrderStatusConversions.ToStringValue(source.Status),
            StatusCode = OrderStatusConversions.ToIntValue(source.Status),
            Bs = source.Bs.Select(item => item.ToModelBWire()).ToList(),
            CreatedAt = source.CreatedAt == null ? null : MappingConverters.DateTimeToString(source.CreatedAt.Value),
            SomeField = null,
        };
    }

}

