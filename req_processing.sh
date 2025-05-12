#!/bin/bash
# Litespeed Exporter Mini
# Create & build by Arief (nocturnalismee)
# (BETA VERSION 0.1)
# https://github.com/nocturnalismee/litespeed-exporter-mini

# HOSTNAME SERVER
HOST=$(hostname)

# Token & Chat ID Telegram
TBT="6764838396:AAFsCGj8iGy1do9GAOxhoPfh4n9_J_sG--Q" # Token Bot Telegram
TCID="-1002244371996" # Chat ID dari Telegram
MTID="18250" # message_thread_id dari Telegram

# Path ke file .rtreport dari Litespeed
REPORT_FILE="/tmp/lshttpd/.rtreport" # Atau bisa diganti dengan /dev/shm/lsws/status/.rtreport

# Fungsi untuk mengirimkan pesan notifikasi ke Telegram
send_telegram() {
    local message="$1"
    if [[ -n "$MTID" ]]; then
        curl -s --max-time 10 -X POST "https://api.telegram.org/bot${TBT}/sendMessage" \
            -d chat_id="${TCID}" \
            -d text="$message" \
            -d parse_mode="HTML" \
            -d message_thread_id="$MTID" > /dev/null
    else
        curl -s --max-time 10 -X POST "https://api.telegram.org/bot${TBT}/sendMessage" \
            -d chat_id="${TCID}" \
            -d text="$message" \
            -d parse_mode="HTML" > /dev/null
    fi
}

# Cek apakah file .rtreport tersedia
if [[ ! -f "$REPORT_FILE" ]]; then
    echo "File .rtreport tidak ditemukan di $REPORT_FILE"
    exit 1
fi

# Header output
printf "%-40s %-20s %-20s %-20s\n" "VHost" "REQ_PROCESSING" "REQ_PER_SEC" "TOT_REQS"

#Custom command line untuk membaca file .rtreport pada baris ke-6
grep "REQ_RATE" "$REPORT_FILE" | tail -n +6 | while read -r line; do
    req_processing=$(echo "$line" | awk -F', ' '{print $1}' | awk -F': ' '{print $3}')
    # Custom nilai untuk REQ_PROCESSING, misalnya lebih dari 30.
    if (( req_processing > 30 )); then
        vhost=$(echo "$line" | awk -F'[][]' '{print $2}')
        req_per_sec=$(echo "$line" | awk -F', ' '{print $3}' | awk -F': ' '{print $2}')
        tot_reqs=$(echo "$line" | awk -F', ' '{print $4}' | awk -F': ' '{print $2}')
        printf "%-40s %-20s %-20s %-20s\n" "$vhost" "$req_processing" "$req_per_sec" "$tot_reqs"
        # Kirim notifikasi ke Telegram dengan informasi hostname server
        send_telegram "⚠️ <b>ALERT Litespeed</b>\n<b>Hostname:</b> $HOST\n<b>VHost:</b> $vhost\n<b>REQ_PROCESSING:</b> $req_processing\n<b>REQ_PER_SEC:</b> $req_per_sec\n<b>TOT_REQS:</b> $tot_reqs"
    fi
done
