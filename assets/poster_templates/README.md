# 海报模板资源

本目录包含用于 F07-海报长截图功能的海报模板资源。

## 目录结构

```
poster_templates/
├── template_001.jpg          # Fresh Nature 模板（需要3张图片）
├── template_002.jpg          # Minimal Blue 模板（需要4张图片）
├── template_003.jpg          # Warm Sunset 模板（需要2张图片）
├── template_004.jpg          # Green Forest 模板（需要3张图片）
├── template_005.jpg          # Pink Aesthetic 模板（需要6张图片）
├── templates_config.json     # 模板配置文件
└── README.md                 # 本说明文档
```

## 模板配置说明

`templates_config.json` 包含所有模板的元数据：

- **id**: 模板唯一标识
- **name**: 模板名称
- **thumbnail**: 缩略图路径
- **templateUrl**: 模板文件路径
- **imageSlots**: 图片占位区配置数组
  - **x, y**: 占位区左上角坐标
  - **width, height**: 占位区尺寸
  - **shape**: 形状类型（rectangle/circle/roundRect）
- **requiredImageCount**: 需要的图片数量

## 如何使用

1. 读取 `templates_config.json` 获取模板列表
2. 在模板列表页展示缩略图
3. 用户选择模板后，根据 `requiredImageCount` 引导选择对应数量的图片
4. 在编辑页根据 `imageSlots` 配置将图片嵌入到模板的指定位置

## 添加新模板

1. 将模板图片文件放入本目录（建议命名：template_XXX.jpg）
2. 在 `templates_config.json` 中添加对应的配置项
3. 运行 `flutter pub get` 确保资源被识别

## 生成缩略图

建议为每个模板生成缩略图以提升加载性能：

- 缩略图建议尺寸：300x533 (16:9 竖版比例)
- 格式：JPG
- 质量：80-85%

## 注意事项

- 模板图片应为竖版长图（建议比例 9:16）
- 图片占位区坐标基于原始模板尺寸
- 确保占位区不会超出模板边界
- 支持的形状类型：
  - `rectangle`: 矩形
  - `roundRect`: 圆角矩形
  - `circle`: 圆形

## 来源说明

当前模板来自 Unsplash 免费图片库，仅用于开发测试。
正式版本应替换为设计师提供的专业海报模板。
