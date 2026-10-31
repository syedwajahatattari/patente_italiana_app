import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/quiz_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'exam_simulation_screen.dart';
import 'topic_list_screen.dart';
import 'theory_manual_screen.dart';
import 'glossary_screen.dart';
import 'error_review_screen.dart';
import 'statistics_screen.dart';
import 'exam_hints_screen.dart';
import 'premium_paywall_screen.dart';
import 'topic_quiz_screen.dart';
import 'time_attack_screen.dart';
import 'incroci_simulator_screen.dart';
import 'ai_tutor_screen.dart';
import '../providers/subscription_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final quizProvider = Provider.of<QuizProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);
    final subProvider = Provider.of<SubscriptionProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final lang = langProvider.langCode;
    final isUrdu = lang == 'ur';

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 10,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.italianGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.italianGreen, width: 1),
                ),
                child: const Text(
                  "🇮🇹 PATENTE B",
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.italianGreen),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text("Pro", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
        actions: [
          // PRO Status / Toggle Button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumPaywallScreen()));
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                gradient: subProvider.isPremium
                    ? const LinearGradient(colors: [Color(0xFF059669), Color(0xFF10B981)])
                    : const LinearGradient(colors: [Color(0xFFD97706), Color(0xFFF59E0B)]),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: (subProvider.isPremium ? Colors.green : Colors.amber).withOpacity(0.25),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    subProvider.isPremium ? Icons.verified_rounded : Icons.workspace_premium_rounded,
                    size: 13,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    subProvider.isPremium ? "PRO" : "FREE",
                    style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
            onPressed: () => themeProvider.toggleTheme(),
            tooltip: "Switch Theme",
          ),
          PopupMenuButton<AppLanguage>(
            icon: const Icon(Icons.language_rounded),
            onSelected: (l) => langProvider.setLanguage(l),
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: AppLanguage.urdu,
                child: Row(
                  children: [
                    if (langProvider.language == AppLanguage.urdu) const Icon(Icons.check, size: 18, color: AppColors.primary),
                    if (langProvider.language == AppLanguage.urdu) const SizedBox(width: 8),
                    const Text("🇵🇰 اردو (نستعلیق)"),
                  ],
                ),
              ),
              PopupMenuItem(
                value: AppLanguage.english,
                child: Row(
                  children: [
                    if (langProvider.language == AppLanguage.english) const Icon(Icons.check, size: 18, color: AppColors.primary),
                    if (langProvider.language == AppLanguage.english) const SizedBox(width: 8),
                    const Text("🇬🇧 English"),
                  ],
                ),
              ),
              PopupMenuItem(
                value: AppLanguage.italian,
                child: Row(
                  children: [
                    if (langProvider.language == AppLanguage.italian) const Icon(Icons.check, size: 18, color: AppColors.primary),
                    if (langProvider.language == AppLanguage.italian) const SizedBox(width: 8),
                    const Text("🇮🇹 Solo Italiano"),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: quizProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : quizProvider.hasError
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 64, color: AppColors.failedRed),
                        const SizedBox(height: 16),
                        Text(
                          isUrdu ? "ڈیٹا لوڈ کرنے میں دشواری پیش آئی" : (lang == 'en' ? "Error loading datasets" : "Errore nel caricamento dei dati"),
                          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isUrdu
                              ? "براہ کرم دوبارہ کوشش کریں یا ایپ ری اسٹارٹ کریں۔"
                              : "Impossibile caricare il database dei quiz. Riprova.",
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () => quizProvider.initData(),
                          icon: const Icon(Icons.refresh_rounded, size: 20),
                          label: Text(
                            isUrdu ? "دوبارہ کوشش کریں" : (lang == 'en' ? "Retry" : "Riprova"),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
              onRefresh: () async => await quizProvider.initData(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pass Probability Hero Card
                    _buildPassProbabilityCard(context, quizProvider, isDark, lang),
                    const SizedBox(height: 14),

                    // Personalized Target Exam Date & Daily Goals
                    _buildExamCountdownCard(context, quizProvider, isDark, isUrdu, lang),
                    const SizedBox(height: 14),

                    // Daily Streak & Practice Counter
                    _buildStreakCard(context, quizProvider, isDark, isUrdu, lang),
                    const SizedBox(height: 14),

                    // Weakest Area Alert (if user has errors)
                    if (quizProvider.weakestTopic != null) ...[
                      _buildWeakestTopicCard(context, quizProvider, isDark, isUrdu, lang),
                      const SizedBox(height: 14),
                    ],

                    // AI Tutor Interactive Coach Banner
                    _buildAiTutorBanner(context, isUrdu, lang, subProvider),
                    const SizedBox(height: 14),

                    // Gold Pro Banner
                    _buildProBanner(context, isUrdu, subProvider),
                    const SizedBox(height: 16),

                    // Main Primary Action: Start Exam Simulation
                    _buildStartExamBanner(context, quizProvider, lang, subProvider),
                    const SizedBox(height: 22),

                    Text(
                      isUrdu
                          ? "مطالعہ اور پریکٹس سیکشن"
                          : (lang == 'en' ? "Study & Practice Modules" : "Studio e Moduli di Pratica"),
                      style: isUrdu
                          ? AppTheme.urduStyle(fontSize: 22, fontWeight: FontWeight.bold)
                          : GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    // Comprehensive Grid of Features (8 Cards)
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 1.15,
                      children: [
                        _buildFeatureTile(
                          context,
                          title: "Quiz per Argomento",
                          subtitle: isUrdu ? "ٹاپک وار کوئز" : (lang == 'en' ? "Topic-wise Quiz" : "25 Capitoli"),
                          icon: Icons.category_rounded,
                          color: Colors.blue.shade600,
                          isUrdu: isUrdu,
                          badgeText: subProvider.isPremium ? "25 🔓" : (isUrdu ? "5 مفت" : "5 Free"),
                          badgeColor: subProvider.isPremium ? AppColors.passedGreen : Colors.blue.shade700,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TopicListScreen())),
                        ),
                        _buildFeatureTile(
                          context,
                          title: "Sfida Time Attack",
                          subtitle: isUrdu ? "60 سیکنڈز اسپیڈ گیم" : (lang == 'en' ? "60s Speed Quiz Game" : "Sfida 60s & Combo"),
                          icon: Icons.electric_bolt_rounded,
                          color: Colors.amber.shade800,
                          isUrdu: isUrdu,
                          badgeText: "HOT 🔥",
                          badgeColor: Colors.deepOrange,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const TimeAttackScreen()),
                            );
                          },
                        ),
                        _buildFeatureTile(
                          context,
                          title: "Quiz Trabocchetto",
                          subtitle: isUrdu ? "مشکل ترین سوالات" : (lang == 'en' ? "Trap & Hard Quizzes" : "Domande Impossibili"),
                          icon: Icons.whatshot_rounded,
                          color: Colors.red.shade700,
                          isUrdu: isUrdu,
                          badgeText: subProvider.isPremium ? "PRO 🔓" : "PRO 🔒",
                          badgeColor: subProvider.isPremium ? AppColors.passedGreen : AppColors.accentGold,
                          onTap: () {
                            if (!subProvider.isPremium) {
                              _showProGateDialog(
                                context,
                                isUrdu,
                                isUrdu
                                    ? "یہ فیچر صرف PRO ممبرز کے لیے ہے۔ اس میں اٹلی کے سب سے زیادہ فیل کروانے والے ٹرکی سوالات جمع کیے گئے ہیں۔"
                                    : "I Quiz Trabocchetto contengono le domande statisticamente più sbagliate in Italia. Sblocca con PRO!",
                              );
                              return;
                            }
                            quizProvider.startDifficultQuiz();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TopicQuizScreen(topicTitle: "Quiz Trabocchetto (Impossibili)"),
                              ),
                            );
                          },
                        ),
                        _buildFeatureTile(
                          context,
                          title: "Incroci & Precedenze",
                          subtitle: isUrdu ? "چوراہوں میں گاڑیوں کی ترتیب" : (lang == 'en' ? "Intersections Simulator" : "Simulatore Incroci"),
                          icon: Icons.alt_route_rounded,
                          color: Colors.teal.shade600,
                          isUrdu: isUrdu,
                          badgeText: "INTERATTIVO",
                          badgeColor: Colors.teal.shade700,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const IncrociSimulatorScreen(),
                              ),
                            );
                          },
                        ),
                        _buildFeatureTile(
                          context,
                          title: "Ripasso Errori",
                          subtitle: isUrdu
                              ? "غلطیوں کی اصلاح (${quizProvider.errorBankQuestions.length})"
                              : (lang == 'en' ? "Error Review (${quizProvider.errorBankQuestions.length})" : "Banca Errori (${quizProvider.errorBankQuestions.length})"),
                          icon: Icons.assignment_late_rounded,
                          color: Colors.amber.shade700,
                          isUrdu: isUrdu,
                          badgeText: quizProvider.errorBankQuestions.isNotEmpty ? "${quizProvider.errorBankQuestions.length}" : null,
                          badgeColor: AppColors.failedRed,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ErrorReviewScreen())),
                        ),
                        _buildFeatureTile(
                          context,
                          title: "Glossario Vocaboli",
                          subtitle: isUrdu ? "اٹالین-اردو ڈکشنری" : (lang == 'en' ? "Italian-English Dictionary" : "Vocabolario e Audio"),
                          icon: Icons.translate_rounded,
                          color: Colors.purple.shade600,
                          isUrdu: isUrdu,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GlossaryScreen())),
                        ),
                        _buildFeatureTile(
                          context,
                          title: "Trucchi Esame",
                          subtitle: isUrdu ? "💡 پاس ہونے کے ٹوٹکے" : (lang == 'en' ? "💡 Pass Hints & Tricks" : "Parole Magiche VERO/FALSO"),
                          icon: Icons.lightbulb_rounded,
                          color: Colors.orange.shade700,
                          isUrdu: isUrdu,
                          badgeText: subProvider.isPremium ? "PRO 🔓" : "PRO 🔒",
                          badgeColor: subProvider.isPremium ? AppColors.passedGreen : AppColors.accentGold,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExamHintsScreen())),
                        ),
                        _buildFeatureTile(
                          context,
                          title: "Manuale Teoria",
                          subtitle: isUrdu ? "ٹریفک سائنز کتاب" : (lang == 'en' ? "Theory Manual" : "Segnaletica Stradale"),
                          icon: Icons.menu_book_rounded,
                          color: Colors.green.shade600,
                          isUrdu: isUrdu,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TheoryManualScreen())),
                        ),
                        _buildFeatureTile(
                          context,
                          title: "Statistiche & Trend",
                          subtitle: isUrdu ? "پروگریس گراف و تاریخ" : (lang == 'en' ? "Progress & History" : "Grafici e Storico"),
                          icon: Icons.bar_chart_rounded,
                          color: Colors.indigo.shade600,
                          isUrdu: isUrdu,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StatisticsScreen())),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildExamCountdownCard(
    BuildContext context,
    QuizProvider quizProvider,
    bool isDark,
    bool isUrdu,
    String lang,
  ) {
    final targetDate = quizProvider.targetExamDate;
    final daysLeft = quizProvider.daysUntilExam;
    final questionsToday = quizProvider.todayQuestionsPracticed;
    final targetQuestions = quizProvider.dailyTargetQuestions;
    final progress = quizProvider.dailyTargetProgress;

    return InkWell(
      onTap: () async {
        HapticFeedback.lightImpact();
        final picked = await showDatePicker(
          context: context,
          initialDate: targetDate ?? DateTime.now().add(const Duration(days: 30)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          helpText: isUrdu ? "امتحان کی متوقع تاریخ منتخب کریں" : "Seleziona la data dell'esame teorico",
          confirmText: isUrdu ? "محفوظ کریں" : "Imposta Data",
          cancelText: isUrdu ? "منسوخ" : "Annulla",
        );
        if (picked != null) {
          await quizProvider.setTargetExamDate(picked);
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.withOpacity(0.25), width: 1.2),
          boxShadow: [
            BoxShadow(color: Colors.blue.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.event_available_rounded, color: Colors.blue, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            isUrdu ? "🎯 امتحانی ہدف و منصوبہ" : "🎯 Obiettivo & Data Esame",
                            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                          ),
                          const Spacer(),
                          Text(
                            targetDate != null
                                ? "${targetDate.day}/${targetDate.month}/${targetDate.year}"
                                : (isUrdu ? "تاریخ طے کریں" : "Imposta data"),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        targetDate != null
                            ? (isUrdu
                                ? "امتحان میں $daysLeft دن باقی ہیں • روزانہ 30 سوالات کا ہدف"
                                : "Mancano $daysLeft giorni • Obiettivo: $questionsToday/$targetQuestions quiz oggi")
                            : (isUrdu
                                ? "امتحان کی تاریخ مقرر کریں تاکہ ایپ آپ کا روزانہ کا ہدف بنا سکے"
                                : "Tocca per impostare la data del tuo esame e calcolare l'obiettivo"),
                        style: isUrdu
                            ? AppTheme.urduStyle(fontSize: 13, color: Colors.grey.shade600)
                            : TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.edit_calendar_rounded, size: 18, color: Colors.grey),
              ],
            ),
            if (targetDate != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: Colors.blue.withOpacity(0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress >= 1.0 ? AppColors.passedGreen : Colors.blue,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard(
    BuildContext context,
    QuizProvider quizProvider,
    bool isDark,
    bool isUrdu,
    String lang,
  ) {
    final streak = quizProvider.dailyStreak;
    final questionsToday = quizProvider.todayQuestionsPracticed;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1.2),
        boxShadow: [
          BoxShadow(color: Colors.orange.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF97316), Color(0xFFEF4444)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text("🔥", style: TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUrdu
                      ? "$streak دن کی لگاتار محنت! 🚀"
                      : (lang == 'en' ? "$streak Day Streak! 🚀" : "Serie di $streak Giorni! 🚀"),
                  style: isUrdu
                      ? AppTheme.urduStyle(fontSize: 16, fontWeight: FontWeight.bold)
                      : GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  isUrdu
                      ? "آج کے حل شدہ سوالات: $questionsToday"
                      : (lang == 'en' ? "Questions practiced today: $questionsToday" : "Quiz completati oggi: $questionsToday"),
                  style: isUrdu
                      ? AppTheme.urduStyle(fontSize: 13, color: Colors.grey.shade500)
                      : TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "$streak 🔥",
              style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.deepOrange, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeakestTopicCard(
    BuildContext context,
    QuizProvider quizProvider,
    bool isDark,
    bool isUrdu,
    String lang,
  ) {
    final info = quizProvider.weakestTopic;
    if (info == null) return const SizedBox.shrink();

    final topic = info['topic'];
    final errorRate = info['errorRate'];

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        quizProvider.startTopicQuiz(topic.id);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TopicQuizScreen(topicTitle: topic.titleIt)),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.failedRed.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.failedRed.withOpacity(0.35), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.failedRed.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: AppColors.failedRed, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        isUrdu ? "⚠️ کمزور ترین موضوع" : "⚠️ Argomento con più errori",
                        style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.failedRed),
                      ),
                      const SizedBox(width: 6),
                      Text("($errorRate% errori)", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                  Text(
                    topic.titleIt,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.failedRed),
          ],
        ),
      ),
    );
  }

  Widget _buildAiTutorBanner(BuildContext context, bool isUrdu, String lang, SubscriptionProvider subProvider) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AiTutorScreen()));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFF9333EA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED).withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.psychology_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        isUrdu ? "🤖 استاد AI سے سوال پوچھیں" : "🤖 Chiedi all'Istruttore AI",
                        style: isUrdu
                            ? AppTheme.urduStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)
                            : GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text("24/7 AI", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isUrdu
                        ? "اشارے اور چوراہے سمجھیں اردو آواز کے ساتھ 🔊"
                        : "Spiegazioni con voce e trucchi d'esame 🔊",
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF4F46E5), size: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProBanner(BuildContext context, bool isUrdu, SubscriptionProvider subProvider) {
    final isPro = subProvider.isPremium;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumPaywallScreen()));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isPro
                ? [const Color(0xFF0F766E), const Color(0xFF059669)]
                : [const Color(0xFFD97706), const Color(0xFFF59E0B)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (isPro ? const Color(0xFF059669) : Colors.amber.shade700).withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isPro ? Icons.stars_rounded : Icons.workspace_premium_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        isPro ? "PATENTE B PRO MEMBER ⭐" : "PATENTE B PRO 👑",
                        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isPro ? "ACTIVE" : "UPGRADE",
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    isPro
                        ? (isUrdu
                            ? "آپ کے تمام 25 ٹاپکس، امتحانی ٹوٹکے اور لامحدود شیٹس فعال ہیں ✅"
                            : "Tutti i 25 argomenti, trucchi e schede illimitate sbloccati ✅")
                        : (isUrdu
                            ? "تمام امتحانی ٹوٹکے، 25 ٹاپکس اور لامحدود شیٹس حاصل کریں"
                            : "Sblocca trucchi ministeriali, 25 argomenti e schede illimitate"),
                    style: isUrdu
                        ? AppTheme.urduStyle(fontSize: 13, color: Colors.white.withOpacity(0.95), height: 1.4)
                        : TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.9)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPassProbabilityCard(BuildContext context, QuizProvider quizProvider, bool isDark, String lang) {
    final double? probability = quizProvider.passProbability;
    final bool hasData = probability != null;
    final isUrdu = lang == 'ur';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [Colors.white, const Color(0xFFF1F5F9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shield_outlined, color: AppColors.primary, size: 20),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        "Probabilità di Promozione",
                        style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
                if (lang != 'it') ...[
                  const SizedBox(height: 6),
                  Text(
                    isUrdu ? "امتحان پاس کرنے کا امکان" : "Pass Probability",
                    style: isUrdu
                        ? AppTheme.urduStyle(fontSize: 17, fontWeight: FontWeight.bold)
                        : GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  hasData
                      ? "Totale: ${quizProvider.totalExamsTaken}  •  Promosso: ${quizProvider.passedExamsCount}"
                      : (isUrdu ? "امتحان دینے کے بعد اسکور ظاہر ہوگا" : "Fai la tua prima scheda d'esame"),
                  style: isUrdu
                      ? AppTheme.urduStyle(fontSize: 13, color: Colors.grey.shade500)
                      : TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(
                  value: hasData ? (probability / 100) : 0.0,
                  strokeWidth: 8,
                  backgroundColor: AppColors.primary.withOpacity(0.15),
                  color: hasData
                      ? (probability >= 75 ? AppColors.passedGreen : AppColors.warningOrange)
                      : Colors.grey.shade400,
                ),
              ),
              Text(
                hasData ? "${probability.toStringAsFixed(0)}%" : "--%",
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStartExamBanner(
    BuildContext context,
    QuizProvider quizProvider,
    String lang,
    SubscriptionProvider subProvider,
  ) {
    final isUrdu = lang == 'ur';
    final isPro = subProvider.isPremium;

    return InkWell(
      onTap: () async {
        HapticFeedback.lightImpact();
        if (!subProvider.canTakeExam) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              title: Row(
                children: [
                  const Icon(Icons.lock_clock_rounded, color: Colors.amber, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    isUrdu ? "روزانہ کی حد مکمل!" : "Limite Giornaliero!",
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Text(
                isUrdu
                    ? "آپ آج کے 3 مفت امتحانی شیٹس مکمل کر چکے ہیں۔ بغیر کسی حد کے لامحدود امتحانات دینے کے لیے PRO ایکٹیویٹ کریں۔"
                    : "Hai utilizzato le 3 schede gratuite per oggi. Passa a PRO per esercitarti senza limiti!",
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
                    isUrdu ? "PRO حاصل کریں 👑" : "Passa a PRO 👑",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
          return;
        }

        // Deduct attempt only upon completion in submitExam()
        quizProvider.startMinisterialExam(subProvider: subProvider);
        if (context.mounted) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ExamSimulationScreen()));
        }
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF059669), Color(0xFF10B981)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "SIMULAZIONE ESAME MINISTERIALE",
                        style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "30 Domande  •  20 Minuti  •  Max 3 Errori",
                        style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w500),
                      ),
                      if (lang != 'it') ...[
                        const SizedBox(height: 2),
                        Text(
                          isUrdu
                              ? "مکمل منسٹریل ایگزام سیمولیشن شروع کریں"
                              : "Start Full Ministerial Exam Simulation",
                          style: isUrdu
                              ? AppTheme.urduStyle(fontSize: 15, color: Colors.white.withOpacity(0.95), height: 1.4)
                              : GoogleFonts.inter(fontSize: 12, color: Colors.white.withOpacity(0.8)),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
              ],
            ),
            const SizedBox(height: 12),
            // Daily Limit Indicator Tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPro ? Icons.all_inclusive_rounded : Icons.calendar_today_rounded,
                    size: 13,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isPro
                        ? (isUrdu ? "امتحانی شیٹس: لامحدود (PRO Active)" : "Schede: Illimitate (PRO Active)")
                        : (isUrdu
                            ? "آج کے فری امتحانات: ${subProvider.remainingDailyExams}/${subProvider.maxDailyFreeExams} باقی"
                            : "Schede oggi: ${subProvider.remainingDailyExams}/${subProvider.maxDailyFreeExams} rimaste"),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withOpacity(0.95),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isUrdu,
    required VoidCallback onTap,
    String? badgeText,
    Color? badgeColor,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2), width: 1.2),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                if (badgeText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeColor ?? color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badgeText,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: isUrdu
                        ? AppTheme.urduStyle(fontSize: 12, color: Colors.grey.shade500, height: 1.2)
                        : TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showProGateDialog(BuildContext context, bool isUrdu, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            const Icon(Icons.workspace_premium_rounded, color: AppColors.accentGold, size: 28),
            const SizedBox(width: 8),
            Text(
              isUrdu ? "پریمیئم فیچر 🔒" : "Funzione PRO 🔒",
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          message,
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
              isUrdu ? "PRO ان لاک کریں 👑" : "Sblocca con PRO 👑",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
