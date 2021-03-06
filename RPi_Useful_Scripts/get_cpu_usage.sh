#!/bin/bash
# Make the total cpu utilization measurement
# When sleep duration is 0s, the sampling interval is about 0.2s
startTime=$(date +%s.%N)
cpu="cpu"
sleepDurationSeconds=$1
echo "time,freq,util"

# taken the previous measurement
previousStats=$(cat /proc/stat)
# Only get the total cpu info line
previousLine=$(echo "$previousStats" | grep "$cpu ")
prevuser=$(echo "$previousLine" | awk -F " " '{print $2}')
prevnice=$(echo "$previousLine" | awk -F " " '{print $3}')
prevsystem=$(echo "$previousLine" | awk -F " " '{print $4}')
previdle=$(echo "$previousLine" | awk -F " " '{print $5}')
previowait=$(echo "$previousLine" | awk -F " " '{print $6}')
previrq=$(echo "$previousLine" | awk -F " " '{print $7}')
prevsoftirq=$(echo "$previousLine" | awk -F " " '{print $8}')
prevsteal=$(echo "$previousLine" | awk -F " " '{print $9}')
prevguest=$(echo "$previousLine" | awk -F " " '{print $10}')
prevguest_nice=$(echo "$previousLine" | awk -F " " '{print $11}')
# echo $previousLine
sleep $sleepDurationSeconds

while true; do
    currentTime=$(date +%s.%N)
    currentStats=$(cat /proc/stat)
    
    currentLine=$(echo "$currentStats" | grep "$cpu ")
    user=$(echo "$currentLine" | awk -F " " '{print $2}')
    nice=$(echo "$currentLine" | awk -F " " '{print $3}')
    system=$(echo "$currentLine" | awk -F " " '{print $4}')
    idle=$(echo "$currentLine" | awk -F " " '{print $5}')
    iowait=$(echo "$currentLine" | awk -F " " '{print $6}')
    irq=$(echo "$currentLine" | awk -F " " '{print $7}')
    softirq=$(echo "$currentLine" | awk -F " " '{print $8}')
    steal=$(echo "$currentLine" | awk -F " " '{print $9}')
    guest=$(echo "$currentLine" | awk -F " " '{print $10}')
    guest_nice=$(echo "$currentLine" | awk -F " " '{print $11}')

    PrevIdle=$((previdle + previowait))
    Idle=$((idle + iowait))

    PrevNonIdle=$((prevuser + prevnice + prevsystem + previrq + prevsoftirq + prevsteal))
    NonIdle=$((user + nice + system + irq + softirq + steal))

    PrevTotal=$((PrevIdle + PrevNonIdle))
    Total=$((Idle + NonIdle))

    totald=$((Total - PrevTotal))
    idled=$((Idle - PrevIdle))

    # calculate the total cpu util
    CPU_Percentage=$(awk "BEGIN {print ($totald - $idled)/$totald*100}")

    # calculate the avg cpu freq
    CPU_Freq_List=$(cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq)
    CPU_Freq=$(echo "$CPU_Freq_List" | awk -F " " '{ total += $1; count++ } END { print total/count }')
    elapsedTime=$(echo "$currentTime-$startTime" | bc)

    echo "$elapsedTime,$CPU_Freq,$CPU_Percentage"

    # prepare for the next round
    prevuser=$user
    prevnice=$nice
    prevsystem=$system
    previdle=$idle
    previowait=$iowait
    previrq=$irq
    prevsoftirq=$softirq
    prevsteal=$steal
    prevguest=$guest
    prevguest_nice=$guest_nice

    sleep $sleepDurationSeconds

done
