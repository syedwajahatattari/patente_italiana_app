import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class ScrapingGuideScreen extends StatelessWidget {
  const ScrapingGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Web Scraper & Data Sources", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.teal, Color(0xFF0F766E)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cloud_download_rounded, color: Colors.white, size: 44),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Data Scraping Blueprint", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text("کوئز کا ڈیٹا کہاں سے اور کیسے اسکریپ کرنا ہے", style: GoogleFonts.inter(fontSize: 13, color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildSection(
              context,
              title: "1. Data Scraping Sources (ڈیٹا کہاں سے اسکریپ ہوگا)",
              icon: Icons.public_rounded,
              content: """
• Il Portale dell'Automobilista (ilportaledellautomobilista.it):
  اٹلی کی منسٹری آف ٹرانسپورٹ (MIT) کا آفیشل پورٹل جہاں سے آفیشل سوالات حاصل کیے جاتے ہیں۔

• QuizPatente.it & Mininterno.net:
  عوام کے لیے مفت آن لائن پریکٹس پورٹلز جہاں چیپٹر وائز اور ٹریفک سائنز کا تمام ڈیٹا دستیاب ہے۔

• Open Source GitHub Repositories:
  'avalla/quiz-patente-ab' اور 'DomandePatenteB' جیسے اوپن سورس پروجیکٹس جہاں سے منسٹریل 7,000+ سوالات اور تصاویر JSON میں مل سکتی ہیں۔
""",
            ),

            _buildSection(
              context,
              title: "2. Python Scraper Tool (اسکرپٹ چلانے کا طریقہ)",
              icon: Icons.code_rounded,
              content: """
پروجیکٹ کی سورس ڈائریکٹری میں پائتھون اسکریپر موجود ہے:
'scraper/scrape_patente.py'

اسکرپٹ چلانے کی کمانڈز:
1. Terminal کھولیے:
   cd scraper

2. لائبریریز انسٹال کیجیے:
   pip install -r requirements.txt

3. اسکریپر رن کریں:
   python3 scrape_patente.py

یہ اسکرپٹ خود بخود تمام سوالات، VERO/FALSO کیز اور تصاویر ڈاؤن لوڈ کر کے 'assets/data/quiz_questions.json' میں اپ ڈیٹ کر دے گی۔
""",
            ),

            _buildSection(
              context,
              title: "3. Multi-Language & Urdu Support Strategy",
              icon: Icons.translate_rounded,
              content: """
آفیشل منسٹریل امتحان صرف اٹالین زبان میں ہوتا ہے۔ یہ ایپ اٹالین سوالات کے ساتھ رومن اردو اور انگلش کی ڈکشنری منسلک کرتی ہے تاکہ تارکینِ وطن (جنوبی ایشیائی طلباء) کو پیپر کی تکنیکی زبان سمجھنے میں آسانی ہو۔
""",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required String title, required IconData icon, required String content}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 24),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold))),
            ],
          ),
          const Divider(height: 20),
          Text(content, style: const TextStyle(fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }
}
