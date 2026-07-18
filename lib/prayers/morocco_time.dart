import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// All prayer-related date/time math must use Tetouan's actual wall-clock
/// time, not the device's own system timezone — a phone/browser set to a
/// different region (e.g. Saudi Arabia) would otherwise shift every Adhan
/// time, countdown, and "today" boundary by hours.
class MoroccoTime {
  MoroccoTime._();

  static bool _ready = false;

  static tz.Location get _location {
    if (!_ready) {
      tz_data.initializeTimeZones();
      _ready = true;
    }
    return tz.getLocation('Africa/Casablanca');
  }

  static tz.TZDateTime now() => tz.TZDateTime.now(_location);

  static tz.TZDateTime date(int year, int month, int day, [int hour = 0, int minute = 0]) =>
      tz.TZDateTime(_location, year, month, day, hour, minute);
}
