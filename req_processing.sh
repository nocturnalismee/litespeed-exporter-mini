#!/bin/bash
#///////////////////////////////////////////////////////////
# Demo Litespeed Exporter Mini
# Create & build by Arief (nocturnalismee
# https://github.com/nocturnalismee/simple-monitor-utility
#///////////////////////////////////////////////////////////



# Path ke file .rtreport
REPORT_FILE="/tmp/lshttpd/.rtreport" # Atau path ini dapat diganti dengan /dev/shm/lsws/status/.rtreport karena keduanya dihubungkan dengan symlink ketika saya cek


# Cek apakah file .rtreport ada
if [[ ! -f "$REPORT_FILE" ]]; then
    echo "File .rtreport tidak ditemukan di $REPORT_FILE"
    exit 1
fi

# Custom untuk baca file .rtreport dan cari baris yang mengandung REQ_RATE dengan REQ_PROCESSING
grep "REQ_RATE" "$REPORT_FILE" | tail -n +6 | while read -r line; do
    # Nilai REQ_PROCESSING
    req_processing=$(echo "$line" | awk -F', ' '{print $1}' | awk -F': ' '{print $3}')
    
    # Custom Cek REQ_PROCESSING lebih dari 30 misalnya
    if (( req_processing > 30 )); then
        # Ekstrak informasi VHost dan metrik lainnya
        vhost=$(echo "$line" | awk -F'[][]' '{print $2}')
        req_per_sec=$(echo "$line" | awk -F', ' '{print $3}' | awk -F': ' '{print $2}')
        tot_reqs=$(echo "$line" | awk -F', ' '{print $4}' | awk -F': ' '{print $2}')
        
        # Menampilkan hasil
         printf "%-40s %-20s %-20s %-20s\n" "VHost: $vhost" "REQ_PROCESSING: $req_processing" "REQ_PER_SEC: $req_per_sec" "TOT_REQS: $tot_reqs"
    fi
done
