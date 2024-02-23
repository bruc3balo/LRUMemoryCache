# LRUCache
The LRU cache is a component used to cache data in memory

# Problem
1. Unneccessary fetching data from the network
2. Keeping stale data cached


# Solution
*  The LRUCache is used to cache data in memory so you don't require to fetch it from the network unneccessary. The LRUCache solves this problem by keeping a cetain amount of data in memory
* The LRUCache has an option of setting an expiryData for each item inserted. If data can change frequently, you should set a short duration and when it's expired it will be removed from the cache

# Working

The LRUCache uses a linked hash map to store data and a stack to keep track of most recently used items.

You can add and get items from the cache.

When you add an item, you can set an expiry data for the item and when the date elapses, it will be removed from the cache. This item will become the most recenlty used item.

When you access an item, this item becomes the most recently used item and other items are pushed down the stack.


```dart

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
      });
```


# Features
### Dynamic capacity
You can set the capacity of the cache dynamically

### Item expiry
You can set the duration an item should last in memory

### Item persistence
You can decide to persist an item from being removed, though being the least used

You can decide to persist an item from being removed, though is has expired

### Expire modes
Based on your usage, you can decide to remove expired items based on access or automatically using a Timer

You can also decide when to check the frequency duration of expiring

