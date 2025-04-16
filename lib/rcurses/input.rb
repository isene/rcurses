module Rcurses
  module Input
    def getchr(t = nil)
      begin
        # If a timeout is provided, wrap the blocking getch call in Timeout.timeout.
        c = t ? Timeout.timeout(t) { $stdin.getch } : $stdin.getch
      rescue Timeout::Error
        return nil
      end

      # Process the character (including escape sequences)
      case c
      when "\e"    # ANSI escape sequences
        # Check quickly for any following bytes
        unless IO.select([$stdin], nil, nil, 0.001)
          return "ESC"
        end
        second_char = $stdin.getc
        case second_char
        when '['   # CSI
          third_char = $stdin.getc
          case third_char
          when 'A' then chr = "UP"
          when 'a' then chr = "S-UP"
          when 'B' then chr = "DOWN"
          when 'b' then chr = "S-DOWN"
          when 'C' then chr = "RIGHT"
          when 'c' then chr = "S-RIGHT"
          when 'D' then chr = "LEFT"
          when 'd' then chr = "S-LEFT"
          when 'Z' then chr = "S-TAB"
          when '1'
            fourth_char = $stdin.getc
            case fourth_char
            when '1'
              fifth_char = $stdin.getc
              chr = fifth_char == '~' ? "F1" : ""
            when '2'
              fifth_char = $stdin.getc
              chr = fifth_char == '~' ? "F2" : ""
            when '3'
              fifth_char = $stdin.getc
              chr = fifth_char == '~' ? "F3" : ""
            when '4'
              fifth_char = $stdin.getc
              chr = fifth_char == '~' ? "F4" : ""
            when '5'
              fifth_char = $stdin.getc
              chr = fifth_char == '~' ? "F5" : ""
            when '7'
              fifth_char = $stdin.getc
              chr = fifth_char == '~' ? "F6" : ""
            when '8'
              fifth_char = $stdin.getc
              chr = fifth_char == '~' ? "F7" : ""
            when '9'
              fifth_char = $stdin.getc
              chr = fifth_char == '~' ? "F8" : ""
            end
          when '2'
            fourth_char = $stdin.getc
            case fourth_char
            when '~' then chr = "INS"
            when '0'
              fifth_char = $stdin.getc
              chr = fifth_char == '~' ? "F9" : ""
            when '1'
              fifth_char = $stdin.getc
              chr = fifth_char == '~' ? "F10" : ""
            when '3'
              fifth_char = $stdin.getc
              chr = fifth_char == '~' ? "F11" : ""
            when '4'
              fifth_char = $stdin.getc
              chr = fifth_char == '~' ? "F12" : ""
            else chr = ""
            end
          when '3'
            fourth_char = $stdin.getc
            chr = fourth_char == '~' ? "DEL" : ""
          when '5'
            fourth_char = $stdin.getc
            case fourth_char
            when '~' then chr = "PgUP"
            when '^' then chr = "C-PgUP"
            else chr = ""
            end
          when '6'
            fourth_char = $stdin.getc
            case fourth_char
            when '~' then chr = "PgDOWN"
            when '^' then chr = "C-PgDOWN"
            else chr = ""
            end
          when '1', '7'
            fourth_char = $stdin.getc
            case fourth_char
            when '~' then chr = "HOME"
            when '^' then chr = "C-HOME"
            else chr = ""
            end
          when '4', '8'
            fourth_char = $stdin.getc
            case fourth_char
            when '~' then chr = "END"
            when '^' then chr = "C-END"
            else chr = ""
            end
          else
            chr = ""
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
      # Treat both "\r" and "\n" as Enter
      when "\r", "\n" then chr = "ENTER"
      when "\t" then chr = "TAB"
      when "\u007F", "\b" then chr = "BACK"
      when "\u0000" then chr = "C-SPACE"
      when "\u0001" then chr = "C-A"
      when "\u0002" then chr = "C-B"
      when "\u0003" then chr = "C-C"
      when "\u0004" then chr = "C-D"
      when "\u0005" then chr = "C-E"
      when "\u0006" then chr = "C-F"
      when "\u0007" then chr = "C-G"
      when "\u0008" then chr = "C-H"
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
      when "\u0017" then chr = "WBACK" # C-W
      when /[[:print:]]/ then chr = c
      else chr = ""
      end

      chr
    end
  end
end
