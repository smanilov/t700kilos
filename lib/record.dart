/// A single entry of weight and time.
class Record {
  final num weight;
  final DateTime time;

  Record(this.weight, this.time);

  @override
  bool operator ==(Object other) {
    if (other is! Record) return false;
    return weight == other.weight && time == other.time;
  }

  @override
  int get hashCode => weight.hashCode + time.hashCode;
}
