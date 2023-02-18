#!/usr/bin/env python
# Instructions: Symlink /usr/local/bin/poweroff to this script
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

now = datetime.now()
dt_string = now.strftime("%d/%m/%Y %H:%M:%S")

cmd_stopdwagent = '/usr/bin/systemctl is-active dwagent && /usr/bin/systemctl stop dwagent'
cmd_slurm_cancel = 'squeue -ho %A -t R| xargs -n 1 scancel'
cmd_slurm_shutdown = 'scontrol shutdown'
cmd_os_shutdown = '/usr/sbin/poweroff'

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
        #Announce Downtime
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
        os.system(cmd_os_shutdown)

    except Exception:
        traceback.print_exc()
