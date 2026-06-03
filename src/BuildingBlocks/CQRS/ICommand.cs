using MediatR;

namespace BuildingBlocks.CQRS;

/// <summary>
/// Marker interface for commands that mutate state and return a response.
/// </summary>
public interface ICommand<out TResponse> : IRequest<TResponse>;

/// <summary>
/// Marker interface for commands that mutate state without returning data.
/// </summary>
public interface ICommand : IRequest<Unit>;
