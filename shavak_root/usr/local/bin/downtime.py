#!/usr/bin/env python
import sys
import traceback
import asyncio
import telegram
from datetime import datetime
import os, json, time

botinfo_file="/usr/local/etc/telegrambot-scripts/botinfo.json"

content_scheduled = '''
# Broadcast Message: Scheduled Downtime

BUParamShavak is going into regularly scheduled maintainance downtime now.

* Date and Time: 
'''

content_unscheduled = '''
# Broadcast Message: Unscheduled Downtime

BUParamShavak is going into regularly scheduled maintainance downtime now.

* Date and Time: 
'''

now = datetime.now()
dt_string = now.strftime("%d/%m/%Y %H:%M:%S")



cmd_gui = '/usr/local/bin/notify-send-all -t 10 "Going into downtime now."'
cmd_stopdwagent = '/usr/bin/systemctl is-active dwagent && /usr/bin/systemctl stop dwagent'
cmd_tty = '/usr/bin/wall -t 10 "Going into downtime now."'
cmd_shutdown = '/usr/bin/systemctl poweroff'

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
		if len(sys.argv) > 1:
			#Scheduled Downtime
			scheduled_downtime = sys.argv[1]
			message = content_scheduled + dt_string
		else:
			#Unscheduled Downtime
			message = content_unscheduled + dt_string
		
		#Announce Downtime
		os.system(cmd_gui)
		os.system(cmd_tty)
		#asyncio.run(telegram_send(message))
		time.sleep(60.0)
		
		#Kill external logins
		#os.system(cmd_stopdwagent)
		
		#Drain all nodes on SLURM
		
		#Find and kill all running jobs on slurm
		
		#Finally, shutdown
		#os.system(cmd_shutdown)
	except Exception:
		traceback.print_exc()
