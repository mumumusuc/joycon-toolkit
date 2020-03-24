import 'package:community_material_icon/community_material_icon.dart';
import 'package:flutter/material.dart';

class IconText extends StatelessWidget {
  final String text;
  final double gap;
  final Widget leading;
  final Widget trailing;
  final EdgeInsetsGeometry padding;

  const IconText({
    @required this.text,
    this.gap = 12,
    this.leading,
    this.trailing,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final Widget child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leading != null) leading,
        if (leading != null) SizedBox(width: gap),
        Text(text),
        if (trailing != null) SizedBox(width: gap),
        if (trailing != null) trailing,
      ],
    );
    if (padding != null) return Padding(padding: padding, child: child);
    return child;
  }
}

class LabeledDropDownStyle extends InheritedWidget {
  final bool singleLine;
  final bool isDense;

  const LabeledDropDownStyle({
    Key key,
    Widget child,
    this.singleLine,
    this.isDense,
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(LabeledDropDownStyle old) {
    return old.singleLine != singleLine || old.isDense != isDense;
  }
}

class LabeledDropDown<T> extends StatelessWidget {
  final String label;
  final List<T> items;
  final T value;
  final bool singleLine;
  final bool isDense;
  final ValueChanged<T> onChanged;

  const LabeledDropDown({
    @required this.label,
    @required this.items,
    this.value,
    this.onChanged,
    this.singleLine,
    this.isDense,
  }) : assert(label != null);

  @override
  Widget build(BuildContext context) {
    final LabeledDropDownStyle style =
        context.dependOnInheritedWidgetOfExactType<LabeledDropDownStyle>();
    bool singleLine = this.singleLine ?? style?.singleLine ?? true;
    bool isDense = this.isDense ?? style?.isDense ?? false;
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: const Border(
          bottom: BorderSide(color: const Color(0xFFBDBDBD), width: 0),
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 0,
        alignment:
            singleLine ? WrapAlignment.spaceBetween : WrapAlignment.start,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('$label :', style: Theme.of(context).textTheme.caption),
          DropdownButton(
            isDense: !singleLine || isDense,
            isExpanded: !singleLine,
            iconSize: 14,
            underline: const SizedBox(),
            icon: const Icon(CommunityMaterialIcons.unfold_more_horizontal),
            value: value,
            items: items
                .map((e) => DropdownMenuItem(value: e, child: Text('$e')))
                .toList(growable: false),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class BoxedDropDown<T> extends StatelessWidget {
  final List<T> items;
  final T value;
  final ValueChanged<T> onChanged;
  final Widget hint;

  const BoxedDropDown({
    @required this.items,
    this.value,
    this.onChanged,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButton<T>(
        underline: const SizedBox(),
        isExpanded: true,
        iconSize: 14,
        hint: hint,
        value: value,
        items: items
            .map((e) => DropdownMenuItem<T>(value: e, child: Text('$e')))
            .toList(growable: false),
        onChanged: onChanged,
      ),
    );
  }
}
