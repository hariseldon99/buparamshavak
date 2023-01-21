#!/usr/bin/env python
import traceback
import asyncio
import telegram
from datetime import datetime
import time, json

botinfo_file="./botinfo.json"

content = '''
# Broadcast Message

The Param Shavak DLGPU system is coming out of Hibernation Mode now.

* Date and Time: 
'''
now = datetime.now()
dt_string = now.strftime("%d/%m/%Y %H:%M:%S")

message = content + dt_string

async def main():
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
        time.sleep(10.0)
        asyncio.run(main())
    except Exception:
        traceback.print_exc()
