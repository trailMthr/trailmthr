# Activity Recording Known Risks

## Android/OEM behavior
- Aggressive battery optimization may throttle or kill foreground services.
- Screen-off can reduce GPS frequency; rely on gating + stall detection.

## Data integrity risks
- ID mismatch between controller and recorder (fixed Jan 2026).
- Non-atomic resume flows causing UI/stream desync (fixed Jan 2026).

## Next mitigations
- Gap markers / segment model (pause + stall + screen-off).
- UI should surface stall state clearly.
- Export should include gaps and reason codes.
