import 'package:flutter_test/flutter_test.dart';
import 'package:ozioma/core/database/daos/ministry_planner_dao.dart';
import 'package:ozioma/core/database/daos/return_visit_dao.dart';
import 'package:ozioma/core/database/daos/service_log_dao.dart';

void main() {
  group('Discipleship Milestones & Ministry Planner Models', () {
    test('Canonical student milestones cover complete journey through baptism', () {
      expect(canonicalStudentMilestones.length, 8);
      final keys = canonicalStudentMilestones.map((m) => m.key).toList();
      expect(keys, [
        'started_study',
        'gave_witness',
        'attended_first_meeting',
        'regular_meetings',
        'made_comment',
        'first_assignment',
        'became_publisher',
        'baptized',
      ]);
      for (var i = 0; i < canonicalStudentMilestones.length; i++) {
        expect(canonicalStudentMilestones[i].order, i + 1);
      }
    });

    test('MinistryGoalItem calculates progress safely within [0.0, 1.0]', () {
      final goal = MinistryGoalItem(
        id: 'g1',
        title: 'Monthly Pioneer Pace',
        category: 'hours',
        targetValue: 50,
        currentValue: 25,
        unit: 'hrs',
        period: 'monthly',
        notes: '',
        isCompleted: false,
        dueDate: '',
      );
      expect(goal.progress, 0.5);

      final exceeded = MinistryGoalItem(
        id: 'g2',
        title: 'Daily Reading',
        category: 'spiritual_routine',
        targetValue: 30,
        currentValue: 40,
        unit: 'days',
        period: 'monthly',
        notes: '',
        isCompleted: true,
        dueDate: '',
      );
      expect(exceeded.progress, 1.0);
    });

    test('ServiceLogItem maps detailed session fields accurately', () {
      final item = ServiceLogItem.fromRow(
        {
          'id': 'log-1',
          'log_date': '2026-11-26',
          'duration_minutes': 150,
          'bible_studies_count': 2,
          'placements_count': 5,
          'video_showings_count': 3,
        },
        startTime: '08:30',
        endTime: '11:00',
        activityType: 'Door-to-Door',
        partnerName: 'Bro. Samuel',
        notes: 'Productive morning in Rumuola',
      );
      expect(item.durationMinutes, 150);
      expect(item.startTime, '08:30');
      expect(item.endTime, '11:00');
      expect(item.partnerName, 'Bro. Samuel');
    });
  });
}
