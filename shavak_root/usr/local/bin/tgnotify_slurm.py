#!/usr/bin/env python
import sys, subprocess
import traceback
import asyncio
import telegram
from datetime import datetime
import os, json, time

botinfo_file="/usr/local/etc/telegrambot-scripts/botinfo.json"

shutdown_msg_content = '''
# Broadcast Message: Unscheduled Downtime!

BUParamShavak is going into Downtime through full shutdown.

This means that:

1. All running jobs: Cancelled.
2. Queued jobs: Unaffected.

This bot will announce the restart when it completes.

* Date and Time: 
'''

bootup_msg_content = '''
# Broadcast Message: Uptime Mode!

BUParamShavak is cold booting and going into Uptime.

This means that:

1. All running jobs:
   * Cancelled.
2. Queued jobs:
   * Unaffected.

Please login and check your job status.
Remember to checkpoint jobs in future.

* Date and Time:
'''

now = datetime.now()
dt_string = now.strftime("%d/%m/%Y %H:%M:%S")

cmd_gui = '/usr/local/bin/notify-send-all -t 10 "BUParamShavak will shutdown soon. Save your work and logout now!"'
cmd_stopdwagent = '/usr/bin/systemctl is-active dwagent && /usr/bin/systemctl stop dwagent'
cmd_tty = '/usr/bin/wall -t 10 "BUParamShavak will shutdown soon. Save your work and logout now!"'
cmd_slurm_cancel = 'squeue -ho %A -t R| xargs -n 1 scancel'
cmd_slurm_shutdown = 'scontrol shutdown'

slurm_partitions = ["CPU", "GPU"]

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
            if sys.argv[1] == 'shutdown':
                #Announce Downtime
                os.system(cmd_gui)
                os.system(cmd_tty)
                message = shutdown_msg_content + dt_string
                asyncio.run(telegram_send(message))
                time.sleep(10.0)
		
		#Kill external logins
		#os.system(cmd_stopdwagent)
		
		#Drain all SLURM partitions
                #for partition in slurm_partitions:
                #    draincmd = f'scontrol update PartitionName={partition} State=DRAIN'
                #    os.system(draincmd)
                #Cancel all running jobs
                #subprocess.call(cmd_slurm_cancel, shell=True)
                #subprocess.call(cmd_slurm_shutdown, shell=True)
             
            elif sys.argv[1] == 'bootup':
                message = bootup_msg_content + dt_string
                asyncio.run(telegram_send(message))
                #UnDrain all SLURM partitions
                #for partition in slurm_partitions:
                #    undraincmd = f'scontrol update PartitionName={partition} State=UP'
                #    os.system(undraincmd)
            else:
                print("Error: Please enter either 'shutdown' or 'bootup' as options.")

	except Exception:
		traceback.print_exc()
