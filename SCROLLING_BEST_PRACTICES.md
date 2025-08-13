# Rcurses Scrolling Best Practices

## Overview

When building applications with rcurses that display scrollable content, it's important to understand how to properly manage scrolling, especially when dealing with long lines that wrap.

## Key Principles

### 1. Give Rcurses the Full Content

Instead of manually managing which portion of content to display:

```ruby
# ❌ DON'T: Manually slice content for display
lines = []
(start_idx...end_idx).each do |idx|
  lines << items[idx]
end
pane.text = lines.join("\n")
```

Give rcurses ALL the content and let it handle the viewport:

```ruby
# ✅ DO: Give full content to rcurses
lines = []
items.each do |item|
  lines << format_item(item)
end
pane.text = lines.join("\n")
```

### 2. Use `pane.ix` for Scroll Position

Rcurses provides the `ix` attribute to control which line appears at the top of the pane:

```ruby
# Set scroll position
pane.ix = desired_top_line

# Rcurses automatically handles:
# - Displaying the correct portion
# - Line wrapping
# - Scroll indicators (▲ and ▼)
```

### 3. Implement Scrolloff Logic

For better UX, maintain a buffer of visible lines above/below the cursor:

```ruby
scrolloff = 3  # Number of buffer lines
total = items.length
page = pane.h  # Visible height

if current - pane.ix < scrolloff
  # Too close to top - scroll up
  pane.ix = [current - scrolloff, 0].max
elsif (pane.ix + page - 1 - current) < scrolloff
  # Too close to bottom - scroll down
  max_off = total - page
  pane.ix = [current + scrolloff - page + 1, max_off].min
end
```

### 4. Handle Line Wrapping

When lines are longer than the pane width, rcurses automatically wraps them during display. This creates a mismatch between logical lines (your content) and display lines (what appears on screen).

To handle this properly:

```ruby
# Calculate extra lines created by wrapping
extra_wrapped_lines = 0
lines.each do |line|
  clean_line = line.gsub(/\e\[[0-9;]*m/, '')  # Remove ANSI codes
  if clean_line.length > pane.w
    extra_lines = (clean_line.length.to_f / pane.w).ceil - 1
    extra_wrapped_lines += extra_lines
  end
end

# Adjust scroll limits to account for wrapped lines
max_offset = [total - page + extra_wrapped_lines, 0].max
```

### 5. Visual End-of-Document Indicator

To clearly show users they've reached the end of the document:

```ruby
# Add a blank line at the bottom
lines << ""

# Treat it as part of the content for scroll calculations
total = items.length + 1  # +1 for the blank line
```

## Complete Example

Here's a complete example showing proper scrolling implementation:

```ruby
def render_pane(items, current_index, pane)
  # Build all lines
  lines = []
  items.each_with_index do |item, idx|
    line = format_item(item)
    
    # Apply highlighting for current item
    if idx == current_index
      line = apply_highlight(line)
    end
    
    lines << line
  end
  
  # Add end-of-document indicator
  lines << ""
  
  # Set full content
  pane.text = lines.join("\n")
  
  # Calculate wrapped lines
  extra_wrapped = calculate_wrapped_lines(lines, pane.w)
  
  # Apply scrolloff logic
  scrolloff = 3
  total = items.length + 1
  page = pane.h
  
  if total <= page
    pane.ix = 0
  elsif current_index - pane.ix < scrolloff
    pane.ix = [current_index - scrolloff, 0].max
  elsif (pane.ix + page - 1 - current_index) < scrolloff
    max_off = [total - page + extra_wrapped, 0].max
    pane.ix = [current_index + scrolloff - page + 1, max_off].min
  end
  
  pane.refresh
end
```

## Common Pitfalls to Avoid

1. **Don't manually manage visible portions** - Let rcurses handle the viewport
2. **Don't ignore line wrapping** - Account for wrapped lines in scroll calculations
3. **Don't forget about `pane.ix`** - This is the primary way to control scrolling
4. **Don't call `refresh` multiple times** - Once per render cycle is enough

## Benefits of This Approach

- **Simpler code**: No manual offset management
- **Automatic scroll indicators**: Rcurses shows ▲/▼ when content extends beyond view
- **Proper line wrapping**: Rcurses handles wrapped lines correctly
- **Better performance**: Rcurses optimizes the actual terminal output

## References

- See HyperList (https://github.com/isene/HyperList) for a real-world implementation
- RTFM and IMDB applications also use these patterns effectively