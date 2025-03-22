#!/bin/bash

PIHOLE_DNS="192.168.1.30"  
GOOGLE_DNS="8.8.8.8"       
CLOUDFLARE_DNS="1.1.1.1"   

DOMINIOS=($(cat dominios.txt))  
TOTAL_DOMINIOS=${#DOMINIOS[@]} 

DISPOSITIVOS=10

DOMINIOS_POR_DISPOSITIVO=$((TOTAL_DOMINIOS / DISPOSITIVOS))

testar_estresse_dns() {
    local dns_server=$1
    local total_time=0
    local count=0

    echo "🔄 Executando teste de estresse no DNS: $dns_server com $DISPOSITIVOS dispositivos simultâneos"
    echo "====================================="

    for ((i=0; i<DISPOSITIVOS; i++)); do
        (
            inicio=$((i * DOMINIOS_POR_DISPOSITIVO))
            fim=$((inicio + DOMINIOS_POR_DISPOSITIVO))

            for ((j=inicio; j<fim; j++)); do
                dominio=${DOMINIOS[j]}
                query_time=$(dig $dominio @$dns_server | grep "Query time" | awk '{print $4}')
                
                if [[ -n "$query_time" ]]; then
                    echo "[Dispositivo $((i+1))] $dominio → Tempo: $query_time ms"
                    echo "$query_time" >> "resultados_$dns_server.txt"  
                else
                    echo "[Dispositivo $((i+1))] $dominio → Falha ao resolver"
                fi
                
                sleep 0.5  
            done
        ) &
    done

    wait

    if [[ -f "resultados_$dns_server.txt" ]]; then
        total_time=$(awk '{sum+=$1} END {print sum}' "resultados_$dns_server.txt")
        count=$(wc -l < "resultados_$dns_server.txt")
        media_time=$(awk "BEGIN {printf \"%.2f\", $total_time/$count}")
        rm "resultados_$dns_server.txt"  
    else
        media_time="N/A"
    fi

    echo " Teste de estresse finalizado para $dns_server"
    echo " Média do tempo de resposta: $media_time ms"
    echo "====================================="
}


testar_estresse_dns $PIHOLE_DNS
testar_estresse_dns $GOOGLE_DNS
testar_estresse_dns $CLOUDFLARE_DNS
