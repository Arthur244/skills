---
name: skill-std-validator
description: Validates Skill folders against the official Skill standard specification. Use when user asks to "validate skill", "check skill compliance", "verify skill structure", or when creating/reviewing any Skill.
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
├── scripts/          # 可选
├── references/       # 可选
└── assets/           # 可选
```

**验证规则：**

- [ ] SKILL.md 文件存在（区分大小写）
- [ ] skill 文件夹内无 README.md（应仅在仓库根目录）

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
- [PASS/FAIL] 无 README.md: <details>

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
- [PASS] 无 README.md: skill 文件夹内无 README.md

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
- [PASS] No README.md: No README.md in skill folder

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
- [PASS] 无 README.md: skill 文件夹内无 README.md

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
- [PASS] 无 README.md: skill 文件夹内无 README.md

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
- [PASS] 无 README.md: skill 文件夹内无 README.md

### 注意事项
文件夹名称 "MyLegacySkill" 不符合 kebab-case 规范，但用户选择保持原名称。
这可能导致在某些平台或工具中出现兼容性问题。

...
```

### 示例 6：发现问题（其他项）

**用户：** "检查 my-skill 是否符合标准"

**Agent：** "请问您希望使用哪种语言输出验证报告？1. 中文  2. 原语言"

**用户：** "中文"

**响应：**（如果发现其他问题，如 README.md、YAML 等）

```markdown
## Skill 验证报告: my-skill

### 结构检查 (Structure Check)
- [PASS] 文件夹命名: 使用 kebab-case "my-skill"
- [PASS] SKILL.md 存在: 文件已找到
- [FAIL] 无 README.md: skill 文件夹内发现 README.md

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
1. 将 README.md 从 skill 文件夹移至仓库根目录
2. 更新 YAML 中的 name 为 "my-skill"（与文件夹名匹配）
3. 改进 description: 添加功能描述 + 触发条件
   示例: "验证数据文件。当用户上传 CSV 或 JSON 文件需要验证时使用。"
4. 将指令、示例和说明文档改为中文编写
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
