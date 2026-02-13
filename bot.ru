import telebot
import time
from datetime import datetime, timedelta, timezone

TOKEN = '8264651710:AAECvnLSt6ME4A1IOy-GYDMwgdPpt-e1WFg'
CHAT_ID = '787312267'

# Очистка
import requests
requests.get(f'https://api.telegram.org/bot{TOKEN}/deleteWebhook?drop_pending_updates=True')
time.sleep(2)

bot = telebot.TeleBot(TOKEN)
bot.remove_webhook()
time.sleep(1)

def get_msk():
    return datetime.now(timezone.utc) + timedelta(hours=3)

@bot.message_handler(commands=['start'])
def start(message):
    bot.reply_to(message, "✅ Бот работает на Render!")

@bot.message_handler(commands=['time'])
def time_cmd(message):
    bot.reply_to(message, f"🕐 МСК: {get_msk().strftime('%H:%M:%S')}")

print("🚀 Бот запущен!")
bot.infinity_polling()
