---
description: Refresh the statusline to update usage information
---

```bash
# Clear all session-specific statusline caches to force refresh
rm -f ~/.claude/.statusline_cache_* 2>/dev/null
```

Statusline refreshed. The usage information in the bottom status bar has been updated with token-based calculations, including current model information.
