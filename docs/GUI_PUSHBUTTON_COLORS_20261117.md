# BLASST v0.3.4-dev — EEGLAB pushbutton palette correction

This update corrects the **OK** and **Cancel** pushbutton backgrounds in the active `+blasstdispatch/settingsDialog.m` used for both Legacy and Optimized BLASST.

| GUI object | Background RGB | Foreground RGB |
| --- | --- | --- |
| Dialog and static text | `[0.66 0.76 1]` | `[0 0 0.4]` |
| User-edit and popup controls | white | `[0 0 0]` |
| OK and Cancel pushbuttons | **`[0.93 0.96 1]`** | `[0 0 0.4]` |

The implementation selection remains Optimized by default, and execution mode remains Serial by default. The inactive historical `+blasstcore/settingsDialog.m` remains byte-exact to retain reference source fidelity; the active dialog is `+blasstdispatch/settingsDialog.m`.

`tests/test_blasst_gui_presentation.m` includes static assertions for the pushbutton color and version label. An actual MATLAB Desktop GUI render remains necessary to confirm the palette visually.

No FFT, atom, histogram, cache, boundary, progress, or metadata logic was changed.
