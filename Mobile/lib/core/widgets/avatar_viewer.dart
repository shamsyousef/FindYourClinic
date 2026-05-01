import 'package:flutter/material.dart';

class AvatarViewer extends StatelessWidget {
  final ImageProvider imageProvider;
  final String? tag;

  const AvatarViewer({
    super.key,
    required this.imageProvider,
    this.tag,
  });

  static void show(BuildContext context, ImageProvider imageProvider, {String? tag}) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black,
        pageBuilder: (context, _, __) => AvatarViewer(imageProvider: imageProvider, tag: tag),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Center(
          child: Hero(
            tag: tag ?? 'avatar_${imageProvider.hashCode}',
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image(
                image: imageProvider,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
