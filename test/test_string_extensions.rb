require "minitest/autorun"
require_relative "../lib/string_extensions"

class TestStringExtensions < Minitest::Test
  def test_pure_removes_ansi_codes
    colored = "\e[38;5;196mhello\e[39m"
    assert_equal "hello", colored.pure
  end

  def test_pure_removes_multiple_ansi_codes
    styled = "\e[1m\e[38;5;42mbold green\e[39m\e[22m"
    assert_equal "bold green", styled.pure
  end

  def test_pure_leaves_plain_text_unchanged
    assert_equal "plain text", "plain text".pure
  end

  def test_fg_produces_256_color_sequence
    result = "hi".fg(196)
    assert_includes result, "\e[38;5;196m"
    assert_includes result, "hi"
    assert_includes result, "\e[39m"
  end

  def test_fg_produces_truecolor_sequence
    result = "hi".fg("FF0000")
    assert_includes result, "\e[38;2;255;0;0m"
    assert_includes result, "hi"
  end

  def test_bg_produces_256_color_sequence
    result = "hi".bg(42)
    assert_includes result, "\e[48;5;42m"
    assert_includes result, "hi"
    assert_includes result, "\e[49m"
  end

  def test_bg_produces_truecolor_sequence
    result = "hi".bg("00FF00")
    assert_includes result, "\e[48;2;0;255;0m"
    assert_includes result, "hi"
  end

  def test_bold
    result = "hi".b
    assert_includes result, "\e[1m"
    assert_includes result, "hi"
    assert_includes result, "\e[22m"
  end

  def test_italic
    result = "hi".i
    assert_includes result, "\e[3m"
    assert_includes result, "hi"
    assert_includes result, "\e[23m"
  end

  def test_underline
    result = "hi".u
    assert_includes result, "\e[4m"
  end

  def test_reverse
    result = "hi".r
    assert_includes result, "\e[7m"
  end

  def test_shorten_truncates_visible_length
    text = "hello world"
    assert_equal "hello", text.shorten(5)
  end

  def test_shorten_preserves_ansi
    text = "\e[1mhello world\e[22m"
    shortened = text.shorten(5)
    assert_includes shortened, "\e[1m"
    assert_equal "hello", shortened.pure
  end
end
