import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/syllabus_data.dart';
import '../models/study_model.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/widgets/app_widgets.dart';
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
        return lower.contains('itihas') ||
            lower.contains('history') ||
            lower.contains('bhugol') ||
            lower.contains('geography') ||
            lower.contains('rajyashastra');
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
    final theme = Theme.of(context);
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
          parent: ClampingScrollPhysics(),
        ),
        slivers: [
          // ── 1. HEADER & SEARCH ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
                vertical: AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const AppBadge(
                        label: "MAHARASHTRA STATE BOARD",
                        variant: AppBadgeVariant.info,
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.open_in_new_rounded, size: 14),
                        label: const Text("Balbharti Library"),
                        onPressed: () => _openOfficialLibrary(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    "Study Materials",
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    "Official Class 10th textbooks, chapter summaries & revision notes",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Search Field
                  AppTextField(
                    controller: _searchController,
                    label: "Search syllabus",
                    hint: "Search subjects or chapter names...",
                    prefix: const Icon(Icons.search_rounded, size: 20),
                    suffix: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    onChanged: (val) {
                      setState(() => _searchQuery = val.trim());
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Category Filter Chips
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const ClampingScrollPhysics(),
                      itemCount: _categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                      itemBuilder: (context, idx) {
                        final cat = _categories[idx];
                        final isSelected = cat == _selectedCategory;

                        return ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedCategory = cat);
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── 2. SUBJECTS GRID ───────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
              vertical: AppSpacing.sm,
            ),
            sliver: filteredSubjects.isEmpty
                ? const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                      child: AppEmptyState(
                        icon: Icons.search_off_rounded,
                        title: "No subjects found",
                        subtitle: "Try another search term or clear category filters.",
                      ),
                    ),
                  )
                : SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.sizeOf(context).width >= 850 ? 4 : 2,
                      crossAxisSpacing: AppSpacing.md,
                      mainAxisSpacing: AppSpacing.md,
                      childAspectRatio: MediaQuery.sizeOf(context).width >= 850 ? 1.15 : 0.95,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final subject = filteredSubjects[index];
                        final style = _getSubjectStyle(subject.name);
                        final cleanTitle = subject.name.replaceFirst(RegExp(r'^\d+\.\s*'), '');

                        return RepaintBoundary(
                          child: AppCard(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChapterListScreen(subject: subject),
                                ),
                              );
                            },
                            padding: const EdgeInsets.all(AppSpacing.cardPadding),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(AppSpacing.sm),
                                      decoration: BoxDecoration(
                                        color: style.primaryColor.withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        style.icon,
                                        color: style.primaryColor,
                                        size: 22,
                                      ),
                                    ),
                                    AppBadge(
                                      label: "${subject.chapters.length} Ch",
                                      variant: AppBadgeVariant.neutral,
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      style.categoryTag,
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: style.primaryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      cleanTitle,
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Row(
                                      children: [
                                        Text(
                                          "View Notes",
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 12,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: filteredSubjects.length,
                    ),
                  ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.xxxl),
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
