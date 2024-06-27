import 'package:flutter/material.dart';

class PublicScreen extends StatefulWidget {
  static const routeName = '/PublicScreen';
  const PublicScreen({super.key});

  @override
  State<PublicScreen> createState() => _PublicScreenState();
}

class _PublicScreenState extends State<PublicScreen> {
  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Center(
          child: Text('Public Screen'),
        ),
        SizedBox(
          height: 20,
        ),
        CircularProgressIndicator(),
      ],
    );
  }
}
