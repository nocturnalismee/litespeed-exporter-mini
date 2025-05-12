#!/bin/bash
# Litespeed Exporter Mini
# Create & build by Arief (nocturnalismee)
# (BETA VERSION 0.1)
# https://github.com/nocturnalismee/litespeed-exporter-mini

# HOSTNAME SERVER
HOST=$(hostname)

# Path ke file .rtreport dari Litespeed
REPORT_FILE="/tmp/lshttpd/.rtreport" # Atau bisa diganti dengan /dev/shm/lsws/status/.rtreport

# Konfigurasi Telegram
TELEGRAM_BOT_TOKEN="ISI_TOKEN_BOT_ANDA"
TELEGRAM_CHAT_ID="ISI_CHAT_ID_ANDA"

# Fungsi untuk mengirim pesan ke Telegram
send_telegram() {
    local message="$1"
    curl -s --max-time 10 -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d chat_id="${TELEGRAM_CHAT_ID}" \
        -d text="$message" \
        -d parse_mode="HTML" > /dev/null
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
        # Kirim notifikasi ke Telegram dengan informasi hostname
        send_telegram "⚠️ <b>ALERT Litespeed</b>\n<b>Hostname:</b> $HOST\n<b>VHost:</b> $vhost\n<b>REQ_PROCESSING:</b> $req_processing\n<b>REQ_PER_SEC:</b> $req_per_sec\n<b>TOT_REQS:</b> $tot_reqs"
    fi
done
