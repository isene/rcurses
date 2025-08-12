# Changelog

## [5.1.0] - 2025-08-12

### Added
- Support for Ctrl+Arrow key combinations (C-UP, C-DOWN, C-LEFT, C-RIGHT)
  - Added detection for standard CSI format escape sequences (`\e[1;5A`, `\e[1;5B`, `\e[1;5C`, `\e[1;5D`)
  - Added detection for SS3 format escape sequences used by some terminals (`\eOa`, `\eOb`, `\eOc`, `\eOd`)
- Improved compatibility with different terminal emulators

### Fixed
- SS3 escape sequence handling now properly recognizes Ctrl+Arrow combinations

## [5.0.0] - Previous version
- Major improvements - memory leak fixes, terminal state protection, Unicode support, and enhanced error handling while maintaining full backward compatibility and 4.8.3 performance.