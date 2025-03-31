# 贡献指南

感谢您对好生意记账助手项目的兴趣！我们非常欢迎各种形式的贡献，无论是功能改进、错误修复还是文档完善。本文档将指导您如何参与贡献。

## 开发流程

1. **Fork 项目仓库**
   
   首先，在GitHub上Fork本仓库到您自己的账号下。

2. **克隆您的Fork仓库**

   ```bash
   git clone https://github.com/您的用户名/haoshengyi-jzzs-app.git
   cd haoshengyi-jzzs-app
   ```

3. **添加上游仓库**

   ```bash
   git remote add upstream https://github.com/原始仓库用户名/haoshengyi-jzzs-app.git
   ```

4. **创建分支**

   请为每个新功能或修复创建单独的分支：

   ```bash
   git checkout -b feature/your-feature-name
   # 或者
   git checkout -b fix/issue-description
   ```

5. **提交更改**

   ```bash
   git add .
   git commit -m "描述性的提交信息"
   ```

6. **保持分支同步**

   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

7. **推送更改**

   ```bash
   git push origin feature/your-feature-name
   ```

8. **创建Pull Request**

   在GitHub上创建一个Pull Request，从您的分支到原始仓库的main分支。

## 代码规范

- 请遵循项目的代码风格和格式约定
- 运行 `flutter analyze` 确保没有代码质量问题
- 使用有意义的变量名和函数名
- 为公共API添加适当的文档注释

## 提交PR前的检查清单

- [ ] 代码通过了 `flutter analyze` 检查
- [ ] 所有测试通过 (`flutter test`)
- [ ] 添加了新功能的测试（如适用）
- [ ] 更新了文档（如适用）
- [ ] 提交消息描述了更改内容

## 报告Bug

如果您发现了Bug，请在GitHub issues中报告，并尽可能提供：

- 简洁明了的问题描述
- 复现步骤
- 期望行为与实际行为
- 截图（如适用）
- 环境信息（操作系统、Flutter版本等）

## 功能建议

欢迎提出新功能建议！请在GitHub issues中描述您的想法，包括：

- 功能描述
- 使用场景
- 实现建议（可选）

## 问题讨论

如有任何疑问，欢迎在GitHub discussions中讨论或联系项目维护者。

感谢您的贡献！ 