# Talented_CNWotLK
Personal modified version

Start From [TalentedClassic v230910-wotlk](https://github.com/Lethay/TalentedClassic/tree/v230910)

# 修改原因
国服怀旧服目前插件接口的版本和海外插件接口版本不一致，导致海外 WLK 可用的插件无法在国服使用，或者有各种报错。

## Change Log
### 2025/3/23
- `Talented_SpecTabs\core.lua` 中 `GetTalentTabInfo` 新的接口返回了更多的返回值，进行了适配。
- `Talented_GlyphFrame\glyph.lua` 中 `GetGlyphSocketInfo` 新的接口返回了更多的返回值，进行了适配。
- `Talented\view.lua` 中 `GetTalentTabInfo` 新的接口返回了更多的返回值，进行了适配。
- `Talented\ui\menu.lua` 中，`EasyMenu` 在 3.4.4 中移除了，重新进行了实现
- `Talented\check.lua` 中，`GetTalentTabInfo` 新的接口返回了更多的返回值，进行了适配。