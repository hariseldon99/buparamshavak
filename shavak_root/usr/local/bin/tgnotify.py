#!/usr/bin/env python
from tgbot import *

shutdown_announce = f'''Unscheduled Downtime!\n
{hostname} is going into downtime through full shutdown.\n
'''

bootup_announce = f'''Uptime Mode!\n
{hostname} is coming out of shutdown and going into uptime.\n
'''

pre_hibernate_announce = f''' Downtime Notice.\n
{hostname} is going into downtime through hibernation.\n
'''

post_hibernate_announce = f''' Uptime Mode.\n
{hostname} is coming out of hibernation and going into uptime.\n
'''

shutdown_content = f'''
1. All running jobs: Cancelled.
2. Queued jobs: Unaffected.\n
'''

bootup_content = '''
1. All running jobs: Cancelled.
2. Queued jobs: Unaffected.\n
'''

pre_hibernate_content = '''
1. Normal-QoS jobs: 
   * Cancelled.
2. Elevated-QoS jobs: 
   * Suspend attempted.
   * Will attempt resume on restart.
3. Queued jobs: 
   * Unaffected.\n
'''

post_hibernate_content = '''
1. Normal-QoS jobs:
   * Cancelled.
2. Elevated-Qos jobs:
   * Likely resumed. 
3. Queued jobs:
   * Unaffected.\n
'''

advice_poweroff = "This bot will announce the restart when it completes.\n\n"

advice_startup = '''Please login and check your job status.
Remember to checkpoint jobs in future.\n\n'''

msg_content = {'shutdown': shutdown_announce + shutdown_content + advice_poweroff, 
               'bootup' : bootup_announce + bootup_content + advice_startup,
               'pre_hibernate' : pre_hibernate_announce + pre_hibernate_content + advice_poweroff,
               'post_hibernate' : post_hibernate_announce + post_hibernate_content + advice_startup
               }

if __name__ == '__main__':
    try:
        asyncio.run(telegram_send(msg_title + msg_content[sys.argv[1]] +\
                                  dt_string))    
    except Exception:
        traceback.print_exc()
