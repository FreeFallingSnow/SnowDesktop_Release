# Third-Party Notices

SnowDesktop includes or redistributes the following third-party software and
assets. These notices apply only to the named components. The SnowDesktop core
is licensed under the GNU General Public License v3.0; the separate Steam bridge
under `steam_bridge/` is licensed under the MIT License.

| Component | Version | License | Copyright / source |
| --- | --- | --- | --- |
| Microsoft Windows App SDK | 2.4.0 NuGet package | Microsoft Software License Terms | Copyright (c) Microsoft Corporation; <https://github.com/microsoft/WindowsAppSDK> |
| Microsoft Windows ML Runtime | 2.1.74 NuGet package | Microsoft Software License Terms | Copyright (c) Microsoft Corporation; <https://learn.microsoft.com/windows/ai/new-windows-ml/> |
| Microsoft Edge WebView2 SDK | 1.0.3719.77 NuGet package | BSD 3-Clause | Copyright (c) Microsoft Corporation; <https://developer.microsoft.com/microsoft-edge/webview2/> |
| Microsoft.Windows.CppWinRT | 3.0.260818.1 NuGet package | MIT | Copyright (c) Microsoft Corporation; <https://github.com/microsoft/cppwinrt> |
| Dear ImGui | 1.92.5 WIP | MIT | Copyright (c) 2014-2025 Omar Cornut and contributors; <https://github.com/ocornut/imgui> |
| Lua | 5.4.7 | MIT | Copyright (C) 1994-2024 Lua.org, PUC-Rio; <https://www.lua.org> |
| Everything SDK client | bundled source | MIT | Copyright (C) 2016, 2022 David Carpenter; <https://www.voidtools.com/support/everything/sdk/> |
| pinyin-data | bundled data | MIT | Copyright (c) 2016 mozillazg; <https://github.com/mozillazg/pinyin-data> |
| MinHook | bundled source | BSD 2-Clause | Copyright (c) 2009-2017 Tsuda Kageyu; <https://github.com/TsudaKageyu/minhook> |
| Font Awesome 6 Free Solid | 6.5.2 font | SIL Open Font License 1.1 | Copyright (c) Font Awesome; <https://fontawesome.com/license/free> |
| Fluent System Icons Regular | upstream commit `21d5d02f724be2aaf586564775fff73a18a76eb6` | MIT | Copyright (c) 2020 Microsoft Corporation; <https://github.com/microsoft/fluentui-system-icons> |
| DeskMakeover shape catalog | upstream `main` as referenced in 2026 | MIT | Copyright (c) 2026 Jinming Yang; <https://github.com/nicepkg/deskmakeover> |
| TranslucentTB-derived portions | upstream commit `322e2b7395a51975150126276308b415970e080b` | GPL-3.0-only | Copyright (c) TranslucentTB contributors; <https://github.com/TranslucentTB/TranslucentTB/tree/322e2b7395a51975150126276308b415970e080b> |

The complete Everything SDK, Dear ImGui, Lua, pinyin-data, Font Awesome,
Microsoft Fluent System Icons and MinHook license texts are retained under
their corresponding `third_party/` directories. All are copied into the
`licenses` directory of release packages. The Font Awesome font is distributed
under the SIL Open Font License 1.1 with the reserved font name
"Font Awesome".

The Microsoft Windows App SDK runtime is redistributed self-contained under
the license terms and third-party NOTICE installed by the pinned 2.4.0 NuGet
package. The build records those files in `SnowDesktop.deployment.json`, and all
release packagers copy them to the payload `licenses` directory. The pinned
Windows ML 2.1.74 and WebView2 1.0.3719.77 licenses and third-party notices are
copied the same way, along with the Microsoft.Windows.CppWinRT 3.0.260818.1 MIT
license.

## TranslucentTB-derived portions

SnowDesktop contains modified portions derived from TranslucentTB at upstream
commit `322e2b7395a51975150126276308b415970e080b`. The incorporated material is
copyright TranslucentTB contributors and remains licensed under GPL-3.0-only,
the same license used by the SnowDesktop core. SnowDesktop modified the material
in 2026 for its own taskbar integration and desktop backdrop implementation.

The affected files are:

- `src/taskbar_dynamic/ShellViewCoordinator.idl`
- `src/taskbar_hook/taskview_visibility.h`
- portions of `src/taskbar_hook/taskbar_hook.cpp`
- portions of `src/app/desktop_backdrop_compositor.cpp`

The complete GPL v3 license text is retained in the repository root `LICENSE`.
The upstream source and history remain available at the pinned TranslucentTB
commit linked above.

## DeskMakeover-derived shape geometry

`src/icon_beautify.cpp` adapts normalized shape control points and continuous
corner geometry from DeskMakeover's `dm-icon-core` shape catalog. The upstream
visual-language reference is available at
<https://github.com/nicepkg/deskmakeover/blob/main/docs/specs/02-visual-language.md>
and the upstream project source is available at
<https://github.com/nicepkg/deskmakeover>.

DeskMakeover is distributed under the following MIT License:

Copyright (c) 2026 Jinming Yang

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## Optional Steamworks dependency

`steam_bridge/` can optionally be built against a separately obtained
Steamworks SDK. The SDK, its headers, import libraries, and redistributable
binary are not included in this repository and are not covered by either the
SnowDesktop GPL license or the bridge MIT license. See
`steam_bridge/THIRD_PARTY_NOTICES.md` for the distribution boundary.
