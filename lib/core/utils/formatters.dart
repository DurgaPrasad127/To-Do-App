/// Date / time helpers. Times of day are stored as minutes since midnight
/// (0..1439) and dates as local midnight DateTimes - never compared as strings.
class Fmt {
  Fmt._();

  static const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static const monthsShort = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static const weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];
  static const weekdaysShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  static String _p(int n) => n.toString().padLeft(2, '0');

  static DateTime day(DateTime d) => DateTime(d.year, d.month, d.day);
  static DateTime addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);
  static DateTime weekStart(DateTime d) => DateTime(d.year, d.month, d.day - (d.weekday - 1));
  static bool same(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  static String key(DateTime d) => '${d.year}-${_p(d.month)}-${_p(d.day)}';
  static int minutesOf(DateTime d) => d.hour * 60 + d.minute;

  static int daysBetween(DateTime from, DateTime to) => DateTime.utc(to.year, to.month, to.day)
      .difference(DateTime.utc(from.year, from.month, from.day))
      .inDays;

  /// "2:05"
  static String clock(int min) {
    final h = (min ~/ 60) % 24;
    final m = min % 60;
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:${_p(m)}';
  }

  static String ampm(int min) => (min ~/ 60) % 24 >= 12 ? 'PM' : 'AM';
  static String time(int min) => '${clock(min)} ${ampm(min)}';
  static String range(int s, int e) => '${time(s)} – ${time(e)}';

  static String duration(int min) {
    if (min <= 0) return '0m';
    final h = min ~/ 60;
    final m = min % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  static String dateLong(DateTime d) => '${weekdays[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
  static String dateShort(DateTime d) => '${monthsShort[d.month - 1]} ${d.day}';
  static String monthYear(DateTime d) => '${months[d.month - 1]} ${d.year}';
  static String stamp(DateTime d) => '${dateShort(d)}, ${d.year} · ${time(minutesOf(d))}';

  static String greeting(int hour) {
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  static String relativeDay(DateTime d, DateTime today) {
    final diff = daysBetween(today, d);
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    return dateShort(d);
  }
}
