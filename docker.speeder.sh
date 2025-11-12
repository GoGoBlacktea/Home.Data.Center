#!/bin/bash
clear
# 定义颜色代码
readonly BLACK='\033[30m'
readonly RED='\033[31m'
readonly GREEN='\033[32m'
readonly YELLOW='\033[33m'
readonly BLUE='\033[34m'
readonly MAGENTA='\033[35m'
readonly CYAN='\033[36m'
readonly WHITE='\033[37m'
readonly RESET='\033[0m'

echo -e "
${WHITE}    _    _             _                _    _                   _          _               
${RED}   | |  (_)           (_)              | |  / )                 | |        | |              
${CYAN}    \ \  _ ____  ____  _ ____   ____   | | / / ____   ___  _ _ _| | ____ _ | | ____  ____   
${YELLOW}     \ \| |  _ \|  _ \| |  _ \ / _  |  | |< < |  _ \ / _ \| | | | |/ _  ) || |/ _  |/ _  )  
${GREEN} _____) ) | | | | | | | | | | ( ( | |  | | \ \| | | | |_| | | | | ( (/ ( (_| ( ( | ( (/ /   
${BLUE}(______/|_| ||_/| ||_/|_|_| |_|\_|| |  |_|  \_)_| |_|\___/ \____|_|\____)____|\_|| |\____)  
${MAGENTA}          |_|   |_|           (_____|                                        (_____|        
${BLUE}       _      _        ______  _             _                                              
${GREEN}      (_)_   | |      (____  \| |           | |    _                                        
${YELLOW} _ _ _ _| |_ | | _     ____)  ) | ____  ____| |  _| |_  ____ ____                           
${CYAN}| | | | |  _)| || \   |  __  (| |/ _  |/ ___) | / )  _)/ _  ) _  |                          
${RED}| | | | | |__| | | |  | |__)  ) ( ( | ( (___| |< (| |_( (/ ( ( | |                          
${WHITE} \____|_|\___)_| |_|  |______/|_|\_||_|\____)_| \_)\___)____)_||_|                          
                                                                                            
${GREEN}================================================================${RESET}
     一键更新 本地Docker镜像加速地址（原地备份版） v1.3 
${GREEN}================================================================${RESET}
${RED}[注意：本脚本只针对Linux环境]${RESET}

" 

# 提示用户输入本地加速镜像地址
read -p "请输入本地加速镜像地址（格式：http://IP:PORT 或 https://IP:PORT ，如果不需要本地镜像源，请直接按回车）： " local_mirror

# 检查输入格式
if [[ -n $local_mirror && ! $local_mirror =~ ^(http|https)://[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(:[0-9]+)?$ ]]; then
  echo "输入格式错误，请确保输入格式为 http://IP:PORT 或 https://IP:PORT。"
  exit 1
fi

# 如果用户输入了本地镜像源，则提取协议、IP和端口
if [ -n "$local_mirror" ]; then
  protocol=$(echo $local_mirror | awk -F '://' '{print $1}')
  ip_port=$(echo $local_mirror | awk -F '://' '{print $2}')
  ip=$(echo $ip_port | awk -F ':' '{print $1}')
  port=$(echo $ip_port | awk -F ':' '{print $2}')

  # 如果没有指定端口，则根据协议设置默认端口
  if [ -z "$port" ]; then
    if [ "$protocol" == "http" ]; then
      port=80
    elif [ "$protocol" == "https" ]; then
      port=443
    fi
  fi

  # 构造完整的镜像地址
  if [ "$port" == "80" ] && [ "$protocol" == "http" ]; then
    local_mirror="$protocol://$ip"
  elif [ "$port" == "443" ] && [ "$protocol" == "https" ]; then
    local_mirror="$protocol://$ip"
  else
    local_mirror="$protocol://$ip:$port"
  fi
fi

# 定义备份文件的路径和日期时间
BACKUP_FILE="/etc/docker/daemon.json.$(date +%Y%m%d%H%M%S).bak"

# 检查 daemon.json 文件是否存在
if [ -f /etc/docker/daemon.json ]; then
  # 提示用户开始备份
  echo "正在备份原始 daemon.json 文件到 $BACKUP_FILE..."

  # 备份原始 daemon.json 文件
  sudo mv /etc/docker/daemon.json "$BACKUP_FILE"

  # 检查备份是否成功
  if [ $? -eq 0 ]; then
    echo "备份成功！"
  else
    echo "备份失败，请检查权限或文件路径。"
    exit 1
  fi
else
  echo "未找到 daemon.json 文件，将直接创建新文件。"
fi

# 提示用户开始更新 daemon.json 文件
echo "正在更新 daemon.json 文件内容..."

# 定义新的 daemon.json 内容
if [ -n "$local_mirror" ]; then
  cat <<JSON | sudo tee /etc/docker/daemon.json
{
  "registry-mirrors": [
    "$local_mirror",
    "https://docker.1ms.run",
    "https://docker.nju.edu.cn",
    "https://ghcr.nju.edu.cn",
    "https://xget.xi-xu.me"
  ],
  "insecure-registries": [
    "$ip"
  ]
}
JSON
else
  cat <<JSON | sudo tee /etc/docker/daemon.json
{
  "registry-mirrors": [
    "https://docker.1ms.run",
    "https://docker.nju.edu.cn",
    "https://ghcr.nju.edu.cn",
    "https://xget.xi-xu.me"
  ]
}
JSON
fi

# 检查更新是否成功
if [ $? -eq 0 ]; then
  echo "daemon.json 文件更新成功！"
else
  echo "更新失败，请检查权限或文件路径。"
  exit 1
fi

# 提示用户正在重启 Docker 服务
echo "正在重启 Docker 服务中..."

# 重启 Docker 服务
sudo systemctl restart docker

# 检查服务是否重启成功
if [ $? -eq 0 ]; then
  echo "Docker 服务重启成功！"
else
  echo "Docker 服务重启失败，请检查服务状态。"
  exit 1
fi

# 输出操作结果
if [ -f "$BACKUP_FILE" ]; then
  echo "Docker daemon.json 文件已更新并备份到 $BACKUP_FILE"
else
  echo "Docker daemon.json 文件已创建并更新"
fi


# MIT License
#
# Copyright (c) [2025] [GoGoBlacktea]
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
