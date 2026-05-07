# 变更日志

本文件记录 EasyTrojan 项目的所有重要变更。

格式基于 [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)，项目遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

## [v2.11.2] - 2026-05-06

### 安全性
- **修复命令注入漏洞** - 添加密码 JSON 转义函数 `json_escape()`，防止特殊字符注入
- **密码验证增强** - 检查空密码和控制字符
- **Caddy 二进制文件校验** - 下载后验证版本信息
- **系统配置备份** - 修改 limits.conf 和 sysctl.conf 前自动备份
- **添加二进制文件 SHA256 校验** - GitHub Actions 发布时生成校验文件

### 功能改进
- **limits.conf 幂等性检查** - 避免重复配置
- **安装验证重试逻辑** - 最多 3 次重试，提高成功率
- **端口检查兼容** - 支持 ss/netstat 命令
- **域名验证改进** - 优先使用 getent，回退到 ping 解析
- **流量查询文件检查** - 避免文件不存在时报错
- **删除密码使用 grep** - 改进删除逻辑

### 代码质量
- **函数化重构** - 拆分为 10+ 个函数，提升可维护性
- **sysctl 管理优化** - 使用标记块管理，合并 28 个 sed 命令
- **统一错误处理** - 使用标准 log_error 函数

### CI/CD
- **actions/checkout** - v4 升级至 v6
- **actions/setup-go** - v5 升级至 v6
- **action-gh-release** - v2 升级至 v3
- **Go 版本** - 1.22 升级至 1.26
- **并行构建** - 使用 matrix 策略同时构建 amd64/arm64
- **依赖缓存** - 启用 Go 模块缓存加速构建
- **权限最小化** - 添加 permissions 声明

### 文档
- **统一密码说明** - README 与实际验证逻辑一致
- **添加故障排查 FAQ** - 涵盖 7 个常见问题
- **添加 CHANGELOG.md** - 版本变更记录

---

## [v2.11.1] - 2026-05-06

### 修复
- 修复 Caddy URL 版本号
- 更新 Release Badge 为 v2.11.2

---

## [v2.11.0] - 2026-05-05

### 新增
- 初始发布脚本
- 支持 RHEL 7-9, Debian 9-12, Ubuntu 16-22
