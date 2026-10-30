import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/study_model.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/widgets/app_widgets.dart';
import 'pdf_viewer_screen.dart';
import '../widgets/ai_chapter_guide_sheet.dart';

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
      appBar: AppBar(
        title: Text(cleanTitle),
        actions: [
          IconButton(
            tooltip: "Official Balbharti Books",
            icon: const Icon(Icons.school_rounded),
            onPressed: () => _openOfficialLibrary(context),
          ),
        ],
      ),
      body: ListView.separated(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal,
          vertical: AppSpacing.md,
        ),
        itemCount: subject.chapters.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.listItemGap),
        itemBuilder: (context, index) {
          final chapter = subject.chapters[index];

          return RepaintBoundary(
            child: AppCard(
              onTap: () => _openPdf(context, chapter.pdfFileName, chapter.title),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Center(
                      child: Text(
                        "${index + 1}",
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
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
                        Row(
                          children: [
                            Icon(
                              Icons.picture_as_pdf_rounded,
                              size: 13,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "Balbharti Textbook Chapter",
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: "AI Chapter Study Guide & Formulas",
                    icon: const Icon(
                      Icons.auto_awesome_rounded,
                      size: 20,
                    ),
                    onPressed: () => AiChapterGuideSheet.show(
                      context,
                      chapter.title,
                      subject.name,
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
