#!/bin/bash

USER=$(whoami)
WORKDIR="/home/${USER}/.nezha-agent"
FILE_PATH="/home/${USER}/.s5"
VMESS_PATH="/home/${USER}/.vmess"  # 添加 vmess 的路径

CRON_S5="nohup ${FILE_PATH}/s5 -c ${FILE_PATH}/config.json >/dev/null 2>&1 &"
CRON_NEZHA="nohup ${WORKDIR}/start.sh >/dev/null 2>&1 &"
CRON_VM="nohup ${VMESS_PATH}/bot tunnel --edge-ip-version auto --config tunnel.yml run >/dev/null 2>&1 &"  # vmess 保活命令
PM2_PATH="/home/${USER}/.npm-global/lib/node_modules/pm2/bin/pm2"

CRON_JOB="*/12 * * * * $PM2_PATH resurrect >> /home/$(whoami)/pm2_resurrect.log 2>&1"
REBOOT_COMMAND="@reboot pkill -kill -u $(whoami) && $PM2_PATH resurrect >> /home/$(whoami)/pm2_resurrect.log 2>&1"

echo "检查并添加 crontab 任务"

if [ "$(command -v pm2)" == "/home/${USER}/.npm-global/bin/pm2" ]; then
  echo "已安装 pm2，并返回正确路径，启用 pm2 保活任务"
  (crontab -l | grep -F "$REBOOT_COMMAND") || (crontab -l; echo "$REBOOT_COMMAND") | crontab -
  (crontab -l | grep -F "$CRON_JOB") || (crontab -l; echo "$CRON_JOB") | crontab -
  (crontab -l | grep -F "*/12 * * * * pgrep -x \"bot\" > /dev/null || ${CRON_VM}") || (crontab -l; echo "*/12 * * * * pgrep -x \"bot\" > /dev/null || ${CRON_VM}") | crontab -  # 添加 vmess 保活的 crontab
else
  if [ -e "${WORKDIR}/start.sh" ] && [ -e "${FILE_PATH}/config.json" ] && [ -e "${VMESS_PATH}/tunnel.yml" ]; then
    echo "添加 nezha, socks5 & vmess 的 crontab 保活任务"
    (crontab -l | grep -F "@reboot pkill -kill -u $(whoami) && ${CRON_S5} && ${CRON_NEZHA} && ${CRON_VM}") || (crontab -l; echo "@reboot pkill -kill -u $(whoami) && ${CRON_S5} && ${CRON_NEZHA} && ${CRON_VM}") | crontab -
    (crontab -l | grep -F "*/12 * * * * pgrep -x \"nezha-agent\" > /dev/null || ${CRON_NEZHA}") || (crontab -l; echo "*/12 * * * * pgrep -x \"nezha-agent\" > /dev/null || ${CRON_NEZHA}") | crontab -
    (crontab -l | grep -F "*/12 * * * * pgrep -x \"s5\" > /dev/null || ${CRON_S5}") || (crontab -l; echo "*/12 * * * * pgrep -x \"s5\" > /dev/null || ${CRON_S5}") | crontab -
    (crontab -l | grep -F "*/12 * * * * pgrep -x \"bot\" > /dev/null || ${CRON_VM}") || (crontab -l; echo "*/12 * * * * pgrep -x \"bot\" > /dev/null || ${CRON_VM}") | crontab -  # 添加 vmess 保活的 crontab
  elif [ -e "${WORKDIR}/start.sh" ]; then
    echo "添加 nezha 的 crontab 重启任务"
    (crontab -l | grep -F "@reboot pkill -kill -u $(whoami) && ${CRON_NEZHA}") || (crontab -l; echo "@reboot pkill -kill -u $(whoami) && ${CRON_NEZHA}") | crontab -
    (crontab -l | grep -F "*/12 * * * * pgrep -x \"nezha-agent\" > /dev/null || ${CRON_NEZHA}") || (crontab -l; echo "*/12 * * * * pgrep -x \"nezha-agent\" > /dev/null || ${CRON_NEZHA}") | crontab -
    (crontab -l | grep -F "*/12 * * * * pgrep -x \"bot\" > /dev/null || ${CRON_VM}") || (crontab -l; echo "*/12 * * * * pgrep -x \"bot\" > /dev/null || ${CRON_VM}") | crontab -  # 添加 vmess 保活的 crontab
  elif [ -e "${FILE_PATH}/config.json" ]; then
    echo "添加 socks5 的 crontab 重启任务"
    (crontab -l | grep -F "@reboot pkill -kill -u $(whoami) && ${CRON_S5}") || (crontab -l; echo "@reboot pkill -kill -u $(whoami) && ${CRON_S5}") | crontab -
    (crontab -l | grep -F "*/12 * * * * pgrep -x \"s5\" > /dev/null || ${CRON_S5}") || (crontab -l; echo "*/12 * * * * pgrep -x \"s5\" > /dev/null || ${CRON_S5}") | crontab -
    (crontab -l | grep -F "*/12 * * * * pgrep -x \"bot\" > /dev/null || ${CRON_VM}") || (crontab -l; echo "*/12 * * * * pgrep -x \"bot\" > /dev/null || ${CRON_VM}") | crontab -  # 添加 vmess 保活的 crontab
  fi
fi
