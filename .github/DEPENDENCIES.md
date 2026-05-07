# 依赖管理指南

本文档说明 EasyTrojan 项目的依赖管理机制和自动化检查流程。

## 📦 依赖类型

### GitHub Actions
项目使用以下 GitHub Actions：

| Action | 版本 | 用途 |
|--------|------|------|
| actions/checkout | v6.0.2 | 代码检出 |
| actions/setup-go | v6.4.0 | Go 环境设置 |
| actions/cache | v5.0.5 | 构建缓存 |
| actions/upload-artifact | v7.0.1 | 构建产物上传 |
| actions/download-artifact | v8.0.1 | 构建产物下载 |
| softprops/action-gh-release | v3.0.0 | GitHub Release 发布 |
| ludeeus/action-shellcheck | v2.0.0 | Shell 脚本静态分析 |

### Go 语言依赖
主要依赖通过 xcaddy 构建时自动获取：

- `github.com/caddyserver/caddy/v2` - Web 服务器核心
- `github.com/imgk/caddy-trojan` - Trojan 协议插件

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
- ✅ Go 语言依赖
- ✅ Docker 镜像（如有）
- ✅ Devcontainer 配置（如有）

**PR 限制：** 每个类别最多 5 个待处理 PR

### 工作流检查

**文件：** `.github/workflows/dependency-check.yml`

**触发条件：**
- 定时：每周一 09:00 UTC
- 手动：通过 GitHub Actions 界面触发

**检查项目：**

1. **GitHub Actions 版本检查**
   - 对比当前版本与最新 release
   - 标记可更新的 Action

2. **Go 依赖检查**
   - Go 版本验证
   - 列出所有依赖项
   - 检查可更新的模块

3. **Shell 脚本检查**
   - ShellCheck 静态分析
   - 脚本统计信息

4. **安全检查**
   - 硬编码密钥扫描
   - 依赖漏洞检查

5. **构建验证**
   - 编译测试
   - 二进制文件验证

**查看报告：**
工作流完成后，在 GitHub Actions 页面查看 Summary 选项卡的详细报告。

## 📋 手动触发检查

在 GitHub 仓库页面：
1. 进入 **Actions** 标签
2. 选择 **Weekly Dependency Check** 工作流
3. 点击 **Run workflow**
4. 选择检查类型（all/actions/go/scripts）
5. 点击确定触发检查

## 🔄 更新依赖流程

### GitHub Actions 更新

1. Dependabot 自动创建 PR
2. 检查变更日志确认兼容性
3. 运行 CI 测试
4. 合并 PR

### Go 依赖更新

1. Dependabot 创建 PR
2. 本地测试构建：
   ```bash
   xcaddy build --with github.com/imgk/caddy-trojan
   ```
3. 确认测试通过
4. 合并 PR

## 📊 版本策略

### 语义化版本遵循

- **MAJOR.MINOR.PATCH** (如 v6.0.2)
- MAJOR: 不兼容的 API 修改
- MINOR: 向后兼容的功能性新增
- PATCH: 向后兼容的问题修正

### 更新策略

- **Actions:** 跟随最新 major 版本（如 v6.x）
- **Go 模块:** 使用最新稳定版本
- **xcaddy:** 固定版本（当前 v0.4.5）

## 🛡️ 安全最佳实践

1. **定期更新依赖** - 响应 Dependabot PR
2. **审查变更** - 合并前查看 release notes
3. **测试验证** - 确保 CI 通过
4. **固定版本** - 避免使用 `master` 或 `main` 作为版本
5. **Secret 管理** - 使用 GitHub Secrets，不要硬编码

## 📈 监控指标

建议关注：
- Dependabot PR 数量（保持 < 5）
- 构建时间变化
- 安全检查结果
- 测试覆盖率

## 🔗 相关资源

- [Dependabot 文档](https://docs.github.com/en/code-security/dependabot)
- [GitHub Actions 版本](https://github.com/actions)
- [Go 模块管理](https://go.dev/ref/mod)
- [xcaddy 构建工具](https://github.com/caddyserver/xcaddy)

---

**最后更新:** 2026-05-07
**维护者:** EasyTrojan Team
