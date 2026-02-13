import telebot
import requests
from bs4 import BeautifulSoup
import time
import threading
from datetime import datetime, timedelta, timezone
import re

TOKEN = '8264651710:AAECvnLSt6ME4A1IOy-GYDMwgdPpt-e1WFg'
CHAT_ID = '787312267'

# Очистка вебхуков
requests.get(f'https://api.telegram.org/bot{TOKEN}/deleteWebhook?drop_pending_updates=True')
time.sleep(1)

bot = telebot.TeleBot(TOKEN)
processed_games = set()
total_analyzed = 0

# ============================================
# ВРЕМЯ
# ============================================
def get_msk():
    return datetime.now(timezone.utc) + timedelta(hours=3)

# ============================================
# ПАРСИНГ
# ============================================
HEADERS = {'User-Agent': 'Mozilla/5.0'}

def parse_flashscore():
    global total_analyzed
    try:
        url = "https://www.flashscorekz.com/basketball/"
        r = requests.get(url, headers=HEADERS, timeout=10)
        
        if r.status_code == 200:
            soup = BeautifulSoup(r.text, 'html.parser')
            matches = soup.find_all('div', class_='event__match')
            
            for match in matches:
                try:
                    home = match.find('div', class_='event__homeParticipant')
                    away = match.find('div', class_='event__awayParticipant')
                    scores = match.find_all('span', class_='event__score')
                    
                    if home and away and len(scores) >= 2:
                        h_name = home.text.strip()
                        a_name = away.text.strip()
                        h_score = int(scores[0].text.strip())
                        a_score = int(scores[1].text.strip())
                        
                        game_id = f"{h_name}_{a_name}_{get_msk().strftime('%Y%m%d%H')}"
                        
                        if game_id not in processed_games:
                            total = h_score + a_score
                            if 20 <= total <= 80:
                                is_even = total % 2 == 0
                                parity = "ЧЕТНАЯ 🟢" if is_even else "НЕЧЕТНАЯ 🔴"
                                
                                msg = (
                                    f"🏀 *{h_name} vs {a_name}*\n"
                                    f"━━━━━━━━━━━━━━━━\n"
                                    f"📊 *1-я ЧЕТВЕРТЬ!*\n\n"
                                    f"{h_name}: {h_score}\n"
                                    f"{a_name}: {a_score}\n"
                                    f"Всего: {total}\n"
                                    f"Результат: {parity}\n"
                                    f"━━━━━━━━━━━━━━━━\n"
                                    f"🕐 МСК: {get_msk().strftime('%H:%M:%S')}"
                                )
                                
                                bot.send_message(CHAT_ID, msg, parse_mode='Markdown')
                                processed_games.add(game_id)
                                total_analyzed += 1
                except:
                    continue
    except Exception as e:
        print(f"Ошибка: {e}")

# ============================================
# КОМАНДЫ
# ============================================
@bot.message_handler(commands=['start'])
def start(message):
    bot.reply_to(message, "🏀 Бот работает!\n/status - статистика\n/time - время")

@bot.message_handler(commands=['time'])
def time_cmd(message):
    bot.reply_to(message, f"🕐 МСК: {get_msk().strftime('%H:%M:%S')}")

@bot.message_handler(commands=['status'])
def status(message):
    bot.reply_to(message, f"📊 Проанализировано: {total_analyzed}")

@bot.message_handler(commands=['test'])
def test(message):
    bot.send_message(CHAT_ID, "🔔 Тест!")
    bot.reply_to(message, "✅ Отправлено")

# ============================================
# ЦИКЛ ПАРСИНГА
# ============================================
def monitor():
    while True:
        print(f"\n🔍 {get_msk().strftime('%H:%M:%S')} МСК - Проверка...")
        parse_flashscore()
        print(f"📊 Всего: {total_analyzed}")
        time.sleep(120)

thread = threading.Thread(target=monitor)
thread.daemon = True
thread.start()

print("\n" + "="*50)
print("🏀 БАСКЕТБОЛЬНЫЙ МОНИТОР")
print("="*50)
print(f"🚀 Запуск: {get_msk().strftime('%H:%M:%S')} МСК")
print("✅ Команды: /status, /time, /test")
print("="*50)

bot.infinity_polling()
