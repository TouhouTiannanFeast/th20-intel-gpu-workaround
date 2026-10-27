# TH20 startup crash in Intel igd9trinity32.dll

Compatibility reference. Alternate-GPU workaround, not an upstream driver fix.

## Anonymized reference case

- TH20 retail executable; the rendered title identifies version 1.00c.
- Executable, th20.dat and thbgm.dat matched their original local ZIP by SHA-256.
- Windows Application Error event 1000 records th20.exe crashing in igd9trinity32.dll, driver 32.0.101.8331, exception 0xc0000005, offset 0x00a53755.
- Hardware category: a Windows hybrid-graphics computer with Intel integrated graphics and a non-Intel discrete GPU. Exact adapter model and machine identifiers are omitted.
- Setting the current user's per-application GPU preference to high performance was followed by successful startup. No new application crash was found during the short observation window.
- A separate offscreen-window problem also required correcting saved window coordinates from (-32000, -32000). The game then visibly rendered its startup screen. The package deliberately does not change window configuration.
- No controlled switch-back reproduction, driver stack analysis or extended gameplay test was performed. The evidence supports trying the alternate-GPU workaround; it does not establish the exact driver defect or general failure rate. Actual adapter selection was not independently traced.

## Public reports checked

No exact TH20 + igd9trinity32.dll + driver 32.0.101.8331 report was found in the searched public results. This is a search result, not proof that no report exists.

1. An Intel Community first-person report describes other software crashing with an access violation in igd9trinity32 during graphics initialization. Different applications and driver versions; supporting context, not an identical TH20 issue:
   https://community.intel.com/t5/GPU-Compute-Software/EXCEPTION-ACCESS-VIOLATION-READ-Crashes-in-igd9trinity32/m-p/1648245
2. TH20's Steam startup-crash discussion includes AMD/NVIDIA GPUs and exceptions 0xc0000409 / 0xe06d7363, including discussion of non-Latin user paths. It must not be counted as the same Intel-module crash:
   https://steamcommunity.com/app/3671710/discussions/0/603029860838861052/
3. Intel documents choosing an application's preferred GPU through Windows graphics settings:
   https://www.intel.com/content/www/us/en/support/articles/000090168/graphics.html

## Package validation

The workaround reproduces the per-application setting used in the reference case. The portable script passed PowerShell syntax, read-only status and no-write preview checks. Those checks do not constitute validation on other hardware.

The tool backs up only the selected application's original preference, retains unrelated fields, supports restoration, refuses unexpected registry types and detects preference changes before restoration. It neither updates nor disables the Intel driver.
