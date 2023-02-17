#!/usr/bin/env python
import traceback
import asyncio
import telegram
from datetime import datetime
import os, subprocess, json, time

botinfo_file="/usr/local/etc/telegrambot-scripts/botinfo.json"

content = '''
# Broadcast Message: Downtime Notice!

BUParamShavak is going into Downtime through Hibernation.

This means that:

1. Normal-QoS jobs: 
   * Cancelled.
2. Elevated-QoS jobs: 
   * Suspend attempted.
   * Will attempt resume on restart.
3. Queued jobs: 
   * Unaffected.

This bot will announce the restart when it completes.

* Date and Time: 
'''

now = datetime.now()
dt_string = now.strftime("%d/%m/%Y %H:%M:%S")

message = content + dt_string

cmd_slurm_cancel = 'squeue -q normal -ho %A -t R| xargs -n 1 scancel'
cmd_slurm_suspend = 'squeue -q elevated -ho %A -t R | xargs -n 1 scontrol suspend'


slurm_partitions = ["CPU", "GPU"]

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
        asyncio.run(telegram_send())
        time.sleep(10.0)
        #Drain all SLURM partitions
        for partition in slurm_partitions:
            draincmd = f'scontrol update PartitionName={partition} State=DRAIN'
            os.system(draincmd)
        #Cancel all jobs running in normal SLURM QoS
        subprocess.call(cmd_slurm_cancel, shell=True)
        #Suspend all jobs running in SLURM: 
        subprocess.call(cmd_slurm_suspend, shell=True)
        time.sleep(10.0)
    except Exception:
        traceback.print_exc()
