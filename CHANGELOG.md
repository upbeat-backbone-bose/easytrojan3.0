# 变更日志

本文件记录 EasyTrojan 项目的所有重要变更。

格式基于 [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)，项目遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

## [Unreleased]

### CI/CD
- **ShellCheck 静态分析** - 添加 ludeeus/action-shellcheck@2.0.0 (使用无 v 前缀版本)
- **ShellCheck 配置** - 添加 .shellcheckrc 忽略 SC2155 (readonly 变量初始化误报)
- **xcaddy 缓存** - 使用 actions/cache@v5.0.5 加速构建 (减少重复下载)
- **二进制文件验证** - 构建后验证文件类型、权限、大小
- **Release 合并优化** - 使用 upload/download-artifact 合并多架构到单一 Release
- **自动 Release Notes** - 动态嵌入 SHA256 校验和到 Release 描述
- **Action 版本锁定** - 所有 Actions 使用最新固定版本 (checkout@v6.0.2, setup-go@v6.4.0, upload-artifact@v7.0.1, download-artifact@v8.0.1)
- **权限增强** - 添加 security-events 用于安全扫描
- **Dependabot 自动化** - 每周一检查依赖更新 (Actions, Go, Docker)
- **每周依赖检查** - 自动检查 Actions 版本、Go 依赖、ShellCheck、安全、构建验证

### 测试
- **audit.sh** - 添加 13 阶段本地审计脚本（语法、安全、API、幂等性、重试、配置、文档、Trojan Link 兼容性）
- **test_quick.sh** - 8 项快速测试（语法、正则、函数、配置、幂等性、重试、文档）
- **test_all.sh** - 58 项完整测试套件（12 个测试分类）
- **tests/README.md** - 测试指南和故障排查文档
- **CI 集成** - GitHub Actions 构建前自动运行测试

### 文档
- **CHANGELOG.md** - 添加版本变更记录
- **FAQ** - README 添加 7 个常见故障排查问题
- **Trojan Link 兼容性** - 添加标准格式说明和 9 款客户端验证清单
- **密码说明统一** - README 与实际验证逻辑一致（仅限字母数字下划线）
- **DEPENDENCIES.md** - 依赖管理指南

### 安全性
- **密码验证强化** - 严格限制为 `^[a-zA-Z0-9_]+$`，删除 json_escape() 函数
- **命令注入修复** - 移除不安全的 JSON 转义逻辑

---

## [v2.11.2] - 2026-05-07

### 安全性
- **修复命令注入漏洞** - 删除 json_escape() 函数，直接使用密码变量
- **密码验证增强** - 严格限制为字母 (a-zA-Z)、数字 (0-9)、下划线 (_)，正则：`^[a-zA-Z0-9_]+$`
- **Caddy 二进制文件校验** - 下载后验证版本信息
- **系统配置备份** - 修改 limits.conf 和 sysctl.conf 前自动备份
- **添加二进制文件 SHA256 校验** - GitHub Actions 发布时生成校验文件

### 功能改进
- **limits.conf 幂等性检查** - 添加 `limits_conf_already_configured()` 函数避免重复配置
- **安装验证重试逻辑** - 最多 3 次重试，每次间隔 5 秒，提高成功率
- **端口检查兼容** - 支持 ss/netstat 命令
- **域名验证改进** - 优先使用 getent，回退到 ping 解析
- **流量查询文件检查** - 避免文件不存在时报错
- **删除密码使用 grep** - 改进删除逻辑

### 代码质量
- **函数化重构** - 拆分为 10+ 个函数，提升可维护性
- **sysctl 管理优化** - 使用标记块管理，合并 28 个 sed 命令
- **统一错误处理** - 使用标准 log_error 函数
- **删除冗余代码** - 移除 json_escape 函数及所有调用

### CI/CD
- **actions/checkout** - v4 升级至 v6
- **actions/setup-go** - v5 升级至 v6
- **action-gh-release** - v2 升级至 v3
- **Go 版本** - 1.22 升级至 1.26
- **并行构建** - 使用 matrix 策略同时构建 amd64/arm64
- **依赖缓存** - 启用 Go 模块缓存加速构建
- **权限最小化** - 添加 permissions 声明
- **测试集成** - 添加测试步骤，构建前自动运行测试

### 测试
- **测试框架** - 添加 tests/test_quick.sh 快速测试
- **完整测试套件** - 添加 tests/test_all.sh 完整测试
- **测试文档** - 添加 tests/README.md 测试指南
- **CI 集成** - GitHub Actions 自动运行测试

### 文档
- **统一密码说明** - README 与实际验证逻辑一致（仅限字母数字下划线）
- **添加故障排查 FAQ** - 涵盖 7 个常见问题
- **添加 CHANGELOG.md** - 版本变更记录
- **删除重复内容** - 清理 README 重复的密码管理章节

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
