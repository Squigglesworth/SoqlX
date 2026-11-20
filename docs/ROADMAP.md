# SoqlX Rebooted: roadmap and decisions

Design source of truth: the "SoqlX Rebooted" design system (tokens, components, brand book).
The app stays native AppKit; the system is translated by hand, with native behaviour winning
where the two conflict and the system's colour, type, spacing and layout winning everywhere else.
The SOQL engine (parser, tokenizer, completions) is not changed by this work.

## Decisions (Nov 2026)

- Public release is the goal. Until the release phase, the bundle identifier, update feed and
  signing stay as they are so preferences and saved logins survive; see Release plumbing below.
- Query All becomes a checkbox beside Run: "Include deleted and archived".
- Multiple org windows stay, as native macOS window tabs; each tab shows the org's custom label
  and colour. A single-window org switcher is deferred.
- Org settings are keyed by Organization Id: label, colour, type tag, "Prevent deleting of data",
  "Read-only". Read-only also blocks in-grid edits and running Apex. Anything that isn't a sandbox
  or a Developer Edition is treated as Production for the safety rules.
- Zoom is a text size setting (editor, results, sidebar, inspector), not whole-UI scaling.
- Sidebar keeps object icons, but flat ones that don't overlap the text. Field capability marks
  live in the hover, under a "Metadata" heading, not in the tree.
- Theme follows the system by default, with Light/Dark overrides. Density is a setting.

## Phases

1. Foundation: name, icon, bundled Inter + JetBrains Mono, colour tokens as asset catalog colours
   (`SXTokens`), View > Appearance, API call meter in the status bar.
2. Shell: NavRail, title bar with the OrgChip, window tabs, Details docked as the inspector,
   Recent as a panel, status bar with facts only.
3. Editor and results: Run in the editor footer, deleted-records checkbox, keywords mustard and
   semibold with fields in ink, delete in the results footer with count and typed confirmation in
   Production, per-org safety toggles, Id links, null cells, empty state.
4. Sidebar: Standard / Custom / Metadata / Platform events filters, show system objects, show
   non-queryable objects, Recent first, flat icons, reorganised hover metadata.
5. Settings page replacing Preferences: Appearance (theme, density, text size), Query, Safety,
   Apex and logs, Connections (org table + consumer key), Start Here guide, Release notes (linked
   from the version in the footer), About.
6. Schema view restyle with the tokens (no behaviour change).

## Backlog

- Apex view and LogViewer per the design system.
- Schema rebuild: focus + filter chips, no dragging, one hop at a time.
- Single-window org switcher from the OrgChip.
- Six `QueryResultTableTest` failures on macOS 27 (column widths; diagnostics in the test).
- Release plumbing: own bundle identifier, Sparkle 2 feed and EdDSA keys, Apple Developer
  signing and notarization, full OFL licence text for the bundled fonts, connected app for
  public distribution (orgs must install it), Fragaria submodule deployment target.
- Field descriptions in the hover: the describe API returns only inline help text. The Description
  a field has in Setup needs a Tooling API query on FieldDefinition, one call per object.
- Sidebar: drag a name into the editor; a Custom badge; density and text size (phase 5).
