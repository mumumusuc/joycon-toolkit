import 'package:flutter/material.dart';

class AppTextScaleValue {
  final double scale;
  final String label;
  const AppTextScaleValue(this.scale, this.label);

  @override
  bool operator ==(dynamic other) {
    if (runtimeType != other.runtimeType) {
      return false;
    }
    final AppTextScaleValue _other = other;
    return scale == _other.scale && label == _other.label;
  }

  @override
  int get hashCode => hashValues(scale, label);

  @override
  String toString() {
    return '$runtimeType($label)';
  }
}

const List<AppTextScaleValue> allTextScaleValues = <AppTextScaleValue>[
  AppTextScaleValue(null, 'Default'),
  AppTextScaleValue(0.8, 'Small'),
  AppTextScaleValue(1.0, 'Normal'),
  AppTextScaleValue(1.2, 'Large'),
  AppTextScaleValue(1.5, 'Huge'),
];
