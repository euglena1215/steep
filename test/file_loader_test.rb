require_relative "test_helper"

class FileLoaderTest < Minitest::Test
  include Steep
  include TestHelper
  include ShellHelper

  Pattern = Project::Pattern
  FileLoader = Services::FileLoader

  def dirs
    @dirs ||= []
  end

  def test_each_path_in_patterns
    in_tmpdir do
      loader = FileLoader.new(base_dir: current_dir)

      (current_dir + "lib").mkdir()
      (current_dir + "test").mkdir()
      (current_dir + "lib/foo.rb").write("")
      (current_dir + "lib/parser.y").write("")
      (current_dir + "test/foo_test.rb").write("")
      (current_dir + "Rakefile").write("")

      pat = Pattern.new(patterns: ["lib", "test"], extensions: [".rb"])

      assert_equal [Pathname("lib/foo.rb"), Pathname("test/foo_test.rb")], loader.each_path_in_patterns(pat).to_a
      assert_equal [Pathname("lib/foo.rb")], loader.each_path_in_patterns(pat, ["lib"]).to_a
      assert_equal [Pathname("lib/foo.rb")], loader.each_path_in_patterns(pat, ["lib/foo.rb"]).to_a
      assert_equal [Pathname("lib/foo.rb")], loader.each_path_in_patterns(pat, [(current_dir + "lib/foo.rb".to_s)]).to_a
      assert_empty loader.each_path_in_patterns(pat, ["lib/parser.y"]).to_a
      assert_empty loader.each_path_in_patterns(pat, ["Rakefile"]).to_a
    end
  end

  def test_each_path_in_patterns_with_glob
    in_tmpdir do
      loader = FileLoader.new(base_dir: current_dir)

      (current_dir + "lib/foo/bar").mkpath()
      (current_dir + "lib/foo/bar/baz.rb").write("")
      (current_dir + "lib/foo/parser.rb").write("")
      (current_dir + "lib/foo/bar/index.html.erb").write("")

      pat = Pattern.new(patterns: ["lib/*/bar"], extensions: [".rb"])

      assert_equal [Pathname("lib/foo/bar/baz.rb")], loader.each_path_in_patterns(pat, []).to_a
    end
  end

  def test_each_path_in_patterns_with_glob_and_ext
    in_tmpdir do
      loader = FileLoader.new(base_dir: current_dir)

      (current_dir + "lib/foo/bar").mkpath()
      (current_dir + "lib/foo/bar/baz.rb").write("")
      (current_dir + "lib/foo/parser.rb").write("")
      (current_dir + "lib/foo/bar/index.html.erb").write("")

      pat = Pattern.new(patterns: ["lib/*/bar/baz.rb"], extensions: [".rb"])

      assert_equal [Pathname("lib/foo/bar/baz.rb")], loader.each_path_in_patterns(pat, []).to_a
    end
  end
end
