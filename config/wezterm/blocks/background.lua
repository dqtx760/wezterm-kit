-- ===================== 背景图片 =====================
-- 由 install.ps1 在传入 -BackgroundImage 时注入
config.background = {
  {
    source = { File = "__BACKGROUND_IMAGE__" },
    repeat_x = "NoRepeat",
    repeat_y = "NoRepeat",
    vertical_align = "Middle",
    horizontal_align = "Center",
    opacity = 0.5,
    hsb = {
      brightness = 0.5,
      saturation = 1.0,
      hue = 1.0,
    },
  },
}
