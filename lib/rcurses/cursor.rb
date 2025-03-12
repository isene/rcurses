module Rcurses
  module Cursor
    # Terminal cursor movement ANSI codes (inspired by https://github.com/piotrmurach/tty-cursor)
    module_function
    ESC = "\e".freeze
    CSI = "\e[".freeze
    def save;    print(Gem.win_platform? ? CSI + 's' : ESC + '7'); end # Save current position
    def restore; print(Gem.win_platform? ? CSI + 'u' : ESC + '8'); end # Restore cursor position
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
    def set(r = 1, c = 1); print(CSI + "#{r}d"); print(CSI + "#{c}G");  end # Set cursor position to Row, Col (y,x)
    def up(n = 1);         print(CSI + "#{(n)}A");                      end # Move cursor up by n
    def down(n = 1);       print(CSI + "#{(n)}B");                      end # Move the cursor down by n
    def left(n = 1);       print(CSI + "#{n}D");                        end # Move the cursor backward by n
    def right(n = 1);      print(CSI + "#{n}C");                        end # Move the cursor forward by n
    def col(c = 1);        print(CSI + "#{c}G");                        end # Cursor moves to nth position horizontally in the current line
    def row(r = 1);        print(CSI + "#{r}d");                        end # Cursor moves to the nth position vertically in the current column
    def next_line;         print(CSI + 'E' + CSI + "1G");               end # Move cursor down to beginning of next line
    def prev_line;         print(CSI + 'A' + CSI + "1G");               end # Move cursor up to beginning of previous line
    def clear_char(n = 1); print(CSI + "#{n}X");                        end # Erase n characters from the current cursor position
    def clear_line;        print(CSI + '2K' + CSI + "1G");              end # Erase the entire current line and return to beginning of the line
    def clear_line_before; print(CSI + '1K');                           end # Erase from the beginning of the line up to and including the current cursor position.
    def clear_line_after;  print(CSI + '0K');                           end # Erase from the current position (inclusive) to the end of the line
    def clear_screen_down; print(CSI + 'J');                            end # Clear screen down from current row
    def scroll_up;         print(ESC + 'M');                            end # Scroll display up one line
    def scroll_down;       print(ESC + 'D');                            end # Scroll display down one line
    def hide;              print(CSI + '?25l');                         end # Scroll display down one line
    def show;              print(CSI + '?25h');                         end # Scroll display down one line
  end
end
