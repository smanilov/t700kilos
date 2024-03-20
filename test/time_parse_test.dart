import 'package:t700kilos/util/time_formatting.dart';
import 'package:test/test.dart';

void main() {
  test('tryParseEnteredTime accepts 09:17', () {
    final time = tryParseEnteredTime("09:17")!;
    expect(time.hour, 9);
    expect(time.minute, 17);
  });

  test('tryParseEnteredTime accepts 0917 as 09:17', () {
    final time = tryParseEnteredTime("0917")!;
    expect(time.hour, 9);
    expect(time.minute, 17);
  });

  test('tryParseEnteredTime accepts 917 as 09:17', () {
    final time = tryParseEnteredTime("917")!;
    expect(time.hour, 9);
    expect(time.minute, 17);
  });

  test('tryParseEnteredTime does not accept 91', () {
    final time = tryParseEnteredTime("91");
    expect(time, null);
  });

  test('tryParseEnteredTime accepts 9 as 09:00', () {
    final time = tryParseEnteredTime("9")!;
    expect(time.hour, 9);
    expect(time.minute, 0);
  });

  test('tryParseEnteredTime does not accept 9:111', () {
    final time = tryParseEnteredTime("9:111");
    expect(time, null);
  });

  test('tryParseEnteredTime does not accept :1111', () {
    final time = tryParseEnteredTime(":1111");
    expect(time, null);
  });

  test('tryParseEnteredTime does not accept 111:1', () {
    final time = tryParseEnteredTime("111:1");
    expect(time, null);
  });

  test('tryParseEnteredTime does not accept 1111:', () {
    final time = tryParseEnteredTime("1111:");
    expect(time, null);
  });

  test('tryParseEnteredTime does not accept 25:11', () {
    final time = tryParseEnteredTime("25:11");
    expect(time, null);
  });

  test('tryParseEnteredTime does not accept 11:66', () {
    final time = tryParseEnteredTime("11:66");
    expect(time, null);
  });

  test('tryParseEnteredTime accepts 17:48', () {
    final time = tryParseEnteredTime("17:48")!;
    expect(time.hour, 17);
    expect(time.minute, 48);
  });

  test('tryParseEnteredTime accepts 1748 as 17:48', () {
    final time = tryParseEnteredTime("1748")!;
    expect(time.hour, 17);
    expect(time.minute, 48);
  });

  test('tryParseEnteredTime accepts 1701 as 17:01', () {
    final time = tryParseEnteredTime("1701")!;
    expect(time.hour, 17);
    expect(time.minute, 1);
  });

  test('tryParseEnteredTime does not accept 171', () {
    final time = tryParseEnteredTime("171");
    expect(time, null);
  });
}