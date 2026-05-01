import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'avatar_viewer.dart';

class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? initials;
  final String? fullName;
  final double radius;
  final Color? backgroundColor;
  final TextStyle? textStyle;
  final bool showBorder;
  final Color? borderColor;
  final bool enableViewer;

  const UserAvatar({
    super.key,
    this.imageUrl,
    this.initials,
    this.fullName,
    this.radius = 24,
    this.backgroundColor,
    this.textStyle,
    this.showBorder = false,
    this.borderColor,
    this.enableViewer = true,
  });

  String _getInitials() {
    if (initials != null && initials!.isNotEmpty) return initials!;
    if (fullName == null || fullName!.isEmpty) return '?';

    final parts = fullName!.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayInitials = _getInitials();
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    
    final imageProvider = hasImage ? CachedNetworkImageProvider(imageUrl!) : null;
    final heroTag = 'avatar_${imageUrl ?? displayInitials}_${radius}_${hashCode}';

    Widget avatar = Hero(
      tag: heroTag,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? colorScheme.primary,
        backgroundImage: imageProvider,
        child: !hasImage
            ? Text(
                displayInitials,
                style: textStyle ??
                    TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: radius * 0.8,
                    ),
              )
            : null,
      ),
    );

    if (enableViewer && hasImage) {
      avatar = GestureDetector(
        onTap: () => AvatarViewer.show(context, imageProvider!, tag: heroTag),
        child: avatar,
      );
    }

    if (showBorder) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: borderColor ?? colorScheme.surface,
            width: 2,
          ),
        ),
        child: avatar,
      );
    }

    return avatar;
  }
}
