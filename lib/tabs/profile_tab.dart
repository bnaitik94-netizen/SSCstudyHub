import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../screens/developer_info_screen.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/widgets/app_widgets.dart';
import '../services/notification_service.dart';

class ProfileTab extends StatefulWidget {
  final String studentName;
  final ValueChanged<String>? onNameUpdated;

  const ProfileTab({
    super.key,
    required this.studentName,
    this.onNameUpdated,
  });

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  late String _currentName;

  @override
  void initState() {
    super.initState();
    _currentName = widget.studentName;
  }

  @override
  void didUpdateWidget(covariant ProfileTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.studentName != widget.studentName) {
      _currentName = widget.studentName;
    }
  }

  void _showEditNameDialog() {
    HapticFeedback.lightImpact();
    final textController = TextEditingController(text: _currentName);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Edit Student Name"),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Enter your full name as registered for your SSC Maharashtra Board studies:",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                controller: textController,
                autofocus: true,
                label: "Student Name",
                hint: "e.g. Naitik Patil",
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return "Name cannot be empty";
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          AppButton.text(
            label: "Cancel",
            onPressed: () => Navigator.pop(ctx),
          ),
          AppButton.filled(
            label: "Save",
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                final newName = textController.text.trim();
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('studentName', newName);
                await prefs.setString('student_name', newName);

                setState(() => _currentName = newName);
                widget.onNameUpdated?.call(newName);

                if (ctx.mounted) Navigator.pop(ctx);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Name updated successfully!"),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _launchExternalUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not open external URL');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Unable to open link."),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: ClampingScrollPhysics(),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
              vertical: AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. STUDENT AVATAR & NAME
                AppAvatar(
                  name: _currentName,
                  size: 80,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        _currentName,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      tooltip: "Edit name",
                      onPressed: _showEditNameDialog,
                    ),
                  ],
                ),
                const AppBadge(
                  label: "SSC 10th Board Student",
                  variant: AppBadgeVariant.info,
                ),
                const SizedBox(height: AppSpacing.xl),

                // 2. QUICK STATS
                AppCard(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.md,
                    horizontal: AppSpacing.lg,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(context, "Board", "Maharashtra", Icons.school_rounded),
                      const AppDivider(isVertical: true),
                      _buildStatItem(context, "Class", "10th Semi", Icons.menu_book_rounded),
                      const AppDivider(isVertical: true),
                      _buildStatItem(context, "Status", "Active", Icons.verified_rounded, isAccent: true),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // 3. NOTIFICATION & SYNC DIAGNOSTICS
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.notifications_active_rounded,
                                size: 18,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                'Live Class Alerts',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          ValueListenableBuilder<bool>(
                            valueListenable: NotificationService.isRegisteredNotifier,
                            builder: (context, isRegistered, _) {
                              return AppBadge(
                                label: isRegistered ? "Connected" : "Syncing",
                                variant: isRegistered
                                    ? AppBadgeVariant.success
                                    : AppBadgeVariant.warning,
                                icon: Icon(
                                  isRegistered ? Icons.check_circle_rounded : Icons.sync_rounded,
                                  size: 10,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        "Receive instant alerts when the teacher starts a live class or makes an important study announcement.",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton.outlined(
                              label: "Test Alert",
                              icon: const Icon(Icons.send_rounded, size: 14),
                              onPressed: () async {
                                HapticFeedback.lightImpact();
                                await NotificationService().showNativeNotificationFromDart(
                                  title: "SSC Study Hub Pro 🔔",
                                  body: "Device notification system is 100% active and connected!",
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Test notification sent to phone drawer!"),
                                      duration: Duration(seconds: 3),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: AppButton.filled(
                              label: "Sync Token",
                              icon: const Icon(Icons.cloud_sync_rounded, size: 15),
                              onPressed: () async {
                                HapticFeedback.mediumImpact();
                                await NotificationService().syncTokenAndTopics(maxRetries: 5);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Device token successfully registered in cloud!"),
                                      duration: Duration(seconds: 3),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // 4. LEARNING PORTALS
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.auto_stories_rounded,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Direct Learning Portals',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      InkWell(
                        onTap: () => _launchExternalUrl("https://books.ebalbharati.in/"),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                          child: _buildInfoRow(
                            context,
                            Icons.library_books_rounded,
                            'Official eBalbharti Library',
                            'Maharashtra State Board Portal',
                            trailing: const Icon(Icons.open_in_new_rounded, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // 5. APPLICATION INFORMATION
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Application Information',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DeveloperInfoScreen(),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                          child: _buildInfoRow(
                            context,
                            Icons.code_rounded,
                            'Developed By',
                            'Mr. Naitik Bobade',
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                          ),
                        ),
                      ),
                      const AppDivider(),
                      _buildInfoRow(
                        context,
                        Icons.build_circle_rounded,
                        'Version',
                        'SSC Study Hub 4.0.0 Pro',
                      ),
                      const AppDivider(),
                      _buildInfoRow(
                        context,
                        Icons.security_rounded,
                        'Security & Live Sync',
                        'Secured & Connected',
                        isSuccess: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    bool isAccent = false,
  }) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(
          icon,
          size: 18,
          color: isAccent ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: isAccent ? theme.colorScheme.primary : theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String title,
    String value, {
    bool isSuccess = false,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 18,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isSuccess ? AppColors.success : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }
}
