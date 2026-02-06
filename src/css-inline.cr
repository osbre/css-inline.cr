@[Link(ldflags: "-L#{__DIR__}/../css-inline/bindings/c/target/release -lcss_inline -Wl,-rpath,#{__DIR__}/../css-inline/bindings/c/target/release")]
lib LibCssInline
  enum CssResult
    Ok
    MissingStylesheet
    RemoteStylesheetNotAvailable
    IoError
    InternalSelectorParseError
    NullOptions
    InvalidUrl
    InvalidExtraCss
    InvalidInputString
    InvalidCacheSize
  end

  struct StylesheetCache
    size : LibC::SizeT
  end

  struct CssInlinerOptions
    inline_style_tags : Bool
    keep_style_tags : Bool
    keep_link_tags : Bool
    keep_at_rules : Bool
    load_remote_stylesheets : Bool
    cache : StylesheetCache*
    base_url : LibC::Char*
    extra_css : LibC::Char*
    preallocate_node_capacity : LibC::SizeT
    minify_css : Bool
    remove_inlined_selectors : Bool
    apply_width_attributes : Bool
    apply_height_attributes : Bool
  end

  fun css_inline_to(options : CssInlinerOptions*, input : LibC::Char*, output : LibC::Char*, output_size : LibC::SizeT) : CssResult
  fun css_inline_fragment_to(options : CssInlinerOptions*, input : LibC::Char*, css : LibC::Char*, output : LibC::Char*, output_size : LibC::SizeT) : CssResult
  fun css_inliner_default_options : CssInlinerOptions
  fun css_inliner_stylesheet_cache(size : LibC::SizeT) : StylesheetCache
end

module CssInline
  VERSION = "0.1.0"

  MAX_OUTPUT_SIZE = 1024 * 1024 * 10 # 10 MB

  class Error < Exception; end

  class StylesheetCache
    getter cache : LibCssInline::StylesheetCache

    def initialize(size : Int32)
      if size <= 0
        raise Error.new("Cache size must be an integer greater than zero")
      end
      @cache = LibCssInline.css_inliner_stylesheet_cache(size.to_u64)
    end
  end

  class CSSInliner
    @options : LibCssInline::CssInlinerOptions
    # Hold references so GC doesn't collect the strings while C holds pointers
    @base_url_str : String?
    @extra_css_str : String?
    @cache : StylesheetCache?

    def initialize(
      inline_style_tags : Bool? = nil,
      keep_style_tags : Bool? = nil,
      keep_link_tags : Bool? = nil,
      keep_at_rules : Bool? = nil,
      load_remote_stylesheets : Bool? = nil,
      minify_css : Bool? = nil,
      remove_inlined_selectors : Bool? = nil,
      apply_width_attributes : Bool? = nil,
      apply_height_attributes : Bool? = nil,
      preallocate_node_capacity : Int32? = nil,
      base_url : String? = nil,
      extra_css : String? = nil,
      cache : StylesheetCache? = nil
    )
      @options = LibCssInline.css_inliner_default_options
      @base_url_str = nil
      @extra_css_str = nil
      @cache = nil

      @options.inline_style_tags = inline_style_tags unless inline_style_tags.nil?
      @options.keep_style_tags = keep_style_tags unless keep_style_tags.nil?
      @options.keep_link_tags = keep_link_tags unless keep_link_tags.nil?
      @options.keep_at_rules = keep_at_rules unless keep_at_rules.nil?
      @options.load_remote_stylesheets = load_remote_stylesheets unless load_remote_stylesheets.nil?
      @options.minify_css = minify_css unless minify_css.nil?
      @options.remove_inlined_selectors = remove_inlined_selectors unless remove_inlined_selectors.nil?
      @options.apply_width_attributes = apply_width_attributes unless apply_width_attributes.nil?
      @options.apply_height_attributes = apply_height_attributes unless apply_height_attributes.nil?
      @options.preallocate_node_capacity = preallocate_node_capacity.to_u64 unless preallocate_node_capacity.nil?

      if url = base_url
        @base_url_str = url
        @options.base_url = url.to_unsafe.as(LibC::Char*)
      end

      if css = extra_css
        @extra_css_str = css
        @options.extra_css = css.to_unsafe.as(LibC::Char*)
      end

      if c = cache
        @cache = c
        @options.cache = pointerof(c.@cache)
      end
    end

    def inline(html : String) : String
      with_buffer(html.bytesize) do |output, size|
        LibCssInline.css_inline_to(pointerof(@options), html.to_unsafe, output, size)
      end
    end

    def inline_fragment(html : String, css : String) : String
      with_buffer(html.bytesize) do |output, size|
        LibCssInline.css_inline_fragment_to(pointerof(@options), html.to_unsafe, css.to_unsafe, output, size)
      end
    end

    private def with_buffer(input_size : Int32, &) : String
      buffer_size = Math.max(input_size * 4, 4096)

      loop do
        output = Bytes.new(buffer_size)
        result = yield output.to_unsafe.as(LibC::Char*), buffer_size

        if result.io_error? && buffer_size < MAX_OUTPUT_SIZE
          buffer_size = Math.min(buffer_size * 2, MAX_OUTPUT_SIZE)
          next
        end

        check_result!(result)
        return String.new(output.to_unsafe)
      end
    end

    private def check_result!(result : LibCssInline::CssResult)
      case result
      when .ok?
        return
      when .missing_stylesheet?
        raise Error.new("Missing stylesheet file")
      when .remote_stylesheet_not_available?
        raise Error.new("Remote stylesheet is not available")
      when .io_error?
        raise Error.new("IO error")
      when .internal_selector_parse_error?
        raise Error.new("Invalid CSS selector")
      when .null_options?
        raise Error.new("Options pointer is null")
      when .invalid_url?
        base_url = @options.base_url
        if base_url.null?
          raise Error.new("Invalid URL")
        else
          raise Error.new("relative URL without a base: #{String.new(base_url)}")
        end
      when .invalid_extra_css?
        raise Error.new("Invalid extra CSS")
      when .invalid_input_string?
        raise Error.new("Invalid input string: not valid UTF-8")
      when .invalid_cache_size?
        raise Error.new("Invalid cache size")
      end
    end
  end

  def self.inline(html : String, **options) : String
    CSSInliner.new(**options).inline(html)
  end

  def self.inline_fragment(html : String, css : String, **options) : String
    CSSInliner.new(**options).inline_fragment(html, css)
  end
end
