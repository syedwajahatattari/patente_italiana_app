import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../providers/language_provider.dart';
import '../providers/subscription_provider.dart';
import '../services/revenuecat_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class PremiumPaywallScreen extends StatefulWidget {
  const PremiumPaywallScreen({super.key});

  @override
  State<PremiumPaywallScreen> createState() => _PremiumPaywallScreenState();
}

class _PremiumPaywallScreenState extends State<PremiumPaywallScreen> {
  int _selectedPlanIndex = 0;
  List<Package> _packages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    final packages = await RevenueCatService.getOfferings();
    if (mounted) {
      setState(() {
        _packages = packages;
        _isLoading = false;
        // Default to middle or popular package if available
        if (packages.length > 1) {
          _selectedPlanIndex = 1;
        } else {
          _selectedPlanIndex = 0;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final subProvider = Provider.of<SubscriptionProvider>(context);
    final lang = langProvider.langCode;
    final isUrdu = lang == 'ur';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isUrdu ? "پریمیئم پلان" : (lang == 'en' ? "Patente B PRO" : "Passa a PRO"),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(context),
            tooltip: "Chiudi",
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            // Hero Pro Crown Card with Glassmorphic Gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFD97706), Color(0xFFB45309)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.shade700.withOpacity(0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.workspace_premium_rounded, size: 48, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "PATENTE B ITALIA PRO",
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isUrdu
                      ? "پہلی بار میں اطالوی ڈرائیونگ لائسنس تھیوری امتحان پاس کرنے کا مصدقہ فارمولا!"
                      : (lang == 'en'
                          ? "Pass your Italian driving theory exam on your 1st attempt guaranteed!"
                          : "Supera l'esame teorico della patente al 1° colpo senza stress!"),
                    textAlign: TextAlign.center,
                    style: isUrdu
                      ? AppTheme.urduStyle(fontSize: 16, color: Colors.white.withOpacity(0.95), height: 1.4)
                      : GoogleFonts.inter(fontSize: 13, color: Colors.white.withOpacity(0.9), height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  // Social Proof Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_user_rounded, color: Colors.white, size: 15),
                        const SizedBox(width: 6),
                        Text(
                          isUrdu
                            ? "50,000+ طلباء کی پہلی پسند • 94% کامیابی کی شرح"
                            : (lang == 'en'
                                ? "Trusted by 50,000+ students • 94% pass rate"
                                : "Scelto da 50.000+ allievi • 94% promossi al 1° colpo"),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),



            // Comparison Table: Free vs PRO (Pushes conversion drastically)
            _buildComparisonCard(context, isUrdu, lang),
            const SizedBox(height: 20),

            // Highlighted PRO Super-Features
            _buildFeatureRow(
              icon: Icons.auto_awesome_rounded,
              color: Colors.amber.shade700,
              titleIt: "Trucchi Ministeriali (Parole Magiche)",
              descIt: "Lista segreta di parole che sono 99% sempre VERO o FALSO.",
              titleUr: "🔑 امتحانی خفیہ ٹوٹکے (جادوئی الفاظ)",
              descUr: "وہ مخصوص الفاظ جو 99% ہمیشہ VERO یا FALSO ہوتے ہیں۔",
              isUrdu: isUrdu,
            ),
            _buildFeatureRow(
              icon: Icons.all_inclusive_rounded,
              color: AppColors.primary,
              titleIt: "Simulazioni Esame Ministeriali Illimitate",
              descIt: "Fai tutte le schede d'esame ministeriali senza alcun blocco giornaliero.",
              titleUr: "♾️ لامحدود ایگزام شیٹس",
              descUr: "بغیر کسی روزانہ حد کے جتنی چاہیں اصلی امتحانی شیٹس حل کریں۔",
              isUrdu: isUrdu,
            ),
            _buildFeatureRow(
              icon: Icons.category_rounded,
              color: Colors.blue.shade600,
              titleIt: "Tutti i 25 Argomenti Ministeriali",
              descIt: "Accesso completo a tutti i 7.000+ quiz divisi per capitolo ed errore frequente.",
              titleUr: "📚 تمام 25 ٹاپکس کی مکمل مشق",
              descUr: "تمام 7,000 سے زائد سوالات اور حل کی مکمل رسائی۔",
              isUrdu: isUrdu,
            ),
            _buildFeatureRow(
              icon: Icons.replay_circle_filled_rounded,
              color: Colors.purple.shade600,
              titleIt: "Banca Errori Smart (Metodo Zero Errori)",
              descIt: "Ripeti in modo mirato gli errori fino a padroneggiarli al 100%.",
              titleUr: "🔄 سمارٹ غلطیوں کا بینک (Zero Error)",
              descUr: "اپنی غلطیوں کو بار بار دوہرا کر صفر غلطی کے ساتھ امتحان دیں۔",
              isUrdu: isUrdu,
            ),
            _buildFeatureRow(
              icon: Icons.offline_bolt_rounded,
              color: Colors.green.shade600,
              titleIt: "Quiz e Teoria Offline",
              descIt: "Esercitati anche senza connessione internet su oltre 7.000 quiz.",
              titleUr: "📴 کوئز اور تھیوری آف لائن",
              descUr: "بغیر انٹرنیٹ کے بھی 7,000 سے زائد سوالات اور اصول پڑھیں۔",
              isUrdu: isUrdu,
            ),
            const SizedBox(height: 22),

            // Plan Selector Cards
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: AppColors.accentGold),
                ),
              )
            else if (_packages.isEmpty)
              _buildFallbackPricingCards(context, isUrdu, lang)
            else
              Row(
                children: List.generate(_packages.length, (index) {
                  final pkg = _packages[index];
                  final isPop = index == 1 || _packages.length == 1;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: index < _packages.length - 1 ? 8 : 0,
                        left: index > 0 ? 8 : 0,
                      ),
                      child: _buildPlanCard(
                        index: index,
                        title: pkg.storeProduct.title,
                        price: pkg.storeProduct.priceString,
                        period: pkg.packageType.toString().split('.').last.toUpperCase(),
                        badge: isPop ? (isUrdu ? "مقبول" : "POPOLARE") : null,
                        isPopular: isPop,
                      ),
                    ),
                  );
                }),
              ),
            const SizedBox(height: 22),

            // Main Purchase / CTA Button
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: subProvider.isPremium ? AppColors.passedGreen : AppColors.accentGold,
                  foregroundColor: Colors.black,
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                onPressed: () async {
                  HapticFeedback.mediumImpact();
                  if (subProvider.isPremium) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isUrdu ? "آپ پہلے سے ہی PRO ممبر ہیں! تمام خصوصیات کھلی ہوئی ہیں۔" : "Sei già un membro PRO!",
                          style: isUrdu ? AppTheme.urduStyle(fontSize: 14, color: Colors.white) : null,
                        ),
                        backgroundColor: AppColors.passedGreen,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  if (_packages.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isUrdu
                              ? "ادائیگی کی سروس فی الحال دستیاب نہیں ہے۔ براہ کرم انٹرنیٹ چیک کریں یا بعد میں کوشش کریں۔"
                              : (lang == 'en'
                                  ? "Payment service is currently unavailable. Please check internet or try again later."
                                  : "Servizio acquisti momentaneamente non disponibile. Verifica la connessione e riprova più tardi."),
                        ),
                        backgroundColor: AppColors.failedRed,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  // Safe index boundary check
                  final packageIndex = _selectedPlanIndex.clamp(0, _packages.length - 1);
                  final selectedPackage = _packages[packageIndex];

                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (ctx) => const Center(
                      child: CircularProgressIndicator(color: AppColors.accentGold),
                    ),
                  );

                  final success = await RevenueCatService.purchasePackage(selectedPackage);

                  if (context.mounted) {
                    Navigator.pop(context); // Remove loader
                  }

                  if (success) {
                    await subProvider.refreshSubscriptionStatus();
                    if (!context.mounted) return;
                    _showSuccessDialog(context, isUrdu);
                  } else {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isUrdu ? "ادائیگی منسوخ یا نامکمل رہی!" : "Pagamento annullato o non riuscito!",
                          style: isUrdu ? AppTheme.urduStyle(fontSize: 14, color: Colors.white) : null,
                        ),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                icon: Icon(
                  subProvider.isPremium ? Icons.verified_rounded : Icons.flash_on_rounded,
                  color: Colors.black,
                  size: 24,
                ),
                label: Text(
                  subProvider.isPremium
                    ? (isUrdu ? "PRO فعال ہے ✅" : "PRO ATTIVO ✅")
                    : (isUrdu ? "ابھی PRO حاصل کریں 👑" : "SBLOCCA PRO ADESSO 👑"),
                  style: isUrdu
                    ? AppTheme.urduStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)
                    : GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Trial & Guarantee Note
            Text(
              isUrdu
                ? "🔒 100% محفوظ ادائیگی • کسی بھی وقت Google Play سے منسوخ کریں"
                : "🔒 Pagamento sicuro Google Play / App Store • Annulla in qualsiasi momento",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 16),

            // Mandatory "Restore Purchases" button for App Store Review guidelines
            TextButton.icon(
              onPressed: subProvider.isRestoring
                ? null
                : () async {
                    HapticFeedback.lightImpact();
                    final restored = await subProvider.restorePurchases();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          restored
                            ? (isUrdu ? "آپ کی خریداریاں بحال ہو گئیں! 🎉" : "Acquisti ripristinati con successo! 🎉")
                            : (isUrdu ? "کوئی فعال خریداری نہیں ملی۔" : "Nessun acquisto precedente trovato."),
                          style: isUrdu ? AppTheme.urduStyle(fontSize: 14, color: Colors.white) : null,
                        ),
                        backgroundColor: restored ? AppColors.passedGreen : Colors.orange.shade800,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
              icon: subProvider.isRestoring
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.restore_rounded, size: 16, color: Colors.grey),
              label: Text(
                isUrdu ? "پہلے سے خریدا ہوا ہے؟ بحال کریں (Restore)" : "Già acquistato? Ripristina acquisti",
                style: const TextStyle(fontSize: 12, color: Colors.grey, decoration: TextDecoration.underline),
              ),
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonCard(BuildContext context, bool isUrdu, String lang) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accentGold.withOpacity(0.35), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.compare_arrows_rounded, color: AppColors.accentGold, size: 22),
              const SizedBox(width: 8),
              Text(
                isUrdu ? "فری بمقابلہ پرو (Free vs PRO)" : (lang == 'en' ? "Free vs PRO Comparison" : "Confronto Free vs PRO"),
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildComparisonRow(
            feature: isUrdu ? "امتحانی ٹاپکس" : "Argomenti d'esame",
            freeVal: isUrdu ? "صرف 5 ٹاپکس" : "Solo 5 argomenti",
            proVal: isUrdu ? "تمام 25 مکمل 🔓" : "Tutti i 25 🔓",
            isProAdvantage: true,
          ),
          _buildComparisonRow(
            feature: isUrdu ? "روزانہ امتحانی شیٹس" : "Schede esame al giorno",
            freeVal: "3 schede/giorno",
            proVal: isUrdu ? "لامحدود (Unlimited) ♾️" : "Illimitate ♾️",
            isProAdvantage: true,
          ),
          _buildComparisonRow(
            feature: isUrdu ? "خفیہ ٹوٹکے (Trucchi)" : "Trucchi Ministeriali",
            freeVal: isUrdu ? "صرف 3 نمونے" : "Solo 3 regole",
            proVal: isUrdu ? "تمام 100% ان لاک 🔑" : "Sbloccati al 100% 🔑",
            isProAdvantage: true,
          ),
          _buildComparisonRow(
            feature: isUrdu ? "غلطیوں کی اصلاح بینک" : "Banca Errori Smart",
            freeVal: isUrdu ? "بنیادی" : "Base",
            proVal: isUrdu ? "ایڈوانس ریپیٹیشن 🔄" : "Zero Errori 3x 🔄",
            isProAdvantage: true,
          ),
          _buildComparisonRow(
            feature: isUrdu ? "آف لائن کوئز اور تھیوری" : "Quiz e Teoria Offline",
            freeVal: "❌",
            proVal: isUrdu ? "✅ کوئز آف لائن" : "✅ Quiz Offline",
            isProAdvantage: true,
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonRow({
    required String feature,
    required String freeVal,
    required String proVal,
    required bool isProAdvantage,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(feature, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              freeVal,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.passedGreen.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                proVal,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.passedGreen),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackPricingCards(BuildContext context, bool isUrdu, String lang) {
    return Row(
      children: [
        _buildStaticPlanCard(
          index: 0,
          title: isUrdu ? "1 مہینہ" : "1 Mese",
          price: "€4,99",
          period: "/mese",
          isPopular: false,
        ),
        const SizedBox(width: 10),
        _buildStaticPlanCard(
          index: 1,
          title: isUrdu ? "3 مہینے" : "3 Mesi",
          price: "€9,99",
          period: "Totale (Sconto 33%)",
          badge: isUrdu ? "مقبول" : "PIÙ SCELTO",
          isPopular: true,
        ),
        const SizedBox(width: 10),
        _buildStaticPlanCard(
          index: 2,
          title: isUrdu ? "لائف ٹائم" : "A Vita",
          price: "€14,99",
          period: "Una volta sola",
          badge: isUrdu ? "بچت" : "BEST VALUE",
          isPopular: false,
        ),
      ],
    );
  }

  Widget _buildStaticPlanCard({
    required int index,
    required String title,
    required String price,
    required String period,
    String? badge,
    required bool isPopular,
  }) {
    final isSelected = _selectedPlanIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPlanIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accentGold.withOpacity(0.15) : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.accentGold : Colors.grey.withOpacity(0.25),
              width: isSelected ? 2.5 : 1,
            ),
            boxShadow: isSelected
              ? [BoxShadow(color: AppColors.accentGold.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4))]
              : [],
          ),
          child: Column(
            children: [
              if (badge != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accentGold,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                )
              else
                const SizedBox(height: 18),
              Text(
                title,
                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                price,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? AppColors.accentGold : null,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                period,
                style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required int index,
    required String title,
    required String price,
    required String period,
    String? badge,
    required bool isPopular,
  }) {
    final isSelected = _selectedPlanIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedPlanIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentGold.withOpacity(0.15) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.accentGold : Colors.grey.withOpacity(0.25),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
            ? [BoxShadow(color: AppColors.accentGold.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4))]
            : [],
        ),
        child: Column(
          children: [
            if (badge != null)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accentGold,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              )
            else
              const SizedBox(height: 18),
            Text(
              title,
              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              price,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: isSelected ? AppColors.accentGold : null,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              period,
              style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required Color color,
    required String titleIt,
    required String descIt,
    required String titleUr,
    required String descUr,
    required bool isUrdu,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withOpacity(0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUrdu ? titleUr : titleIt,
                  style: isUrdu
                    ? AppTheme.urduStyle(fontSize: 16, fontWeight: FontWeight.bold)
                    : GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  isUrdu ? descUr : descIt,
                  style: isUrdu
                    ? AppTheme.urduStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.3)
                    : TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, bool isUrdu) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            const Icon(Icons.stars_rounded, color: AppColors.accentGold, size: 30),
            const SizedBox(width: 10),
            Text(
              isUrdu ? "مبارک ہو! 🎉" : "Congratulazioni! 🎉",
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isUrdu
                ? "آپ کا PATENTE B PRO اکاؤنٹ کامیابی سے ایکٹیویٹ ہو چکا ہے!"
                : "Il tuo account Patente B PRO è stato attivato con successo!",
              style: isUrdu
                ? AppTheme.urduStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.4)
                : GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildBenefitItem(Icons.check_circle_rounded, isUrdu ? "تمام 25 امتحانی ٹاپکس مکمل ان لاک" : "Tutti i 25 argomenti sbloccati"),
            _buildBenefitItem(Icons.check_circle_rounded, isUrdu ? "خفیہ امتحانی ٹوٹکے (Trucchi) ان لاک" : "Trucchi ministeriali sbloccati"),
            _buildBenefitItem(Icons.check_circle_rounded, isUrdu ? "روزانہ لامحدود امتحانی شیٹس (Unlimited)" : "Schede d'esame illimitate"),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentGold,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text(
              isUrdu ? "ایپ کا استعمال کریں" : "Vai all'app",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: AppColors.passedGreen, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
