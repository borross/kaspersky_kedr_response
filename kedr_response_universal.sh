#!/bin/bash
#RU_PRESALE_TEAM_BORIS_O

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

UUID_FILE=UUID.txt
KATA_IP=KATA_IP.txt
LONG_CURL="curl -k --cert ./kata_ext.pem –key ./kata_ext.pem -X"
usage="\n$(basename "$0") [-h] [-uuid] [-kata] [-kedr_isolate] [-kedr_isolate_off] [-kedr_block] [-kedr_exec] <ARGUMENTS> -- program for executing response commands in KEDR \n
\n
where:\n
    ${YELLOW}-h${NC} -- show this help text\n
    ${YELLOW}-uuid${NC} -- generate or show KUMA UUID for KATA integration\n
    ${YELLOW}-kata <KATA_IP_ADDRESS>${NC} -- generating crt/key (for new request) and send confirmation to KATA\n
    ${YELLOW}-kedr_isolate <KEDR_IP_ADDRESS> <HOURS>${NC} -- isolating KEDR_IP_ADDRESS host from network for <HOURS> hours\n
    ${YELLOW}-kedr_isolate_off <KEDR_IP_ADDRESS>${NC} -- disabling isolation <KEDR_IP_ADDRESS> host from network for <HOURS> hours\n
    ${YELLOW}-kedr_block <KEDR_IP_ADDRESS or all> <md5 or sha256> <hash>${NC} -- disabling isolation <KEDR_IP_ADDRESS> host from network for <HOURS> hours\n
    ${YELLOW}-kedr_exec <KEDR_IP_ADDRESS> \"<file_execute>\"${NC} -- file executing on host <KEDR_IP_ADDRESS>. For path use four back slashes instead of one.\n
\n
	Type: ${YELLOW}journalctl | grep kuma-KEDR-response${NC} -- for looking script activity in log
\n
"

if [[ $# -eq 0 ]]; then
	echo -e "${RED}No arguments supplied${NC}"
	echo -e $usage
	exit 1
fi

case $1 in
	"-h")
	echo -e $usage
	;;

	"-uuid")
        if [[ ! -f $UUID_FILE ]]; then
                echo -e "${YELLOW}No UUID file!\nGenerating UUID in file ...${NC}"
                touch $UUID_FILE && uuidgen > $UUID_FILE
                echo -e "${GREEN}UUID $(cat ${UUID_FILE}) generated!${NC}"
        else
                echo -e "${GREEN}Your UUID is $(cat ${UUID_FILE})${NC}"
        fi
	;;

        "-kata")
        if [[ ! -f $UUID_FILE ]]; then
                echo -e "${YELLOW}No UUID file!\nUse -uuid option!${NC}"
		echo -e $usage
		exit 1
	fi

	CHK_IP1=$(awk -v ip="$2" ' BEGIN { n=split(ip, i,"."); e = 0; if (6 < length(ip) && length(ip) < 16 && n == 4 && i[4] > 0 && i[1] > 0){for(z in i){if (i[z] !~ /[0-9]{1,3}/ || i[z] > 256){e=1;break;}}} else { e=1; } print(e);}') 
	if [[ ! $# -eq 2 ]] || [[ $2 == ""  ]] || [[ $CHK_IP2 -eq 1 ]]; then
		echo -e "${YELLOW}Please enter valid KATA IP address!\nExample: -kata 192.168.123.123${NC}"
	else
		touch $KATA_IP && $2 > $KATA_IP
		if [[ ! -f "kata_ext.key" ]] && [[ ! -f "kata_ext.crt" ]]; then
			echo -e "${YELLOW}No key/crt files for KATA\nGenerating files ...${NC}"
			openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout kata_ext.pem -out kata_ext.pem -subj "/C=RU/ST=MSK/L=Moscow/O=Company Name/OU=Org/CN=$(hostname -f)"
		fi
		$LONG_CURL GET https://$(cat ${KATA_IP}):443/kata/scanner/v1/sensors/$(cat ${UUID_FILE})/scans/state
		$LONG_CURL GET https://$(cat ${KATA_IP}):443/kata/scanner/v1/sensors/$(cat ${UUID_FILE})/sensors
		echo -e "${GREEN}Your key/crt files are generated!${NC}"
	fi
        ;;

        "-kedr_isolate")
        if [[ ! -f $UUID_FILE ]]; then
                echo -e "${YELLOW}No UUID file!\nUse -uuid option!${NC}"
                echo -e $usage
                exit 1
        fi

	if [[ ! -f "kata_ext.key" ]] && [[ ! -f "kata_ext.crt" ]]; then
                echo -e "${YELLOW}No key/crt files for KATA!\nUse -kata option!${NC}"
                echo -e $usage
                exit 1
	fi

	CHK_IP1=$(awk -v ip="$2" ' BEGIN { n=split(ip, i,"."); e = 0; if (6 < length(ip) && length(ip) < 16 && n == 4 && i[4] > 0 && i[1] > 0){for(z in i){if (i[z] !~ /[0-9]{1,3}/ || i[z] > 256){e=1;break;}}} else { e=1; } print(e);}')
	if [[ ! $# -eq 3 ]] || [[ $2 == ""  ]] || [[ $CHK_IP1 -eq 1 ]]; then
                echo -e "${YELLOW}Please enter valid KEDR host or isolate time!!\nExample: --kedr_isolate 192.168.123.123 100${NC}"
        else
		agentId=$($LONG_CURL GET https://$(cat ${KATA_IP}):443/kata/response_api/v1/$(cat ${UUID_FILE})/sensors?ip=$2 | jq -r ".sensors[0]|.sensorId")
		cmd=$($LONG_CURL POST "https://$(cat ${KATA_IP}):443/kata/response_api/v1/$(cat ${UUID_FILE})/settings?sensor_id=$agentId&settings_type=network_isolation" -H "Content-Type: application/json" -d "{settings: {autoTurnoffTimeoutInSec: $4}}" --write-out %{http_code})
		write_to_log=$(echo "kata_ip: $(cat ${KATA_IP}), host_ip: $2, agent_id: $agentId, result: $cmd" | systemd-cat -t kuma-KEDR-response-ISOLATION -p info)
	fi
        ;;

        "-kedr_isolate_off")
        if [[ ! -f $UUID_FILE ]]; then
                echo -e "${YELLOW}No UUID file!\nUse -uuid option!${NC}"
                echo -e $usage
                exit 1
        fi

        if [[ ! -f "kata_ext.key" ]] && [[ ! -f "kata_ext.crt" ]]; then
                echo -e "${YELLOW}No key/crt files for KATA!\nUse -kata option!${NC}"
                echo -e $usage
                exit 1
        fi

	CHK_IP1=$(awk -v ip="$2" ' BEGIN { n=split(ip, i,"."); e = 0; if (6 < length(ip) && length(ip) < 16 && n == 4 && i[4] > 0 && i[1] > 0){for(z in i){if (i[z] !~ /[0-9]{1,3}/ || i[z] > 256){e=1;break;}}} else { e=1; } print(e);}')
        if [[ ! $# -eq 2 ]] || [[ $2 == ""  ]] || [[ $CHK_IP1 -eq 1 ]]; then
                echo -e "${YELLOW}Please enter valid KEDR host!\nExample: --kedr_isolate_off 192.168.123.123${NC}"
        else
                agentId=$($LONG_CURL GET https://$(cat ${KATA_IP}):443/kata/response_api/v1/$(cat ${UUID_FILE})/sensors?ip=$2 | jq -r ".sensors[0]|.sensorId")
		cmd=$($LONG_CURL DELETE "https://$(cat ${KATA_IP}):443/kata/response_api/v1/$(cat ${UUID_FILE})/settings?sensor_id=$agentId&settings_type=network_isolation" --write-out %{http_code})
                write_to_log=$(echo "kata_ip: $(cat ${KATA_IP}), host_ip: $2, agent_id: $agentId, result: $cmd" | systemd-cat -t kuma-KEDR-response-ISOLATION-OFF -p info)
        fi
        ;;

        "-kedr_block")
        if [[ ! -f $UUID_FILE ]]; then
                echo -e "${YELLOW}No UUID file!\nUse -uuid option!${NC}"
                echo -e $usage
                exit 1
        fi

        if [[ ! -f "kata_ext.key" ]] && [[ ! -f "kata_ext.crt" ]]; then
                echo -e "${YELLOW}No key/crt files for KATA!\nUse -kata option!${NC}"
                echo -e $usage
                exit 1
        fi

	CHK_IP1=$(awk -v ip="$2" ' BEGIN { n=split(ip, i,"."); e = 0; if (6 < length(ip) && length(ip) < 16 && n == 4 && i[4] > 0 && i[1] > 0){for(z in i){if (i[z] !~ /[0-9]{1,3}/ || i[z] > 256){e=1;break;}}} else { e=1; } print(e);}')
        if [[ $2 == "all" ]];then
                CHK_IP1=0
		agentId="all"
        else
                CHK_IP1=1
		agentId=$($LONG_CURL GET https://$(cat ${KATA_IP}):443/kata/response_api/v1/$(cat ${UUID_FILE})/sensors?ip=$2 | jq -r ".sensors[0]|.sensorId")
        fi

        if [[ $4 =~ ^(md5|sha256)$ ]] && [[ $5 =~ ^([0-9a-f]{32}|[0-9a-f]{64})$ ]];then
		CHK_IP1=0
	else
		CHK_IP1=1
		echo -e "${YELLOW}It is not a hash!${NC}"
	fi

        if [[ ! $# -eq 4 ]] || [[ $2 == ""  ]] || [[ $CHK_IP1 -eq 1 ]]; then
                echo -e "${YELLOW}Please enter valid KEDR_host_IP/all then md5/sha256 <hash>!\nExample: --kedr_block 192.168.123.123 md5 <md5hash>${NC}"
        else
                cmd=$($LONG_CURL POST "https://$(cat ${KATA_IP}):443/kata/response_api/v1/$(cat ${UUID_FILE})/settings?sensor_id=$agentId&settings_type=prevention" -H "Content-Type: application/json" -d "{settings: {objects: [{file: {$4: $5}}]}}"  --write-out %{http_code})
                write_to_log=$(echo "kata_ip: $(cat ${KATA_IP}), host_ip: $2, agent_id: $agentId, hash_type: $4, hash: $5, result: $cmd" | systemd-cat -t kuma-KEDR-response-BLOCK -p info)
        fi
        ;;

        "-kedr_exec")
        if [[ ! -f $UUID_FILE ]]; then
                echo -e "${YELLOW}No UUID file!\nUse -uuid option!${NC}"
                echo -e $usage
                exit 1
        fi

        if [[ ! -f "kata_ext.key" ]] && [[ ! -f "kata_ext.crt" ]]; then
                echo -e "${YELLOW}No key/crt files for KATA!\nUse -kata option!${NC}"
                echo -e $usage
                exit 1
        fi

	CHK_IP1=$(awk -v ip="$2" ' BEGIN { n=split(ip, i,"."); e = 0; if (6 < length(ip) && length(ip) < 16 && n == 4 && i[4] > 0 && i[1] > 0){for(z in i){if (i[z] !~ /[0-9]{1,3}/ || i[z] > 256){e=1;break;}}} else { e=1; } print(e);}')
        if [[ ! $# -eq 3 ]] || [[ $2 == ""  ]] || [[ $CHK_IP1 -eq 1 ]]; then
                echo -e "${YELLOW}Please enter valid KEDR_host_IP/all command in quotas \"<command>\" for path use four back slashes!\nExample: --kedr_exec 192.168.123.123 192.168.123.12 \"response_script.bat\"${NC}"
        else
                TASK_ID=$(uuidgen)
		agentId=$($LONG_CURL GET https://$(cat ${KATA_IP}):443/kata/response_api/v1/$(cat ${UUID_FILE})/sensors?ip=$2 | jq -r ".sensors[0]|.sensorId")
                cmd=$($LONG_CURL POST "https://$(cat ${KATA_IP}):443/kata/response_api/v1/$(cat ${UUID_FILE})/tasks/$TASK_ID?sensor_id=$agentId&task_type=run_process" -H "Content-Type: application/json" -d "{task: {schedule: {startNow: true}, execCommand: \"$4\"}}" --write-out %{http_code})
                write_to_log=$(echo "kata_ip: $(cat ${KATA_IP}), host_ip: $2, agent_id: $agentId, task_id: $TASK_ID, cmd_exec: $4, result: $cmd" | systemd-cat -t kuma-KEDR-response-EXECUTE -p info)
        fi
	;;

	* )
	echo -e $usage
	;;
esac
