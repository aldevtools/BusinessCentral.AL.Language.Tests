---
title: "29.1"
---

What changed in Business Central 29.1 (2026 release wave 2, update 29.1), compared with 29.0.

Measured on build 29.1.57326.58076 (local sandbox) and 29.1.57326.58760 (corpus CI), against 29.0.54011.55816.
63 corpus tests gave a different result. Most of them came from four version-data changes. Three are behavior changes.

Three of the changes undo a 29.0 difference: in these cases 29.1 behaves like 27 and 28 again. They are also listed
on the [29.0 page](../29.0/).

{{< change-list version="29.1" >}}

Not listed: the build number in text that Business Central writes (for example the Test Runner app version in call
stack frames). It changes with every build and is not a change of behavior.

Microsoft sources searched: the
[what's new page for update 29.1](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/whatsnew/whatsnew-update-29-1)
and the hotfix list in [KB 5135161](https://support.microsoft.com/help/5135161).
