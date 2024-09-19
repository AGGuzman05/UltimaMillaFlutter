// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

Widget customShimmer() {
  return ListView.builder(
    itemCount: 10,
    itemBuilder: (context, index) {
      return Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: ListTile(
          title: Container(
            width: double.infinity,
            height: 26.0,
            color: Colors.white,
          ),
          subtitle: Container(
            width: double.infinity,
            height: 24.0,
            color: Colors.white,
          ),
        ),
      );
    },
  );
}
