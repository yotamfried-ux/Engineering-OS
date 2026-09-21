# RuView

**Canonical upstream:** `ruvnet/RuView`

Experimental WiFi/CSI spatial-sensing platform for presence, movement, pose and vital-sign inference using radio signals rather than cameras. Upstream includes firmware, sensing software, tests, agent/plugin assets and MCP support.

## Use when
Use as a specialized reference for RF/WiFi sensing, ESP32 CSI pipelines, edge perception, sensor fusion and agent-assisted hardware workflows.

## Important limitations
Full CSI functionality requires compatible hardware; ordinary consumer WiFi telemetry is not equivalent. Upstream labels the software beta and documents accuracy/hardware limitations. Treat health/vital-sign outputs as experimental sensing data, not medical diagnosis.

## Qualification
Start with upstream deterministic verification and documented smoke tests before hardware claims. For live sensing, record hardware, firmware, environment, calibration, dataset/model and measured result.

**Status:** SPECIALIZED REFERENCE / HOST-AND-HARDWARE-DEPENDENT.
