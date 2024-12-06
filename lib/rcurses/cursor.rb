module Rcurses
  module Cursor
    # Terminal cursor movement ANSI codes (inspired by https://github.com/piotrmurach/tty-cursor)
    module_function
    ESC = "\e".freeze
    CSI = "\e[".freeze
    def save # Save current position
      print(Gem.win_platform? ? CSI + 's' : ESC + '7')
    end
    def restore # Restore cursor position
      print(Gem.win_platform? ? CSI + 'u' : ESC + '8')
    end
    def pos # Query cursor current position
      res = ''
      $stdin.raw do |stdin|
        $stdout << CSI + '6n' # The actual ANSI get-position
        $stdout.flush
        while (c = stdin.getc) != 'R'
          res << c if c
        end
      end
      m = res.match(/(?<row>\d+);(?<col>\d+)/)
      return m[:row].to_i, m[:col].to_i
    end
    def rowget
      row, _col = pos
      row
    end
    def colget
      _row, col = pos
      col
    end
    def up(n = 1) # Move cursor up by n
      print(CSI + "#{(n || 1)}A")
    end
    def down(n = 1) # Move the cursor down by n
      print(CSI + "#{(n || 1)}B")
    end
    def left(n = 1) # Move the cursor backward by n
      print(CSI + "#{n || 1}D")
    end
    def right(n = 1) # Move the cursor forward by n
      print(CSI + "#{n || 1}C")
    end
    def col(n = 1) # Cursor moves to nth position horizontally in the current line
      print(CSI + "#{n || 1}G")
    end
    def row(n = 1) # Cursor moves to the nth position vertically in the current column
      print(CSI + "#{n || 1}d")
    end
    def next_line # Move cursor down to beginning of next line
      print(CSI + 'E' + CSI + "1G")
    end
    def prev_line # Move cursor up to beginning of previous line
      print(CSI + 'A' + CSI + "1G")
    end
    def clear_char(n = 1) # Erase n characters from the current cursor position
      print(CSI + "#{n}X")
    end
    def clear_line # Erase the entire current line and return to beginning of the line
      print(CSI + '2K' + CSI + "1G")
    end
    def clear_line_before # Erase from the beginning of the line up to and including the current cursor position.
      print(CSI + '1K')
    end
    def clear_line_after # Erase from the current position (inclusive) to the end of the line
      print(CSI + '0K')
    end
    def clear_screen_down # Clear screen down from current row
      print(CSI + 'J')
    end
    def scroll_up # Scroll display up one line
      print(ESC + 'M')
    end
    def scroll_down # Scroll display down one line
      print(ESC + 'D')
    end
  end
end
