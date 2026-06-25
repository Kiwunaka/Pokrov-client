# Assets

This folder contains public repository visuals used by the README and docs.

## Current Assets

- `brand/pokrov-oss-hero.png`: hero artwork for the repository README.
- `brand/oss-status-card.png`: public repository status artwork.
- `brand/open-source-showroom.png`: README track overview for personal,
  operator, and source-only boundary positioning.
- `brand/client-flow-loop.gif`: lightweight animated README flow preview.
- `brand/repo-social-preview.png`: GitHub social preview candidate; set it
  manually in repository settings if desired.
- `diagrams/open-source-boundary.png`: open-client/private-service boundary
  artwork.
- `IMAGEGEN_PROMPTS.md`: generation prompts and provenance notes for the
  raster artwork and scripted visuals.
- `../config/generated-assets.seed.json`: machine-readable source-release
  inventory for every PNG asset and its reuse scope. GIF previews are described
  here and in `IMAGEGEN_PROMPTS.md`, but the current machine inventory is
  intentionally PNG-only.

## Asset Rules

- Keep repository visuals public-safe.
- Do not include secrets, private hostnames, personal data, private logs, or
  unreleased official claims in images.
- Keep generated raster assets paired with prompt/provenance notes.
- Do not add third-party icons, fonts, or images without source and license
  notes.
- Do not use official brand assets in a way that lets forks impersonate
  official POKROV builds.
