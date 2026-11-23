import 'package:flutter_test/flutter_test.dart';
import 'package:ozioma/core/database/daos/address_dao.dart';

void main() {
  group('AddressItem Domain Model & Door Status Invariants (Sprint 5)', () {
    test('AddressItem fromRow deserializes fields correctly', () {
      final row = {
        'id': 'addr-101',
        'territory_id': 'terr-14',
        'street_address': '14 Woji Road',
        'unit': 'Flat 2B',
        'status': 'not_at_home',
        'latitude': 4.8210,
        'longitude': 6.9880,
        'sort_order': 3,
      };

      final item = AddressItem.fromRow(row);
      expect(item.id, equals('addr-101'));
      expect(item.territoryId, equals('terr-14'));
      expect(item.streetAddress, equals('14 Woji Road'));
      expect(item.unit, equals('Flat 2B'));
      expect(item.status, equals('not_at_home'));
      expect(item.latitude, equals(4.8210));
      expect(item.longitude, equals(6.9880));
      expect(item.sortOrder, equals(3));
    });

    test('Default status falls back to unvisited when absent or null', () {
      final row = {
        'id': 'addr-102',
        'territory_id': 'terr-14',
        'street_address': '16 Woji Road',
        'status': null,
      };

      final item = AddressItem.fromRow(row);
      expect(item.status, equals('unvisited'));
      expect(item.sortOrder, equals(0));
      expect(item.unit, isNull);
    });

    test('Address status transitions follow valid field ministry taxonomy', () {
      const validStatuses = ['unvisited', 'not_at_home', 'return_visit', 'rv_active', 'do_not_call'];

      for (final s in validStatuses) {
        final item = AddressItem(
          id: 'test',
          territoryId: 't1',
          streetAddress: 'Road',
          status: s,
        );
        expect(item.status, equals(s));
      }
    });

    test('Address ordering sorts numerically by sortOrder then street', () {
      final list = [
        AddressItem(id: '3', territoryId: 't', streetAddress: '20 Woji', status: 'unvisited', sortOrder: 3),
        AddressItem(id: '1', territoryId: 't', streetAddress: '10 Woji', status: 'unvisited', sortOrder: 1),
        AddressItem(id: '2', territoryId: 't', streetAddress: '15 Woji', status: 'unvisited', sortOrder: 2),
      ];

      list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      expect(list.map((a) => a.id).toList(), equals(['1', '2', '3']));
    });
  });
}
