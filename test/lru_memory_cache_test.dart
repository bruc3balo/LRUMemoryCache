import 'package:lru_cache/lru_memory_cache.dart';
import 'package:test/test.dart';


class Person {
  int id;

  String name;

  Person(this.id, this.name);

  @override
  String toString() => "{id: $id, name: $name}";

}

void main() {
  group('LRU test', () {

    test(
      'Capacity Test',
      () {
        print("Capacity Test");

        int capacity = 2;

        LRUMemoryCache<String, int> cache = LRUMemoryCache(
          generateKey: (i) => i.toString(),
          capacity: capacity,
        );

        cache.add(1);
        cache.add(2);
        cache.add(3);

        expect(cache.data.length, capacity);
      },
    );

    test(
      "LRU cache",
      () {
        print("LRU Test");

        int capacity = 2;

        LRUMemoryCache<String, int> cache = LRUMemoryCache(
          generateKey: (i) => i.toString(),
          capacity: capacity,
        );

        cache.add(1);
        cache.add(2);
        cache.add(3);

        var list = cache.data;
        expect(list[0], 3);
        expect(list[1], 2);
      },
    );

    test(
      "Interaction expire test",
      () async {
        print("Interaction expire test");

        LRUMemoryCache<String, int> cache = LRUMemoryCache(
          generateKey: (i) => i.toString(),
          capacity: 10,
        );

        cache.add(
          1,
          expiryDuration: Duration(seconds: 2),
        );

        expect(cache.get("1"), 1);

        await Future.delayed(Duration(seconds: 3));

        expect(cache.get("1"), null);

      },
    );

    test(
      "Dynamic types",
          () async {
        print("Dynamic type test");

        LRUMemoryCache<dynamic, dynamic> cache = LRUMemoryCache(
          generateKey: (i) {
            switch(i.runtimeType) {
              case String:
                return i.toString();

              case int:
                return i.toString();

              case Person:
                return (i as Person).id;

            }
          },
          capacity: 10,
        );

        cache.add(
          1,
        );

        cache.add(Person(1, "Bruce"));
        List<dynamic> data = cache.data;
        expect(data[0] is Person, true);
        expect(data[1] is int, true);

        print(data);

      },
    );


  });
}
