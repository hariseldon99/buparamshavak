#!/bin/bash

function echo_mem_stat () {
    mem_total="$(free | grep 'Mem:' | awk '{print $2}')"
    free_mem="$(free | grep 'Mem:'  | awk '{print $7}')"
    mem_percentage=$(($free_mem * 100 / $mem_total))
    swap_total="$(free | grep 'Swap:' | awk '{print $2}')"
    used_swap="$(free | grep 'Swap:' | awk '{print $3}')"
    swap_percentage=$(($used_swap * 100 / $swap_total))

    echo -e "Free memory:\t$((free_mem / 1024))/$((mem_total / 1024)) MB\t($mem_percentage%)"
    echo -e "Used swap:\t$((used_swap / 1024))/$((swap_total / 1024)) MB\t($swap_percentage%)"
}

echo "Testing..."
echo_mem_stat

if [[ $used_swap -eq 0 ]]; then
	echo "No swap is in use."
elif [[ $used_swap -lt $free_mem ]]; then
	echo "Freeing swap..."
	swapoff -a
	swapon -a
	echo_mem_stat
else
	echo "Not enough free memory. Exiting."
	exit 1
fi
