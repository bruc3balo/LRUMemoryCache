import 'dart:async';
import 'dart:collection';

/// Holds cache data in memory for a set capacity
/// Allows setting for a duration
class LRUMemoryCache<K, V> {
  /// Maximum Capacity of [_cache]
  int _capacity;

  /// If set, when adding items it will be used as default expiry time when no expiry time is set
  Duration? globalExpiryTime;

  /// Generate key [K] from value [V]
  final K Function(V data) generateKey;

  /// Hold cached data
  final LinkedHashMap<K, _LRUData<V>> _cache;

  /// Hold order of keys as a stack
  final Queue<K> _keyStack = Queue();

  /// Duration to check if items have expired
  /// When set a [Timer] will execute every set [autoExpireCheckDuration]
  Duration? autoExpireCheckDuration;

  /// Callback function before an item has expired and the return result
  /// i.e. true or false decide whether to remove the item or keep it
  final bool Function(K, V)? onExpire;

  /// Callback function when an item has been removed when another item
  /// has been added by the [add] or [addMany] functions due to [isAtCapacity]
  /// being true
  final void Function(K, V)? onCapacityRemoved;

  /// Callback function before an item is removed due to [capacity] and the return result
  /// i.e. true or false decide whether to remove the item or keep it
  /// if all items have not been removed then item at bottom of stack will be removed
  final bool Function(K, V)? shouldRemoveOnCapacity;

  /// Removes [ExpireMode.autoExpire] items from the [_cache]
  late final Timer? _timer;

  ///Tells the cache how to remove [_LRUData.expiryDuration] expired items
  final ExpireMode expireMode;

  LRUMemoryCache({
    required this.generateKey,
    int capacity = 100,
    this.onExpire,
    this.autoExpireCheckDuration,
    this.globalExpiryTime,
    this.onCapacityRemoved,
    this.shouldRemoveOnCapacity,
    this.expireMode = ExpireMode.onInteraction,
    bool Function(K, K)? equals,
    int Function(K)? hashCode,
    bool Function(dynamic)? isValidKey,
  })  : _cache = LinkedHashMap<K, _LRUData<V>>(
          equals: equals,
          hashCode: hashCode,
          isValidKey: isValidKey,
        ),
        _capacity = capacity,
        assert(capacity > 0) {
    if (expireMode == ExpireMode.autoExpire) {
      assert(autoExpireCheckDuration != null);
      _timer = Timer.periodic(
        autoExpireCheckDuration!,
        (_) => _removeExpired(),
      );
    }
  }

  ///Check if [_cache] is at capacity
  bool get isAtCapacity => _cache.length >= _capacity;

  ///Check if [_cache] has allowance of items
  bool get isNotAtCapacity => !isAtCapacity;

  /// Dynamically change the [_capacity] of the [_cache]
  set capacity(int capacity) {
    assert(capacity > 0);
    _capacity = capacity;

    //Correct size
    while (_cache.length > _capacity) {
      _removeLRUFromStack();
    }
  }

  ///Returns the value of current [_capacity]
  int get capacity => _capacity;

  /// O(n) but asynchronous
  /// Internal function to add a value to the [_cache]
  V _add(
    V value, {
    Duration? expiryDuration,
  }) {
    expiryDuration ??= globalExpiryTime;

    //Create key O(1)
    K newKey = generateKey(value);

    //Check if key exists O(1)
    bool exist = _cache.containsKey(newKey);

    //Check capacity O(1)
    if (isAtCapacity && !exist) _removeLRUFromStack();

    //Create new item O(1)
    _LRUData<V> newData = _LRUData<V>(
      value,
      expiryDuration: expiryDuration,
    );

    //Update used O(n)
    _moveUpStack(newKey, newData, exist);

    //return value
    return value;
  }

  /// Adds a [value] to the cache
  /// If it exists, it will be replaced, and will be most recently used i.e. Moved to top of stack
  /// Sets optional [expiryDuration] for data to expire when the [Duration] elapses
  /// O(n)
  V add(
    V value, {
    Duration? expiryDuration,
  }) {
    //Remove Expired O(n)
    _removeInteractionExpired();

    return _add(
      value,
      expiryDuration: expiryDuration,
    );
  }

  /// O(n) where n is [values.length]
  Map<K, V> addMany(Map<V, Duration?> values) {
    //Remove Expired O(n)
    _removeInteractionExpired();

    //Return map
    Map<K, V> map = {};

    // Add Values
    // O(n)
    for (var e in values.entries) {
      V value = e.key;
      K k = generateKey(value);
      Duration? expiryDuration = e.value;

      //O(n)
      value = _add(
        value,
        expiryDuration: expiryDuration,
      );

      //O(1)
      map.putIfAbsent(
        k,
        () => value,
      );
    }

    return map;
  }

  /// O(n) get
  MapEntry<K, V>? _get(K key) {
    //Get data O(1)
    _LRUData<V>? value = _cache[key];

    if (value == null) return null;

    // Update Last Used O(1)
    _moveUpStack(key, value, true);

    return MapEntry(key, value.data);
  }

  /// Get cached data [V] based on [key]
  /// It also removes expired data first
  /// O(n)
  V? get(K key) {
    //Remove expired data O(n)
    _removeInteractionExpired();

    // O(1)
    return _get(key)?.value;
  }

  /// O(n) where n is [keys.length]
  ManyResult getMany(List<K> keys) {
    //Remove expired data O(n)
    _removeInteractionExpired();

    //Return map
    ManyResult<K, V> result = ManyResult();

    //Get keys
    // O(n)
    for (K key in keys) {
      MapEntry<K, V>? data = _get(key);

      if (data == null) {
        result.addNotFound(key);
        continue;
      }

      result.addFound(key, data.value);
    }

    return result;
  }

  /// O(n) remove from stack
  V? remove(K key) {
    _keyStack.remove(key);
    return _cache.remove(key)?.data;
  }

  /// Iterates through the list and removes expired data from [_cache] & [_keyStack]
  /// O(n) where n is [_cache.length]
  void _removeExpired() {
    //O(n)
    _cache.removeWhere(
      (key, value) {
        bool expired = value.hasDataExpired;
        if (!expired) return false;

        bool removeDecision = onExpire?.call(key, value.data) ?? true;

        //remove key from stack
        if (removeDecision) _keyStack.remove(key);

        //remove entry from cache if returned true
        return removeDecision;
      },
    );
  }

  /// If [expireMode] is [ExpireMode.onInteraction]
  /// Remove expired items
  void _removeInteractionExpired() {
    if (expireMode != ExpireMode.onInteraction) return;
    _removeExpired();
  }

  /// Updates [key] to top of stack [_keyStack]
  /// Updates / adds [value] to [_cache]
  /// O(n) due to removing from [_keyStack]
  /// It's not time required immediately so it's asyncronous
  Future<void> _moveUpStack(K key, _LRUData<V> value, bool exists) async {
    //remove key O(n)
    if (exists) _keyStack.remove(key);

    //add key to top of stack O(1)
    _keyStack.addFirst(key);

    //Update item O(1)
    _cache.update(
      key,
      (v) => value,
      ifAbsent: () => value,
    );
  }

  /// Removes LRU item i.e. bottom item of stack from [_keyStack] & [_cache]
  /// O(1)
  void _removeLRUFromStack() {
    //Fail fast
    if (_keyStack.isEmpty) return;

    K key = _keyStack.last;
    V value = _cache[key]!.data;

    bool remove = shouldRemoveOnCapacity?.call(key, value) ?? true;
    if (!remove) {
      //search stack from bottom till item is removed
      List<V> stack = _keyStack.map((e) => _cache[e]!.data).toList();
      for (int i = stack.length - 1; i >= 0; i--) {
        V nextValue = stack[i];
        K nextKey = generateKey(nextValue);

        //Skip this item as it's not to be removed
        if (key == nextKey) continue;

        remove = shouldRemoveOnCapacity?.call(nextKey, nextValue) ?? true;
        if (remove) {
          _keyStack.remove(nextKey);
          _cache.remove(nextValue);
          onCapacityRemoved?.call(nextKey, nextValue);
          return;
        }
      }

      //If not item is removed then the bottom item will be removed
    }

    //remove key O(1)
    key = _keyStack.removeLast();

    //remove entry O(1)
    value = _cache.remove(key)!.data;

    //Notify item has been removed due to max capacity
    onCapacityRemoved?.call(key, value);
  }

  /// O(n) [_removeInteractionExpired]
  /// O(n) Then creates a list from Most recent used
  List<V> get data {
    _removeInteractionExpired();
    return _keyStack.map((e) => _cache[e]!.data).toList();
  }

  /// O(n) [_removeInteractionExpired]
  /// O(n) Then creates a map from Most recent used
  LinkedHashMap<K, V> get dataMap {
    _removeInteractionExpired();
    return LinkedHashMap.fromIterable(
      _keyStack,
      key: (i) => i,
      value: (i) => _cache[i as K]!.data,
    );
  }

  /// Clears the timer and removes all data from [_keyStack] && [_cache]
  void dispose() {
    if (_timer?.isActive ?? false) {
      _timer?.cancel();
    }
    _cache.clear();
    _keyStack.clear();
  }
}

/// Data Type of the [LRUMemoryCache]
class _LRUData<V> {
  final V data;
  final DateTime addedAt;
  final Duration? expiryDuration;

  _LRUData(this.data, {this.expiryDuration}) : addedAt = DateTime.now();

  bool get hasDataExpired {
    if (expiryDuration == null) return false;

    DateTime now = DateTime.now();
    DateTime expiryTime = addedAt.add(expiryDuration!);

    return !now.isBefore(expiryTime);
  }
}

/// Result of [LRUMemoryCache.getMany]
/// Returns found and not found
class ManyResult<K, V> {
  Map<K, V> found = {};

  Set<K> notFound = {};

  ManyResult();

  addFound(K key, V value) => found.putIfAbsent(key, () => value);
  addNotFound(K key) => notFound.add(key);

  @override
  String toString() {
    return "{found : $found, notFound : $notFound}";
  }
}

/// Option on how to remove expired items
enum ExpireMode { autoExpire, onInteraction }
