# Starting a headless windows virtual machine with vagrant and Virtualbox

## Introduction
Since BUParamShavak runs Ubuntu Linux as a base OS, running windows software will require a windows Virtual Machine (VM). Your VMs will be hosted in this on top of your base OS, sharing its resources. VirtualBox is an open source (GPL v2) virtualization platform that works on almost any base OS, and is installed on BUParamShavak. For advanced users, it also has some command line, advanced networking capabilities, and integrates nicely with Vagrant. Vagrant is a time-saving open source (MIT) tool that acts as a simple frontend to VMs. It allows for some fundamental integration and automation with platforms like VirtualBox, Microsoft Hyper-V, VMware, etc. In summary, this is a time-saving tool for standing up VMs faster, configuring them, adding packages to VMs, or integrating your virtual platforms.

A windows VM can be downloaded freely from the Vagrant cloud network. However, note that Microsoft only allows you to use a single VM instance for three months, after which you'll have to download a new instance again. Also, note that there is a single folder in the VM, named "C:\vagrant_data\", that is synchronized with the host (BUParamShavak). Therefore, all your input, scratch and output files must be placed there.

Also, note that VMs can only be accessed locally on BUParamShavak. **Remote access to running VMs using the DWService system is not currently possible**, although I am working on enabling this.

Finally, the VM will run headlessly. That means, it will run in the background.So, you'll have to access it using a Remote Desktop Protocol, or RDP. The Remmina RDP client, installed on the host, can do this.

Thus, the workflow will be:

For the first time:

* Start an interactive shell job on the SLURM engine on the host.

* From that shell, download and initialize a windows Virtual Machine from the Vagrant Cloud. The VM will run headlessly.

* From the same shell, start a remote desktop (RDP) client and connect to the VM.

* Once you have access to the VM, install and run the required software from the 'C:\vagrant_data\' folder.

* When finished, exit the RDP client, go back to the host shell and shutdown the VM

* Exit the host shell, thus terminating the SLURM job


Next time, you do not need to download the VM, since it was already downloaded and saved. Just start an interactive shell job on SLURM, initialize the previous VM, connect to it using the RDP client, and do your work. Once finished, you can kill the client, shutdown the VM and exit the host shell.


## Instructions

1. First, choose the number of processors that you will use, as well as the total memory. These should be elss than the amount allowed by the SLURM scheduler. Typically acceptable values are 4,8, or 16 cpus and 4GB (4096 MB), 8GB (8192 MB), or 16 GB (16384 MB) of RAM.

1. A sample vagrant file and data directory can be found in $EXAMPLES/vagrant. Copy it over to your home directory with the command

	```bash
	$ cp -R $EXAMPLES/vagrant $HOME
	```

2. Change to the copied vagrant directory with "cd $HOME/vagrant". In there, you will see a file named "Vagrantfile". This file contains the parameters for the virtual machine. Open it using any text editor like nano or vi.

3. In the file, look at the section beginning with "Vagrant.configure("2") do |config|". The following lines are configured

	```json
	config.vm.box = "valengus/windows10-22h2-x64-pro"
	config.vm.box_version = "1.0.20230501"
	```
   	These specify the VM that will be downloaded from Vagrant cloud. Do not change these unless problems occur.
   
   	```json
   	config.vm.network "forwarded_port", guest: 3389, host: 3389, host_ip: "127.0.0.1"
   	```
   	Here, 3389 is the port number for accessing the windows remote desktop while the VM is running headlessly.
   
   	```json
   	config.vm.synced_folder "./data", "/vagrant_data"
   	```
   	This ensures that the folder $HOME/vagrant/data in the host is synced with the "C:\vagrant_data\" folder in the VM.			
	
	```json
	config.vm.provider "virtualbox" do |vb|
      		vb.cpus = "8"
		vb.memory = "8192"
  	end
	```
   	These entries fix the number of VM cpus and RAM in MB. Adjust these as per the recommendations above.	

4. Save the exit Vagrantfile. Now, put all your install files and input data in $HOME/vagrant/data so that your VM has access to them.

5. Now, start an interactive shell using SLURM. tell the grid engine to allocate the same number of cpus as you put in the 'vb.cpus' entry in Vagrantfile. In this example., it is 8.

	```bash
	srun --ntasks=8 --job-name=vagrant <ADDITIONAL SLURM OPTIONS, IF ANY> --pty bash
	```
   	This will start a bash shell with resources allocated by SLURM.
   
6. In the vagrant directory. Initialize the VM with the command

	```bash
	$vagrant up
	```
   	Note that, if you're doing this for the first time, this will download the VM and then initialize it, which will take some time, depending on available internet bandwidth. If you've already done this before, then it will simply initialize the downloaded VM with parameters from Vagrantfile.	
	
7. Once the VM is initialized, check the status with the command 

	```bash
	$vagrant status
	```
   	The VM should be shown as 'running'.
   
 8. Once the VM is confirmed to be running, start the RDP client from the interactive host shell with the command  		

	```bash
	$remmina
	```
    	A window should open with the RDP client in it. On the top bar, select "RDP" for the access protocol, and enter the local ip address of BUParamShavak, followed by the port number of the RDP 		server. The local ip address is '127.0.0.1', and the port number is '3389', unless you've changed it in Vagrantfile. Enter it thus:
    
	```bash
	127.0.0.1:3389
	``` 
	or
	```bash
	localhost:3389
	```
	Then, press Enter. The RDP client will try to connect to the Windows VM, when prompted for credentials, enter the default username and password as shown below
	
	```json
	username: vagrant
	password: vagrant
	```	
	Click "Connect". 
	
9. If all goes well, the RDP client should show you a windows desktop. Navigate to "C:\vagrant_data\" using either a PowerShell or Windows Explorer and install your software and run it as needed.
	Note that, while running any software, you can kill the RDP window. Windows will continue to run in the background. To get back to it, simply start remmina from the interactive host shell 		and log into the VM again.

10. When you're finished, make sure that all output files and data are somewhere in "C:\vagrant_data\", then exit the RDP client by killing the window. To terminate the VM, simply go back to the interactive shell and enter the following command:

	```bash
	$vagrant halt
	```
	Once the VM has been halted, check the status using the 'vagrant status' command as shown above. make sure that the status reads "poweroff".

11. Finally, exit the interactive shell with the command

	```bash
	$exit
	```
	and your job is finished! All outputs can be found in the '$HOME/vagrant/data' directory on the host.

