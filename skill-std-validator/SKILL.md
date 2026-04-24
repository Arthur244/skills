---
name: skill-std-validator
description: Validates Skill folders against the official Skill standard specification. Use when user asks to "validate skill", "check skill compliance", "verify skill structure", "optimize skill", "format skill", "generate README", "update README", or when creating/reviewing any Skill.
---

# Skill 标准验证器

验证 Skill 文件夹是否符合官方 Skill 标准规范（定义于 `references/skill-stddoc.md`）。

## Instructions

### 步骤 1：询问语言偏好

在开始验证前，询问用户希望使用哪种语言输出验证报告和说明：

1. **中文**：验证报告、说明文档、建议均使用中文
2. **原语言**：保持 Skill 原有语言，不做翻译检查

根据用户选择，调整后续验证步骤的语言要求。

### 步骤 2：识别目标 Skill 文件夹

当被要求验证 Skill 时，首先识别目标文件夹：

1. 如果用户指定了路径，使用该路径
2. 如果用户提到了 skill 名称，在当前工作区中查找
3. 如果未指定目标，询问用户要验证哪个 Skill

### 步骤 3：检查文件夹结构

验证文件夹结构是否符合标准：

```
skill-name/
├── SKILL.md          # 必需
├── README.md         # 可选 - 面向人类开发者的说明文档
├── scripts/          # 可选 - 功能脚本
├── references/       # 可选 - 资源文档
└── assets/           # 可选 - 静态资源
```

**验证规则：**

- [ ] SKILL.md 文件存在（区分大小写）

#### 3.0 文件分类与归档（优化/格式化模式）

**当用户请求"优化"或"格式化" skill 结构时，执行文件分类：**

**文件分类规则：**

| 文件类型 | 目标文件夹 | 说明 |
|----------|------------|------|
| `.ps1`, `.sh`, `.py`, `.js`, `.ts` | `scripts/` | 功能脚本文件 |
| `.md`（非 SKILL.md） | `references/` | 文档文件 |
| `.json`, `.yaml`, `.yml` | `references/` | 配置/数据文件 |
| `.png`, `.jpg`, `.svg`, `.gif` | `assets/` | 图片资源 |
| `.css`, `.scss` | `assets/` | 样式文件 |

**分类流程：**

1. 扫描 skill 根目录下的所有文件（排除 SKILL.md）
2. 根据文件扩展名确定目标文件夹
3. 如果目标文件夹不存在，创建该文件夹
4. 将文件移动到对应的目标文件夹
5. 更新 SKILL.md 中的文件引用路径

**注意事项：**

- `SKILL.md` 必须保留在根目录
- 移动文件后需更新 SKILL.md 中的引用路径
- 如果文件已在正确位置，跳过移动

#### 3.1 文件夹命名检查与交互

如果文件夹名称不符合 kebab-case 规范（仅小写字母和连字符，无空格/下划线），通过提问让用户选择：

**提问格式：**

```
文件夹名称 "{current_name}" 不符合 kebab-case 规范（仅小写字母和连字符）。

请选择如何处理：
1. 保持原名称 "{current_name}"
2. 使用建议名称 "{suggested_name}"
3. 输入自定义名称

请输入您的选择（1/2/3）：
```

**处理逻辑：**

- **选择 1（保持原名称）**：记录为 `[PASS - 用户选择]`，继续验证
- **选择 2（使用建议名称）**：执行重命名操作，记录为 `[PASS - 已重命名]`
- **选择 3（自定义名称）**：提示用户输入新名称，验证是否符合规范：
  - 如果符合：执行重命名，记录为 `[PASS - 已重命名]`
  - 如果不符合：再次提示用户选择，直到获得有效名称

**kebab-case 转换规则：**

- 将空格和下划线替换为连字符
- 将大写字母转换为小写
- 移除连续的多个连字符
- 示例：`My_Skill Name` → `my-skill-name`

### 步骤 4：验证 SKILL.md 内容

#### 4.1 语言一致性检查 (Language Consistency Check)

**如果用户选择"中文"：**

- [ ] 指令使用中文编写
- [ ] 示例使用中文编写
- [ ] 说明文档使用中文编写
- [ ] 技术术语可保留英文

**如果用户选择"原语言"：**

- [ ] 跳过语言检查
- [ ] 仅验证内容结构和技术规范

#### 4.2 检查 YAML Frontmatter

验证 SKILL.md 包含有效的 YAML frontmatter：

```yaml
---
name: <skill-name>
description: <功能描述 + 触发条件>
---
```

**验证规则：**

- [ ] YAML frontmatter 存在（以 `---` 开始和结束）
- [ ] `name` 字段存在且与文件夹名匹配
- [ ] `description` 字段存在且少于 200 字符
- [ ] Description 包含：(1) 功能描述，(2) 触发条件
- [ ] YAML frontmatter 中无 XML 尖括号 (`<` 或 `>`)（安全要求）

#### 4.3 检查 SKILL.md Body

验证 body 包含清晰的指令：

**验证规则：**

- [ ] 包含可执行的指令（不仅仅是描述）
- [ ] 指令具体明确（非模糊语言如 "请妥善验证"）
- [ ] 包含错误处理指导（如适用）
- [ ] 对 `references/` 或 `scripts/` 文件的引用清晰

### 步骤 5：检查渐进式披露

验证 skill 遵循三层渐进式披露：

| 层级 | 内容 | 加载时机 |
|------|------|----------|
| 1 | YAML frontmatter (name + description) | 始终在系统提示中 |
| 2 | SKILL.md body | 当 skill 与任务相关时 |
| 3 | references/ 或 scripts/ 中的文件 | 仅当明确引用时 |

**验证规则：**

- [ ] Description 简洁（Layer 1）
- [ ] 详细指令在 body 中，而非 description（Layer 2）
- [ ] 长文档移至 references/（Layer 3）

### 步骤 6：检查安全与合规

**验证规则：**

- [ ] SKILL.md 中无敏感数据
- [ ] 高风险操作包含用户确认步骤
- [ ] 指令中定义了失败路径
- [ ] 如使用 tools/MCP，遵循最小权限原则

### 步骤 7：生成验证报告

生成结构化报告，格式如下：

```markdown
## Skill Validation Report: <skill-name>

### 结构检查 (Structure Check)
- [PASS/FAIL] 文件夹命名: <details>
- [PASS/FAIL] SKILL.md 存在: <details>
- [PASS/FAIL] 文件分类: <details>（优化/格式化模式）

### YAML Frontmatter 检查
- [PASS/FAIL] 有效 YAML: <details>
- [PASS/FAIL] name 字段: <details>
- [PASS/FAIL] description 字段: <details>
- [PASS/FAIL] 安全检查 (无 XML 尖括号): <details>

### 语言一致性检查 (Language Consistency Check)
- [PASS/FAIL/SKIP] 语言一致性: <details>
  - 如果选择"中文"：检查指令、示例、说明文档是否使用中文
  - 如果选择"原语言"：显示 SKIP，跳过语言检查

### 内容质量检查 (Content Quality Check)
- [PASS/FAIL] 可执行指令: <details>
- [PASS/FAIL] 渐进式披露: <details>
- [PASS/FAIL] 错误处理: <details>

### 安全检查 (Security Check)
- [PASS/FAIL] 无敏感数据: <details>
- [PASS/FAIL] 失败路径定义: <details>

### 总结 (Summary)
- 总检查项: X
- 通过: Y
- 失败: Z
- 合规率: Y/X%

### 建议 (Recommendations)
<列出发现的问题和修复建议>
```

### 步骤 8：生成或更新 README（可选）

**当用户请求"优化"或"格式化" skill 结构时，在验证完成后询问是否需要生成/更新 README。**

#### 8.1 README 存放位置

根据 Skill 标准规范，README.md 应放在 skill 根目录，与 SKILL.md 同级：

```
skill-name/
├── SKILL.md
├── README.md         <- README 存放位置
├── scripts/
├── references/
└── assets/
```

**说明**：README.md 是可选文件，用于面向人类开发者的说明文档，包含 Skill 的用途、安装方法和使用示例。

#### 8.2 README 生成流程

1. **询问用户**：是否需要生成或更新 README？
   - 如果用户选择"是"，继续下一步
   - 如果用户选择"否"，跳过此步骤

2. **收集信息**：从 SKILL.md 中提取以下信息：
   - YAML frontmatter 中的 `name`、`description`、`version`、`author` 等字段
   - SKILL.md body 中的核心功能描述
   - 目录结构信息

3. **生成 README 内容**：

```markdown
# <skill-name>

<description from YAML>

## 功能概述

<从 SKILL.md body 提取的核心功能描述>

## 目录结构

```
<skill-name>/
├── SKILL.md          # 核心指令文件
├── README.md         # 本文档
├── scripts/          # 功能脚本（如有）
├── references/       # 参考文档（如有）
└── assets/           # 静态资源（如有）
```

## 使用方法

<从 SKILL.md 提取的快速开始指南>

## 相关链接

- [SKILL.md](./SKILL.md) - 核心指令文件
- <其他 references/ 中的文档链接>

## 元信息

- **版本**: <version>
- **作者**: <author>
- **许可证**: <license>
```

4. **写入文件**：将 README.md 写入 skill 根目录
   - 如果文件已存在，询问用户是否覆盖

#### 8.3 README 更新逻辑

如果根目录的 `README.md` 已存在：

1. 读取现有 README 内容
2. 比较关键信息（name、description、version）是否与 SKILL.md 一致
3. 如果不一致，提示用户：
   ```
   检测到 README.md 内容与 SKILL.md 不一致：
   - 名称: "old-name" → "new-name"
   - 版本: "1.0.0" → "1.1.0"
   
   是否更新 README.md？
   1. 更新（保留自定义内容，仅更新元信息）
   2. 完全覆盖（重新生成）
   3. 保持不变
   ```
4. 根据用户选择执行相应操作

#### 8.4 README 模板变量

支持以下模板变量，从 SKILL.md YAML frontmatter 中提取：

| 变量 | 来源 | 说明 |
|------|------|------|
| `{{name}}` | YAML name | Skill 名称 |
| `{{description}}` | YAML description | 功能描述 |
| `{{version}}` | YAML version | 版本号（可选） |
| `{{author}}` | YAML author | 作者（可选） |
| `{{license}}` | YAML license | 许可证（可选） |
| `{{homepage}}` | YAML homepage | 主页链接（可选） |

#### 8.5 生成报告

README 生成完成后，在验证报告中添加：

```markdown
### README 生成 (README Generation)
- [PASS/SKIP] README 生成: <details>
  - 如果生成：显示文件路径
  - 如果跳过：显示用户选择跳过
```

## Examples

### 示例 1：验证一个 Skill（选择中文）

**用户：** "验证 skill-std-validator skill"

**Agent：** "请问您希望使用哪种语言输出验证报告？1. 中文  2. 原语言"

**用户：** "中文"

**响应：**

```markdown
## Skill 验证报告: skill-std-validator

### 结构检查 (Structure Check)
- [PASS] 文件夹命名: 使用 kebab-case "skill-std-validator"
- [PASS] SKILL.md 存在: 文件位于 SKILL.md

### YAML Frontmatter 检查
- [PASS] 有效 YAML: 正确的 --- 分隔符
- [PASS] name 字段: "skill-std-validator" 与文件夹名匹配
- [PASS] description 字段: 包含功能描述 + 触发条件
- [PASS] 安全检查: 无 XML 尖括号

### 语言一致性检查 (Language Consistency Check)
- [PASS] 语言一致性: 指令、示例、说明文档均使用中文编写

### 内容质量检查 (Content Quality Check)
- [PASS] 可执行指令: 包含分步骤验证流程
- [PASS] 渐进式披露: description 简洁，详细内容在 body
- [PASS] 错误处理: 包含验证规则和失败报告

### 总结 (Summary)
- 总检查项: 11
- 通过: 11
- 失败: 0
- 合规率: 100%

### 建议 (Recommendations)
Skill 符合所有标准规范。未发现问题。
```

### 示例 2：验证一个 Skill（选择原语言）

**用户：** "验证 my-english-skill"

**Agent：** "请问您希望使用哪种语言输出验证报告？1. 中文  2. 原语言"

**用户：** "原语言"

**响应：**

```markdown
## Skill Validation Report: my-english-skill

### Structure Check
- [PASS] Folder naming: Uses kebab-case "my-english-skill"
- [PASS] SKILL.md exists: File found at SKILL.md

### YAML Frontmatter Check
- [PASS] Valid YAML: Proper --- delimiters
- [PASS] name field: "my-english-skill" matches folder name
- [PASS] description field: Contains what it does + when to use
- [PASS] Security: No XML brackets

### Language Consistency Check
- [SKIP] Language check skipped: User selected original language

### Content Quality Check
- [PASS] Actionable instructions: Contains step-by-step process
- [PASS] Progressive disclosure: Description concise, details in body
- [PASS] Error handling: Includes validation rules

### Summary
- Total Checks: 10
- Passed: 10
- Failed: 0
- Skipped: 1
- Compliance Rate: 100%

### Recommendations
Skill follows all standard specifications. No issues found.
```

### 示例 3：文件夹命名交互（选择建议名称）

**用户：** "检查 My_Skill 是否符合标准"

**Agent：** "请问您希望使用哪种语言输出验证报告？1. 中文  2. 原语言"

**用户：** "中文"

**Agent：** 
```
文件夹名称 "My_Skill" 不符合 kebab-case 规范（仅小写字母和连字符）。

请选择如何处理：
1. 保持原名称 "My_Skill"
2. 使用建议名称 "my-skill"
3. 输入自定义名称

请输入您的选择（1/2/3）：
```

**用户：** "2"

**Agent：** 执行重命名操作 `My_Skill` → `my-skill`

**响应：**

```markdown
## Skill 验证报告: my-skill

### 结构检查 (Structure Check)
- [PASS - 已重命名] 文件夹命名: 已从 "My_Skill" 重命名为 "my-skill"
- [PASS] SKILL.md 存在: 文件已找到

### YAML Frontmatter 检查
- [PASS] 有效 YAML: frontmatter 格式正确
- [PASS] name 字段: "my-skill" 与文件夹名匹配
- [PASS] description 字段: 包含功能描述 + 触发条件
- [PASS] 安全检查: 无 XML 尖括号

### 总结 (Summary)
- 总检查项: 7
- 通过: 7
- 失败: 0
- 合规率: 100%

### 建议 (Recommendations)
文件夹已重命名为符合规范的名称。Skill 符合所有标准规范。
```

### 示例 4：文件夹命名交互（选择自定义名称）

**用户：** "检查 My_Awesome_Skill 是否符合标准"

**Agent：** "请问您希望使用哪种语言输出验证报告？1. 中文  2. 原语言"

**用户：** "中文"

**Agent：** 
```
文件夹名称 "My_Awesome_Skill" 不符合 kebab-case 规范（仅小写字母和连字符）。

请选择如何处理：
1. 保持原名称 "My_Awesome_Skill"
2. 使用建议名称 "my-awesome-skill"
3. 输入自定义名称

请输入您的选择（1/2/3）：
```

**用户：** "3"

**Agent：** "请输入您期望的文件夹名称（仅小写字母和连字符）："

**用户：** "super-skill"

**Agent：** 执行重命名操作 `My_Awesome_Skill` → `super-skill`

**响应：**

```markdown
## Skill 验证报告: super-skill

### 结构检查 (Structure Check)
- [PASS - 已重命名] 文件夹命名: 已从 "My_Awesome_Skill" 重命名为 "super-skill"（用户自定义）
- [PASS] SKILL.md 存在: 文件已找到

...
```

### 示例 5：文件夹命名交互（保持原名称）

**用户：** "检查 MyLegacySkill 是否符合标准"

**Agent：** "请问您希望使用哪种语言输出验证报告？1. 中文  2. 原语言"

**用户：** "中文"

**Agent：** 
```
文件夹名称 "MyLegacySkill" 不符合 kebab-case 规范（仅小写字母和连字符）。

请选择如何处理：
1. 保持原名称 "MyLegacySkill"
2. 使用建议名称 "my-legacy-skill"
3. 输入自定义名称

请输入您的选择（1/2/3）：
```

**用户：** "1"

**响应：**

```markdown
## Skill 验证报告: MyLegacySkill

### 结构检查 (Structure Check)
- [PASS - 用户选择] 文件夹命名: 用户选择保持原名称 "MyLegacySkill"（不符合 kebab-case 规范）
- [PASS] SKILL.md 存在: 文件已找到

### 注意事项
文件夹名称 "MyLegacySkill" 不符合 kebab-case 规范，但用户选择保持原名称。
这可能导致在某些平台或工具中出现兼容性问题。

...
```

### 示例 6：优化 Skill 结构（文件分类）

**用户：** "优化 my-skill 的结构"

**Agent：** "请问您希望使用哪种语言输出验证报告？1. 中文  2. 原语言"

**用户：** "中文"

**Agent：** 扫描 skill 文件夹，发现以下文件需要分类：

```
my-skill/
├── SKILL.md
├── validate.ps1        # 应移至 scripts/
├── usage.md            # 应移至 references/
├── config.json         # 应移至 references/
└── logo.png            # 应移至 assets/
```

**响应：**

```markdown
## Skill 结构优化报告: my-skill

### 文件分类操作

| 文件 | 原位置 | 目标位置 | 状态 |
|------|--------|----------|------|
| validate.ps1 | 根目录 | scripts/ | ✅ 已移动 |
| usage.md | 根目录 | references/ | ✅ 已移动 |
| config.json | 根目录 | references/ | ✅ 已移动 |
| logo.png | 根目录 | assets/ | ✅ 已移动 |

### 更新后的目录结构

```
my-skill/
├── SKILL.md
├── scripts/
│   └── validate.ps1
├── references/
│   ├── usage.md
│   └── config.json
└── assets/
    └── logo.png
```

### 引用路径更新

已更新 SKILL.md 中的以下引用：
- `validate.ps1` → `scripts/validate.ps1`
- `usage.md` → `references/usage.md`
- `config.json` → `references/config.json`
- `logo.png` → `assets/logo.png`

### 总结
- 移动文件: 4
- 创建文件夹: 3
- 更新引用: 4
```

### 示例 7：发现问题（其他项）

**用户：** "检查 my-skill 是否符合标准"

**Agent：** "请问您希望使用哪种语言输出验证报告？1. 中文  2. 原语言"

**用户：** "中文"

**响应：**（如果发现其他问题，如 YAML、语言等）

```markdown
## Skill 验证报告: my-skill

### 结构检查 (Structure Check)
- [PASS] 文件夹命名: 使用 kebab-case "my-skill"
- [PASS] SKILL.md 存在: 文件已找到
- [FAIL] 文件分类: 根目录存在未分类文件 (validate.ps1, usage.md)

### YAML Frontmatter 检查
- [PASS] 有效 YAML: frontmatter 格式正确
- [FAIL] name 字段: "MySkill" 与文件夹名 "my-skill" 不匹配
- [FAIL] description 字段: 过于模糊: "Helps with tasks"
- [PASS] 安全检查: 无 XML 尖括号

### 语言一致性检查 (Language Consistency Check)
- [FAIL] 语言一致性: 指令、示例、说明文档未使用中文编写

### 总结 (Summary)
- 总检查项: 8
- 通过: 4
- 失败: 4
- 合规率: 50%

### 建议 (Recommendations)
1. 将 validate.ps1 移至 scripts/ 目录，usage.md 移至 references/ 目录
2. 更新 YAML 中的 name 为 "my-skill"（与文件夹名匹配）
3. 改进 description: 添加功能描述 + 触发条件
   示例: "验证数据文件。当用户上传 CSV 或 JSON 文件需要验证时使用。"
4. 将指令、示例和说明文档改为中文编写
```

### 示例 8：优化 Skill 并生成 README

**用户：** "优化 my-skill 并生成 README"

**Agent：** "请问您希望使用哪种语言输出验证报告？1. 中文  2. 原语言"

**用户：** "中文"

**Agent：** 执行优化操作后询问：

```
优化完成！是否需要生成或更新 README.md？
1. 是，生成 README
2. 是，更新现有 README
3. 否，跳过

请输入您的选择（1/2/3）：
```

**用户：** "1"

**Agent：** 从 SKILL.md 提取信息并生成 README：

**响应：**

```markdown
## Skill 结构优化报告: my-skill

### 文件分类操作
...（文件移动记录）

### README 生成 (README Generation)
- [PASS] README 生成: 已创建 README.md（根目录）

#### 生成的 README 内容预览

```markdown
# my-skill

验证数据文件。当用户上传 CSV 或 JSON 文件需要验证时使用。

## 功能概述

本 skill 提供数据文件验证功能，支持 CSV 和 JSON 格式。

## 目录结构

my-skill/
├── SKILL.md          # 核心指令文件
├── README.md         # 本文档
├── scripts/
│   └── validate.py   # 验证脚本
└── references/       # 参考文档（如有）

## 使用方法

1. 加载 skill
2. 运行 `python scripts/validate.py --input <filename>`
3. 查看验证结果

## 相关链接

- [SKILL.md](./SKILL.md) - 核心指令文件

## 元信息

- **版本**: 1.0.0
- **作者**: Developer
- **许可证**: MIT
```

### 总结
- 移动文件: 2
- 创建文件夹: 2
- 生成 README: 1
```

### 示例 9：更新现有 README

**用户：** "优化 my-skill 并更新 README"

**Agent：** 检测到现有 README 与 SKILL.md 不一致：

```
检测到 README.md 内容与 SKILL.md 不一致：
- 版本: "1.0.0" → "1.1.0"
- 描述: "验证数据文件" → "验证数据文件并生成报告"

是否更新 README.md？
1. 更新（保留自定义内容，仅更新元信息）
2. 完全覆盖（重新生成）
3. 保持不变

请输入您的选择（1/2/3）：
```

**用户：** "1"

**响应：**

```markdown
### README 生成 (README Generation)
- [PASS] README 更新: 已更新 README.md（保留自定义内容）

#### 更新的字段
- 版本: 1.0.0 → 1.1.0
- 描述: 已更新

#### 保留的自定义内容
- 使用示例部分保持不变
- 常见问题部分保持不变
```

## Troubleshooting

### 问题：找不到 SKILL.md

**症状：** 验证失败，因为找不到 SKILL.md

**解决方案：**

1. 检查文件是否准确命名为 `SKILL.md`（区分大小写）
2. 确认文件在 skill 文件夹根目录，而非子目录
3. 确保文件名无拼写错误

### 问题：YAML 解析错误

**症状：** Frontmatter 未被识别为有效 YAML

**解决方案：**

1. 确保 frontmatter 以 `---` 开始于第 1 行
2. 确保 frontmatter 以 `---` 结束
3. 检查 YAML 语法（缩进、冒号后需空格）
4. 验证无破坏 YAML 的特殊字符

### 问题：Description 过长

**症状：** Description 超过 200 字符

**解决方案：**

1. 将详细解释移至 SKILL.md body
2. 仅保留：功能描述 + 触发条件
3. 使用 references/ 存放额外文档

### 问题：指令模糊不清

**症状：** 指令使用模糊语言如 "请妥善验证"

**解决方案：**

1. 替换为具体命令或步骤
2. 使用 "运行 `python scripts/validate.py`" 而非 "验证"
3. 包含预期输出和错误处理

### 问题：语言不一致

**症状：** 用户选择中文但 Skill 内容未使用中文编写

**解决方案：**

1. 确认用户选择的语言偏好
2. 如果选择"中文"，将所有指令翻译为中文
3. 如果选择"原语言"，跳过语言检查
4. 技术术语可保留英文（如 API、YAML、kebab-case）

**注意：** 如果用户选择"原语言"，语言检查将被跳过，不会报告语言问题。

## References

完整的 Skill 标准规范请参阅 `references/skill-stddoc.md`。
