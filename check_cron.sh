#!/bin/bash

USER=$(whoami)
FILE_PATH="/home/${USER}/.s5"
PM2_PATH="/home/${USER}/.npm-global/lib/node_modules/pm2/bin/pm2"

CRON_S5="nohup ${FILE_PATH}/s5 -c ${FILE_PATH}/config.json >/dev/null 2>&1 &"
CRON_JOB="*/12 * * * * $PM2_PATH resurrect >> /home/$(whoami)/pm2_resurrect.log 2>&1"
REBOOT_COMMAND="@reboot pkill -kill -u $(whoami) && $PM2_PATH resurrect >> /home/$(whoami)/pm2_resurrect.log 2>&1"
ARGO_JOB="0 */6 * * * ~/argo_install.sh >> /home/$(whoami)/argo_install.log 2>&1"
S5_KEEPALIVE="*/12 * * * * pgrep -x \"s5\" > /dev/null || ${CRON_S5}"

echo "检查并添加 crontab 任务"

# 检查 pm2 是否存在，若存在则设置 pm2 保活任务
if [ "$(command -v pm2)" == "/home/${USER}/.npm-global/bin/pm2" ]; then
  echo "已安装 pm2，并返回正确路径，启用 pm2 保活任务"
  (crontab -l | grep -F "$REBOOT_COMMAND") || (crontab -l; echo "$REBOOT_COMMAND") | crontab -
  (crontab -l | grep -F "$CRON_JOB") || (crontab -l; echo "$CRON_JOB") | crontab -
else
  # 检查 socks5 配置文件是否存在，若存在则添加 socks5 保活任务
  if [ -e "${FILE_PATH}/config.json" ]; then
    echo "添加 socks5 的 crontab 保活任务"
    (crontab -l | grep -F "@reboot pkill -kill -u $(whoami) && ${CRON_S5}") || (crontab -l; echo "@reboot pkill -kill -u $(whoami) && ${CRON_S5}") | crontab -
    (crontab -l | grep -F "$S5_KEEPALIVE") || (crontab -l; echo "$S5_KEEPALIVE") | crontab -
  fi
fi

# 添加 argo_install.sh 每6小时执行一次的 crontab
(crontab -l | grep -F "$ARGO_JOB") || (crontab -l; echo "$ARGO_JOB") | crontab -

echo "crontab 任务设置完成"
