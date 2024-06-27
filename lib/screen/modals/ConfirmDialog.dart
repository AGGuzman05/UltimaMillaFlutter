// ignore_for_file: camel_case_types

import 'package:flutter/material.dart';

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmButtonText;
  final String cancelButtonText;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const ConfirmDialog({
    Key? key,
    required this.title,
    required this.content,
    required this.confirmButtonText,
    required this.cancelButtonText,
    required this.onConfirm,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: Text(cancelButtonText),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          child: Text(confirmButtonText),
        ),
      ],
    );
  }
}
