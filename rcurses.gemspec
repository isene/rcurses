Gem::Specification.new do |s|
  s.name          = 'rcurses'
  s.version       = '4.6'
  s.licenses      = ['Unlicense']
  s.summary       = "rcurses - An alternative curses library written in pure Ruby"
  s.description   = "Create curses applications for the terminal easier than ever. Create panes (with the colors and(or border), manipulate the panes and add content. Dress up text (in panes or anywhere in the terminal) in bold, italic, underline, reverse color, blink and in any 256 terminal colors for foreground and background. Use a simple editor to let users edit text in panes. Left, right or center align text in panes. Cursor movement around the terminal. New in 3.8: Fixed border fragments upon utf-8 characters. 4.6: Fixed a broken pane.edit. Fixed ANSI termination bug in RGB support."
  s.authors       = ["Geir Isene"]
  s.email         = 'g@isene.com'
  s.homepage      = 'https://isene.com/'
  s.metadata      = { "source_code_uri" => "https://github.com/isene/rcurses" }
  s.files         = Dir['{lib,examples}/**/*', 'README.md', 'LICENSE']
  s.require_paths = ['lib']
  s.add_runtime_dependency 'clipboard', '~> 2.0'
end
