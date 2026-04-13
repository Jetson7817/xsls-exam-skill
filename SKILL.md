---
name: xsls-exam-skill
description: 使用此技能把样卷 OCR 图片、扫描 PDF、OCR PDF 转成符合正规考试卷规范的 LaTeX 试卷项目，并编译成 PDF。当用户想“按大8开/A3 横版试卷复刻样卷”“带装订线生成数学试卷”“题量和题型变化时仍按标准灵活排版”时触发。
---

# XSLS Exam Skill

## Overview

这个技能面向“样卷图片/PDF -> 标准化 LaTeX 试卷项目 -> PDF”的出卷流程。

它继承并收敛了我们前面已经验证过的规则：

- 默认按 `A3` 试卷模板工作，同时兼容 `大8开`
- 默认按 **横版成卷** 排版，不按竖版 A4 思路排
- 每一页优先按 **左右两个半页** 组织内容
- 默认包含左侧 **装订线**
- 数学试卷优先用 `XeLaTeX`
- 题量、题型、图题变化时，允许增加或重排半页，但不能破坏纸张规格和成卷标准

如果只是把 OCR 文本简单排成一页页文档，不要用这个技能；当目标是“接近正规考试卷成品”时再用。

## Use This Skill When

- 用户要把样卷 PDF、截图、扫描图复刻成正式试卷 PDF
- 用户明确提到 `A3`、`大8开`、`装订线`、`横版`
- 用户要适配选择题、填空题、解答题、带图题、表格题
- 用户希望题量变化后仍能自动保持成卷规范

## Core Workflow

### 1. 判断输入类型

- **OCR PDF / 可搜索 PDF**：优先提取文字层，再人工校正公式与图形。
- **扫描 PDF / 图片**：先看版式，再逐题转写。
- **单页截图**：先识别它属于整卷中的哪个半页，再决定放位。

### 2. 自动识别版式骨架

这一阶段是 `xsls-exam-skill` 的第二阶段能力，目标不是直接排出 LaTeX，而是先判断样卷的结构骨架。

必须先读：

- [references/layout-detection-rules.md](references/layout-detection-rules.md)
- [references/auto-pagination-rules.md](references/auto-pagination-rules.md)

识别目标包括：

1. 纸张更接近 `A3` 还是 `大8开`
2. 是否是 `横版双半页`
3. 每一页的左半页、右半页分别是什么题型块
4. 哪些题是长题、哪些题是图题、哪些题应优先独占半页

### 3. 先判断整卷结构，再写题目

不要一边识别一边盲排。先做这三件事：

1. 判断纸张基线：默认 `A3`，若用户或样卷更接近 `大8开`，切到 `大8开`
2. 判断总页数：按“横版一页 = 左半页 + 右半页”估算半页数量
3. 判断分区块：标题区、分值表、选择题、填空题、解答题、图题分别作为块来排

然后把判断结果先写进 `pagination-plan.md`，再开始排 `main.tex`。

### 4. 初始化项目

优先运行：

```bash
bash /Users/jetson/.codex/skills/xsls-exam-skill/scripts/new_exam_project.sh /path/to/project
```

这会创建：

- `main.tex`
- `pagination-plan.md`
- `review.md`
- `source/`
- `build/`

模板来自 `assets/templates/exam-paper.tex`。

### 5. 按“半页块”填充内容

必须遵守：

- 先排 **块**，再调块内细节
- 题目应尽量整题落在同一个半页中
- 不要为了凑页数把一道解答题切成很碎的上下两截
- 带图题优先给独立半页，或至少保证图文在同一半页内

### 6. 编译 PDF

优先运行：

```bash
bash /Users/jetson/.codex/skills/xsls-exam-skill/scripts/compile_exam_latex.sh /path/to/project/main.tex --engine xelatex --use-latexmk --preview
```

### 7. 输出与迭代

标准交付物：

1. `main.tex`
2. `main.pdf`
3. `pagination-plan.md`
4. `review.md`
5. `previews/`

用户之后提出“选择题改成 10 道”“加一道立体几何图题”“改成大8开”时，应直接改 `.tex` 并重新编译。

## Layout Standards

先读 [references/layout-standards.md](references/layout-standards.md)。

这是硬标准，优先级高于单页内容密度：

- `A3` / `大8开` 纸张标准
- 横版双半页
- 左侧装订线
- 标题区、分值表、题型分区的基本秩序

## Adaptive Rules

当题量或题型变化时，必须读 [references/adaptive-layout-rules.md](references/adaptive-layout-rules.md)。

关键原则：

- **先保完整，再保相似**
- **先保成卷标准，再做局部微调**
- **优先移动整块，不优先压字距和行距**

也就是说，遇到内容变多时，优先：

1. 调整半页块分配
2. 增加新半页或新横版页
3. 只在最后一步微调局部间距

不要一开始就把字号和行距压得过密。

## Auto Pagination

自动分页的真正含义不是“自动塞满页面”，而是：

1. 先根据样卷识别整卷骨架
2. 再产出一个 `pagination-plan.md`
3. 最后依据这个规划文件排成 `main.tex`

也就是说，自动化重点在：

- 识别样卷是不是横版双半页
- 识别哪些块属于第一页左半、第一页右半、第二页左半、第二页右半
- 识别图题、长题和应独占半页的题

而不是跳过结构分析，直接把 OCR 文本堆进模板。

## Project Rules

- 默认把 `.tex` 视作主资产，`PDF` 是编译产物。
- 中文数学试卷优先 `XeLaTeX`。
- 不要求用户手写 LaTeX。
- 开始排版前，优先先写 `pagination-plan.md`。
- 对 OCR 不确定项、公式疑点、图形裁切来源，必须同步记录到 `review.md`。
- 如果样卷是“成卷横版”，不要误按 A4 竖版逻辑拆页。

## Formal Example

这个技能已经内置了第一份正式样卷案例：

- [26-baimu-math-4](/Users/jetson/.codex/skills/xsls-exam-skill/examples/26-baimu-math-4/CASE.md)

它不是普通示例，而是当前这套规范的首个回归样本。后续修改模板、分页规则、装订线位置、A3/大8开切换逻辑时，应优先拿这个案例重新编译检查，避免把已经验证过的版式改坏。

## Quick Commands

```bash
# 1. 创建项目
bash /Users/jetson/.codex/skills/xsls-exam-skill/scripts/new_exam_project.sh ~/Desktop/my-xsls-exam

# 2. 编译并生成预览
bash /Users/jetson/.codex/skills/xsls-exam-skill/scripts/compile_exam_latex.sh ~/Desktop/my-xsls-exam/main.tex --engine xelatex --use-latexmk --preview
```
