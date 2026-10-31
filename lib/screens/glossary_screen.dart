import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/quiz_provider.dart';
import '../providers/language_provider.dart';
import '../services/tts_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class GlossaryScreen extends StatefulWidget {
  const GlossaryScreen({super.key});

  @override
  State<GlossaryScreen> createState() => _GlossaryScreenState();
}

class _GlossaryScreenState extends State<GlossaryScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    TTSService.init();
  }

  @override
  void dispose() {
    TTSService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quizProvider = Provider.of<QuizProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);
    final lang = langProvider.langCode;

    final filteredItems = quizProvider.glossaryItems.where((item) {
      final q = _searchQuery.toLowerCase();
      return item.termIt.toLowerCase().contains(q) ||
          item.termUr.toLowerCase().contains(q) ||
          item.termEn.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          lang == 'ur' ? "اٹالین ڈکشنری" : (lang == 'en' ? "Italian Glossary" : "Glossario Vocaboli"),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Search Field
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: lang == 'ur'
                    ? "اٹالین / اردو الفاظ تلاش کریں..."
                    : (lang == 'en' ? "Search Italian / English term..." : "Cerca termine in Italiano..."),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Glossary List
          Expanded(
            child: filteredItems.isEmpty
                ? Center(
                    child: Text(
                      lang == 'ur' ? "کوئی لفظ نہیں ملا" : (lang == 'en' ? "No terms found" : "Nessun termine trovato"),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.secondary.withOpacity(0.15)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 3)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.secondary.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(item.category, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          item.termIt,
                                          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.volume_up_rounded, color: AppColors.primary),
                                  onPressed: () => TTSService.speak(item.termIt, langCode: 'it'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // Show only the selected language translation
                            if (lang == 'ur') ...[
                              Text(
                                "🇵🇰 ${item.termUr}",
                                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.amber.shade700),
                              ),
                            ] else if (lang == 'en') ...[
                              Text(
                                "🇬🇧 ${item.termEn}",
                                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.amber.shade700),
                              ),
                            ],
                            const Divider(height: 20),

                            // Italian definition
                            Text(
                              lang == 'ur' ? "اٹالین میں وضاحت:" : (lang == 'en' ? "Italian definition:" : "Spiegazione:"),
                              style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                            Text(item.definitionIt, style: const TextStyle(fontSize: 13, height: 1.3)),

                            // Translation of definition (only if not Italian-only)
                            if (lang != 'it') ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lang == 'ur' ? "اردو میں وضاحت:" : "English explanation:",
                                      style: lang == 'ur'
                                          ? AppTheme.urduStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryDark)
                                          : GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                                    ),
                                    const SizedBox(height: 4),
                                    Directionality(
                                      textDirection: lang == 'ur' ? TextDirection.rtl : TextDirection.ltr,
                                      child: Text(
                                        lang == 'ur' ? item.definitionUr : item.definitionUr, // TODO: Add definitionEn to GlossaryItem model when English definitions are available
                                        style: lang == 'ur'
                                            ? AppTheme.urduStyle(fontSize: 16, height: 1.5, color: AppColors.primaryDark)
                                            : GoogleFonts.inter(fontSize: 13, height: 1.4, color: AppColors.primaryDark),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
