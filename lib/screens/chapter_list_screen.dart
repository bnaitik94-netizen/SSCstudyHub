import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/study_model.dart';
import '../utils/app_colors.dart';
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
    String cleanTitle = subject.name.replaceFirst(RegExp(r'^\d+\.\s*'), '');

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          cleanTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: -0.4,
          ),
        ),
        actions: [
          IconButton(
            tooltip: "Official Balbharti Books",
            icon: const Icon(Icons.school_rounded, color: AppColors.accent),
            onPressed: () => _openOfficialLibrary(context),
          ),
        ],
      ),
      body: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
        itemCount: subject.chapters.length,
        itemBuilder: (context, index) {
          final chapter = subject.chapters[index];

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: AppColors.liquidGlassCard,
            child: Material(
              color: Colors.transparent,
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                onTap: () =>
                    _openPdf(context, chapter.pdfFileName, chapter.title),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryLight.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      "${index + 1}",
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  chapter.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.35,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.picture_as_pdf_rounded,
                        size: 13,
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Balbharti Textbook Chapter",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: "AI Chapter Study Guide & Formulas",
                      icon: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Color(0xFFA855F7),
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 34, minHeight: 34),
                      onPressed: () => AiChapterGuideSheet.show(
                        context,
                        chapter.title,
                        subject.name,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: AppColors.accent,
                        size: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
              .animate()
              .fadeIn(
                  delay:
                      Duration(milliseconds: 25 * (index < 12 ? index : 12)))
              .slideX(begin: 0.05);
        },
      ),
    );
  }
}
