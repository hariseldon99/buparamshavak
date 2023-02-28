#!/usr/bin/env python
#from tgbot import *
import sys, requests, json
import traceback

botinfo_file="/etc/slurm-llnl/tgslurmbot.conf"
api_url = 'https://api.telegram.org/bot{token}/{method}'.format
buparamshavak_chatid = '-1001215703472'

hostname = "BUParamShavak"

shutdown_announce = f'''Unscheduled Downtime!
----------------------------------------\n
{hostname} - **FULL SHUTDOWN**
'''

bootup_announce = f'''Uptime Mode!
----------------------------------------\n
{hostname} - **BOOTUP**
'''

pre_hibernate_announce = f''' Downtime Notice.
----------------------------------------\n
{hostname} - **HIBERNATING**
'''

post_hibernate_announce = f''' Uptime Mode.
----------------------------------------\n
{hostname}  - **WAKEUP**
'''

shutdown_content = f'''
- All running jobs: Cancelled.
- Queued jobs: Unaffected.\n
'''

bootup_content = '''
- All running jobs: Cancelled.
- Queued jobs: Unaffected.\n
'''

pre_hibernate_content = '''
- All running jobs: Likely suspended. 
- Queued jobs: Unaffected.
- Suspended jobs: Will attempt resume.\n
'''

post_hibernate_content = '''
- All running jobs: Likely resumed. 
- Queued jobs: Unaffected.\n
'''

advice_poweroff = "This bot will broadcast after restart."

advice_startup = '''Please login and check your job status.
Remember to checkpoint jobs in future.'''

msg_content = {'shutdown': shutdown_announce + shutdown_content + advice_poweroff, 
               'bootup' : bootup_announce + bootup_content + advice_startup,
               'pre_hibernate' : pre_hibernate_announce + pre_hibernate_content + advice_poweroff,
               'post_hibernate' : post_hibernate_announce + post_hibernate_content + advice_startup
               }

def telegram_command(token, name, data):
    url = api_url(token=token, method=name)
    return requests.post(url=url, json=data)

def telegram_sendMessage(api_key, text: str, chat_id: str, notify=True):
    return telegram_command(api_key,'sendMessage', {
        'text': text,
        'chat_id': chat_id,
        'parse_mode': 'markdown',
        'disable_notification': not notify})

if __name__ == '__main__':
    try:
        f = open(botinfo_file)
        botinfo = json.load(f)
        if botinfo["defaultconnector"] == "telegram":
            connectors = botinfo["connectors"]
            telegram = connectors["telegram"]
            api_key = telegram["token"]
    
            chat_id = buparamshavak_chatid
        else:
            pass
        f.close()
        
        message = msg_content[sys.argv[1]]
        result = telegram_sendMessage(api_key, message, chat_id)
    
    except Exception:
        traceback.print_exc()
