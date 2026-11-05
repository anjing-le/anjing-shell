# 开发与交互说明

面向 Mac 的本地终端界面预览，使用 Swift / SwiftUI / AppKit，与 EnglishX、createX 延续同一纸张风格和鼠标指针。

```sh
bash scripts/preview.sh
```

提供模拟服务器搜索、分组收起、多标签打开/关闭/拖动排序、左右/上下分屏及比例调整、文件夹浏览与模拟传输。终端支持选择复制、搜索和少量固定 mock 命令；`help` 查看支持项。分区比例及侧栏显隐保存在本机偏好中。

快捷键：⌘T 新标签、⌘W 关闭标签、⌘D 左右分屏、⌘⇧D 上下分屏、⌘B 服务器栏、⌘⇧E 文件栏、⌘⇧[ / ] 切换标签、⌘, 设置。

所有地址、日志和文件均为示例。没有 SSH、SFTP、网络请求或 shell 执行；文件拖入仅读取文件 URL 的名称，不读取文件内容，不创建上传或下载文件。尚未提供正式安装包或 OTA。

`.local/cursor-preview` 保留个人预览指针原件与 NOTICE；仅被打包到本地 `.preview` 应用，不应提交或用于分发。

侧栏交互：顶部「＋」新增服务器或分组，组内「＋」自动选中分组；「…」支持编辑、移动分组、重命名分组与另开标签。普通点击优先回到已有会话。搜索名称、地址、分组和用户名，空格分隔的多个条件同时匹配；搜索时临时展开分组，清空后恢复折叠状态。Enter 打开首个结果，Esc 清空搜索或关闭当前面板。

服务器与分组编辑只在本次运行的内存中生效，重启恢复示例。没有凭据输入或真实连接。已打开标签保留原配置快照；修改后的配置用于新标签。


## 图标与素材

仓库包含已编译的图标资源，普通构建无需重建。重新生成图标需要 Xcode 27+ 的 Icon Composer / actool：

```sh
python3 scripts/build-icon.py
```

可通过 `SHELL_X_ICON_DEVELOPER_DIR` 指定 Xcode 的 `Contents/Developer`，不修改系统 Xcode 选择。原图在 `Resources/AppIcon-source.png`，原生图标文档在 `Resources/ShellX.icon/`。图标铺满原生轮廓，避免旧版 ICNS 被嵌套显示。

公开源码不包含个人 Old Roblox 指针素材，也不分发许可未核实的 Richfree PNG；缺失时自动使用系统箭头、点击手形和文本指针。本机已有的素材继续保留，`.local/cursor-preview` 仅用于个人本地预览。拖动指针的代码绘制和共享 cursorUpdate 跟踪保留。

上层技术栈和基础纸张、窗口、指针跟踪实现参考同账号的 createX 与 EnglishX。没有连接真实服务器的代码路径，不应把模拟输出当成服务器执行结果。
