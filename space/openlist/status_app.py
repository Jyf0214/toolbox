import os
import time
from flask import Flask

# --- 配置 ---
# 在 Docker 容器中，主网络接口通常是 eth0
NETWORK_INTERFACE = os.getenv('MONITOR_INTERFACE', 'eth0')
LISTEN_PORT = 7860
# ---

app = Flask(__name__)

# 全局变量，用于存储服务启动时的初始网络流量数据
initial_stats = {
    'rx_bytes': 0,
    'tx_bytes': 0,
    'start_time': time.time()
}

def get_traffic_stats():
    """从 /proc/net/dev 读取并解析指定网络接口的流量统计"""
    try:
        with open('/proc/net/dev', 'r') as f:
            for line in f:
                if NETWORK_INTERFACE in line:
                    parts = line.split()
                    # 格式为: Inter-|   Receive                                                |  Transmit
                    # face |bytes    packets errs drop fifo frame compressed multicast|bytes    packets errs drop fifo colls carrier compressed
                    # eth0: 12345    ...                                             | 67890   ...
                    return {
                        'rx_bytes': int(parts[1]),
                        'tx_bytes': int(parts[9])
                    }
    except (IOError, IndexError, ValueError):
        # 如果文件不存在或格式不符，返回 0
        return {'rx_bytes': 0, 'tx_bytes': 0}
    return {'rx_bytes': 0, 'tx_bytes': 0}

def format_bytes(byte_count):
    """将字节数格式化为可读的 KB, MB, GB 等"""
    if byte_count is None:
        return "0 B"
    power = 1024
    n = 0
    power_labels = {0: '', 1: 'K', 2: 'M', 3: 'G', 4: 'T'}
    while byte_count >= power and n < len(power_labels) -1 :
        byte_count /= power
        n += 1
    return f"{byte_count:.2f} {power_labels[n]}B"

@app.route('/')
def status_page():
    """渲染状态页面"""
    current_stats = get_traffic_stats()
    
    # 计算自服务启动以来的累计流量
    cumulative_rx = current_stats['rx_bytes'] - initial_stats['rx_bytes']
    cumulative_tx = current_stats['tx_bytes'] - initial_stats['tx_bytes']
    total_cumulative = cumulative_rx + cumulative_tx
    
    uptime = time.time() - initial_stats['start_time']
    days, rem = divmod(uptime, 86400)
    hours, rem = divmod(rem, 3600)
    minutes, seconds = divmod(rem, 60)

    html = f"""
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <meta http-equiv="refresh" content="5">
        <title>服务状态监控</title>
        <style>
            body {{ font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif; background-color: #f4f7f9; color: #333; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; }}
            .container {{ background: #fff; padding: 30px 40px; border-radius: 12px; box-shadow: 0 4px 20px rgba(0,0,0,0.1); text-align: center; }}
            h1 {{ color: #2c3e50; margin-bottom: 25px; }}
            .stats-grid {{ display: grid; grid-template-columns: 1fr 1fr; gap: 15px 25px; margin-top: 20px; text-align: left;}}
            .stat-label {{ font-weight: 600; color: #555; }}
            .stat-value {{ color: #2980b9; font-weight: bold; }}
            .total {{ grid-column: 1 / -1; border-top: 1px solid #eee; padding-top: 15px; }}
        </style>
    </head>
    <body>
        <div class="container">
            <h1>服务流量监控</h1>
            <div class="stats-grid">
                <div class="stat-label">服务运行时长:</div>
                <div class="stat-value">{int(days)}d {int(hours)}h {int(minutes)}m {int(seconds)}s</div>

                <div class="stat-label">累计接收流量:</div>
                <div class="stat-value">{format_bytes(cumulative_rx)}</div>
                
                <div class="stat-label">累计发送流量:</div>
                <div class="stat-value">{format_bytes(cumulative_tx)}</div>

                <div class="stat-label total">累计总流量:</div>
                <div class="stat-value total">{format_bytes(total_cumulative)}</div>
            </div>
            <p style="font-size: 0.8em; color: #999; margin-top: 25px;">页面每 5 秒自动刷新</p>
        </div>
    </body>
    </html>
    """
    return html

if __name__ == '__main__':
    # 在服务启动时，获取一次初始流量数据
    initial_stats.update(get_traffic_stats())
    # 启动 Flask Web 服务器
    app.run(host='0.0.0.0', port=LISTEN_PORT)