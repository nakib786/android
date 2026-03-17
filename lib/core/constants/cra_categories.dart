import 'package:flutter/material.dart';

class CraCategory {
  final String name;
  final Color color;
  final bool isDeductible;

  const CraCategory(this.name, this.color, {this.isDeductible = true});

  static const List<CraCategory> all = [
    CraCategory('Business', Colors.blue),
    CraCategory('Medical', Colors.green),
    CraCategory('Moving', Colors.orange),
    CraCategory('Charity', Colors.yellow),
    CraCategory('Personal', Colors.black, isDeductible: false),
  ];
}
