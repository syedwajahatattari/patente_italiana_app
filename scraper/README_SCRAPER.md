# Data Scraping Guide for Italy Driving License (Patente B)

This directory contains the automated python scraper used to pull and format ministerial quiz data for the Patente Italiana Flutter application.

## 📌 Data Sources
1. **Ministero delle Infrastrutture e dei Trasporti (MIT)** official ministerial quiz database.
2. **Il Portale dell'Automobilista** (`https://www.ilportaledellautomobilista.it/`)
3. **Public Quiz Portals** (`https://www.mininterno.net/`, `https://www.quizpatente.it/`, `https://www.patentati.it/`)
4. Open Source GitHub Mirrors (`avalla/quiz-patente-ab`)

## 🚀 How to Run the Scraper

```bash
cd scraper
pip install -r requirements.txt
python3 scrape_patente.py
```

The script will fetch the questions, extract the Vero/Falso answer key, group by topic, download sign images, and save JSON straight into `../assets/data/`.
