using MediatR;

namespace BuildingBlocks.CQRS;

/// <summary>
/// Marker interface for queries that read state without side effects.
/// </summary>
public interface IQuery<out TResponse> : IRequest<TResponse>;
