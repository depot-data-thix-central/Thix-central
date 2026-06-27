import 'package:flutter/material.dart';

void showThixFeatureReadySnackBar(BuildContext context, String label) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$label prêt à être utilisé.')),
  );
}
