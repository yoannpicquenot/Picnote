/// A notification on a given day at a given time ("9:00").
class Reminder {
  const Reminder({required this.date, required this.time});

  final DateTime date;
  final String time;

  Reminder copyWith({DateTime? date, String? time}) => Reminder(date: date ?? this.date, time: time ?? this.time);

  @override
  bool operator ==(Object other) => other is Reminder && other.date == date && other.time == time;

  @override
  int get hashCode => Object.hash(date, time);
}
