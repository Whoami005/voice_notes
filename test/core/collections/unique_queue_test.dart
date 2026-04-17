import 'package:flutter_test/flutter_test.dart';
import 'package:voice_notes/core/collections/unique_queue.dart';

void main() {
  group('UniqueQueue', () {
    test('new instance is empty', () {
      final queue = UniqueQueue<String>();

      expect(queue.isEmpty, isTrue);
      expect(queue.length, 0);
      expect(queue.toList(), isEmpty);
    });

    group('add', () {
      test('adds new element and returns true', () {
        final queue = UniqueQueue<String>();

        expect(queue.add('a'), isTrue);
        expect(queue.length, 1);
        expect(queue.contains('a'), isTrue);
        expect(queue.first, 'a');
      });

      test('rejects duplicate and does not grow', () {
        final queue = UniqueQueue<String>()..add('a');

        expect(queue.add('a'), isFalse);
        expect(queue.length, 1);
      });

      test('preserves insertion order (FIFO)', () {
        final queue = UniqueQueue<String>()
          ..add('a')
          ..add('b')
          ..add('c');

        expect(queue.toList(), ['a', 'b', 'c']);
      });
    });

    group('addFirst', () {
      test('puts element at head', () {
        final queue = UniqueQueue<String>()
          ..add('a')
          ..add('b');

        expect(queue.addFirst('x'), isTrue);
        expect(queue.toList(), ['x', 'a', 'b']);
        expect(queue.first, 'x');
      });

      test('rejects duplicate', () {
        final queue = UniqueQueue<String>()..add('a');

        expect(queue.addFirst('a'), isFalse);
        expect(queue.length, 1);
      });
    });

    group('addAll', () {
      test('returns count of actually added elements', () {
        final queue = UniqueQueue<String>()..add('a');

        expect(queue.addAll(['a', 'b', 'c', 'b']), 2);
        expect(queue.toList(), ['a', 'b', 'c']);
      });

      test('returns 0 for empty iterable', () {
        final queue = UniqueQueue<String>();

        expect(queue.addAll(const <String>[]), 0);
        expect(queue.isEmpty, isTrue);
      });

      test('preserves order of added elements', () {
        final queue = UniqueQueue<int>()..addAll([3, 1, 2]);

        expect(queue.toList(), [3, 1, 2]);
      });

      test('returns 0 when all elements are duplicates', () {
        final queue = UniqueQueue<String>()..addAll(['a', 'b']);

        expect(queue.addAll(['a', 'b']), 0);
        expect(queue.length, 2);
      });
    });

    group('remove', () {
      test('removes by value and returns true', () {
        final queue = UniqueQueue<String>()..addAll(['a', 'b', 'c']);

        expect(queue.remove('b'), isTrue);
        expect(queue.toList(), ['a', 'c']);
        expect(queue.contains('b'), isFalse);
      });

      test('returns false for absent element', () {
        final queue = UniqueQueue<String>()..add('a');

        expect(queue.remove('missing'), isFalse);
        expect(queue.length, 1);
      });

      test('allows re-adding removed element', () {
        final queue = UniqueQueue<String>()
          ..add('a')
          ..remove('a');

        expect(queue.add('a'), isTrue);
        expect(queue.toList(), ['a']);
      });

      test('removes head correctly', () {
        final queue = UniqueQueue<String>()..addAll(['a', 'b']);

        expect(queue.remove('a'), isTrue);
        expect(queue.first, 'b');
      });

      test('removes tail correctly', () {
        final queue = UniqueQueue<String>()..addAll(['a', 'b']);

        expect(queue.remove('b'), isTrue);
        expect(queue.toList(), ['a']);
      });
    });

    group('removeFirst', () {
      test('returns and removes head', () {
        final queue = UniqueQueue<String>()..addAll(['a', 'b']);

        expect(queue.removeFirst(), 'a');
        expect(queue.toList(), ['b']);
        expect(queue.contains('a'), isFalse);
      });

      test('throws StateError on empty queue', () {
        final queue = UniqueQueue<String>();

        expect(queue.removeFirst, throwsStateError);
      });
    });

    group('first', () {
      test('returns head without removing', () {
        final queue = UniqueQueue<String>()..addAll(['a', 'b']);

        expect(queue.first, 'a');
        expect(queue.length, 2);
      });

      test('throws StateError on empty queue', () {
        final queue = UniqueQueue<String>();

        expect(() => queue.first, throwsStateError);
      });
    });

    group('clear', () {
      test('empties both structures and allows re-adding', () {
        final queue = UniqueQueue<String>()
          ..addAll(['a', 'b'])
          ..clear();

        expect(queue.isEmpty, isTrue);
        expect(queue.contains('a'), isFalse);
        expect(queue.add('a'), isTrue);
        expect(queue.toList(), ['a']);
      });
    });

    group('iterator', () {
      test('yields elements in FIFO order', () {
        final queue = UniqueQueue<String>()..addAll(['a', 'b', 'c']);

        final result = <String>[];
        queue.forEach(result.add);

        expect(result, ['a', 'b', 'c']);
      });

      test('reflects addFirst in traversal order', () {
        final queue = UniqueQueue<int>()
          ..add(2)
          ..addFirst(1)
          ..add(3);

        expect(queue.toList(), [1, 2, 3]);
      });
    });

    test('works with int elements and ignores duplicates', () {
      final queue = UniqueQueue<int>()
        ..add(1)
        ..add(2)
        ..add(1);

      expect(queue.toList(), [1, 2]);
    });

    test('mixed operations keep invariant', () {
      final queue = UniqueQueue<String>()
        ..addAll(['a', 'b', 'c'])
        ..remove('b')
        ..addFirst('z')
        ..removeFirst();

      expect(queue.toList(), ['a', 'c']);
      expect(queue.contains('b'), isFalse);
      expect(queue.contains('z'), isFalse);
      expect(queue.length, 2);
    });
  });
}
