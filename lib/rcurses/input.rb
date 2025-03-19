module Rcurses
  module Input
    def getchr(m = nil, t = nil)
      # Function to process key presses
      c = $stdin.getch(min: m, time: t)
      case c
      when "\e"    # ANSI escape sequences
        return "ESC" if !$stdin.ready?
        second_char = $stdin.getc
        case second_char
        when '['   # CSI
          third_char = $stdin.getc
          case third_char
          when 'A' then chr = "UP"
          when 'B' then chr = "DOWN"
          when 'C' then chr = "RIGHT"
          when 'D' then chr = "LEFT"
          when 'Z' then chr = "S-TAB"
          when '2'
            fourth_char = $stdin.getc
            chr = fourth_char == '~' ? "INS" : ""
          when '3'
            fourth_char = $stdin.getc
            chr = fourth_char == '~' ? "DEL" : ""
          when '5'
            fourth_char = $stdin.getc
            chr = fourth_char == '~' ? "PgUP" : ""
          when '6'
            fourth_char = $stdin.getc
            chr = fourth_char == '~' ? "PgDOWN" : ""
          when '1', '7'
            fourth_char = $stdin.getc
            chr = fourth_char == '~' ? "HOME" : ""
          when '4', '8'
            fourth_char = $stdin.getc
            chr = fourth_char == '~' ? "END" : ""
          else chr = ""
          end
        when 'O'   # Function keys
          third_char = $stdin.getc
          case third_char
          when 'a' then chr = "C-UP"
          when 'b' then chr = "C-DOWN"
          when 'c' then chr = "C-RIGHT"
          when 'd' then chr = "C-LEFT"
          else chr = ""
          end
        else
          chr = ""
        end
      when "\r" then chr = "ENTER"
      when "\t" then chr = "TAB"
      when "\u007F", "\b" then chr = "BACK"
      when "\u0001" then chr = "C-A"
      when "\u0002" then chr = "C-B"
      when "\u0003" then chr = "C-C"
      when "\u0004" then chr = "C-D"
      when "\u0005" then chr = "C-E"
      when "\u0006" then chr = "C-F"
      when "\u0007" then chr = "C-G"
      when "\u0008" then chr = "C-H"
      when "\u000A" then chr = "C-J"
      when "\u000B" then chr = "C-K"
      when "\u000C" then chr = "C-L"
      when "\u000D" then chr = "C-M"
      when "\u000E" then chr = "C-N"
      when "\u000F" then chr = "C-O"
      when "\u0010" then chr = "C-P"
      when "\u0011" then chr = "C-Q"
      when "\u0012" then chr = "C-R"
      when "\u0013" then chr = "C-S"
      when "\u0014" then chr = "C-T"
      when "\u0015" then chr = "C-U"
      when "\u0016" then chr = "C-V"
      when "\u0018" then chr = "C-X"
      when "\u0019" then chr = "C-Y"
      when "\u001A" then chr = "C-Z"
      when "\u0017" then chr = "WBACK"
      when /[[:print:]]/ then chr = c
      else chr = ""
      end
      chr
    end
  end
end
