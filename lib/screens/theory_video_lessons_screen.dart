import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/language_provider.dart';
import '../providers/subscription_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../services/tts_service.dart';
import 'premium_paywall_screen.dart';

class VideoLesson {
  final String id;
  final String titleIt;
  final String titleUr;
  final String titleEn;
  final String duration;
  final String summaryIt;
  final String summaryUr;
  final bool isFree;
  final IconData icon;

  const VideoLesson({
    required this.id,
    required this.titleIt,
    required this.titleUr,
    required this.titleEn,
    required this.duration,
    required this.summaryIt,
    required this.summaryUr,
    required this.isFree,
    required this.icon,
  });
}

class TheoryVideoLessonsScreen extends StatelessWidget {
  const TheoryVideoLessonsScreen({super.key});

  final List<VideoLesson> _lessons = const [
    VideoLesson(
      id: "v1",
      titleIt: "Lezione 1: Segnali di Pericolo & Precedenza",
      titleUr: "سبق نمبر 1: خطرے کے اشارے اور ترجیح کے قوانین",
      titleEn: "Lesson 1: Danger Signs & Right-of-Way Rules",
      duration: "12 min",
      summaryIt: "Forma triangolare, distanza standard 150 metri, regole di arresto al segnale STOP e Dare Precedenza.",
      summaryUr: "تکون اشاروں کی پہچان، 150 میٹر فاصلے کی شرط، STOP اور ترجیح دینے کے لازمی قواعد۔",
      isFree: true,
      icon: Icons.warning_rounded,
    ),
    VideoLesson(
      id: "v2",
      titleIt: "Lezione 2: Incroci e Regola della Destra Libera",
      titleUr: "سبق نمبر 2: چوراہوں کا فارمولا اور دائیں ہاتھ کی ترجیح",
      titleEn: "Lesson 2: Intersections & Clear Right Formula",
      duration: "15 min",
      summaryIt: "Come risolvere qualsiasi incrocio ministeriale con il metodo dell'orologio e veicoli speciali (tram).",
      summaryUr: "امتحان میں آنے والے تمام چوک حل کرنے کا گھڑیال میتھڈ اور ٹرام کے گزرنے کی ترجیح۔",
      isFree: true,
      icon: Icons.alt_route_rounded,
    ),
    VideoLesson(
      id: "v3",
      titleIt: "Lezione 3: Limiti di Velocità & Distanza di Sicurezza",
      titleUr: "سبق نمبر 3: رفتار کی حدود اور گاڑیوں کا درمیانی فاصلہ",
      titleEn: "Lesson 3: Speed Limits & Safety Distance Calculation",
      duration: "18 min",
      summaryIt: "50-90-110-130 km/h, regole per neopatentati, pioggia, nebbia e calcolo dello spazio di frenatura.",
      summaryUr: "شہر اور ہائی وے کی رفتار کی حدود، نئے ڈرائیورز کی رعایتیں اور بارش میں بریک کا فاصلہ۔",
      isFree: false,
      icon: Icons.speed_rounded,
    ),
    VideoLesson(
      id: "v4",
      titleIt: "Lezione 4: Sorpasso, Sosta e Fermata",
      titleUr: "سبق نمبر 4: اوورٹیکنگ اور گاڑی کھڑی کرنے کے قوانین",
      titleEn: "Lesson 4: Overtaking, Parking & Stopping",
      duration: "14 min",
      summaryIt: "Dove è vietato sorpassare (dossi, curve, incroci) e differenza cruciale tra sosta e fermata.",
      summaryUr: "کن جگہوں پر اوورٹیکنگ ممنوع ہے اور سوسٹا (Sosta) اور فیرماتا (Fermata) میں باریک فرق۔",
      isFree: false,
      icon: Icons.local_parking_rounded,
    ),
    VideoLesson(
      id: "v5",
      titleIt: "Lezione 5: Alcol, Patente a Punti e Ritiro",
      titleUr: "سبق نمبر 5: الکحل، پوائنٹس سسٹم اور لائسنس کی منسوخی",
      titleEn: "Lesson 5: Alcohol Limits & Points System",
      duration: "16 min",
      summaryIt: "Tolleranza zero per neopatentati, sottrazione punti (raddoppiata per neopatentati), sospensione e revoca.",
      summaryUr: "نئے ڈرائیورز کے لیے الکحل کی صفر حد، ڈبل پوائنٹس کٹنا اور لائسنس معطلی کی شرائط۔",
      isFree: false,
      icon: Icons.local_bar_rounded,
    ),
    VideoLesson(
      id: "v6",
      titleIt: "Lezione 6: Masterclass Trucchi Ministeriali",
      titleUr: "سبق نمبر 6: ماسٹر کلاس — امتحانی خفیہ الفاظ",
      titleEn: "Lesson 6: Masterclass Exam Tricks & Magic Words",
      duration: "22 min",
      summaryIt: "Le parole che rendono il quiz 99% VERO o FALSO senza nemmeno dover leggere tutta la domanda.",
      summaryUr: "وہ جادوئی الفاظ جنہیں دیکھ کر بغیر پورا سوال پڑھے 99% درست جواب دیا جا سکتا ہے۔",
      isFree: false,
      icon: Icons.auto_awesome_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final subProvider = Provider.of<SubscriptionProvider>(context);
    final lang = langProvider.langCode;
    final isUrdu = lang == 'ur';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isUrdu ? "آڈیو لیسنز اور تھیوری خلاصہ" : (lang == 'en' ? "Audio Lessons & Theory" : "Audio Lezioni & Teoria"),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(18),
        itemCount: _lessons.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Container(
              margin: const EdgeInsets.only(bottom: 18),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.volume_up_rounded, color: Colors.white, size: 36),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isUrdu ? "تھیوری آڈیو اسباق اور اہم نکات" : "Audio Lezioni & Trucchi d'Esame",
                          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          isUrdu
                              ? "اطالوی ڈرائیونگ تھیوری کو آسان اردو اور اٹالین آڈیو وضاحت کے ساتھ سمجھیں"
                              : "Ascolta i concetti ministeriali più difficili spiegati in modo semplice.",
                          style: isUrdu
                              ? AppTheme.urduStyle(fontSize: 13, color: Colors.white.withOpacity(0.9))
                              : TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.85)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          final lesson = _lessons[index - 1];
          final bool isUnlocked = lesson.isFree || subProvider.isPremium;

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isUnlocked ? AppColors.primary.withOpacity(0.2) : Colors.amber.withOpacity(0.3),
                width: 1.2,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isUnlocked ? AppColors.primary.withOpacity(0.15) : Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isUnlocked ? lesson.icon : Icons.lock_rounded,
                  color: isUnlocked ? AppColors.primary : Colors.amber.shade700,
                  size: 26,
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      isUrdu ? lesson.titleUr : lesson.titleIt,
                      style: isUrdu
                          ? AppTheme.urduStyle(fontSize: 16, fontWeight: FontWeight.bold)
                          : GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isUnlocked ? AppColors.passedGreen.withOpacity(0.15) : AppColors.accentGold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isUnlocked ? (lesson.isFree ? "GRATIS" : "PRO 🔓") : "PRO 🔒",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isUnlocked ? AppColors.passedGreen : Colors.amber.shade800,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Text(
                    isUrdu ? lesson.summaryUr : lesson.summaryIt,
                    style: isUrdu
                        ? AppTheme.urduStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.3)
                        : TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(lesson.duration, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
              onTap: () {
                HapticFeedback.lightImpact();
                if (!isUnlocked) {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                      title: Row(
                        children: [
                          const Icon(Icons.workspace_premium_rounded, color: AppColors.accentGold, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            isUrdu ? "آڈیو سبق PRO 🔒" : "Lezione Audio PRO 🔒",
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      content: Text(
                        isUrdu
                            ? "یہ ماسٹر کلاس آڈیو سبق صرف PRO ممبرز کے لیے دستیاب ہے۔ تمام اسباق، ٹاپکس اور امتحانی فارمولے ان لاک کرنے کے لیے PRO شروع کریں۔"
                            : "Questa lezione audio e sintesi è riservata ai membri PRO. Passa a PRO per sbloccare l'intero corso teorico!",
                        style: isUrdu ? AppTheme.urduStyle(fontSize: 15, height: 1.5) : const TextStyle(fontSize: 14),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(isUrdu ? "بعد میں" : "Annulla"),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentGold,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumPaywallScreen()));
                          },
                          child: Text(
                            isUrdu ? "PRO حاصل کریں 👑" : "Sblocca PRO 👑",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  );
                  return;
                }

                // Show Lesson Summary Dialog / Player
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                  builder: (ctx) => Container(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.play_circle_fill_rounded, color: AppColors.primary, size: 28),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                isUrdu ? lesson.titleUr : lesson.titleIt,
                                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Text(
                          isUrdu ? "سبق کے اہم نکات:" : "Punti Chiave della Lezione:",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          lesson.summaryIt,
                          style: GoogleFonts.outfit(fontSize: 14, height: 1.4),
                        ),
                        if (lang != 'it') ...[
                          const SizedBox(height: 10),
                          Directionality(
                            textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
                            child: Text(
                              lesson.summaryUr,
                              style: isUrdu
                                  ? AppTheme.urduStyle(fontSize: 16, color: AppColors.primaryDark, height: 1.6)
                                  : GoogleFonts.inter(fontSize: 13, color: AppColors.primaryDark),
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () {
                              TTSService.speak(
                                isUrdu ? lesson.summaryUr : lesson.summaryIt,
                                langCode: isUrdu ? 'ur' : 'it',
                                id: "lesson_${lesson.id}",
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isUrdu ? "🔊 آڈیو وضاحت شروع ہو گئی ہے..." : "🔊 Riproduzione audio spiegazione...",
                                    style: isUrdu ? AppTheme.urduStyle(fontSize: 14, color: Colors.white) : null,
                                  ),
                                  backgroundColor: AppColors.primary,
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            icon: const Icon(Icons.volume_up_rounded),
                            label: Text(
                              isUrdu ? "آڈیو خلاصہ سنیں (Audio)" : "Ascolta Spiegazione Audio",
                              style: isUrdu
                                  ? AppTheme.urduStyle(fontSize: 16, fontWeight: FontWeight.bold)
                                  : const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.info_outline_rounded, size: 14, color: Colors.grey),
                              const SizedBox(width: 6),
                              Text(
                                isUrdu
                                    ? "🎬 ویڈیو اسٹریمنگ جلد اگلی اپڈیٹ میں شامل ہو گی"
                                    : "🎬 Streaming video in arrivo nel prossimo aggiornamento",
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

