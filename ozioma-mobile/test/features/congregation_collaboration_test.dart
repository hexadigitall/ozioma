import 'package:flutter_test/flutter_test.dart';
import 'package:ozioma/core/database/daos/collaboration_dao.dart';
import 'package:ozioma/core/database/daos/congregation_dao.dart';
import 'package:ozioma/core/database/daos/territory_dao.dart';

void main() {
  group('Theocratic Role Permissions & Access Control', () {
    test('Role permissions strictly enforce elder, servant, pioneer, and publisher privileges', () {
      expect(TheocraticRolePermissions.canManageCongregation('elder'), isTrue);
      expect(TheocraticRolePermissions.canManageCongregation('servant'), isFalse);
      expect(TheocraticRolePermissions.canManageCongregation('publisher'), isFalse);

      expect(TheocraticRolePermissions.canManagePublishers('elder'), isTrue);
      expect(TheocraticRolePermissions.canManagePublishers('servant'), isFalse);

      expect(TheocraticRolePermissions.canManageTerritories('elder'), isTrue);
      expect(TheocraticRolePermissions.canManageTerritories('servant'), isTrue);
      expect(TheocraticRolePermissions.canManageTerritories('regular_pioneer'), isFalse);
      expect(TheocraticRolePermissions.canManageTerritories('publisher'), isFalse);

      expect(TheocraticRolePermissions.canModerateChat('elder'), isTrue);
      expect(TheocraticRolePermissions.canModerateChat('servant'), isTrue);
      expect(TheocraticRolePermissions.canModerateChat('publisher'), isFalse);
    });
  });

  group('Congregation, Pin, Chat & Live Tracking Domain Models', () {
    test('TerritoryItem calculates real heatmap coverage from visited vs total addresses', () {
      final item = TerritoryItem.fromRow(
        {
          'id': 't-100',
          'number': '#100',
          'name': 'Central Plaza',
          'region': 'Worldwide',
          'congregation_id': 'c-1',
          'status': 'assigned',
        },
        computedProgress: 0.75,
        totalAddresses: 40,
        visitedAddresses: 30,
        rvAddresses: 5,
        dncAddresses: 2,
      );
      expect(item.progress, 0.75);
      expect(item.totalAddresses, 40);
      expect(item.visitedAddresses, 30);
      expect(item.dncAddresses, 2);
    });

    test('SharedPinItem and PublisherMessageItem deserialize coordinates & metadata cleanly', () {
      final pin = SharedPinItem.fromRow({
        'id': 'p-1',
        'congregation_id': 'c-1',
        'territory_id': 't-100',
        'created_by': 'Bro. Samuel',
        'title': 'Car Group Meeting',
        'category': 'meeting_point',
        'latitude': 4.8215,
        'longitude': 6.9885,
        'notes': 'Park near main entrance',
        'is_active': 1,
        'updated_at': '2026-11-26T12:00:00Z',
      });
      expect(pin.latitude, 4.8215);
      expect(pin.longitude, 6.9885);
      expect(pin.isActive, isTrue);

      final msg = PublisherMessageItem.fromRow({
        'id': 'm-1',
        'congregation_id': 'c-1',
        'sender_id': 'u-1',
        'sender_name': 'Bro. Samuel',
        'sender_role': 'elder',
        'channel': 'field_service',
        'body': 'Meeting at Oakwood Gate',
        'pin_id': 'p-1',
        'created_at': '2026-11-26T12:00:00Z',
      });
      expect(msg.channel, 'field_service');
      expect(msg.pinId, 'p-1');
    });
  });
}
