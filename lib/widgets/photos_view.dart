import 'package:flutter/material.dart';

class PhotosView extends StatelessWidget {
  final String tricountId;

  const PhotosView({
    super.key,
    required this.tricountId,
  });

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Vue Photos'),
    );
  }
}
