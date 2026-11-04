# Changelog

## [2026-10-07] - Claim + reset hardening

### Fixed
- `UpdateStarterPack` is now console/admin only (was: any client could reset claims or delete records).
- `ClaimVehicle` rejects non-allowlisted vehicles (configured/random pool) and is skipped for players who already claimed.
- `ClaimStarterpack` awaits the radius check before granting or flagging the pack as received.
