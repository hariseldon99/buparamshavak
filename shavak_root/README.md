#To copy quota settings from user1 to user2:

```bash
	edquota -p user1 user2
```

#Setting up swapfile and hibernating to it

url: https://askubuntu.com/questions/6769/hibernate-and-resume-from-a-swap-file

Make your /swapfile have at least the size of your RAM
sudo swapoff /swapfile
sudo dd if=/dev/zero of=/swapfile bs=$(cat /proc/meminfo | awk '/MemTotal/ {print $2}') count=1024 conv=notrunc
sudo mkswap /swapfile
sudo swapon /swapfile
Note the UUID of the partition containing your /swapfile:
$ sudo findmnt -no UUID -T /swapfile
20562a02-cfa6-42e0-bb9f-5e936ea763d0
Reconfigure the package uswsusp in order to correctly use the swapfile:
sudo dpkg-reconfigure -pmedium uswsusp
# Answer "Yes" to continue without swap space
# Select "/dev/disk/by-uuid/20562a02-cfa6-42e0-bb9f-5e936ea763d0" replace the UUID with the result from the previous findmnt command
# Encrypt: "No"
Edit the SystemD hibernate service using sudo systemctl edit systemd-hibernate.service and fill it with the following content:
[Service]
ExecStart=
ExecStartPre=-/bin/run-parts -v -a pre /lib/systemd/system-sleep
ExecStart=/usr/sbin/s2disk
ExecStartPost=-/bin/run-parts -v --reverse -a post /lib/systemd/system-sleep
Note the resume offset of your /swapfile:
$ sudo swap-offset /swapfile
resume offset = 34818
Configure Grub to resume from the swapfile by editing /etc/default/grub and modify the following line:
GRUB_CMDLINE_LINUX_DEFAULT="resume=UUID=20562a02-cfa6-42e0-bb9f-5e936ea763d0 resume_offset=34818 quiet splash"
Update Grub:
sudo update-grub
Create the following /etc/initramfs-tools/conf.d/resume:
RESUME=UUID=20562a02-cfa6-42e0-bb9e-5e936ea763d0 resume_offset=34816
    # Resume from /swapfile
Update initramfs:
sudo update-initramfs -u -k all
Now you can hibernate with sudo systemctl hibernate.

One can also lock screen before hibernating with the command

dbus-send --type=method_call --dest=org.gnome.ScreenSaver /org/gnome/ScreenSaver org.gnome.ScreenSaver.Lock
sleep 2

