import 'package:flutter_test/flutter_test.dart';
import 'package:walim_logistics/features/attendance/presentation/attendance_notifier.dart';

void main() {
  group('AttendanceState', () {
    group('defaults', () {
      test('isCheckingIn is false', () {
        expect(AttendanceState().isCheckingIn, false);
      });

      test('hasActiveShift is false', () {
        expect(AttendanceState().hasActiveShift, false);
      });

      test('error is null', () {
        expect(AttendanceState().error, null);
      });

      test('todayCheckIns is 0', () {
        expect(AttendanceState().todayCheckIns, 0);
      });

      test('shiftStartTime is null', () {
        expect(AttendanceState().shiftStartTime, null);
      });

      test('elapsedShiftTime returns em dash', () {
        expect(AttendanceState().elapsedShiftTime, '—');
      });
    });

    group('elapsedShiftTime', () {
      test('returns em dash when hasActiveShift is false even with shiftStartTime set', () {
        final state = AttendanceState(
          hasActiveShift: false,
          shiftStartTime: DateTime.now(),
        );
        expect(state.elapsedShiftTime, '—');
      });

      test('returns em dash when shiftStartTime is null even if hasActiveShift is true', () {
        final state = AttendanceState(hasActiveShift: true, shiftStartTime: null);
        expect(state.elapsedShiftTime, '—');
      });

      test('returns formatted hh h mm m string when shift is active', () {
        final startTime = DateTime.now().subtract(const Duration(hours: 2, minutes: 15));
        final state = AttendanceState(hasActiveShift: true, shiftStartTime: startTime);
        expect(state.elapsedShiftTime, matches(RegExp(r'^\d{2}h \d{2}m$')));
      });

      test('pads single-digit hours and minutes with leading zeros', () {
        final startTime = DateTime.now().subtract(const Duration(minutes: 5));
        final state = AttendanceState(hasActiveShift: true, shiftStartTime: startTime);
        expect(state.elapsedShiftTime, matches(RegExp(r'^0\dh 0[0-9]m$')));
      });

      test('shows 00h 00m for very recent shift start', () {
        final startTime = DateTime.now().subtract(const Duration(seconds: 30));
        final state = AttendanceState(hasActiveShift: true, shiftStartTime: startTime);
        expect(state.elapsedShiftTime, '00h 00m');
      });
    });

    group('copyWith', () {
      test('preserves all fields when called with no arguments', () {
        final shiftTime = DateTime(2024, 6, 15, 8, 0);
        final original = AttendanceState(
          isCheckingIn: true,
          hasActiveShift: true,
          todayCheckIns: 3,
          shiftStartTime: shiftTime,
        );
        final copy = original.copyWith();
        expect(copy.isCheckingIn, true);
        expect(copy.hasActiveShift, true);
        expect(copy.todayCheckIns, 3);
        expect(copy.shiftStartTime, shiftTime);
      });

      test('overrides isCheckingIn', () {
        final state = AttendanceState(isCheckingIn: false);
        expect(state.copyWith(isCheckingIn: true).isCheckingIn, true);
      });

      test('overrides hasActiveShift', () {
        final state = AttendanceState(hasActiveShift: false);
        expect(state.copyWith(hasActiveShift: true).hasActiveShift, true);
      });

      test('overrides todayCheckIns', () {
        final state = AttendanceState(todayCheckIns: 0);
        expect(state.copyWith(todayCheckIns: 2).todayCheckIns, 2);
      });

      test('overrides shiftStartTime', () {
        final original = AttendanceState();
        final newTime = DateTime(2024, 1, 1, 9, 0);
        expect(original.copyWith(shiftStartTime: newTime).shiftStartTime, newTime);
      });

      test('clears error when called without error argument', () {
        final state = AttendanceState(error: 'something went wrong');
        expect(state.copyWith(isCheckingIn: true).error, null);
      });

      test('sets error when provided', () {
        final state = AttendanceState();
        expect(state.copyWith(error: 'new error').error, 'new error');
      });

      test('clearShiftStartTime flag nullifies shiftStartTime', () {
        final startTime = DateTime.now();
        final state = AttendanceState(hasActiveShift: true, shiftStartTime: startTime);
        final updated = state.copyWith(clearShiftStartTime: true, hasActiveShift: false);
        expect(updated.shiftStartTime, null);
      });

      test('preserves shiftStartTime when clearShiftStartTime is false', () {
        final startTime = DateTime(2024, 3, 10, 7, 30);
        final state = AttendanceState(hasActiveShift: true, shiftStartTime: startTime);
        expect(state.copyWith(todayCheckIns: 1).shiftStartTime, startTime);
      });

      test('does not modify other fields when only one is changed', () {
        final original = AttendanceState(
          isCheckingIn: false,
          hasActiveShift: true,
          todayCheckIns: 2,
        );
        final updated = original.copyWith(isCheckingIn: true);
        expect(updated.hasActiveShift, true);
        expect(updated.todayCheckIns, 2);
      });
    });

    group('todayCheckIns getter', () {
      test('returns 0 when not explicitly set', () {
        expect(AttendanceState().todayCheckIns, 0);
      });

      test('returns the value passed to constructor', () {
        expect(AttendanceState(todayCheckIns: 4).todayCheckIns, 4);
      });

      test('returns 0 when null is passed via copyWith', () {
        final state = AttendanceState(todayCheckIns: 3);
        // copyWith without todayCheckIns preserves the original
        expect(state.copyWith().todayCheckIns, 3);
      });
    });
  });
}
