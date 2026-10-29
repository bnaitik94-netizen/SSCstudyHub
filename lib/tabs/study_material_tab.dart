import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/syllabus_data.dart';
import '../models/study_model.dart';
import '../utils/app_colors.dart';
import '../screens/chapter_list_screen.dart';

class StudyMaterialTab extends StatefulWidget {
  const StudyMaterialTab({super.key});

  @override
  State<StudyMaterialTab> createState() => _StudyMaterialTabState();
}

class _StudyMaterialTabState extends State<StudyMaterialTab> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'All',
    'Mathematics',
    'Sciences',
    'Social Studies',
    'Languages',
  ];

  IconData _getCategoryIcon(String cat) {
    switch (cat) {
      case 'Mathematics':
        return Icons.calculate_rounded;
      case 'Sciences':
        return Icons.biotech_rounded;
      case 'Social Studies':
        return Icons.public_rounded;
      case 'Languages':
        return Icons.translate_rounded;
      default:
        return Icons.grid_view_rounded;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  bool _matchesCategory(Subject subject, String category) {
    final lower = subject.name.toLowerCase();
    switch (category) {
      case 'Mathematics':
        return lower.contains('math') || lower.contains('algebra') || lower.contains('geo');
      case 'Sciences':
        return lower.contains('science');
      case 'Social Studies':
        return lower.contains('itihas') || lower.contains('history') || lower.contains('bhugol') || lower.contains('geography') || lower.contains('rajyashastra');
      case 'Languages':
        return lower.contains('marathi') || lower.contains('english') || lower.contains('hindi');
      default:
        return true;
    }
  }

  SubjectStyle _getSubjectStyle(String subjectName) {
    final lower = subjectName.toLowerCase();
    if (lower.contains('math') || lower.contains('algebra')) {
      return const SubjectStyle(
        categoryTag: "FORMULAS & THEOREMS",
        primaryColor: Color(0xFF0284C7),
        accentColor: Color(0xFF38BDF8),
        icon: Icons.calculate_rounded,
      );
    }
    if (lower.contains('geo') && !lower.contains('bhugol') && !lower.contains('geography')) {
      return const SubjectStyle(
        categoryTag: "CONSTRUCTIONS & PROOFS",
        primaryColor: Color(0xFF2563EB),
        accentColor: Color(0xFF60A5FA),
        icon: Icons.architecture_rounded,
      );
    }
    if (lower.contains('science')) {
      return const SubjectStyle(
        categoryTag: "EXPERIMENTS & THEORY",
        primaryColor: Color(0xFF059669),
        accentColor: Color(0xFF34D399),
        icon: Icons.biotech_rounded,
      );
    }
    if (lower.contains('itihas') || lower.contains('history')) {
      return const SubjectStyle(
        categoryTag: "HISTORICAL TIMELINE",
        primaryColor: Color(0xFFD97706),
        accentColor: Color(0xFFFBBF24),
        icon: Icons.history_edu_rounded,
      );
    }
    if (lower.contains('bhugol') || lower.contains('geography')) {
      return const SubjectStyle(
        categoryTag: "MAPS & CLIMATE",
        primaryColor: Color(0xFF0D9488),
        accentColor: Color(0xFF2DD4BF),
        icon: Icons.public_rounded,
      );
    }
    return const SubjectStyle(
      categoryTag: "GRAMMAR & LITERATURE",
      primaryColor: Color(0xFFE11D48),
      accentColor: Color(0xFFFB7185),
      icon: Icons.menu_book_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    const allSubjects = SyllabusData.semiClass10;
    final filteredSubjects = allSubjects.where((subject) {
      final matchesCat = _matchesCategory(subject, _selectedCategory);
      if (!matchesCat) return false;
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final nameMatches = subject.name.toLowerCase().contains(q);
      final chapterMatches = subject.chapters.any((c) => c.title.toLowerCase().contains(q));
      return nameMatches || chapterMatches;
    }).toList();

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          // 1. TOP HEADER & OFFICIAL BALBHARTI PORTAL PILL
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primaryLight.withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_rounded, size: 14, color: AppColors.accent),
                            SizedBox(width: 5),
                            Text(
                              "MAHARASHTRA STATE BOARD",
                              style: TextStyle(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w800,
                                fontSize: 10.5,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _openOfficialLibrary(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.20),
                                width: 1,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.open_in_new_rounded, size: 12, color: Colors.white),
                                SizedBox(width: 5),
                                Text(
                                  "Balbharti E-Library",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Syllabus Explorer",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "SSC Class 10 • All official textbook PDFs & chapter solutions",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. REAL-TIME SEARCH BAR
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.surfaceCardBorder,
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white, fontSize: 13.5),
                      onChanged: (val) {
                        setState(() => _searchQuery = val.trim());
                      },
                      decoration: InputDecoration(
                        hintText: "Search subjects or chapter names...",
                        hintStyle: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(Icons.search_rounded,
                            size: 20, color: AppColors.accent),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded,
                                    size: 16, color: Colors.white70),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 3. RESPONSIVE CATEGORY TABS
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final bool isWide = constraints.maxWidth >= 600;
                      if (isWide) {
                        return Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Row(
                            children: _categories.map((cat) {
                              final bool isSelected = cat == _selectedCategory;
                              final IconData icon = _getCategoryIcon(cat);

                              return Expanded(
                                child: InkWell(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() => _selectedCategory = cat);
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(vertical: 9),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: AppColors.primary.withValues(alpha: 0.4),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          icon,
                                          size: 15,
                                          color: isSelected ? Colors.white : Colors.white70,
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            cat,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                              color: isSelected ? Colors.white : Colors.white70,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      } else {
                        return SizedBox(
                          height: 38,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: _categories.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, idx) {
                              final cat = _categories[idx];
                              final isSelected = cat == _selectedCategory;
                              final IconData icon = _getCategoryIcon(cat);

                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() => _selectedCategory = cat);
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary
                                          : Colors.white.withValues(alpha: 0.07),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.accent
                                            : Colors.white.withValues(alpha: 0.15),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          icon,
                                          size: 14,
                                          color: isSelected ? Colors.white : Colors.white70,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          cat,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                            color: isSelected ? Colors.white : Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          // 4. SUBJECTS GRID
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            sliver: filteredSubjects.isEmpty
                ? SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      margin: const EdgeInsets.symmetric(vertical: 24),
                      decoration: AppColors.liquidGlassCard,
                      child: const Column(
                        children: [
                          Icon(Icons.search_off_rounded, size: 40, color: Colors.white38),
                          SizedBox(height: 12),
                          Text(
                            "No matching subjects found",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Try searching for another chapter or clear the category filter.",
                            style: TextStyle(color: Colors.white54, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.of(context).size.width >= 850 ? 4 : 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: MediaQuery.of(context).size.width >= 850 ? 1.05 : 0.88,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final subject = filteredSubjects[index];
                        final style = _getSubjectStyle(subject.name);
                        final cleanTitle = subject.name.replaceFirst(RegExp(r'^\d+\.\s*'), '');

                        return RepaintBoundary(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChapterListScreen(subject: subject),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(22),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceCard,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: style.accentColor.withValues(alpha: 0.35),
                                    width: 1.0,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x26000000),
                                      blurRadius: 8,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Header with Tag and Icon
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: style.primaryColor.withValues(alpha: 0.35),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: style.accentColor.withValues(alpha: 0.6),
                                              width: 1,
                                            ),
                                          ),
                                          child: Icon(
                                            style.icon,
                                            color: Colors.white,
                                            size: 22,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.35),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            "${subject.chapters.length} Ch",
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w800,
                                              color: style.accentColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Title & Category tag
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          style.categoryTag,
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.5,
                                            color: style.accentColor.withValues(alpha: 0.85),
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          cleanTitle,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                            height: 1.25,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Text(
                                              "View Notes",
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white.withValues(alpha: 0.8),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              Icons.arrow_forward_rounded,
                                              size: 13,
                                              color: style.accentColor,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: filteredSubjects.length,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class SubjectStyle {
  final String categoryTag;
  final Color primaryColor;
  final Color accentColor;
  final IconData icon;

  const SubjectStyle({
    required this.categoryTag,
    required this.primaryColor,
    required this.accentColor,
    required this.icon,
  });
}
