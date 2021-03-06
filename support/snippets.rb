class Snippets
  def initialize(snips)
    @snips = snips
  end

  def to_s(format)
    out = []

    snippets(format).each do |name, snippet, options|
      out << block(
        name: name,
        desc: to_desc(snippet),
        snip: reformat(snippet, format, options || {}))
    end

    out.join("\n\n") + "\n"
  end

  def common_px_dimensions
    (0..15).to_a +
      (20..90).step(10).to_a +
      (200..900).step(100).to_a
  end

  def snippets(format)
    Enumerator.new do |y|
      @snips.each do |name, section|
        if section['formats'].include?(format.to_s)
          section['snippets'].each do |key, val|
            if key.include?('#')
              common_px_dimensions.each do |i|
                key_ = key.gsub('#', "#{i}")
                val_ = val.gsub('{#}', i == 0 ? '0' : "#{i}px")
                y << [key_, val_, section['options']]
              end
              (1..10).each do |i|
                key_ = key.gsub('#', "#{i}e")
                val_ = val.gsub('{#}', "#{i}em")
                y << [key_, val_, section['options']]
              end
            else
              y << [key, val, section['options']]
            end
          end
        end
      end
    end
  end

  def to_markdown
    out = []
    out << "| Snippet | Description |"
    out << "| ---- | ---- |"

    snips = @snips.flat_map do |name, section|
      section['snippets'].to_a
    end

    snips = snips.sort_by { |_, snip| snip }
    out += snips.map do |(sname, snip)|
      %[| **#{sname}** | `#{snip}` |]
    end

    out.join("\n") + "\n"
  end

private

  # Use braces?
  def braced?(format)
    ! indented?(format)
  end

  def indented?(format)
    format == :sass || format == :stylus
  end

  def slash_comments?(format)
    format == :sass || format == :scss || format == :stylus
  end

  # "border: {solid 1px #333};" => "border: ___"
  def to_desc(snippet)
    snippet
      .gsub(/;$/, '')
      .gsub(/\{(.*?)\}/, '___')
  end

  # "{url()}" => "${1:url()}"
  def unplaceholder(snippet)
    i = 0
    snippet.gsub(/\{(.*?)\}/) { |placeholder,x|
      if placeholder =~ /^\{!/
        i = 1
        "${1:#{placeholder[2...-1]}}"
      else
        "${#{i += 1}:#{placeholder[1...-1]}}"
      end
    }
  end

  # Turns a raw snippet into a snippet of a given format
  # "border-top: 0" => "border-top: 0;"
  def reformat(value, format, options={})
    snippet = value.dup

    # Line breaks and semicolons.
    if braced?(format)
      snippet.gsub!(/; /, ";\n")
    else
      snippet.gsub!(/; /, "\n")
      snippet.gsub!(/;$/, '')
    end

    # Fix placeholders ("{url()}" => "${1:url()}"
    snippet = unplaceholder(snippet)

    # Fix comments
    if slash_comments?(format)
      snippet.gsub!(/\/\* (.*?) \*\/$/, "// \\1")
    end

    # Media queries: add a starting bracket if needed
    if snippet.include?("@media")
      snippet.gsub!(') ', ') { ') if braced?(format)
    end

    snippet
  end

  # Formats a block
  #
  #     block(name: "bt0", desc: "border-top", snip: "border-top: 0")
  #     # snippet bt0 "border-top"
  #     # border-top: 0
  #     # endsnippet
  #
  def block(options)
    [
      %[snippet #{options[:name]} "#{options[:desc]}"],
      options[:snip],
      "endsnippet"
    ].join("\n")
  end
end
