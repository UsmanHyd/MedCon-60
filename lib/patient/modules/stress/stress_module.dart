import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'package:medcon30/theme/theme_provider.dart';

class StressModulesScreen extends ConsumerStatefulWidget {
  const StressModulesScreen({super.key});

  @override
  ConsumerState<StressModulesScreen> createState() => _StressModulesScreenState();
}

class _StressModulesScreenState extends ConsumerState<StressModulesScreen> {
  int _selectedFilter = 0;
  final List<String> _filters = ['All', 'Popular', 'Recent', 'Difficulty'];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = provider_pkg.Provider.of<ThemeProvider>(context).isDarkMode;
    final bgColor =
        isDarkMode ? const Color(0xFF121212) : const Color(0xFFE0F7FA);
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final subTextColor =
        isDarkMode ? const Color(0xFFB0B0B0) : const Color(0xFF757575);
    final shadowColor = isDarkMode
        ? Colors.black.withOpacity(0.2)
        : Colors.grey.withOpacity(0.08);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilterChips(isDarkMode),
            const SizedBox(height: 10),
            _buildSearchBar(isDarkMode),
            const SizedBox(height: 18),
            _sectionTitle('Breathing Exercises', textColor),
            _moduleGrid([
              _moduleCard(
                  'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=500&q=80',
                  'Deep Breathing',
                  'Slow, deep breaths to calm your nervous system',
                  0.75,
                  isDarkMode: isDarkMode,
                  cardColor: cardColor,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  shadowColor: shadowColor),
              _moduleCard(
                  'https://d3srkhfokg8sj0.cloudfront.net/wp-content/uploads/sites/669/featured-5-anxiety-696x313.jpg',
                  'Box Breathing',
                  'Equal inhale, hold, exhale pattern',
                  0.3,
                  isDarkMode: isDarkMode,
                  cardColor: cardColor,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  shadowColor: shadowColor),
              _moduleCard(
                  'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=500&q=80',
                  '4-7-8 Technique',
                  'Timed breathing for relaxation',
                  null,
                  isNew: true,
                  isDarkMode: isDarkMode,
                  cardColor: cardColor,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  shadowColor: shadowColor),
            ]),
            const SizedBox(height: 18),
            _sectionTitle('Meditation', textColor),
            _moduleGrid([
              _moduleCard(
                  'https://images.unsplash.com/photo-1508672019048-805c876b67e2?w=500&q=80',
                  'Guided Meditation',
                  'Voice-guided relaxation sessions',
                  0.5,
                  isDarkMode: isDarkMode,
                  cardColor: cardColor,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  shadowColor: shadowColor),
              _moduleCard(
                  'https://images.unsplash.com/photo-1512438248247-f0f2a5a8b7f0?w=500&q=80',
                  'Mindfulness',
                  'Present-moment awareness practice',
                  0.25,
                  isDarkMode: isDarkMode,
                  cardColor: cardColor,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  shadowColor: shadowColor),
              _moduleCard(
                  'https://overcomingms.org/wp-content/uploads/2022/05/Meditation-videos.png',
                  'Body Scan',
                  'Systematic relaxation technique',
                  null,
                  isNew: true,
                  isDarkMode: isDarkMode,
                  cardColor: cardColor,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  shadowColor: shadowColor),
            ]),
            const SizedBox(height: 18),
            _sectionTitle('Physical Activities', textColor),
            _moduleGrid([
              _moduleCard(
                  'https://images.unsplash.com/photo-1575052814086-f385e2e2ad1b?w=500&q=80',
                  'Stretching',
                  'Gentle stretches for tension relief',
                  0.6,
                  isDarkMode: isDarkMode,
                  cardColor: cardColor,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  shadowColor: shadowColor),
              _moduleCard(
                  'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=500&q=80',
                  'Muscle Relaxation',
                  'Tense and release muscle groups',
                  0.4,
                  isDarkMode: isDarkMode,
                  cardColor: cardColor,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  shadowColor: shadowColor),
              _moduleCard(
                  'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=500&q=80',
                  'Quick Exercises',
                  'Short activities for busy days',
                  0.15,
                  isDarkMode: isDarkMode,
                  cardColor: cardColor,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  shadowColor: shadowColor),
            ]),
            const SizedBox(height: 18),
            _sectionTitle('Sleep Improvement', textColor),
            _moduleGrid([
              _moduleCard(
                  'https://assets.clevelandclinic.org/transform/LargeFeatureImage/92ea470e-f918-4e3f-8ca0-bd57663497e7/cihld-sleep-school-1090567386-770x533-1_jpg',
                  'Bedtime Routine',
                  'Establish healthy sleep habits',
                  0.2,
                  isDarkMode: isDarkMode,
                  cardColor: cardColor,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  shadowColor: shadowColor),
              _moduleCard(
                  'https://www.artofliving.org/sites/www.artofliving.org/files/styles/original_image/public/wysiwyg_imageupload/1-MeditationForSleep.jpg.webp?itok=RI2y_KFp',
                  'Sleep Meditation',
                  'Guided relaxation for better sleep',
                  null,
                  isNew: true,
                  isDarkMode: isDarkMode,
                  cardColor: cardColor,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  shadowColor: shadowColor),
              _moduleCard(
                  'https://www.happiesthealth.com/wp-content/uploads/2022/12/Relaxation-techniques.jpg',
                  'Relaxation Techniques',
                  'Methods to calm mind before sleep',
                  0.35,
                  isDarkMode: isDarkMode,
                  cardColor: cardColor,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  shadowColor: shadowColor),
            ]),
            const SizedBox(height: 18),
            _sectionTitle('Stress Education', textColor),
            _moduleGrid([
              _moduleCard(
                  'https://iimtu.edu.in/blog/wp-content/uploads/2023/11/Stress-1-1.png',
                  'Understanding Stress',
                  'Learn how stress affects your body',
                  0.8,
                  isDarkMode: isDarkMode,
                  cardColor: cardColor,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  shadowColor: shadowColor),
              _moduleCard(
                  'https://blog.mdi-training.com/wp-content/uploads/2020/11/shutterstock_632448815.png',
                  'Coping Strategies',
                  'Effective ways to handle stress',
                  0.45,
                  isDarkMode: isDarkMode,
                  cardColor: cardColor,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  shadowColor: shadowColor),
              _moduleCard(
                  'https://static.twentyoverten.com/5cf91870d904cf2044d861a6/ej8sMMog71c/work-stress.jpg',
                  'Stress Triggers',
                  'Identify your personal stressors',
                  0.1,
                  isDarkMode: isDarkMode,
                  cardColor: cardColor,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  shadowColor: shadowColor),
            ]),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(bool isDarkMode) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_filters.length, (index) {
          final selected = _selectedFilter == index;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(_filters[index]),
              selected: selected,
              onSelected: (_) {
                setState(() => _selectedFilter = index);
              },
              selectedColor: const Color(0xFF7B61FF),
              backgroundColor: isDarkMode
                  ? const Color(0xFF2C2C2C)
                  : const Color(0xFFF3F1FF),
              labelStyle: TextStyle(
                color: selected
                    ? Colors.white
                    : (isDarkMode ? Colors.white : Colors.black),
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSearchBar(bool isDarkMode) {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search modules',
        hintStyle: TextStyle(
            color:
                isDarkMode ? const Color(0xFFB0B0B0) : const Color(0xFF757575)),
        prefixIcon: const Icon(Icons.search, color: Color(0xFF7B61FF)),
        filled: true,
        fillColor: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
            fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
      ),
    );
  }

  Widget _moduleGrid(List<Widget> cards) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards
              .map((card) => SizedBox(
                    width: (constraints.maxWidth - 12) / 2,
                    child: card,
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _moduleCard(
    String imagePath,
    String title,
    String subtitle,
    double? progress, {
    bool isNew = false,
    required bool isDarkMode,
    required Color cardColor,
    required Color textColor,
    required Color subTextColor,
    required Color shadowColor,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => Scaffold(
              backgroundColor: cardColor,
              appBar: AppBar(
                title: Text(title, style: TextStyle(color: textColor)),
                backgroundColor: cardColor,
                foregroundColor: textColor,
                elevation: 0,
                scrolledUnderElevation: 0,
                surfaceTintColor: cardColor,
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imagePath,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: double.infinity,
                            height: 200,
                            color: isDarkMode
                                ? const Color(0xFF2C2C2C)
                                : Colors.grey[200],
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                color: const Color(0xFF7B61FF),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: double.infinity,
                            height: 200,
                            color: isDarkMode
                                ? const Color(0xFF2C2C2C)
                                : Colors.grey[200],
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 50,
                                  color: isDarkMode
                                      ? const Color(0xFFB0B0B0)
                                      : Colors.grey[400],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Image not available',
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? const Color(0xFFB0B0B0)
                                        : Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 16,
                        color: subTextColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (progress != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Progress',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: progress,
                            backgroundColor: isDarkMode
                                ? const Color(0xFF2C2C2C)
                                : const Color(0xFFF3F1FF),
                            valueColor:
                                const AlwaysStoppedAnimation(Color(0xFF7B61FF)),
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${(progress * 100).toInt()}% completed',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF7B61FF),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        // TODO: Implement module start functionality
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7B61FF),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Start Module',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imagePath,
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 100,
                    width: double.infinity,
                    color:
                        isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey[200],
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        color: const Color(0xFF7B61FF),
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 100,
                    width: double.infinity,
                    color:
                        isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey[200],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_not_supported_outlined,
                          size: 30,
                          color: isDarkMode
                              ? const Color(0xFFB0B0B0)
                              : Colors.grey[400],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Image not available',
                          style: TextStyle(
                            color: isDarkMode
                                ? const Color(0xFFB0B0B0)
                                : Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14, color: textColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: subTextColor),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            if (progress != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: isDarkMode
                        ? const Color(0xFF2C2C2C)
                        : const Color(0xFFF3F1FF),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF7B61FF)),
                    minHeight: 5,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF7B61FF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            else if (isNew)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF7B61FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'New',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF7B61FF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
