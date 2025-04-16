module Rcurses
  module Input
    def getchr(t = nil)
      # 1) Read a byte (with optional timeout)
      begin
        c = t ? Timeout.timeout(t) { $stdin.getch } : $stdin.getch
      rescue Timeout::Error
        return nil
      end

      # 2) If it's ESC, grab any quick trailing bytes
      seq = c
      if c == "\e"
        if IO.select([$stdin], nil, nil, 0.05)
          begin
            seq << $stdin.read_nonblock(1024)
          rescue IO::WaitReadable, EOFError
          end
        end
      end

      # 3) Single ESC alone
      return "ESC" if seq == "\e"

      # 4) ShiftâTAB
      return "S-TAB" if seq == "\e[Z"

      # 5) Legacy singleâchar shiftâarrows (your old working ones)
      case seq
      when "\e[a" then return "S-UP"
      when "\e[b" then return "S-DOWN"
      when "\e[c" then return "S-RIGHT"
      when "\e[d" then return "S-LEFT"
      end

      # 6) CSI style shiftâarrows (e.g. ESC [1;2A )
      if m = seq.match(/\A\e\[\d+;2([ABCD])\z/)
        return { 'A' => "S-UP", 'B' => "S-DOWN", 'C' => "S-RIGHT", 'D' => "S-LEFT" }[m[1]]
      end

      # 7) Plain arrows
      if m = seq.match(/\A\e\[([ABCD])\z/)
        return { 'A' => "UP", 'B' => "DOWN", 'C' => "RIGHT", 'D' => "LEFT" }[m[1]]
      end

      # 8) CSI + '~' sequences (Ins, Del, Home, End, PgUp, PgDn, F5-F12)
      if seq.start_with?("\e[") && seq.end_with?("~")
        num = seq[/\d+(?=~)/].to_i
        return case num
               when 1, 7   then "HOME"
               when 2       then "INS"
               when 3       then "DEL"
               when 4, 8    then "END"
               when 5       then "PgUP"
               when 6       then "PgDOWN"
               when 15      then "F5"
               when 17      then "F6"
               when 18      then "F7"
               when 19      then "F8"
               when 20      then "F9"
               when 21      then "F10"
               when 23      then "F11"
               when 24      then "F12"
               else ""
               end
      end

      # 9) SS3 function keys F1-F4
      if seq.start_with?("\eO") && seq.length == 3
        return case seq[2]
               when 'P' then "F1"
               when 'Q' then "F2"
               when 'R' then "F3"
               when 'S' then "F4"
               else ""
               end
      end

      # 10) Single / Ctrl-char mappings
      return case seq
             when "\r", "\n"     then "ENTER"
             when "\t"           then "TAB"
             when "\u007F", "\b" then "BACK"
             when "\u0000"       then "C-SPACE"
             when "\u0001"       then "C-A"
             when "\u0002"       then "C-B"
             when "\u0003"       then "C-C"
             when "\u0004"       then "C-D"
             when "\u0005"       then "C-E"
             when "\u0006"       then "C-F"
             when "\u0007"       then "C-G"
             when "\u0008"       then "C-H"
             when "\u000B"       then "C-K"
             when "\u000C"       then "C-L"
             when "\u000D"       then "C-M"
             when "\u000E"       then "C-N"
             when "\u000F"       then "C-O"
             when "\u0010"       then "C-P"
             when "\u0011"       then "C-Q"
             when "\u0012"       then "C-R"
             when "\u0013"       then "C-S"
             when "\u0014"       then "C-T"
             when "\u0015"       then "C-U"
             when "\u0016"       then "C-V"
             when "\u0018"       then "C-X"
             when "\u0019"       then "C-Y"
             when "\u001A"       then "C-Z"
             when "\u0017"       then "WBACK"
             when /\A[[:print:]]\z/ then seq
             else ""
             end
    end
  end
end

