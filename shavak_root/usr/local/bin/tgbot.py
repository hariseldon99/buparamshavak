#!/usr/bin/env python
import traceback
import asyncio
import telegram
from datetime import datetime
import sys, json

botinfo_file="/usr/local/etc/telegrambot-scripts/botinfo.json"
botinfo_file="/usr/local/etc/telegrambot-scripts/botinfo.json"

hostname = "BUParamShavak"
msg_title ="# Broadcast Message: \n"


now = datetime.now()
dt_string = now.strftime("%d/%m/%Y %H:%M:%S")

async def telegram_send(message):
    f = open(botinfo_file)
    botinfo = json.load(f)
    api_key = botinfo["api_key"]
    chatid = botinfo["chatid"]
    f.close()
    bot = telegram.Bot(api_key)
    async with bot:
        await bot.send_message(text=message, chat_id=chatid)

if __name__ == '__main__':
    try:
        content = sys.argv[1]
        message = msg_title + content + dt_string
        asyncio.run(telegram_send(message))
    except Exception:
        traceback.print_exc()
