# LRUCache
LRUCache is a Dart library that provides a least recently used (LRU) caching mechanism for in-memory data storage. It addresses the issues of unnecessary network requests and the persistence of stale data by efficiently managing the storage of frequently accessed items.

# Problem
1. **Unnecessary Network Requests:** Fetching data from the network can be resource-intensive and lead to performance issues, especially when the same data is requested frequently.

2. **Stale Data Persistence:** Caching mechanisms need to handle the removal of stale data to ensure that the cache remains relevant and up-to-date.

# Solution
LRUCache solves the mentioned problems by caching data in memory, reducing the need for redundant network requests. It offers the flexibility to set expiration durations for each item, allowing the automatic removal of stale data.

# Usage

The LRUCache uses a linked hash map to store data and a stack to keep track of most recently used items.

You can add and get items from the cache.

When you add an item, you can set an expiry data for the item and when the date elapses, it will be removed from the cache. This item will become the most recenlty used item.

When you access an item, this item becomes the most recently used item and other items are pushed down the stack.


```dart
    import 'package:lru_memory_cache/lru_memory_cache.dart';
    
    LRUMemoryCache<String, int> cache = LRUMemoryCache(
        generateKey: (k) => k.toString(),
        capacity: 5,
        expireMode: ExpireMode.autoExpire,
        autoExpireCheckDuration: Duration(seconds: 1),
        onExpire: (key, item) {
          print("$item is expiring");
          return true;
        },
        shouldRemoveOnCapacity: (key, item) {
          print("Deciding to remove $item");
          return item % 2 == 0;
        },
        onCapacityRemoved: (key, item) {
          print("$item was removed due to capacity");
        }
    );
    
    // Add items to the cache
    cache.add('key1', value: 42);
    cache.add('key2', value: 87, expiryDuration: Duration(hours: 1));
    
    // Retrieve an item from the cache
    int? result = cache.get('key1');
    
    // Get multiple items from the cache
    ManyResult<String, int> manyResult = cache.getMany(['key1', 'key2']);
    
    // Dispose of the cache when done
    cache.dispose();

```


# Features
### Dynamic capacity
You can dynamically set the capacity of the cache based on your application's requirements.

### Item expiry
Set the duration for which an item should remain in memory. This feature is particularly useful for handling frequently changing data.

### Item persistence
You can choose to persist an item in the cache, preventing it from being removed even if it has expired or is the least used.

### Expire modes
Choose between two modes for removing expired items:

1. **autoExpire:** Automatically remove items based on the specified duration.
2. **onInteraction:** Remove items only when interacting with the cache (e.g., when adding or retrieving items).

### Global Expiry Time
Set a default expiry time for all items in the cache when no specific expiry is defined.

# API
## LRUMemoryCache

```dart
LRUMemoryCache<K, V>({
  required K Function(V data) generateKey,
  int capacity = 100,
  Duration? autoExpireCheckDuration,
  Duration? globalExpiryTime,
  bool Function(K, V)? onExpire,
  void Function(K, V)? onCapacityRemoved,
  bool Function(K, V)? shouldRemoveOnCapacity,
  ExpireMode expireMode = ExpireMode.onInteraction,
  bool Function(K, K)? equals,
  int Function(K)? hashCode,
  bool Function(dynamic)? isValidKey,
})

```

* generateKey: Function to generate a key from a value.
* capacity: Maximum capacity of the cache (default: 100).
* autoExpireCheckDuration: Duration for automatic expiration checks (required if expireMode is ExpireMode.autoExpire).
* globalExpiryTime: Default expiry time for items when no specific expiry is set.
* onExpire: Callback function triggered before an item expires.
* onCapacityRemoved: Callback function triggered when an item is removed due to reaching capacity.
* shouldRemoveOnCapacity: Callback function to decide whether to remove an item when reaching capacity.
* expireMode: Option on how to remove expired items (ExpireMode.autoExpire or ExpireMode.onInteraction).
* equals: Custom equals function for key comparison.
* hashCode: Custom hashCode function for key hashing.
* isValidKey: Custom function to check if a key is valid.

#### Properties
* isAtCapacity: Returns true if the cache is at its capacity.
* isNotAtCapacity: Returns true if the cache has room for more items.
* capacity: Get or set the current capacity of the cache.
#### Methods
* add: Adds a value to the cache with an optional expiry duration.
* addMany: Adds multiple values to the cache with optional expiry durations.
* get: Retrieves a cached value by key.
* getMany: Retrieves multiple cached values by keys.
* dispose: Clears the cache and stops the automatic expiration timer.
* ExpireMode: (Enum)
An enumeration that defines options on how to remove expired items:
1. autoExpire: Automatically expire items based on the specified duration.
2. onInteraction: Expire items only when interacting with the cache (e.g., when adding or retrieving items).

#### ManyResult Class
A result class returned by the getMany method, containing found and not found items.

# Make sure the generateKeyFunction provides unique keys of they will be overwritten

