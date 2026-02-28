#!/bin/bash
# Litespeed Exporter Mini
# Create & build by nocturnalismee
# VERSION 1.0)
# https://github.com/nocturnalismee/litespeed-exporter-mini

set -euo pipefail # Menghentikan script jika ada command yang gagal atau variabel kosong (kecuali di-handle)

# KONFIGURASI PENGGUNAAN & TELEGRAM
THRESHOLD_REQ=800                    # Batas minimal REQ_PROCESSING untuk memicu alert
TBT="MASUKAN_TOKEN_BOT_TELEGRAM"     # Token Bot Telegram (Kosongkan jika hanya ingin tampil di terminal)
TCID="MASUKAN_CHAT_ID_TELEGRAM"      # Chat ID Telegram
MTID=""                              # Message Thread ID (Opsional, isi jika menggunakan topik grup)

# FUNGSI SISTEM (Jangan diubah)
HOST=$(hostname -f 2>/dev/null || hostname)

# 1. Auto-detect lokasi file .rtreport (cPanel / Plesk / CyberPanel)
get_report_file() {
    local paths=(
        "/tmp/lshttpd/.rtreport"
        "/dev/shm/lsws/status/.rtreport"
        "/tmp/lshttpd/status/.rtreport"
    )
    for p in "${paths[@]}"; do
        if [[ -f "$p" ]]; then
            echo "$p"
            return 0
        fi
    done
    return 1
}

REPORT_FILE=$(get_report_file) || { echo "❌ ERROR: File .rtreport tidak ditemukan di server ini."; exit 1; }

# 2. Fungsi Mengirim Telegram yang lebih aman (menggunakan array)
send_telegram() {
    local message="$1"
    
    # Lewati jika Token/ID belum diisi
    if [[ "$TBT" == "MASUKAN_TOKEN_BOT_TELEGRAM" || -z "$TCID" ]]; then
        return 0
    fi

    local url="https://api.telegram.org/bot${TBT}/sendMessage"
    local -a curl_args=(
        "-s" "--max-time" "10"
        "-X" "POST" "$url"
        "-d" "chat_id=${TCID}"
        "-d" "text=${message}"
        "-d" "parse_mode=HTML"
    )

    if [[ -n "$MTID" ]]; then
        curl_args+=("-d" "message_thread_id=${MTID}")
    fi

    curl "${curl_args[@]}" > /dev/null || true
}

# 3. Parsing nama VHost (Menghapus APVH_, VH_, dan port)
parse_vhost_name() {
    local raw="$1"
    # Hapus prefix APVH_ atau VH_, lalu hapus apapun setelah tanda ':' atau spasi
    echo "$raw" | sed -E 's/^(APVH_|VH_)//; s/(:.*|_[a-zA-Z0-9]+$)//'
}

# 4. Auto-detect file akses log berdasarkan Control Panel
find_log_file() {
    local dom="$1"
    local possible_logs=(
        "/usr/local/apache/domlogs/$dom-ssl_log"       # cPanel (HTTPS - Prioritas)
        "/usr/local/apache/domlogs/$dom"               # cPanel (HTTP)
        "/var/www/vhosts/system/$dom/logs/access_log"  # Plesk
        "/var/www/vhosts/system/$dom/logs/access_ssl_log" # Plesk SSL
        "/home/$dom/logs/access.log"                   # CyberPanel
    )
    for log in "${possible_logs[@]}"; do
        if [[ -f "$log" && -s "$log" ]]; then # Pastikan file ada & tidak kosong
            echo "$log"
            return 0
        fi
    done
    return 1
}

# 5. Mendapatkan Top IP
get_top_attackers() {
    local log_file="$1"
    if [[ -f "$log_file" ]]; then
        # Menggunakan 5000 baris terakhir, karena jika req_processing > 800, 1000 baris hanya mencakup 1 detik waktu logs
        tail -n 5000 "$log_file" | awk '{print $1}' | sort | uniq -c | sort -nr | head -10
    else
        echo "Log file tidak ditemukan untuk domain ini."
    fi
}

# MAIN EKSEKUSI
echo "Menganalisa .rtreport dari: $REPORT_FILE"
printf "%-35s | %-15s | %-15s | %-15s\n" "VHost" "REQ_PROCESSING" "REQ_PER_SEC" "TOT_REQS"
echo "----------------------------------------------------------------------------------------"

# Menggunakan Regex Bash untuk mengekstrak nilai (Jauh lebih aman dan cepat daripada pipe AWK)
while read -r line; do
    # Regex untuk menangkap line: REQ_RATE [APVH_domain]: REQ_PROCESSING: 100, REQ_PER_SEC: 10.0, TOT_REQS: 5000
    if [[ "$line" =~ REQ_RATE\ \[(.*)\]:\ REQ_PROCESSING:\ ([0-9]+),\ REQ_PER_SEC:\ ([0-9.]+),\ TOT_REQS:\ ([0-9]+) ]]; then
        vhost="${BASH_REMATCH[1]}"
        req_processing="${BASH_REMATCH[2]}"
        req_per_sec="${BASH_REMATCH[3]}"
        tot_reqs="${BASH_REMATCH[4]}"

        # Cek jika melebihi batas konfigurasi
        if (( req_processing > THRESHOLD_REQ )); then
            domain=$(parse_vhost_name "$vhost")
            log_file=$(find_log_file "$domain" || echo "")
            
            top_ips="Tidak ada data IP."
            if [[ -n "$log_file" ]]; then
                top_ips=$(get_top_attackers "$log_file")
            fi

            # Print ke terminal
            printf "%-35s | %-15s | %-15s | %-15s\n" "$vhost" "$req_processing ⚠️" "$req_per_sec" "$tot_reqs"
            echo -e "📂 Log Target: $log_file\n💀 Top Attackers:\n$top_ips\n"

            # Format Pesan Telegram
            tg_msg="<b>⚠️ ALERT LITESPEED ATTACK ⚠️</b>
<pre>
SERVER  : $HOST
VHOST   : $domain
REQ_PROC: $req_processing ❗
REQ/SEC : $req_per_sec
TOT_REQ : $tot_reqs
</pre>
<b>Top Attackers IPs:</b>
<pre>$top_ips</pre>"

            send_telegram "$tg_msg"
        fi
    fi
done < <(grep "^REQ_RATE \
