# RCurses 5.1.1 Release Notes

## Bug Fixes

### Fixed ANSI color preservation in panes
- Panes now correctly detect and preserve existing ANSI color codes in text
- Added `@skip_colors` flag for panes with nil foreground/background colors
- Text containing ANSI codes is no longer double-colored by pane colors
- This allows panes to act as pass-through containers for pre-colored text

### Improved SGR state tracking in line wrapping
- Completely rewrote `split_line_with_ansi` function for proper SGR tracking
- Now correctly tracks bold, italic, underline, blink, reverse, and color states
- Properly reconstructs SGR sequences when lines wrap
- Supports 256-color and RGB color codes
- Fixes issues with ANSI codes being corrupted on wrapped lines

### Null-safe console handling
- Added safe fallback when `IO.console` is nil (non-TTY environments)
- Prevents crashes in automated tests or non-interactive contexts

## Compatibility
- All changes are fully backward compatible
- No API changes
- Existing applications will continue to work without modification

## Testing
The changes have been tested with:
- HyperList Ruby TUI application
- RTFM file manager  
- IMDB terminal application

These fixes resolve color corruption issues that occurred when displaying pre-colored text in panes, particularly in split-view modes or narrow terminal windows.