import 'package:flutter_test/flutter_test.dart';
import 'package:ozioma/core/utils/sync_conflict_resolver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PowerSync Last-Write-Wins (LWW) Conflict Resolution Tests', () {
    test('isRemoteNewer returns true when remote timestamp is after local timestamp', () {
      final local = {
        'id': 'addr-001',
        'status': 'not_at_home',
        'updated_at': '2026-11-24T08:30:00Z',
      };
      final remote = {
        'id': 'addr-001',
        'status': 'return_visit',
        'updated_at': '2026-11-24T09:15:00Z',
      };

      expect(isRemoteNewer(local, remote), isTrue);
    });

    test('isRemoteNewer returns false when local timestamp is after remote timestamp', () {
      final local = {
        'id': 'addr-002',
        'status': 'do_not_call',
        'updated_at': '2026-11-24T10:00:00Z',
      };
      final remote = {
        'id': 'addr-002',
        'status': 'unvisited',
        'updated_at': '2026-11-24T08:00:00Z',
      };

      expect(isRemoteNewer(local, remote), isFalse);
    });

    test('isRemoteNewer returns false when remote updated_at is null', () {
      final local = {
        'id': 'addr-003',
        'status': 'unvisited',
        'updated_at': '2026-11-24T08:00:00Z',
      };
      final remote = {
        'id': 'addr-003',
        'status': 'not_at_home',
        'updated_at': null,
      };

      expect(isRemoteNewer(local, remote), isFalse);
    });

    test('isRemoteNewer returns true when local updated_at is null but remote exists', () {
      final local = {
        'id': 'addr-004',
        'status': 'unvisited',
        'updated_at': null,
      };
      final remote = {
        'id': 'addr-004',
        'status': 'not_at_home',
        'updated_at': '2026-11-24T08:00:00Z',
      };

      expect(isRemoteNewer(local, remote), isTrue);
    });

    test('isRemoteNewer handles identical timestamps deterministically by returning false', () {
      final local = {
        'id': 'addr-005',
        'status': 'return_visit',
        'updated_at': '2026-11-24T10:00:00Z',
      };
      final remote = {
        'id': 'addr-005',
        'status': 'not_at_home',
        'updated_at': '2026-11-24T10:00:00Z',
      };

      expect(isRemoteNewer(local, remote), isFalse);
    });
  });
}
