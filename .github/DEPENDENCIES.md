# 依赖管理指南

本文档说明 EasyTrojan 项目的依赖管理机制和自动化检查流程。

## 📦 项目类型

**EasyTrojan 是纯 Shell 脚本项目**，不是 Go 项目。

| 组件 | 类型 | 说明 |
|------|------|------|
| easytrojan.sh | Shell 脚本 | 主安装脚本 |
| mytrojan.sh | Shell 脚本 | 密码管理脚本 |
| tests/*.sh | Shell 脚本 | 测试套件 |
| xcaddy | Go 工具 | 仅用于构建 Caddy |
| caddy-trojan | Go 插件 | 通过 xcaddy 远程获取 |

## 🔧 依赖类型

## 🔧 依赖类型

### GitHub Actions
项目使用以下 GitHub Actions：

| Action | 版本 | 用途 |
|--------|------|------|
| actions/checkout | v6.0.2 | 代码检出 |
| actions/setup-go | v6.4.0 | **Go 环境 (仅用于 xcaddy 构建)** |
| actions/cache | v5.0.5 | xcaddy 缓存 |
| actions/upload-artifact | v7.0.1 | 构建产物上传 |
| actions/download-artifact | v8.0.1 | 构建产物下载 |
| softprops/action-gh-release | v3.0.0 | GitHub Release 发布 |
| ludeeus/action-shellcheck | 2.0.0 | Shell 脚本静态分析 |

### 构建工具

**xcaddy** - Caddy 自定义构建工具
- 版本：v0.4.5 (固定)
- 用途：构建包含 caddy-trojan 插件的 Caddy
- 位置：仅在 CI/CD 中使用
- **依赖**: 需要 Go 编译环境 (由 setup-go 提供)

> ⚠️ **重要**: 虽然项目本身是纯 Shell 脚本，但 xcaddy 在构建 Caddy 时需要调用 Go 编译器，因此 CI 中必须安装 Go 环境。

### 系统依赖（运行环境）
- curl
- bash
- systemd

## 🤖 自动化检查

### Dependabot 配置

项目使用 Dependabot 自动检查依赖更新，配置文件位于 `.github/dependabot.yml`。

**检查频率：** 每周一 09:00 UTC

**检查范围：**
- ✅ GitHub Actions 版本

> 注意：由于项目是纯 Shell 脚本，没有 Go 模块依赖，因此 Dependabot 只检查 Actions 版本。

### 每周检查工作流

**文件：** `.github/workflows/dependency-check.yml`

**触发条件：**
- 定时：每周一 09:00 UTC
- 手动：通过 GitHub Actions 界面触发

**检查项目：**

1. **GitHub Actions 版本检查**
   - 对比当前版本与最新 release
   - 标记可更新的 Action
   - 自动生成版本对比表

2. **Shell 脚本检查**
   - ShellCheck 静态分析
   - 脚本统计信息（行数、大小）

3. **安全检查**
   - 硬编码密钥扫描
   - 依赖安全性检查

4. **xcaddy 构建工具检查**
   - 版本对比
   - 构建产物说明

**查看报告：**
工作流完成后，在 GitHub Actions 页面查看 Summary 选项卡的详细报告。

## 📋 手动触发检查

在 GitHub 仓库页面：
1. 进入 **Actions** 标签
2. 选择 **Weekly Dependency Check** 工作流
3. 点击 **Run workflow**
4. 选择检查类型（all/actions/scripts）
5. 点击确定触发检查

## 🔄 更新依赖流程

### GitHub Actions 更新

1. Dependabot 自动创建 PR
2. 检查变更日志确认兼容性
3. 运行 CI 测试
4. 合并 PR

### xcaddy 更新

1. 检查每周检查报告的版本提示
2. 修改 `.github/workflows/build.yml` 中的 `XCADDY_VERSION`
3. 测试构建：
   ```bash
   xcaddy build --with github.com/imgk/caddy-trojan
   ```
4. 运行完整测试套件
5. 提交更新

## 📊 版本策略

### 语义化版本遵循

- **MAJOR.MINOR.PATCH** (如 v6.0.2)
- MAJOR: 不兼容的 API 修改
- MINOR: 向后兼容的功能性新增
- PATCH: 向后兼容的问题修正

### 更新策略

- **Actions:** 跟随最新 major 版本（如 v6.x）
- **xcaddy:** 固定稳定版本（当前 v0.4.5）
- **caddy-trojan:** 使用 xcaddy 自动获取最新版本

## 🛡️ 安全最佳实践

1. **定期更新依赖** - 响应 Dependabot PR
2. **审查变更** - 合并前查看 release notes
3. **测试验证** - 确保 CI 通过
4. **固定版本** - 避免使用 `master` 或 `main` 作为版本
5. **Secret 管理** - 使用 GitHub Secrets，不要硬编码
6. **ShellCheck 检查** - 每次提交自动进行静态分析

## 📈 监控指标

建议关注：
- Dependabot PR 数量（保持 < 5）
- ShellCheck 警告数量
- 构建时间变化
- 安全检查结果

## 🔗 相关资源

- [Dependabot 文档](https://docs.github.com/en/code-security/dependabot)
- [GitHub Actions 版本](https://github.com/actions)
- [xcaddy 构建工具](https://github.com/caddyserver/xcaddy)
- [ShellCheck](https://www.shellcheck.net/)

---

**最后更新:** 2026-05-07  
**维护者:** EasyTrojan Team
