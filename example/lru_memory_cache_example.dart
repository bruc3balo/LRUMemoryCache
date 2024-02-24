import 'dart:async';

import 'package:lru_cache/lru_memory_cache.dart';

Future<void> main() async {
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
    },
  );

  var list = List.generate(10, (index) => index + 1);

  Timer.periodic(Duration(seconds: 1), (timer) {
    print(cache.data);

    // var result = cache.getMany(["3", "5", "8", "9"]);
    // print(result);
  });

  for (var r in list) {
    cache.add(
      r,
      // expiryDuration: Duration(seconds: 5),
    );
    await Future.delayed(Duration(seconds: 1));
  }

  await Future.delayed(Duration(seconds: 10));

  print(cache.data);
}
