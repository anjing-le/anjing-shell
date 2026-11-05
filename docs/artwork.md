# 配图与来源

## README 插画

- 文件：`.github/assets/shellx-hero.png`。
- 生成方式：内置 imagegen，2026-11-05。
- 参考：用户提供的蓝壳蜗牛图标 `Resources/AppIcon-source.png`，仅作为角色与画风参考。
- 这是一张产品概念插画，不是真实客户端截图，不代表已接入 SSH / SFTP。

最终提示词：

```text
Create a wide landscape GitHub README hero illustration, approximately 2.4:1 aspect ratio, for ShellX, a quiet personal macOS terminal workspace. Reference image is ONLY a character and visual-style reference, not an image to edit. Preserve the recognizable simple green snail with blue spiral shell and the small black >_ terminal mark on its shell. Warm off-white textured paper, children's crayon and colored-pencil drawing, uneven charcoal-black outlines, visible wax grain, muted sage green and soft sky blue with tiny butter-yellow accents. Compose one coherent restrained editorial illustration: a friendly snail beside a simple hand-drawn terminal workspace, showing a slim server sidebar as three small stacked rectangles, two top tabs, two side-by-side terminal panes, and a file column suggested with a few blue folder shapes. Large generous negative space and airy spacing. No people, no human faces. The snail's eye stalks are simple black dot eyes, matching the reference. No words, no letters, no numbers, no title, no watermark; the tiny >_ terminal symbol is the only allowed glyph. No fake screenshots or detailed logs. No 3D, glass, glossy rendering, heavy shadows or marketing graphics. It should feel like an illustration drawn in a personal notebook, suitable above a concise README, not a product screenshot.
```

## 应用图标与纸张

蜗牛图标原图由用户提供，保留于 `Resources/AppIcon-source.png`。`scripts/prepare-icon.swift` 只处理原底板边缘和透明角，不重画蜗牛；`Resources/ShellX.icon` 保存原生图标文档，`scripts/build-icon.py` 生成 Assets.car 和兼容 ICNS。

纸张 `Sources/ShellX/Resources/PaperTexture.png` 复用 createX 的 imagegen 静态纹理。基础窗口与共享指针跟踪代码参考 createX / EnglishX。

个人 Old Roblox 指针受原作者个人使用条款限制，仅留在本机忽略目录；Richfree PNG 的再分发许可未核实，也不放入公开源码。缺少这些图片时使用系统指针回退，不改变原生文本选择、输入法或窗口缩放。
