import 'dart:async';

import 'package:lru_memory_cache/lru_memory_cache.dart';

Future<void> main() async {
  LRUMemoryCache<String, int> cache = LRUMemoryCache(
    generateKey: (k) => k.toString(),
    capacity: 5,
    expireMode: ExpireMode.onInteraction,
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
    },
  );

  var list = List.generate(10, (index) => index + 1);

  for (var r in list) {
    cache.add(
      r,
      // expiryDuration: Duration(seconds: 5),
    );
  }

  print(cache.data);

  //Deciding to remove 1
  // Deciding to remove 2
  // 2 was removed due to capacity
  // Deciding to remove 1
  // Deciding to remove 3
  // Deciding to remove 4
  // 4 was removed due to capacity
  // Deciding to remove 1
  // Deciding to remove 3
  // Deciding to remove 5
  // Deciding to remove 6
  // 6 was removed due to capacity
  // Deciding to remove 1
  // Deciding to remove 3
  // Deciding to remove 5
  // Deciding to remove 7
  // Deciding to remove 8
  // 8 was removed due to capacity
  // Deciding to remove 1
  // Deciding to remove 3
  // Deciding to remove 5
  // Deciding to remove 7
  // Deciding to remove 9
  // 1 was removed due to capacity
  // [10, 9, 7, 5, 3]
}
