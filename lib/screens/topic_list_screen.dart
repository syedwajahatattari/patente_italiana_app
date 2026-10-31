import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/quiz_provider.dart';
import '../providers/language_provider.dart';
import '../providers/subscription_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'topic_quiz_screen.dart';
import 'premium_paywall_screen.dart';

class TopicListScreen extends StatelessWidget {
  const TopicListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final quizProvider = Provider.of<QuizProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);
    final subProvider = Provider.of<SubscriptionProvider>(context);
    final lang = langProvider.langCode;
    final isUrdu = lang == 'ur';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isUrdu ? "ٹاپک وار کوئز" : (lang == 'en' ? "Topic-wise Quiz" : "Quiz per Argomento"),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: subProvider.isPremium ? AppColors.passedGreen.withOpacity(0.15) : AppColors.accentGold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: subProvider.isPremium ? AppColors.passedGreen : AppColors.accentGold,
              ),
            ),
            child: Center(
              child: Text(
                subProvider.isPremium
                    ? (isUrdu ? "25 ان لاک🔓" : "All 25 PRO 🔓")
                    : (isUrdu ? "5مفت•20لاک🔒" : "5 Free • 20 PRO🔒"),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: subProvider.isPremium ? AppColors.passedGreen : Colors.amber.shade800,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(18),
        itemCount: quizProvider.topics.length,
        itemBuilder: (context, index) {
          final topic = quizProvider.topics[index];
          final topicQuestions = quizProvider.allQuestions.where((q) => q.topicId == topic.id).toList();
          final qCount = topicQuestions.isEmpty ? topic.totalQuestions : topicQuestions.length;
          final isUnlocked = subProvider.isTopicUnlocked(index);

          // Get translated title
          final translatedTitle = lang == 'en' ? topic.titleEn : (lang == 'ur' ? topic.titleUr : '');

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isUnlocked ? AppColors.primary.withOpacity(0.15) : Colors.amber.withOpacity(0.35),
                width: isUnlocked ? 1 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isUnlocked ? Colors.black.withOpacity(0.03) : Colors.amber.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isUnlocked ? AppColors.primary.withOpacity(0.15) : Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isUnlocked ? Icons.assignment_rounded : Icons.lock_rounded,
                  color: isUnlocked ? AppColors.primary : Colors.amber.shade700,
                  size: 26,
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      topic.titleIt,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isUnlocked ? null : Colors.grey.shade600,
                      ),
                    ),
                  ),
                  if (!isUnlocked)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accentGold,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.workspace_premium_rounded, size: 12, color: Colors.black),
                          SizedBox(width: 2),
                          Text(
                            "PRO",
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (lang != 'it' && translatedTitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      translatedTitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: isUnlocked ? AppColors.primaryDark : Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    topic.descriptionIt,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? AppColors.secondary.withOpacity(0.15)
                          : Colors.grey.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "$qCount Q",
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isUnlocked ? AppColors.secondary : Colors.grey.shade600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    isUnlocked ? Icons.arrow_forward_ios_rounded : Icons.lock_outline_rounded,
                    size: 14,
                    color: isUnlocked ? Colors.grey : Colors.amber.shade700,
                  ),
                ],
              ),
              onTap: () {
                HapticFeedback.selectionClick();
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
                            isUrdu ? "پریمیئم ٹاپک 🔒" : "Argomento PRO 🔒",
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      content: Text(
                        isUrdu
                            ? "ٹاپک ${index + 1} (${topic.titleUr}) صرف PRO ممبرز کے لیے دستیاب ہے۔\n\nپہلے 5 ٹاپکس فری ہیں، اور بقیہ 20 ٹاپکس حاصل کرنے کے لیے PRO ممبر بنیں۔"
                            : "L'argomento ${index + 1} è riservato agli utenti PRO. Passa a PRO per sbloccare tutti i 25 argomenti!",
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
                            isUrdu ? "PRO ان لاک کریں 👑" : "Sblocca PRO 👑",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  );
                  return;
                }

                quizProvider.startTopicQuiz(topic.id);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => TopicQuizScreen(topicTitle: topic.titleIt)),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
