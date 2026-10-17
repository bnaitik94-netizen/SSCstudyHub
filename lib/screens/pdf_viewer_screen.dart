import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/app_colors.dart';
import '../widgets/ai_chapter_guide_sheet.dart';

class PdfViewerScreen extends StatefulWidget {
  final String pdfUrl;
  final String title;

  const PdfViewerScreen({
    super.key,
    required this.pdfUrl,
    required this.title,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late PdfViewerController _pdfViewerController;
  PdfTextSearchResult _searchResult = PdfTextSearchResult();

  late String _activeUrl;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  int _pageCount = 0;
  int _currentPage = 1;
  bool _isSearchOpen = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _activeUrl = widget.pdfUrl;
    _pdfViewerController = PdfViewerController();
  }

  @override
  void dispose() {
    _pdfViewerController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _launchUrlString(String url) async {
    final uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Unable to open link: $url"),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _openOfficialBalbharti() {
    HapticFeedback.lightImpact();
    // Official Maharashtra State Board Textbook Bureau Portal
    _launchUrlString("https://books.ebalbharati.in/");
  }

  void _searchChapterOnline() {
    HapticFeedback.lightImpact();
    final query = "Maharashtra State Board Class 10 ${widget.title} textbook PDF";
    final searchUrl = "https://www.google.com/search?q=${Uri.encodeComponent(query)}";
    _launchUrlString(searchUrl);
  }

  void _loadSampleVerifiedPdf() {
    HapticFeedback.mediumImpact();
    setState(() {
      // Verified working Balbharti math PDF hosted on repo
      _activeUrl = "https://raw.githubusercontent.com/bnaitik94-netizen/ssc_pdfs/main/8m_1.pdf";
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });
  }

  void _showJumpToPageDialog() {
    if (_pageCount <= 1) return;
    final textController = TextEditingController(text: '$_currentPage');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF162544),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0x3338BDF8), width: 1.2),
        ),
        title: const Text(
          "Jump to Page",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Enter page number between 1 and $_pageCount",
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0x33000000),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.accent),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.accent, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              final target = int.tryParse(textController.text.trim());
              if (target != null && target >= 1 && target <= _pageCount) {
                _pdfViewerController.jumpToPage(target);
                Navigator.pop(ctx);
              }
            },
            child: const Text("Go", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B1E),
      appBar: AppBar(
        backgroundColor: const Color(0xCC0B1028),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: _isSearchOpen
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: "Search in document...",
                  hintStyle: TextStyle(color: Colors.white54, fontSize: 14),
                  border: InputBorder.none,
                ),
                onSubmitted: (query) {
                  if (query.trim().isNotEmpty) {
                    _searchResult = _pdfViewerController.searchText(query.trim());
                    setState(() {});
                  }
                },
              )
            : Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
        actions: [
          if (_isSearchOpen) ...[
            if (_searchResult.totalInstanceCount > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Center(
                  child: Text(
                    "${_searchResult.currentInstanceIndex}/${_searchResult.totalInstanceCount}",
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.navigate_before_rounded, color: Colors.white),
              onPressed: () => _searchResult.previousInstance(),
            ),
            IconButton(
              icon: const Icon(Icons.navigate_next_rounded, color: Colors.white),
              onPressed: () => _searchResult.nextInstance(),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white70),
              onPressed: () {
                _searchResult.clear();
                _searchController.clear();
                setState(() => _isSearchOpen = false);
              },
            ),
          ] else ...[
            IconButton(
              tooltip: "AI Chapter Study Guide & Formulas",
              icon: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFA855F7)),
              onPressed: () => AiChapterGuideSheet.show(context, widget.title),
            ),
            if (!_hasError)
              IconButton(
                tooltip: "Search document",
                icon: const Icon(Icons.search_rounded, color: Colors.white70),
                onPressed: () => setState(() => _isSearchOpen = true),
              ),
            IconButton(
              tooltip: "Official Balbharti Portal",
              icon: const Icon(Icons.school_rounded, color: AppColors.accent),
              onPressed: _openOfficialBalbharti,
            ),
          ],
        ],
      ),
      body: Stack(
        children: [
          SfPdfViewer.network(
            _activeUrl,
            controller: _pdfViewerController,
            canShowScrollHead: true,
            canShowScrollStatus: true,
            canShowPaginationDialog: true,
            onDocumentLoaded: (PdfDocumentLoadedDetails details) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _hasError = false;
                  _pageCount = details.document.pages.count;
                  _currentPage = 1;
                });
              }
            },
            onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _hasError = true;
                  _errorMessage = details.error;
                });
              }
            },
            onPageChanged: (PdfPageChangedDetails details) {
              if (mounted && _currentPage != details.newPageNumber) {
                setState(() {
                  _currentPage = details.newPageNumber;
                });
              }
            },
          ),

          // ⏳ LOADING OVERLAY
          if (_isLoading)
            Container(
              color: const Color(0xEE070B1E),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Loading Study PDF...",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "Connecting to Balbharti repository",
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

          // 🌟 RESILIENT FALLBACK CONSOLE (When remote file is uploading or network issue)
          if (_hasError)
            Container(
              color: const Color(0xFC070B1E),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.2),
                              blurRadius: 24,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          color: AppColors.accent,
                          size: 46,
                        ),
                      ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),

                      const SizedBox(height: 20),

                      Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.4,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.info_outline_rounded, size: 14, color: AppColors.accent),
                            SizedBox(width: 6),
                            Text(
                              "Balbharti SSC Maharashtra Board",
                              style: TextStyle(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF162544),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              "This chapter is currently being synchronized with the cloud repository by your instructor. In the meantime, you can access the full official textbook directly on the Balbharti Portal or view online with one tap.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                            if (_errorMessage.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                "Server status: $_errorMessage",
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Action 0: 🤖 Read AI Chapter Study Guide & Formulas
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF9333EA), Color(0xFF4F46E5)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF9333EA).withValues(alpha: 0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.auto_awesome_rounded, size: 20),
                          label: const Text(
                            "🤖 Generate Chapter Notes & Formulas with AI",
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5),
                          ),
                          onPressed: () => AiChapterGuideSheet.show(context, widget.title),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Action 1: Official Balbharti Portal
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white24, width: 1.2),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.open_in_new_rounded, size: 18),
                          label: const Text(
                            "Open Official Balbharti Portal",
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                          onPressed: _openOfficialBalbharti,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Action 2: Direct Google Chapter Search
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.accent,
                            side: const BorderSide(color: AppColors.accent, width: 1.2),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.search_rounded, size: 18),
                          label: const Text(
                            "Search & Read Chapter Online",
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                          onPressed: _searchChapterOnline,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Action 3: Retry & Test PDF
                      Row(
                        children: [
                          Expanded(
                            child: TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white70,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: const Text("Retry Connection"),
                              onPressed: () {
                                setState(() {
                                  _isLoading = true;
                                  _hasError = false;
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.accent,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                              label: const Text("Test Working PDF"),
                              onPressed: _loadSampleVerifiedPdf,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 📄 FLOATING LIQUID GLASS CONTROLS (Active Document)
          if (!_isLoading && !_hasError && _pageCount > 0)
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xCC0B1028),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0x4D38BDF8), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.45),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        blurRadius: 20,
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_rounded, color: Colors.white, size: 18),
                        onPressed: () {
                          if (_pdfViewerController.zoomLevel > 1.0) {
                            _pdfViewerController.zoomLevel =
                                (_pdfViewerController.zoomLevel - 0.25).clamp(1.0, 3.0);
                          }
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                      GestureDetector(
                        onTap: _showJumpToPageDialog,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0x3338BDF8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0x4D38BDF8), width: 1),
                          ),
                          child: Text(
                            "Page $_currentPage / $_pageCount",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                        onPressed: () {
                          if (_pdfViewerController.zoomLevel < 3.0) {
                            _pdfViewerController.zoomLevel =
                                (_pdfViewerController.zoomLevel + 0.25).clamp(1.0, 3.0);
                          }
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
