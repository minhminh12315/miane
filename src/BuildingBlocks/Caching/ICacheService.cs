namespace BuildingBlocks.Caching;

public interface ICacheService
{
    // Use for save Token with expire time (TTL)
    Task SetAsync<T>(string key, T value, TimeSpan? absoluteExpireTime = null);

    // Use for get Token or Data to check
    Task<T?> GetAsync<T>(string key);

    // Use for delete Token (when user logout)
    Task RemoveAsync(string key);
}
