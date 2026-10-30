import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/widgets/app_widgets.dart';
import '../services/notification_service.dart';
import 'main_dashboard.dart';

class NameInputScreen extends StatefulWidget {
  const NameInputScreen({super.key});

  @override
  State<NameInputScreen> createState() => _NameInputScreenState();
}

class _NameInputScreenState extends State<NameInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      NotificationService().syncTokenAndTopics();
    }
  }

  Future<void> _saveName() async {
    if (_isLoading) return;

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final String name = _nameController.text.trim();
    _nameFocusNode.unfocus();
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('studentName', name);
      await prefs.setString('student_name', name);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MainDashboard(studentName: name),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to save name. Please try again."),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                  vertical: AppSpacing.lg,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: AppSpacing.md),
                              const AppBadge(
                                label: "MAHARASHTRA SSC 10TH BOARD",
                                variant: AppBadgeVariant.info,
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                ),
                                child: Icon(
                                  Icons.school_rounded,
                                  size: 28,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              Text(
                                "Welcome to\nSSC Study Hub",
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                "Enter your full student name to access live broadcasts, notes, and 24/7 AI doubt assistance.",
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xxl),
                              AppTextField(
                                controller: _nameController,
                                focusNode: _nameFocusNode,
                                label: "Student Full Name",
                                hint: "e.g. Naitik Patil",
                                prefix: const Icon(Icons.person_rounded, size: 20),
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _saveName(),
                                validator: (val) {
                                  if (val == null || val.trim().length < 2) {
                                    return "Please enter a valid full name";
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Sticky bottom action button
                      SafeArea(
                        top: false,
                        child: AppButton.filled(
                          label: "Get Started",
                          isFullWidth: true,
                          isLoading: _isLoading,
                          icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                          onPressed: _saveName,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
