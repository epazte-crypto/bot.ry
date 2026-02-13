import telebot
import requests
from bs4 import BeautifulSoup
import time
import threading
from datetime import datetime, timedelta, timezone
import re
import random

# ============================================
# ТВОИ ДАННЫЕ
# ============================================
TOKEN = '8264651710:AAECvnLSt6ME4A1IOy-GYDMwgdPpt-e1WFg'
CHAT_ID = '787312267'

# Очистка перед запуском
requests.get(f'https://api.telegram.org/bot{TOKEN}/deleteWebhook?drop_pending_updates=True')
time.sleep(2)

bot = telebot.TeleBot(TOKEN)
bot.remove_webhook()
time.sleep(1)

processed_games = set()
total_analyzed = 0

# ============================================
# ВРЕМЯ МСК
# ============================================
def get_msk():
    return datetime.now(timezone.utc) + timedelta(hours=3)

# ============================================
# 5 САЙТОВ С LIVE БАСКЕТБОЛОМ
# ============================================
HEADERS = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'}

SITES = [
    {
        'name': '⚡ FlashScore',
        'url': 'https://www.flashscorekz.com/basketball/',
        'selector': 'event__match'
    },
    {
        'name': '📊 FlashScore.mobi',
        'url': 'https://www.flashscore.mobi/basketball/',
        'selector': 'match'
    },
    {
        'name': '🇷🇺 FlashScore.ru',
        'url': 'https://www.flashscore.ru/basketball/',
        'selector': 'event__match'
    },
    {
        'name': '🏀 Sport24',
        'url': 'https://sport24.ru/basketball',
        'selector': 'live-event'
    },
    {
        'name': '📈 Sports.ru',
        'url': 'https://www.sports.ru/basketball/',
        'selector': 'match-block'
    }
]

# ============================================
# ПАРСИНГ ВСЕХ САЙТОВ
# ============================================
def parse_all_sites():
    global total_analyzed
    found = 0
    
    print(f"\n{'='*60}")
    print(f"🔍 {get_msk().strftime('%H:%M:%S')} МСК - НАЧАЛО ПРОВЕРКИ")
    print(f"{'='*60}")
    
    for site in SITES:
        try:
            print(f"\n   {site['name']}...", end=' ')
            response = requests.get(site['url'], headers=HEADERS, timeout=10)
            
            if response.status_code == 200:
                soup = BeautifulSoup(response.text, 'html.parser')
                
                # Ищем матчи по селектору
                matches = soup.find_all('div', class_=re.compile(site['selector']))
                
                if not matches:
                    # Если не нашли, ищем любой div с классом содержащим match
                    matches = soup.find_all('div', class_=re.compile('match'))
                
                site_matches = 0
                for match in matches:
                    try:
                        # Получаем текст матча
                        match_text = match.get_text()
                        
                        # Ищем счет в формате "число:число"
                        scores = re.findall(r'(\d+)[:-](\d+)', match_text)
                        
                        # Ищем названия команд (русские или английские)
                        teams = re.findall(r'([А-Яа-яA-Za-z\s]{3,30}?)', match_text)
                        
                        if scores and len(teams) >= 2:
                            # Берем первые две команды и первый счет
                            team1 = teams[0].strip()[:30]
                            team2 = teams[1].strip()[:30]
                            score1 = int(scores[0][0])
                            score2 = int(scores[0][1])
                            
                            game_id = f"{team1}_{team2}_{get_msk().strftime('%Y%m%d%H')}"
                            
                            if game_id not in processed_games:
                                total = score1 + score2
                                
                                # Проверяем что это 1-я четверть (сумма 20-80)
                                if 20 <= total <= 80:
                                    is_even = total % 2 == 0
                                    parity = "ЧЕТНАЯ 🟢" if is_even else "НЕЧЕТНАЯ 🔴"
                                    
                                    # Определяем лигу по названиям команд
                                    league = "🏀 Международный"
                                    if any(word in team1 + team2 for word in ['ЦСКА', 'Зенит', 'Локомотив', 'УНИКС', 'Химки']):
                                        league = "🇷🇺 Единая лига ВТБ"
                                    elif any(word in team1 + team2 for word in ['Лейкерс', 'Уорриорз', 'Буллз', 'Селтикс']):
                                        league = "🇺🇸 NBA"
                                    elif any(word in team1 + team2 for word in ['Реал', 'Барселона', 'Олимпиакос']):
                                        league = "🇪🇺 Евролига"
                                    
                                    msg = (
                                        f"{league}\n"
                                        f"━━━━━━━━━━━━━━━━━━━━\n"
                                        f"📊 *1-я ЧЕТВЕРТЬ ЗАВЕРШЕНА!*\n\n"
                                        f"┌─ {team1}\n"
                                        f"│ vs\n"
                                        f"└─ {team2}\n"
                                        f"━━━━━━━━━━━━━━━━━━━━\n"
                                        f"📈 Счет: *{score1}:{score2}*\n"
                                        f"📊 Всего очков: *{total}*\n"
                                        f"🎯 Результат: *{parity}*\n"
                                        f"━━━━━━━━━━━━━━━━━━━━\n"
                                        f"🕐 МСК: {get_msk().strftime('%H:%M:%S')}"
                                    )
                                    
                                    bot.send_message(CHAT_ID, msg, parse_mode='Markdown')
                                    processed_games.add(game_id)
                                    total_analyzed += 1
                                    site_matches += 1
                                    print(f"\n         ✅ {team1} vs {team2} - {parity}")
                    except:
                        continue
                
                print(f" ({site_matches} матчей)")
                found += site_matches
            else:
                print("❌")
        except Exception as e:
            print(f"❌")
        
        time.sleep(2)
    
    print(f"\n📊 ИТОГО: найдено {found} новых матчей")
    print(f"📈 Всего проанализировано: {total_analyzed}")

# ============================================
# КОМАНДЫ БОТА
# ============================================
@bot.message_handler(commands=['start'])
def start(message):
    msg = (
        "🏀 *БАСКЕТБОЛЬНЫЙ МОНИТОР*\n"
        "━━━━━━━━━━━━━━━━━━━━\n"
        "✅ Мониторинг 5 сайтов\n"
        "✅ Live матчи со всего мира\n"
        "✅ Проверка каждые 2 минуты\n\n"
        "📊 *Команды:*\n"
        "• /status - статистика\n"
        "• /sites - список сайтов\n"
        "• /time - московское время\n"
        "• /test - тест уведомления\n"
        "━━━━━━━━━━━━━━━━━━━━"
    )
    bot.reply_to(message, msg, parse_mode='Markdown')

@bot.message_handler(commands=['sites'])
def sites(message):
    sites_list = "\n".join([f"• {s['name']}" for s in SITES])
    msg = (
        f"🌐 *ОТСЛЕЖИВАЕМЫЕ САЙТЫ*\n"
        f"━━━━━━━━━━━━━━━━━━━━\n"
        f"{sites_list}\n"
        f"━━━━━━━━━━━━━━━━━━━━"
    )
    bot.reply_to(message, msg, parse_mode='Markdown')

@bot.message_handler(commands=['time'])
def time_cmd(message):
    bot.reply_to(message, f"🕐 Московское время: {get_msk().strftime('%H:%M:%S')}")

@bot.message_handler(commands=['status'])
def status(message):
    msg = (
        f"📊 *СТАТИСТИКА РАБОТЫ*\n"
        f"━━━━━━━━━━━━━━━━━━━━\n"
        f"✅ Проанализировано матчей: *{total_analyzed}*\n"
        f"📈 В базе данных: {len(processed_games)}\n"
        f"🌐 Активных сайтов: {len(SITES)}\n"
        f"🕐 МСК: {get_msk().strftime('%H:%M:%S')}\n"
        f"━━━━━━━━━━━━━━━━━━━━"
    )
    bot.reply_to(message, msg, parse_mode='Markdown')

@bot.message_handler(commands=['test'])
def test(message):
    # Тестовый матч
    test_games = [
        ("ЦСКА", "Зенит", 24, 22, "🇷🇺 Единая лига ВТБ"),
        ("ЛА Лейкерс", "Голден Стэйт", 28, 32, "🇺🇸 NBA"),
        ("Реал Мадрид", "Барселона", 25, 27, "🇪🇺 Евролига"),
    ]
    game = random.choice(test_games)
    total = game[2] + game[3]
    parity = "ЧЕТНАЯ 🟢" if total % 2 == 0 else "НЕЧЕТНАЯ 🔴"
    
    msg = (
        f"{game[4]}\n"
        f"━━━━━━━━━━━━━━━━━━━━\n"
        f"📊 *1-я ЧЕТВЕРТЬ ЗАВЕРШЕНА!*\n\n"
        f"{game[0]} vs {game[1]}\n"
        f"Счет: {game[2]}:{game[3]}\n"
        f"Всего очков: *{total}*\n"
        f"Результат: *{parity}*\n"
        f"━━━━━━━━━━━━━━━━━━━━\n"
        f"🕐 МСК: {get_msk().strftime('%H:%M:%S')}"
    )
    bot.send_message(CHAT_ID, msg, parse_mode='Markdown')
    bot.reply_to(message, "✅ Тестовое уведомление отправлено!")

# ============================================
# ЦИКЛ ПАРСИНГА
# ============================================
def monitoring_loop():
    while True:
        try:
            parse_all_sites()
            print(f"\n⏰ Следующая проверка через 2 минуты...")
            time.sleep(120)
        except Exception as e:
            print(f"Ошибка: {e}")
            time.sleep(60)

# ============================================
# ЗАПУСК
# ============================================
if __name__ == "__main__":
    thread = threading.Thread(target=monitoring_loop)
    thread.daemon = True
    thread.start()
    
    print("\n" + "="*60)
    print("🏀 БАСКЕТБОЛЬНЫЙ МОНИТОР v7.0")
    print("="*60)
    print(f"🚀 Запуск: {get_msk().strftime('%Y-%m-%d %H:%M:%S')} МСК")
    print("🌐 Сайтов для парсинга: 5")
    print("⏰ Интервал проверки: 2 минуты")
    print("="*60)
    print("\n✅ Команды в Telegram:")
    print("   /start  - приветствие")
    print("   /status - статистика")
    print("   /sites  - список сайтов")
    print("   /time   - московское время")
    print("   /test   - тест уведомления")
    print("="*60)
    
    bot.infinity_polling()
