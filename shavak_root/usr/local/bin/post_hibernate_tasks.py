#!/usr/bin/env python
import traceback
import asyncio
import telegram
from datetime import datetime
import time, json
import os, subprocess

botinfo_file="/usr/local/etc/telegrambot-scripts/botinfo.json"

content = '''
# Broadcast Message: Uptime Mode!

BUParamShavak is coming out of Hibernation and going into Uptime.
  
This means that:

1. Normal-QoS jobs:
   * Cancelled.
2. Elevated-Qos jobs:
   * Likely resumed. 
3. Queued jobs:
   * Unaffected.

Please login and check your job status.
Remember to checkpoint jobs in future.

* Date and Time:
'''
now = datetime.now()
dt_string = now.strftime("%d/%m/%Y %H:%M:%S")
message = content + dt_string
slurm_partitions = ["CPU", "GPU"]
cmd_slurm_resume="squeue -ho %A -t S | xargs -n 1 scontrol resume"

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
        subprocess.call(cmd_slurm_resume, shell=True)
        #Bring up all SLURM partitions
        for partition in slurm_partitions:
            undraincmd = f'scontrol update PartitionName={partition} State=UP'
            os.system(undraincmd)
    except Exception:
        traceback.print_exc()
