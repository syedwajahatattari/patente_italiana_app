import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/language_provider.dart';
import '../theme/app_colors.dart';
import 'theory_video_lessons_screen.dart';

class TheoryManualScreen extends StatelessWidget {
  const TheoryManualScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final lang = langProvider.langCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          lang == 'ur' ? "ٹریفک سائنز کتاب" : (lang == 'en' ? "Theory Manual & Signs" : "Manuale Teoria & Segnali"),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.menu_book_rounded, color: Colors.white, size: 48),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Segnaletica Stradale", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        if (lang != 'it')
                          Text(
                            lang == 'ur' ? "اٹلی کے تمام ٹریفک کے اشارے اور قوانین" : "All Italian traffic signs and rules",
                            style: GoogleFonts.inter(fontSize: 13, color: Colors.white70),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Video Lessons Shortcut Card
            InkWell(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TheoryVideoLessonsScreen()));
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF4F46E5).withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 36),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lang == 'ur' ? "ویڈیو ماسٹر کلاسز 🎥" : (lang == 'en' ? "Video Masterclasses 🎥" : "Video Lezioni & Trucchi 🎥"),
                            style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          Text(
                            lang == 'ur' ? "تمام چیپٹرز کے اسباق ویڈیو میں دیکھیں" : "Guarda le lezioni spiegate passo per passo",
                            style: const TextStyle(fontSize: 11, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            _buildCategorySection(
              context,
              lang: lang,
              title: "1. Segnali di Pericolo",
              titleUr: "خطرے کے اشارے",
              titleEn: "Danger Signs",
              color: Colors.red.shade700,
              description: "Segnali di forma triangolare con bordo rosso. Preavvisano un pericolo a 150 metri.",
              descriptionUr: "یہ مثلث (تکون) کی شکل میں ہوتے ہیں۔ یہ 150 میٹر پہلے خطرے سے آگاہ کرتے ہیں۔",
              descriptionEn: "Triangular signs with red border. They warn of danger 150 meters ahead.",
              items: [
                _LocalizedItem("Strada sdrucciolevole", "پھسلن والی سڑک", "Slippery road"),
                _LocalizedItem("Lavori in corso", "سڑک پر کام جاری ہے", "Road works ahead"),
                _LocalizedItem("Passaggio a livello", "ریلوے پھاٹک", "Level crossing"),
                _LocalizedItem("Doppio senso di circolazione", "دو طرفہ ٹریفک", "Two-way traffic"),
              ],
            ),

            _buildCategorySection(
              context,
              lang: lang,
              title: "2. Segnali di Divieto",
              titleUr: "ممنوعہ اشارے",
              titleEn: "Prohibition Signs",
              color: Colors.red.shade900,
              description: "Segnali di forma circolare con bordo rosso. Vietano il transito o particolari manovre.",
              descriptionUr: "یہ گول دائرے کی شکل میں سرخ بارڈر کے ساتھ ہوتے ہیں۔ یہ داخلے یا اوورٹیک سے منع کرتے ہیں۔",
              descriptionEn: "Circular signs with red border. They prohibit entry or specific maneuvers.",
              items: [
                _LocalizedItem("Divieto di accesso - Senso vietato", "داخلہ ممنوع", "No entry"),
                _LocalizedItem("Divieto di sorpasso", "اوور ٹیکنگ ممنوع", "No overtaking"),
                _LocalizedItem("Divieto di sosta", "پارکنگ ممنوع", "No parking"),
                _LocalizedItem("Limite massimo di velocità", "تیز ترین رفتار کی حد", "Maximum speed limit"),
              ],
            ),

            _buildCategorySection(
              context,
              lang: lang,
              title: "3. Segnali di Obbligo",
              titleUr: "لازمی اشارے",
              titleEn: "Mandatory Signs",
              color: AppColors.secondary,
              description: "Segnali di forma circolare a fondo blu. Indicano un comportamento obbligatorio.",
              descriptionUr: "یہ نیلے گول دائرے کی شکل میں ہوتے ہیں۔ ان کی ہدایت پر عمل کرنا فرض ہے۔",
              descriptionEn: "Circular signs with blue background. They indicate mandatory behavior.",
              items: [
                _LocalizedItem("Direzione obbligatoria a destra", "دائیں مڑنا لازمی", "Mandatory right turn"),
                _LocalizedItem("Passaggio obbligatorio", "مخصوص راستے سے گزرنا لازمی", "Mandatory passage"),
                _LocalizedItem("Pista ciclabile", "سائیکل کا راستہ", "Bicycle lane"),
                _LocalizedItem("Catene per neve obbligatorie", "برفانی چین لازمی", "Snow chains required"),
              ],
            ),

            _buildCategorySection(
              context,
              lang: lang,
              title: "4. Segnali di Precedenza",
              titleUr: "حقِ فائقیت",
              titleEn: "Right of Way Signs",
              color: Colors.amber.shade800,
              description: "Indicano chi deve passare per primo negli incroci o nelle strettoie.",
              descriptionUr: "یہ اشارے چوک پر پہلے گزرنے یا گاڑی روکنے کی ہدایت دیتے ہیں۔",
              descriptionEn: "They indicate who must pass first at intersections or narrow roads.",
              items: [
                _LocalizedItem("STOP", "گاڑی مکمل روکنا اور راستہ دینا", "Stop completely and yield"),
                _LocalizedItem("Dare precedenza", "راستہ دیں", "Give way / Yield"),
                _LocalizedItem("Diritto di precedenza", "آپ کو پہلے گزرنے کا حق ہے", "You have right of way"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(
    BuildContext context, {
    required String lang,
    required String title,
    required String titleUr,
    required String titleEn,
    required Color color,
    required String description,
    required String descriptionUr,
    required String descriptionEn,
    required List<_LocalizedItem> items,
  }) {
    final displayTitle = lang == 'ur' ? "$title ($titleUr)" : (lang == 'en' ? "$title ($titleEn)" : title);
    final displayDesc = lang == 'ur' ? descriptionUr : (lang == 'en' ? descriptionEn : description);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(displayTitle, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 6),
          Text(description, style: const TextStyle(fontSize: 13, height: 1.3)),
          if (lang != 'it') ...[
            const SizedBox(height: 4),
            Text("${lang == 'ur' ? '🇵🇰' : '🇬🇧'} $displayDesc", style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.9))),
          ],
          const Divider(height: 20),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded, color: color, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      lang == 'ur'
                          ? "${item.it} (${item.ur})"
                          : (lang == 'en' ? "${item.it} (${item.en})" : item.it),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocalizedItem {
  final String it;
  final String ur;
  final String en;
  _LocalizedItem(this.it, this.ur, this.en);
}
