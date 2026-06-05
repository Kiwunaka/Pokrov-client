# Maintainer Checklist

Use this checklist before importing source or publishing an official release.

## Before Source Import

- [ ] Export from the private client lane into a temporary staging area.
- [ ] Remove private history.
- [ ] Remove secrets, tokens, certificates, and signing config.
- [ ] Remove private endpoints and operator-only paths.
- [ ] Remove private logs, screenshots, and release evidence.
- [ ] Confirm all generated assets have source and release-scope notes.
- [ ] Run secret scanning.
- [ ] Complete dependency license review.
- [ ] Confirm a fresh clone builds without private files.

## Before Public Binary Release

- [ ] Build from a public source reference.
- [ ] Record artifact names and versions.
- [ ] Generate SHA-256 checksums.
- [ ] Verify install notes and beta warnings.
- [ ] Confirm official download links.
- [ ] Confirm release claims match evidence.
- [ ] Confirm security contact path.

## Before Announcement

- [ ] Avoid claiming the whole platform is open source.
- [ ] Avoid unsupported store, stable, signing, audit, or readiness claims.
- [ ] Link to source, release notes, checksums, and support.
- [ ] Confirm official channels point to the same artifacts.
