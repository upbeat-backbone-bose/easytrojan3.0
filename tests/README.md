# EasyTrojan 测试指南

## 运行测试

### 快速测试套件

运行快速测试验证所有关键功能：

```bash
bash tests/test_quick.sh
```

测试项目包括：
1. ✓ 脚本语法验证
2. ✓ 密码验证正则表达式
3. ✓ JSON 转义函数已移除
4. ✓ 必需函数存在性
5. ✓ 配置变量定义
6. ✓ 幂等性检查
7. ✓ 重试逻辑
8. ✓ 文档完整性

### 完整测试套件

运行完整测试套件（包含更多验证）：

```bash
bash tests/test_all.sh
```

## CI/CD 集成

测试已集成到 GitHub Actions 工作流中，每次构建时自动运行：

```yaml
- name: Run tests
  run: |
    chmod +x tests/test_all.sh
    bash tests/test_all.sh
```

## 密码规则测试

密码验证规则测试用例：

**有效密码：**
- `password123`
- `test_password`
- `ABC123`
- `________`
- `12345678`

**无效密码：**
- `` (空密码)
- `pass word` (包含空格)
- `pass@word` (包含特殊字符)
- `pass-word` (包含连字符)
- `pass.word` (包含点号)
- `密码` (中文字符)

## 手动测试

### 测试密码验证（不实际执行脚本）

```bash
# 模拟测试密码验证逻辑
test_password() {
    local passwd="$1"
    if [[ "$passwd" =~ ^[a-zA-Z0-9_]+$ ]]; then
        echo "✓ Valid: $passwd"
    else
        echo "✗ Invalid: $passwd"
    fi
}

# 测试用例
test_password "valid_password123"  # Should pass
test_password "invalid@password"   # Should fail
test_password ""                   # Should fail
```

### 验证脚本功能

在测试环境中运行（注意：不要在生产环境测试）：

```bash
# 语法检查
bash -n easytrojan.sh
bash -n mytrojan.sh

# 查看帮助信息
bash mytrojan.sh  # 显示使用说明
```

## 测试覆盖率

当前测试覆盖的关键功能：

- [x] 脚本语法验证
- [x] 密码验证逻辑
- [x] 函数存在性检查
- [x] 配置变量验证
- [x] 幂等性检查 (limits.conf, sysctl)
- [x] 重试逻辑验证
- [x] 文档完整性检查
- [x] CI/CD 工作流验证

## 故障排查

### 测试失败

1. **语法错误**: 使用 `bash -n script.sh` 查看详细错误信息
2. **函数缺失**: 检查脚本是否包含所有必需函数
3. **配置缺失**: 验证所有 `readonly` 配置变量已定义

### 报告问题

如测试失败，请提供：
- 测试输出完整日志
- 操作系统版本
- Bash 版本 (`bash --version`)
