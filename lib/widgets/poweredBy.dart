// Imports
import 'dart:convert';

import 'package:flutter/material.dart';

/// Powered By, multiple optins to show this.
/// The options are blue logo, gray logo and plain text.
class PoweredBy extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          child: const Text(
            "Powered by",
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ),
        Image.memory(
          base64Decode(blueLongLogo),
          height: 15,
        ),
      ],
    );
  }
}
/// Gray logo encoded in Base64
const longLogo =
    "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";

/// Blue logo encoded in Base64
const blueLongLogo =
    "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";
