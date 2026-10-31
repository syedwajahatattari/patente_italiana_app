import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/quiz_provider.dart';
import '../providers/language_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'topic_quiz_screen.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final quizProvider = Provider.of<QuizProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);
    final lang = langProvider.langCode;
    final isUrdu = lang == 'ur';
    final results = quizProvider.examResults;

    final passProb = quizProvider.passProbability;
    final avgErrors = quizProvider.averageErrorsPerExam;
    final avgTimeSeconds = quizProvider.averageTimePerExam.round();
    final avgMins = avgTimeSeconds ~/ 60;
    final avgSecs = avgTimeSeconds % 60;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isUrdu ? "اعداد و شمار اور کارکردگی" : (lang == 'en' ? "Statistics & History" : "Statistiche & Andamento"),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Analytics Overview Card with 4 Metrics
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.25), width: 1.2),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 5)),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    isUrdu ? "کارکردگی کا جامع خلاصہ" : (lang == 'en' ? "Performance Summary" : "Riepilogo Generale"),
                    style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatBox(
                        isUrdu ? "کل شیٹس" : (lang == 'en' ? "Exams" : "Schede"),
                        "${quizProvider.totalExamsTaken}",
                        AppColors.secondary,
                      ),
                      _buildStatBox(
                        isUrdu ? "پاس" : (lang == 'en' ? "Passed" : "Promosso"),
                        "${quizProvider.passedExamsCount}",
                        AppColors.passedGreen,
                      ),
                      _buildStatBox(
                        isUrdu ? "فیل" : (lang == 'en' ? "Failed" : "Bocciato"),
                        "${quizProvider.totalExamsTaken - quizProvider.passedExamsCount}",
                        AppColors.failedRed,
                      ),
                      _buildStatBox(
                        isUrdu ? "پاس تناسب" : (lang == 'en' ? "Pass Rate" : "Tasso %"),
                        passProb != null ? "${passProb.toStringAsFixed(0)}%" : "--%",
                        AppColors.accentGold,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Performance Trend (Visual dots for last 8 exams)
            if (results.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isUrdu ? "📈 حالیہ امتحانات کا رجحان" : (lang == 'en' ? "📈 Recent Exam Trend" : "📈 Andamento Ultime Schede"),
                          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          isUrdu ? "تازہ ترین بائیں طرف" : "Più recenti a sinistra",
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 52,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: results.length.clamp(0, 10),
                        itemBuilder: (context, idx) {
                          final r = results[idx];
                          final bool passed = r.isPassed;
                          return Container(
                            margin: const EdgeInsets.only(right: 10),
                            child: Column(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: passed ? AppColors.passedGreen : AppColors.failedRed,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: (passed ? AppColors.passedGreen : AppColors.failedRed).withValues(alpha: 0.35),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Icon(
                                      passed ? Icons.check_rounded : Icons.close_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${r.errors} err",
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: passed ? AppColors.passedGreen : AppColors.failedRed,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Secondary Insights Row (Avg Time, Avg Errors, Streak)
            Row(
              children: [
                Expanded(
                  child: _buildInsightPill(
                    context,
                    title: isUrdu ? "اوسط وقت" : "Tempo Medio",
                    value: "${avgMins}m ${avgSecs}s",
                    icon: Icons.timer_outlined,
                    color: Colors.teal.shade600,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildInsightPill(
                    context,
                    title: isUrdu ? "اوسط غلطیاں" : "Errori Medi",
                    value: "${avgErrors.toStringAsFixed(1)}/30",
                    icon: Icons.error_outline_rounded,
                    color: Colors.orange.shade700,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildInsightPill(
                    context,
                    title: isUrdu ? "سٹریک" : "Serie Giorni",
                    value: "${quizProvider.dailyStreak} gg 🔥",
                    icon: Icons.local_fire_department_rounded,
                    color: Colors.deepOrange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Weakest Topic Alert Card
            if (quizProvider.weakestTopic != null) ...[
              Builder(builder: (context) {
                final info = quizProvider.weakestTopic!;
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
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.failedRed.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.failedRed.withValues(alpha: 0.35), width: 1.2),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.failedRed.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.warning_amber_rounded, color: AppColors.failedRed, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isUrdu ? "⚠️ فوری توجہ کی ضرورت!" : "⚠️ Area di Miglioramento Consigliata",
                                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.failedRed),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                topic.titleIt,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                isUrdu ? "اس ٹاپک پر غلطی کی شرح $errorRate% ہے۔ مشق کے لیے ٹیپ کریں۔" : "Tasso di errore del $errorRate%. Tocca per esercitarti ora.",
                                style: isUrdu
                                    ? AppTheme.urduStyle(fontSize: 12, color: Colors.grey.shade600)
                                    : TextStyle(fontSize: 11, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.failedRed, size: 16),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),
            ],

            Text(
              isUrdu ? "مکمل امتحانی ہسٹری" : (lang == 'en' ? "Exam History" : "Storico Dettagliato Schede"),
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            results.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        isUrdu
                            ? "ابھی تک کوئی شیٹ مکمل نہیں ہوئی۔ پہلا امتحان دیں۔"
                            : (lang == 'en' ? "No exams completed yet." : "Nessuna scheda ancora completata. Inizia la prima!"),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final r = results[index];
                      final bool passed = r.isPassed;
                      final String formattedDate =
                          "${r.date.day.toString().padLeft(2, '0')}/${r.date.month.toString().padLeft(2, '0')}/${r.date.year} ${r.date.hour.toString().padLeft(2, '0')}:${r.date.minute.toString().padLeft(2, '0')}";

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: passed ? AppColors.passedGreen.withValues(alpha: 0.3) : AppColors.failedRed.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: (passed ? AppColors.passedGreen : AppColors.failedRed).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                passed ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                color: passed ? AppColors.passedGreen : AppColors.failedRed,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    passed
                                        ? (isUrdu ? "پاس (Promosso)" : (lang == 'en' ? "PASSED" : "PROMOSSO"))
                                        : (isUrdu ? "فیل (Bocciato)" : (lang == 'en' ? "FAILED" : "BOCCIATO")),
                                    style: GoogleFonts.outfit(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: passed ? AppColors.passedGreen : AppColors.failedRed,
                                    ),
                                  ),
                                  Text(formattedDate, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "${r.errors} ${isUrdu ? 'غلطیاں' : (lang == 'en' ? 'Errors' : 'Errori')}",
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: passed ? AppColors.passedGreen : AppColors.failedRed,
                                  ),
                                ),
                                Text(
                                  "${r.correctAnswers} / ${r.totalQuestions} ${isUrdu ? 'صحیح' : 'Corrette'}",
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String title, String val, Color color) {
    return Column(
      children: [
        Text(val, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
      ],
    );
  }

  Widget _buildInsightPill(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            title,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
