# Git Ignore Skill

生成 `.gitignore` 文件，用于定义 Git 版本控制中需要排除的文件和目录。

## 功能

- 排除 macOS 系统文件（`.DS_Store`）
- 排除 Node.js 依赖目录（`node_modules`）
- 排除构建产物（`dist`、`dist-ssr`）
- 排除本地环境文件（`.env`、`.env.local`、`.env.*.local`）
- 排除编辑器目录（`.vscode`、`.idea`）
- 排除包管理器日志（npm、yarn、pnpm）
- 排除测试覆盖率报告
- 排除本地配置文件（`*.local`）

## 输出

生成文件：`.gitignore`

## 使用场景

当需要为新项目或现有项目创建 `.gitignore` 文件时调用此技能。
