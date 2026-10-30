import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/study_model.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/widgets/app_widgets.dart';
import 'pdf_viewer_screen.dart';
import '../widgets/ai_chapter_guide_sheet.dart';

/// Detail Screen adhering strictly to Master UI Guidelines:
/// - Collapsing SliverAppBar with large morphing title & frosted glassmorphism.
/// - AppCard.listItem chapters with left accent bar and tactile feedback.
/// - Sticky action bar at the bottom with AppButton.primaryCta.
class ChapterListScreen extends StatelessWidget {
  final Subject subject;

  const ChapterListScreen({super.key, required this.subject});

  void _openPdf(BuildContext context, String fileName, String chapterTitle) {
    HapticFeedback.lightImpact();
    const String githubBaseUrl =
        "https://raw.githubusercontent.com/bnaitik94-netizen/ssc_pdfs/main/";

    final String fullUrl = '$githubBaseUrl$fileName';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerScreen(
          pdfUrl: fullUrl,
          title: chapterTitle,
        ),
      ),
    );
  }

  Future<void> _openOfficialLibrary(BuildContext context) async {
    HapticFeedback.lightImpact();
    final Uri uri = Uri.parse("https://books.ebalbharati.in/");
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not open external URL');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Unable to open Balbharti portal."),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String cleanTitle = subject.name.replaceFirst(RegExp(r'^\d+\.\s*'), '');

    return Scaffold(
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          // 1. COLLAPSING SLIVER APP BAR WITH GLASSMORPHISM
          AppSliverAppBar(
            title: cleanTitle,
            subtitle: "${subject.chapters.length} Chapters • Maharashtra State Board",
            expandedHeight: 140.0,
            leading: AppIconButton(
              icon: Icons.arrow_back_rounded,
              tooltip: "Back",
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              AppIconButton(
                icon: Icons.school_rounded,
                tooltip: "Official Balbharti Books",
                onPressed: () => _openOfficialLibrary(context),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
          ),

          // 2. CHAPTERS LIST BODY
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenHorizontal,
              AppSpacing.md,
              AppSpacing.screenHorizontal,
              90, // Leave room for sticky bottom action bar
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final chapter = subject.chapters[index];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.listItemGap),
                    child: RepaintBoundary(
                      child: AppCard.listItem(
                        onTap: () => _openPdf(context, chapter.pdfFileName, chapter.title),
                        leading: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primaryAccent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: Center(
                            child: Text(
                              "${index + 1}",
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: AppColors.primaryAccent,
                              ),
                            ),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppIconButton(
                              icon: Icons.auto_awesome_rounded,
                              size: 18,
                              color: AppColors.primaryAccent,
                              tooltip: "AI Chapter Study Guide & Formulas",
                              onPressed: () => AiChapterGuideSheet.show(
                                context,
                                chapter.title,
                                subject.name,
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              chapter.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Balbharti Textbook Chapter",
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                childCount: subject.chapters.length,
              ),
            ),
          ),
        ],
      ),

      // 3. STICKY ACTION BAR AT BOTTOM (Always visible)
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            border: Border(
              top: BorderSide(
                color: theme.brightness == Brightness.dark
                    ? AppColors.dividerDark
                    : AppColors.dividerLight,
              ),
            ),
          ),
          child: AppButton.primaryCta(
            label: "Open Balbharti Official Portal",
            height: 52,
            icon: const Icon(Icons.open_in_new_rounded, size: 18),
            onPressed: () => _openOfficialLibrary(context),
          ),
        ),
      ),
    );
  }
}
