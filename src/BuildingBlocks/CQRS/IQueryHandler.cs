using MediatR;

namespace BuildingBlocks.CQRS;

/// <summary>
/// Handler for queries. Queries must never produce side effects.
/// </summary>
public interface IQueryHandler<in TQuery, TResponse> : IRequestHandler<TQuery, TResponse>
    where TQuery : IQuery<TResponse>;
