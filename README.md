![language](https://img.shields.io/badge/language-Shell_&_Go-brightgreen.svg)
![release](https://img.shields.io/badge/release-v2.11.2_20260506-blue.svg)

# EasyTrojan v3.0

> 世界上最简单的 Trojan 部署脚本，仅需一行命令即可搭建一台代理服务器

## 特性

- 该项目会自动提供 trojan 服务所需的免费域名与证书，无需购买、解析等繁琐操作
- 支持 RHEL 7、8、9 (CentOS、RedHat、AlmaLinux、RockyLinux)、Debian 9、10、11、12、Ubuntu 16、18、20、22
- **该项目仅限研究用途，用户应根据所在管辖区的当地法律评估自己的法规遵从义务**

---

## 安装指南

### 首次安装

> 请将结尾的 `password` 更换为自己的密码，例如 `bash easytrojan.sh 123456`，安装成功后会返回 trojan 的连接参数

```bash
curl https://raw.githubusercontent.com/upbeat-backbone-bose/easytrojan3.0/main/easytrojan.sh -o easytrojan.sh && chmod +x easytrojan.sh && bash easytrojan.sh password
```

### 放行端口

如果服务器开启了防火墙，应放行 TCP 80 与 443 端口。如在云厂商的 Web 管理页面有防火墙，应同时放行 TCP 80 与 443 端口。

```bash
# RHEL 7、8、9 (CentOS、RedHat、AlmaLinux、RockyLinux) 放行端口命令
firewall-cmd --permanent --add-port=80/tcp --add-port=443/tcp && firewall-cmd --reload && iptables -F

# Debian 9、10、11、12、Ubuntu 16、18、20、22 放行端口命令
sudo ufw allow proto tcp from any to any port 80,443 && sudo iptables -F
```

> **验证端口是否放行** (示例 IP 应修改为 trojan 服务器的 IP)
>
> 通过浏览器访问脚本提供的免费域名，例如 `1.3.5.7.nip.io`  
> 如果自动跳转至 https，页面显示 Service Unavailable，说明端口已放行

### 密码管理

密码允许包含特殊符号（包括 `@` 和 `*`），但不能为空。以下字符不可使用：`/` `?` `=` `#` 以及空格/制表符（URI 结构字符）。密码中的 `@` 和 `*` 等特殊符号会在生成 Trojan Link 时自动 URL 编码。

```bash
# 下载 trojan 密码管理脚本
curl https://raw.githubusercontent.com/upbeat-backbone-bose/easytrojan3.0/main/mytrojan.sh -o mytrojan.sh && chmod +x mytrojan.sh

# 创建密码
bash mytrojan.sh add password

# 一次创建多个密码示例
bash mytrojan.sh add password1 password2 ...

# 删除密码
bash mytrojan.sh del password

# 一次删除多个密码示例
bash mytrojan.sh del password1 password2 ...

# 流量查询
bash mytrojan.sh status password1 password2 ...

# 流量归零
bash mytrojan.sh rotate
```

> 流量统计归零后会自动在 `/etc/caddy/trojan/data` 目录下生成历史记录

```bash
# 密码列表
bash mytrojan.sh list
```

### 重新安装

```bash
systemctl stop caddy.service && curl https://raw.githubusercontent.com/upbeat-backbone-bose/easytrojan3.0/main/easytrojan.sh -o easytrojan.sh && chmod +x easytrojan.sh && bash easytrojan.sh password
```

### 完全卸载

```bash
systemctl stop caddy.service && systemctl disable caddy.service && rm -rf /etc/caddy /usr/local/bin/caddy /etc/systemd/system/caddy.service
```

---

## 高级配置

### 脚本说明

**注意事项**

- 必须使用 root 用户部署
- 请勿修改配置文件参数

### 免费域名

通过 tbcache.com 提供的免费域名解析服务获取，例如：

```
ip518200520.mobgslb.tbcache.com
```

### 指定域名

仅建议在免费域名被阻断时使用。

在密码后加入域名即可指定域名重新安装，密码与域名之间应使用空格分隔：

```bash
systemctl stop caddy.service && curl https://raw.githubusercontent.com/upbeat-backbone-bose/easytrojan3.0/main/easytrojan.sh -o easytrojan.sh && chmod +x easytrojan.sh && bash easytrojan.sh password yourdomain
```

> 当指定域名后，如需切换回免费域名，必须完全卸载脚本，重新执行首次安装命令

### 更换端口

仅建议在 443 端口被阻断时临时使用。

```bash
# 将 443 端口更换为 8443 端口示例
sed -i "s/443/8443/g" /etc/caddy/Caddyfile && systemctl restart caddy.service
```

> 更换端口后应开启对应端口的防火墙
>
> 当测试临时端口超过 48 小时未阻断后，应尽快更换 IP 并重新安装，使用默认的 443 端口

### 免费证书

通过Caddy的HTTPS模块实现，会自动申请letsencrypt或zerossl的免费证书。

> 关闭防火墙后执行重新安装命令，能大概率解决证书申请失败的问题

```bash
# RHEL 7、8、9 (CentOS、RedHat、AlmaLinux、RockyLinux)
systemctl stop firewalld.service && systemctl disable firewalld.service

# Debian 9、10、11、Ubuntu 16、18、20、22
sudo ufw disable
```

### 连接参数

IP 为 1.3.5.7 密码为 123456 的服务器示例：

- **地址**：`ip***.mobgslb.tbcache.com`（根据服务器 IP 生成，即免费域名）
- **端口**：443
- **密码**：123456（安装时设置的密码）
- **ALPN**: h2/http1.1

### Trojan Link 格式

安装成功后会自动生成标准 Trojan Link：

```
trojan://PASSWORD@HOST:443?security=tls&sni=HOST&alpn=h2,http/1.1&fp=chrome&type=tcp#easytrojan-HOST
```

参数说明：
- `PASSWORD` - 连接密码（已自动 URL 编码）
- `HOST` - 服务器 IP 或域名
- `security=tls` - 传输层安全（必需）
- `sni=HOST` - Server Name Indication，必须与域名一致
- `alpn=h2,http/1.1` - 应用层协议协商，提高兼容性
- `fp=chrome` - TLS 指纹，绕过 GFW 检测
- `type=tcp` - 传输协议类型

### 兼容的客户端

以下客户端已验证兼容：

- ✓ Trojan-Go (v0.10.6+)
- ✓ Trojan (原版)
- ✓ Clash / Clash.Meta
- ✓ Sing-Box
- ✓ Hiddify
- ✓ V2RayN (支持 Trojan 协议)
- ✓ Quantumult X
- ✓ Shadowrocket
- ✓ Surge

### 服务伪装

非密码正确的 trojan 客户端访问返回 503 状态码，将 trojan 伪装成过载的 Web 服务。

---

## 故障排查 (FAQ)

### 1. 证书申请失败

- 确保 TCP 80 和 443 端口已开放
- 关闭服务器防火墙后重试：
  - RHEL/CentOS: `systemctl stop firewalld.service`
  - Debian/Ubuntu: `sudo ufw disable`
- 检查服务器时间是否正确：`date -R`
- 查看 Caddy 日志：`journalctl -u caddy.service -n 50`

### 2. 端口被占用

- 查看占用端口的进程：`ss -tlnp | grep ':80\|:443'`
- 停止冲突服务：`systemctl stop nginx` 或 `systemctl stop apache2`
- 如必须使用其他端口，参考"更换端口"章节

### 3. 连接超时或无法连接

- 检查防火墙是否放行 443 端口
- 确认云服务商安全组已开放 80/443 端口
- 验证域名解析：`ping <你的域名>`
- 检查 Caddy 服务状态：`systemctl status caddy.service`

### 4. 密码添加/删除失败

- 确认 Caddy 服务正在运行：`systemctl status caddy.service`
- 检查 API 是否可访问：`curl http://localhost:2019/trojan/users/list`
- 密码不能包含 URI 结构字符：`/` `?` `=` `#` 或空格/制表符（允许使用 @ 和 *）

### 5. 流量统计异常

- 重启 Caddy 服务：`systemctl restart caddy.service`
- 检查数据文件权限：`ls -la /etc/caddy/trojan/`
- 修复权限：`chown -R caddy:caddy /etc/caddy/trojan/`

### 6. 脚本执行报错 "Permission denied"

- 必须使用 root 用户执行
- 检查脚本执行权限：`chmod +x easytrojan.sh mytrojan.sh`

### 7. 系统资源不足

- 查看文件句柄限制：`ulimit -n`
- 查看进程数限制：`ulimit -u`
- 重新加载系统配置：`sysctl -p`

---

## 鸣谢项目

- [EasyTrojan](https://github.com/eastmaple/easytrojan)
- [CaddyServer](https://github.com/caddyserver/caddy)
- [CaddyTrojan](https://github.com/imgk/caddy-trojan)
