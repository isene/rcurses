require "minitest/autorun"
require_relative "../lib/string_extensions"
require_relative "../lib/rcurses/general"

class TestDisplayWidth < Minitest::Test
  def test_ascii_text_width
    assert_equal 5, Rcurses.display_width("hello")
  end

  def test_empty_string_width
    assert_equal 0, Rcurses.display_width("")
  end

  def test_nil_width
    assert_equal 0, Rcurses.display_width(nil)
  end

  def test_cjk_characters_width_2
    # Each CJK character occupies 2 columns
    assert_equal 2, Rcurses.display_width("\u4e16")  # Chinese character
    assert_equal 4, Rcurses.display_width("\u4e16\u754c")  # Two CJK chars
  end

  def test_mixed_ascii_and_cjk
    # "a" = 1, CJK char = 2, "b" = 1 => total 4
    assert_equal 4, Rcurses.display_width("a\u4e16b")
  end

  def test_ansi_colored_text_codes_dont_count
    plain = "hello"
    colored = "\e[38;5;196m#{plain}\e[39m"
    # ANSI codes should not add to display width.
    # display_width operates on raw chars, so strip first.
    assert_equal 5, Rcurses.display_width(colored.pure)
  end

  def test_fullwidth_latin
    # Fullwidth 'A' (U+FF21) should be width 2
    assert_equal 2, Rcurses.display_width("\uFF21")
  end

  def test_control_characters_zero_width
    assert_equal 0, Rcurses.display_width("\x00")
    assert_equal 0, Rcurses.display_width("\x01")
  end

  def test_spaces_count
    assert_equal 3, Rcurses.display_width("   ")
  end
end
