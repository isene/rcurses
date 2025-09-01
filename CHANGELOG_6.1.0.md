# rcurses 6.1.0 - Safe ANSI Code Handling

## New Methods Added to String Class

### Problem Solved
When applying regex replacements to strings that already contain ANSI color codes, the codes can become corrupted, leading to display issues. This was a common problem when trying to colorize text that might already be partially colored.

### New Methods

#### `safe_gsub(pattern, replacement)` and `safe_gsub!(pattern, replacement)`
Safely apply regex replacements without corrupting existing ANSI sequences.

```ruby
# Example: Color brackets without breaking existing colors
colored_text = "\e[38;5;165m1. \e[39m[? Something]"
result = colored_text.safe_gsub(/\[([^\]]*)\]/) do |match|
  content = match[1..-2]
  "[#{content}]".fg("46")
end
# Result: "\e[38;5;165m1. \e[39m\e[38;5;46m[? Something]\e[39m"
```

#### `has_ansi?`
Check if a string contains ANSI escape sequences.

```ruby
"plain text".has_ansi?        # => false
"colored".fg("196").has_ansi? # => true
```

#### `visible_length`
Get the visible length of a string (excluding ANSI codes).

```ruby
colored = "Hello".fg("196")
colored.length         # => 16 (includes ANSI codes)
colored.visible_length # => 5  (just the visible text)
```

#### `safe_fg(color)` and `safe_bg(color)`
Apply foreground/background color only if the string doesn't already have ANSI codes.

```ruby
"plain".safe_fg("46")           # => colored green
"already".fg("196").safe_fg("46") # => remains red (no change)
```

## Use Cases

These methods are particularly useful when:
- Building syntax highlighters that need to apply multiple layers of coloring
- Processing text that might already be partially colored
- Preventing double-coloring of text
- Working with complex regex replacements on colored terminal output

## Migration Guide

If you have code that does regex replacements on potentially colored text:

**Before:**
```ruby
text.gsub!(/pattern/) { |match| match.fg("color") }
# Could corrupt ANSI codes if text is already colored
```

**After:**
```ruby
text.safe_gsub!(/pattern/) { |match| match.fg("color") }
# Safely handles existing ANSI codes
```