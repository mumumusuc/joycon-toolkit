part of bloc;

class TextScale {
  final double scale;
  final String label;

  const TextScale(this.scale, this.label);

  @override
  bool operator ==(dynamic other) {
    if (runtimeType != other.runtimeType) return false;
    return scale == other.scale && label == other.label;
  }

  @override
  int get hashCode => hashValues(scale, label);

  @override
  String toString() => '$label(x${scale.toStringAsPrecision(2)})';
}

const TextScale kTextScaleSystem = const TextScale(null, 'system');
const TextScale kTextScaleSmall = const TextScale(0.8, 'small');
const TextScale kTextScaleNormal = const TextScale(1.0, 'normal');
const TextScale kTextScaleLarge = const TextScale(1.2, 'large');
const TextScale kTextScaleHuge = const TextScale(1.5, 'huge');

const List<TextScale> kTextScales = [
  kTextScaleSystem,
  kTextScaleSmall,
  kTextScaleNormal,
  kTextScaleLarge,
  kTextScaleHuge,
];
