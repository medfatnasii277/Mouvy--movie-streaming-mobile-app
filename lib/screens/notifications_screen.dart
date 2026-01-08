import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/movie_provider.dart';
import '../l10n/app_localizations.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MovieProvider>().fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.notifications, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Consumer<MovieProvider>(
        builder: (context, movieProvider, child) {
          final notifications = movieProvider.notifications;

          if (notifications.isEmpty) {
            return Center(
              child: Text(
                AppLocalizations.of(context)!.noNotifications,
                style: const TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final isRead = notification['is_read'] as bool;
              final createdAt = DateTime.parse(notification['created_at']);
              final timeAgo = _formatTimeAgo(createdAt);

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: isRead ? const Color(0xFF1A1A1A) : const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(8),
                  border: !isRead ? Border.all(color: const Color(0xFF00FF7F), width: 1) : null,
                ),
                child: ListTile(
                  title: Text(
                    notification['message'],
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    timeAgo,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  trailing: !isRead
                      ? IconButton(
                          icon: const Icon(Icons.mark_email_read, color: Color(0xFF00FF7F)),
                          onPressed: () {
                            movieProvider.markNotificationAsRead(notification['id']);
                          },
                        )
                      : null,
                  onTap: () {
                    if (!isRead) {
                      movieProvider.markNotificationAsRead(notification['id']);
                    }
                    // Could navigate to the related content
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}