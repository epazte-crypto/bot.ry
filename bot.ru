import telebot
import requests
import time
import threading
from datetime import datetime, timedelta, timezone
import random

TOKEN = '8264651710:AAECvnLSt6ME4A1IOy-GYDMwgdPpt-e1WFg'
CHAT_ID = '787312267'

bot = telebot.TeleBot(TOKEN)
total = 0

def get_msk():
    return datetime.now(timezone.utc) + timedelta(hours=3)

@bot.message_handler(commands=['start'])
def start(message):
    bot.reply_to(message, "🏀 Бот работает!\n/status - статистика")

@bot.message_handler(commands=['status'])
def status(message):
    bot.reply_to(message, f"📊 Найдено матчей: {total}")

@bot.message_handler(commands=['time'])
def time_cmd(message):
    bot.reply_to(message, f"🕐 МСК: {get_msk().strftime('%H:%M:%S')}")

@bot.message_handler(commands=['test'])
def test(message):
    global total
    total += 1
    bot.send_message(CHAT_ID, f"🔔 Тест #{total}")
    bot.reply_to(message, f"✅ Отправлено #{total}")

def demo_matches():
    global total
    games = [
        ("ЦСКА", "Зенит", 24, 22),
        ("ЛА Лейкерс", "Голден Стэйт", 28, 32),
        ("Реал Мадрид", "Барселона", 25, 27),
    ]
    while True:
        time.sleep(180)
        game = random.choice(games)
        total_score = game[2] + game[3]
        parity = "ЧЕТНАЯ 🟢" if total_score % 2 == 0 else "НЕЧЕТНАЯ 🔴"
        msg = f"🏀 *{game[0]} vs {game[1]}*\nСчет: {game[2]}:{game[3]}\nВсего: {total_score}\nРезультат: {parity}"
        bot.send_message(CHAT_ID, msg, parse_mode='Markdown')
        total += 1

thread = threading.Thread(target=demo_matches)
thread.daemon = True
thread.start()

print("✅ Бот запущен на Koyeb!")
bot.infinity_polling()
