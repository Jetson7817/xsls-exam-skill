# xsls-exam-skill

一个面向数学试卷生产场景的本地 skill。

它用于把样卷图片、扫描 PDF、OCR PDF 转成符合正规考试卷规范的 LaTeX 试卷项目，并进一步编译成 PDF。

## 核心能力

- 支持 `A3` / `大8开`
- 支持横版双半页排版
- 支持左侧装订线
- 支持选择题、填空题、解答题、图题
- 支持先做版式骨架识别，再做分页规划
- 支持 `XeLaTeX` 编译输出 PDF

## 目录结构

- `SKILL.md`：skill 主说明
- `agents/openai.yaml`：UI 元数据
- `assets/templates/`：LaTeX 模板与分页规划模板
- `references/`：版式标准、自适应规则、自动识别与自动分页规则
- `scripts/`：项目初始化与编译脚本
- `examples/26-baimu-math-4/`：首个正式样卷案例

## 安装到 autoclaw

如果你使用的是 `autoclaw/openclaw`，将整个仓库目录放到：

```bash
~/.openclaw-autoclaw/skills/xsls-exam-skill
```

确保最终存在：

```bash
~/.openclaw-autoclaw/skills/xsls-exam-skill/SKILL.md
```

然后重启 `autoclaw`。

## 使用示例

```text
使用 xsls-exam-skill 把样卷 PDF 转成 A3/大8开横版、带装订线的 LaTeX 试卷项目
```

## 本地初始化与编译

```bash
bash scripts/new_exam_project.sh ~/Desktop/my-xsls-exam
bash scripts/compile_exam_latex.sh ~/Desktop/my-xsls-exam/main.tex --engine xelatex --use-latexmk --preview
```

## 说明

这个 skill 在创建过程中参考并吸收了已有的 `latex-document` 与 `latex` 两个 skill 的思路，再围绕正规考试卷场景补充了试卷专用规则层。
