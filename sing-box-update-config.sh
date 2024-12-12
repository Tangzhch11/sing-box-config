#!/bin/sh

# 配置参数
BACKEND_URL="http://192.168.8.198:5000"
SUBSCRIPTION_URL="https://www.xn--5hqx9equq.org/api/v1/client/subscribe?token=07ebfb5c3dd522f757a143817e6bb9e4"
TEMPLATE_URL="https://raw.githubusercontent.com/Tangzhch11/sing-box-config/main/config.json"
CONFIG_FILE="/storage/sing-box/config.json"

# 构建完整的配置文件 URL
FULL_URL="${BACKEND_URL}/config/${SUBSCRIPTION_URL}&file=${TEMPLATE_URL}"

# 显示生成的完整订阅链接
echo "=========================================================="
echo "生成完整订阅链接:"
echo "$FULL_URL"
echo "=========================================================="

# 停止 sing-box 服务
kill $(pidof sing-box)
echo "sing-box 服务已停止"

# 备份当前配置文件
if [ -f "$CONFIG_FILE" ]; then
    cp "$CONFIG_FILE" "$CONFIG_FILE.bak"
    echo "已备份旧配置文件为 $CONFIG_FILE.bak"
fi

# 等待 20 秒，确保网络稳定
echo "等待 20 秒以确保网络稳定..."
sleep 20

# 下载新的配置文件
if curl -L --connect-timeout 10 --max-time 30 "$FULL_URL" -o "$CONFIG_FILE"; then
    echo "配置文件下载成功，保存到 $CONFIG_FILE"
else
    echo "配置文件下载失败，请检查网络连接或订阅链接！"
    # 还原备份文件
    if [ -f "$CONFIG_FILE.bak" ]; then
        cp "$CONFIG_FILE.bak" "$CONFIG_FILE"
        echo "已还原备份文件到 $CONFIG_FILE"
    fi
    exit 1
fi

# 检查 sing-box 配置文件有效性
if /storage/sing-box/sing-box check -c "$CONFIG_FILE"; then
    echo "配置文件验证通过"
else
    echo "配置文件验证失败，还原备份文件..."
    if [ -f "$CONFIG_FILE.bak" ]; then
        cp "$CONFIG_FILE.bak" "$CONFIG_FILE"
        echo "已还原备份文件到 $CONFIG_FILE"
    fi
    exit 1
fi

# 启动 sing-box 服务
nohup /storage/sing-box/sing-box run -c "$CONFIG_FILE" &
echo "sing-box 服务正在启动..."

# 检查服务是否启动成功
if pgrep -f "sing-box" > /dev/null; then
    echo "=========================================================="
    echo "sing-box 启动成功，运行模式: Tun"
    echo "=========================================================="
else
    echo "=========================================================="
    echo "sing-box 启动失败，请手动检查日志！"
    echo "=========================================================="
    exit 1
fi

# 显示常用命令提示
echo "=========================================================="
echo "常用命令："
echo "检查配置文件: /storage/sing-box/sing-box check -c $CONFIG_FILE"
echo "查看运行状态: pgrep -f 'sing-box'"
echo "=========================================================="