# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 1.0.4

### Added

- `ReceiveEvent` with a `body` for requests with a body
- Route helpers for every HTTP verb (`query`, `put` and `patch` were missing)

### Fixed

- Remove the `update` route helper which raised an error

## 1.0.3

### Fixed

- Requests with a body crashed the router instead of calling `receive`

## 1.0.0

### Changed

- Build static files without trailing slashes

### Fixed

- Pass parent params from node parent to child

## 0.12.0

### Added

- Support translations

## 0.11.0

### Added

- Add an asset compile pipeline for CSS and JS
- Add lowdata

## 0.10.0

### Added

- List support `<{ list: item folder: 'cards' }>`
- Raindown write-back/replace markdown feature

## 0.9.10

### Changed

- Router: Use take instead of trigger
- Router: Rename mid-node handle action to side_effect action
- Router: Rename WildcardRouteEvent to WildcardEvent

## 0.9.0

### Added

- Expose `Rain.pages` API

## 0.8.0

### Added

- Export markdown files to html

## 0.7.0

### Added

- Support raindown
- Serve JS files
- Add `rain` CLI

## 0.6.0

### Added

- Support wildcard routes (`'/*'`)
- Support markdown pages

## 0.5.0

### Added

- Add leet flicker effect

### Changed

- Namespace system nodes
- Handle config path in config loader
- Refactor boot and router setup
- Refactor stream cell color data into color effect

## 0.4.0

### Added

- Dashboard, Events and Routes system pages
- Introduce debug mode with `RAIN_DEBUG`/`debug_mode` config

### Changed

- Load dev gems only when present
- Observe both generic and specific status event

### Fixed

- Fix matrix type expression bug

## 0.3.0

### Added

- Rain Matrix
- Event Pool
- Event Tree

## 0.2.0

### Added

- LowLoad + RBX + Antlers
- Layout node, error 404 node
- Theme system nodes
- Rain Matrix

## 0.1.0

### Added

- Config and config loader

## 0.0.0

### Added

- Basic template
