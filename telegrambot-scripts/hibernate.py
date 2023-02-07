#!/usr/bin/env python
import traceback
import asyncio
import telegram
from datetime import datetime
import os, json, time

botinfo_file="/usr/local/etc/telegrambot-scripts/botinfo.json"

content = '''
# Broadcast Message

The Param Shavak DLGPU system is going into Hibernation Mode now.

* Date and Time: 
'''

now = datetime.now()
dt_string = now.strftime("%d/%m/%Y %H:%M:%S")

message = content + dt_string

cmd_gui = '/usr/local/bin/notify-send-all -t 10 "Hibernating Now ..."'  
#cmd_stopdwagent = '/usr/bin/systemctl is-active dwagent && /usr/bin/systemctl stop dwagent'
cmd_tty = '/usr/bin/wall -t 10 "Hibernating Now ..."'
cmd_hibernate = '/usr/bin/systemctl hibernate'

async def telegram_send():
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
        os.system(cmd_gui)
        #os.system(cmd_stopdwagent)
        os.system(cmd_tty)
        asyncio.run(telegram_send())
        time.sleep(10.0)
        os.system(cmd_hibernate)
    except Exception:
        traceback.print_exc()
