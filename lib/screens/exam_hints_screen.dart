import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../providers/subscription_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'premium_paywall_screen.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class ExamHintsScreen extends StatefulWidget {
  const ExamHintsScreen({super.key});

  @override
  State<ExamHintsScreen> createState() => _ExamHintsScreenState();
}

class _ExamHintsScreenState extends State<ExamHintsScreen> with TickerProviderStateMixin {
  Map<String, dynamic>? _hintsData;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadHints();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHints() async {
    final jsonString = await rootBundle.loadString('assets/data/exam_hints.json');
    setState(() {
      _hintsData = json.decode(jsonString);
    });
  }

  String _t(Map<String, dynamic> map, String lang) {
    if (lang == 'ur') return map['title_ur'] ?? map['title_en'] ?? map['title_it'];
    if (lang == 'en') return map['title_en'] ?? map['title_it'];
    return map['title_it'];
  }

  String _d(Map<String, dynamic> map, String lang) {
    if (lang == 'ur') return map['description_ur'] ?? map['description_en'] ?? map['description_it'];
    if (lang == 'en') return map['description_en'] ?? map['description_it'];
    return map['description_it'];
  }

  String _tip(Map<String, dynamic> map, String lang) {
    if (lang == 'ur') return map['tip_ur'] ?? map['tip_en'] ?? map['tip_it'];
    if (lang == 'en') return map['tip_en'] ?? map['tip_it'];
    return map['tip_it'];
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final subProvider = Provider.of<SubscriptionProvider>(context);
    final lang = langProvider.langCode;

    if (_hintsData == null) {
      return Scaffold(
        appBar: AppBar(title: Text(_screenTitle(lang))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _screenTitle(lang),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumPaywallScreen())),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: subProvider.isPremium ? AppColors.passedGreen.withValues(alpha: 0.15) : AppColors.accentGold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: subProvider.isPremium ? AppColors.passedGreen : AppColors.accentGold,
                ),
              ),
              child: Center(
                child: Text(
                  subProvider.isPremium ? "PRO 🔓" : (lang == 'ur' ? "3 فری • 🔒 PRO" : "3 Free • 🔒 PRO"),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: subProvider.isPremium ? AppColors.passedGreen : Colors.amber.shade800,
                  ),
                ),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.accentGold,
          indicatorWeight: 3,
          labelColor: AppColors.accentGold,
          unselectedLabelColor: Colors.grey,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(text: lang == 'ur' ? "🔑 سنہری اصول" : (lang == 'en' ? "🔑 Golden Rules" : "🔑 Regole d'Oro")),
            Tab(text: lang == 'ur' ? "🏎️ رفتار حدود" : (lang == 'en' ? "🏎️ Speed Limits" : "🏎️ Limiti Velocità")),
            Tab(text: lang == 'ur' ? "🍷 الکحل حدود" : (lang == 'en' ? "🍷 Alcohol Limits" : "🍷 Limiti Alcol")),
            Tab(text: lang == 'ur' ? "🧠 حکمت عملی" : (lang == 'en' ? "🧠 Strategy" : "🧠 Strategia")),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGoldenRulesTab(lang, subProvider),
          _buildSpeedLimitsTab(lang),
          _buildAlcoholLimitsTab(lang),
          _buildStrategyTab(lang),
        ],
      ),
    );
  }

  String _screenTitle(String lang) {
    if (lang == 'ur') return "💡 امتحان پاس کرنے کے ٹوٹکے";
    if (lang == 'en') return "💡 Exam Pass Hints & Tricks";
    return "💡 Trucchi per Superare l'Esame";
  }

  // ─── TAB 1: Golden Rules ───
  Widget _buildGoldenRulesTab(String lang, SubscriptionProvider subProvider) {
    final rules = _hintsData!['golden_rules'] as List;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rules.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildBanner(
            icon: Icons.auto_awesome_rounded,
            color: AppColors.accentGold,
            title: lang == 'ur'
                ? "🔥 یہ اصول 7,139 سوالات کے تجزیے سے اخذ کیے گئے ہیں!"
                : (lang == 'en'
                    ? "🔥 These rules are derived from analyzing all 7,139 questions!"
                    : "🔥 Queste regole derivano dall'analisi di tutte 7.139 domande!"),
            subtitle: lang == 'ur'
                ? "ان ٹوٹکوں سے آپ بہت سے سوالات بغیر پڑھے جواب دے سکتے ہیں"
                : (lang == 'en'
                    ? "With these tricks you can answer many questions without even reading them"
                    : "Con questi trucchi puoi rispondere a molte domande senza leggerle"),
          );
        }

        // Lock from rule 4 onwards for Free users
        if (!subProvider.isPremium && (index - 1) >= 3) {
          return _buildLockedRuleCard(context, lang, index);
        }

        final rule = rules[index - 1] as Map<String, dynamic>;
        final accuracy = (rule['accuracy'] as num).toDouble();
        final predictFalse = rule['predicted_answer'] == false;
        final keywords = (rule['keywords'] as List).cast<String>();

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: predictFalse
                  ? [AppColors.failedRed.withValues(alpha: 0.08), AppColors.failedRed.withValues(alpha: 0.02)]
                  : [AppColors.passedGreen.withValues(alpha: 0.08), AppColors.passedGreen.withValues(alpha: 0.02)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: predictFalse ? AppColors.failedRed.withValues(alpha: 0.3) : AppColors.passedGreen.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rule['icon'] ?? "📌", style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _t(rule, lang),
                            style: lang == 'ur'
                                ? AppTheme.urduStyle(fontSize: 18, fontWeight: FontWeight.bold)
                                : GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          // Accuracy badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: accuracy > 85
                                  ? AppColors.passedGreen.withValues(alpha: 0.2)
                                  : AppColors.accentGold.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "${lang == 'ur' ? 'درستگی' : (lang == 'en' ? 'Accuracy' : 'Accuratezza')}: ${accuracy.toStringAsFixed(1)}%",
                              style: lang == 'ur'
                                  ? AppTheme.urduStyle(fontSize: 13, fontWeight: FontWeight.bold, color: accuracy > 85 ? AppColors.passedGreen : AppColors.accentGold)
                                  : GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: accuracy > 85 ? AppColors.passedGreen : AppColors.accentGold,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Predicted Answer Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: predictFalse ? AppColors.failedRed : AppColors.passedGreen,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        predictFalse ? "FALSO" : "VERO",
                        style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _d(rule, lang),
                  style: lang == 'ur'
                      ? AppTheme.urduStyle(fontSize: 16, height: 1.5, color: Colors.grey.shade800)
                      : GoogleFonts.inter(fontSize: 13, height: 1.5, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 12),
                // Keywords chips
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: keywords.map((kw) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: predictFalse
                          ? AppColors.failedRed.withValues(alpha: 0.15)
                          : AppColors.passedGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: predictFalse
                            ? AppColors.failedRed.withValues(alpha: 0.4)
                            : AppColors.passedGreen.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      "\"$kw\"",
                      style: GoogleFonts.robotoMono(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: predictFalse ? AppColors.failedRed : AppColors.passedGreen,
                      ),
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── TAB 2: Speed Limits ───
  Widget _buildSpeedLimitsTab(String lang) {
    final speedData = _hintsData!['speed_limits'] as Map<String, dynamic>;
    final limits = speedData['limits'] as List;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildBanner(
          icon: Icons.speed_rounded,
          color: AppColors.secondary,
          title: lang == 'ur' ? speedData['title_ur'] : (lang == 'en' ? speedData['title_en'] : speedData['title_it']),
          subtitle: lang == 'ur'
              ? "رفتار کے سوالات امتحان میں بار بار آتے ہیں"
              : (lang == 'en' ? "Speed questions appear frequently in the exam" : "Le domande sulla velocità sono frequenti nell'esame"),
        ),
        ...limits.map((limit) {
          final zone = lang == 'ur' ? limit['zone_ur'] : (lang == 'en' ? limit['zone_en'] : limit['zone_it']);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3)),
              ],
            ),
            child: Row(
              children: [
                Text(limit['icon'], style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(zone, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(limit['zone_it'], style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.secondary, AppColors.primary],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    limit['limit'],
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),
        _buildTipCard(
          lang == 'ur'
              ? "💡 یاد رکھنے کی ترکیب: 50-90-110-130 — ہر سطح +20 یا +40 بڑھتی ہے!"
              : (lang == 'en'
                  ? "💡 Memory trick: 50-90-110-130 — each level increases by +20 or +40!"
                  : "💡 Trucco: 50-90-110-130 — ogni livello aumenta di +20 o +40!"),
        ),
      ],
    );
  }

  // ─── TAB 3: Alcohol Limits ───
  Widget _buildAlcoholLimitsTab(String lang) {
    final alcoholData = _hintsData!['alcohol_limits'] as Map<String, dynamic>;
    final limits = alcoholData['limits'] as List;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildBanner(
          icon: Icons.local_bar_rounded,
          color: AppColors.warningOrange,
          title: lang == 'ur' ? alcoholData['title_ur'] : (lang == 'en' ? alcoholData['title_en'] : alcoholData['title_it']),
          subtitle: lang == 'ur'
              ? "الکحل کے سوالات امتحان میں اکثر آتے ہیں"
              : (lang == 'en' ? "Alcohol questions are common in the exam" : "Le domande sull'alcol sono frequenti nell'esame"),
        ),
        ...limits.map((limit) {
          final category = lang == 'ur' ? limit['category_ur'] : (lang == 'en' ? limit['category_en'] : limit['category_it']);
          final isZero = limit['limit'] == '0.0 g/l';
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isZero ? AppColors.failedRed.withValues(alpha: 0.3) : AppColors.warningOrange.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3)),
              ],
            ),
            child: Row(
              children: [
                Text(limit['icon'], style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(category, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(limit['category_it'], style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isZero ? AppColors.failedRed : AppColors.warningOrange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    limit['limit'],
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),
        _buildTipCard(
          lang == 'ur'
              ? "💡 یاد رکھیں: نئے ڈرائیور، پیشہ ور ڈرائیور اور 21 سال سے کم عمر کے لیے الکحل حد صفر (0.0) ہے!"
              : (lang == 'en'
                  ? "💡 Remember: New drivers, professional drivers and under 21 have ZERO alcohol limit!"
                  : "💡 Ricorda: Neopatentati, professionisti e under 21 hanno limite ZERO!"),
        ),
      ],
    );
  }

  // ─── TAB 4: Exam Strategy ───
  Widget _buildStrategyTab(String lang) {
    final strategies = _hintsData!['exam_strategy'] as List;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: strategies.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildBanner(
            icon: Icons.psychology_rounded,
            color: AppColors.primary,
            title: lang == 'ur' ? "امتحان کی حکمت عملی" : (lang == 'en' ? "Exam Strategy" : "Strategia d'Esame"),
            subtitle: lang == 'ur'
                ? "ان ٹوٹکوں سے آپ کے پاس ہونے کے امکانات بہت بڑھ جائیں گے"
                : (lang == 'en'
                    ? "These tips will significantly increase your chances of passing"
                    : "Questi consigli aumenteranno le tue possibilità di superare l'esame"),
          );
        }
        final strategy = strategies[index - 1] as Map<String, dynamic>;
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3)),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(strategy['icon'] ?? "💡", style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t(strategy, lang),
                      style: lang == 'ur'
                          ? AppTheme.urduStyle(fontSize: 18, fontWeight: FontWeight.bold)
                          : GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _tip(strategy, lang),
                      style: lang == 'ur'
                          ? AppTheme.urduStyle(fontSize: 16, height: 1.5, color: Colors.grey.shade800)
                          : GoogleFonts.inter(fontSize: 13, height: 1.5, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Helpers ───
  Widget _buildBanner({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 36),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentGold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.4)),
      ),
      child: Text(text, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, height: 1.4)),
    );
  }

  Widget _buildLockedRuleCard(BuildContext context, String lang, int ruleNum) {
    final isUrdu = lang == 'ur';
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumPaywallScreen()));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.amber.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.lock_rounded, color: Colors.amber, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        isUrdu ? "خفیہ ٹوٹکا #$ruleNum" : "Trucco Ministeriale #$ruleNum",
                        style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accentGold,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text("PRO", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isUrdu
                        ? "99% درست جواب کی پیشن گوئی کرنے والا لفظ دیکھنے کے لیے PRO شروع کریں"
                        : "Sblocca con PRO per vedere le parole magiche e la spiegazione",
                    style: isUrdu
                        ? AppTheme.urduStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.3)
                        : TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.amber),
          ],
        ),
      ),
    );
  }
}

