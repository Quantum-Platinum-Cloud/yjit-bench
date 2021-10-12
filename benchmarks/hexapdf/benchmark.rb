require 'harness'

# Before we activate Bundler, make sure gems are installed.
Dir.chdir(__dir__) do
  chruby_stanza = ""
  if ENV['RUBY_ROOT']
    ruby_name = ENV['RUBY_ROOT'].split("/")[-1]
    chruby_stanza = "chruby && chruby #{ruby_name} && "
  end

  # Source Shopify-located chruby if it exists to make sure this works in Shopify Mac dev tools.
  # Use bash -l to propagate non-Shopify-style chruby config.
  cmd = "/bin/bash -l -c '[ -f /opt/dev/dev.sh ] && . /opt/dev/dev.sh; #{chruby_stanza}bundle install'"
  puts "Command: #{cmd}"
  success = system(cmd)
  unless success
    raise "Couldn't set up benchmark!"
  end
end

# Based on https://github.com/gettalong/hexapdf/blob/master/benchmark/line_wrapping/hexapdf_composer.rb

# Take a copy of The Odyssey (trans: Samuel Butler) and paginate it to a given line width, in this case 50.
# The original timed several variations (low-level vs Composer interface; TTF vs non-TTF). We don't collect
# a lot of individual variant data.

require "hexapdf"
require "fileutils"

IN_FILENAME = "odyssey.txt"
WIDTH = 50
HEIGHT = 1000

EXPECTED_MIN_SIZE = 569800
EXPECTED_MAX_SIZE = 569900

Dir.chdir __dir__

Dir["/tmp/hexapdf-result*.pdf"].each { |file| FileUtils.rm file }

index = 0
run_benchmark(10) do
  ## TTF benchmark (v. slow)
  #HexaPDF::Composer.create(OUT_FILENAME, page_size: [0, 0, WIDTH, HEIGHT], margin: 0) do |pdf|
  #  pdf.text(File.read(IN_FILENAME), font_features: {kern: false},
  #           font: "./DejaVuSans.ttf", font_size: 10, last_line_gap: true,
  #           line_spacing: {type: :fixed, value: 11.16})
  #end

  # Non-TTF benchmark
  index += 1
  out_filename = "/tmp/hexapdf-result-#{ "%03d" % index }.pdf"
  HexaPDF::Composer.create(out_filename, page_size: [0, 0, WIDTH, HEIGHT], margin: 0) do |pdf|
    pdf.text(File.read(IN_FILENAME), font_features: {kern: false},
             font: "Times", font_size: 10, last_line_gap: true,
             line_spacing: {type: :fixed, value: 11.16})
  end
end

Dir["/tmp/hexapdf-result*.pdf"].each do |file|
  sz = File.stat(file).size
  raise "Incorrect size #{sz} for file #{file}!" unless sz <= EXPECTED_MAX_SIZE && sz >= EXPECTED_MIN_SIZE
  FileUtils.rm file
end