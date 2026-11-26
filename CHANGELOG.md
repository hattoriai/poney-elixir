# Changelog

All notable changes to Poney for Elixir are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and the library follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
The Poney format has its own version (`Poney.format_version/0`).

## [Unreleased]

### Changed

- The package description on Hex says the library writes documents too.

## [0.1.0] - 2026-11-26

### Added

- `Poney.read/1` and `Poney.read!/1`: a conforming reader of the Poney
  format 0.2.0. It upgrades 0.1.0 documents, checks the shape against the
  format's published JSON Schema (a member the format does not know is an
  error), makes the canonical form, and applies rules R1–R14, W1 and the
  extension rules of §8.4.
- `Poney.check/1`: every issue, errors and warnings, each with its path and
  often a hint.
- `Poney.canonical/1`: the canonical form as JSON.
- `Poney.write/1`, `Poney.write!/1` and `Poney.to_json/1`: a document back
  to `.poney` text, checked first; indented, members in the format's order,
  data of unknown extensions kept.
- Structs for the whole document: `Poney.Document`, the model
  (`Poney.Model.*`), the views (`Poney.View.*`), the walkthroughs and their
  scenes (`Poney.Walkthrough.*`, `Poney.Scene.*`) and the presentation.
- `Poney.Ref`: refs such as `"entity:order-service"`, read and written.
- `mix poney.spec`: copies the schema, the conformance suite and the examples
  from a tagged release of Poney (now `v0.2.0`).
