import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.username,
    required this.friendCode,
    required this.avatar,
    required this.onCopy,
    required this.primaryAction,
    this.moreAction,
  });

  final String username;
  final String friendCode;
  final ImageProvider avatar;
  final VoidCallback onCopy;
  final Widget primaryAction;
  final Widget? moreAction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder:
          (context, constraints) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(radius: 42, backgroundImage: avatar),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      username,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Tooltip(
                            message: friendCode,
                            child: Text(
                              friendCode,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: onCopy,
                          tooltip: 'Copy friend code',
                          icon: const Icon(Icons.copy, size: 18),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      primaryAction,
                      if (moreAction != null) ...[
                        const SizedBox(width: 4),
                        moreAction!,
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
    );
  }
}
