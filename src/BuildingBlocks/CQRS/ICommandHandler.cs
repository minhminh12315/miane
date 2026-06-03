using MediatR;

namespace BuildingBlocks.CQRS;

/// <summary>
/// Handler for commands returning a response.
/// </summary>
public interface ICommandHandler<in TCommand, TResponse> : IRequestHandler<TCommand, TResponse>
    where TCommand : ICommand<TResponse>;

/// <summary>
/// Handler for commands with no return value.
/// </summary>
public interface ICommandHandler<in TCommand> : IRequestHandler<TCommand, Unit>
    where TCommand : ICommand;
