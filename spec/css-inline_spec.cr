require "./spec_helper"

SAMPLE_STYLE = "h1, h2 { color:red; } strong { text-decoration:none } p { font-size:2px } p.footer { font-size: 1px}"
SAMPLE_BODY  = "<h1>Big Text</h1><p><strong>Yes!</strong></p><p class=\"footer\">Foot notes</p>"
SAMPLE_HTML  = "<html><head><style>#{SAMPLE_STYLE}</style></head><body>#{SAMPLE_BODY}</body></html>"

SAMPLE_INLINED = "<html><head></head><body><h1 style=\"color: red;\">Big Text</h1>" \
                 "<p style=\"font-size: 2px;\"><strong style=\"text-decoration: none;\">Yes!</strong></p>" \
                 "<p class=\"footer\" style=\"font-size: 1px;\">Foot notes</p></body></html>"

SAMPLE_FRAGMENT       = "<main><h1>Hello</h1><section><p>who am i</p></section></main>"
SAMPLE_FRAGMENT_STYLE = "p { color: red; } h1 { color: blue; }"
SAMPLE_INLINED_FRAGMENT = "<main><h1 style=\"color: blue;\">Hello</h1><section><p style=\"color: red;\">who am i</p></section></main>"

describe CssInline do
  describe ".inline" do
    it "inlines CSS from style tags" do
      result = CssInline.inline(SAMPLE_HTML)
      result.should eq(SAMPLE_INLINED)
    end

    it "keeps style tags when option is set" do
      result = CssInline.inline(SAMPLE_HTML, keep_style_tags: true)
      result.should contain("<style>")
    end

    it "removes style tags by default" do
      result = CssInline.inline(SAMPLE_HTML)
      result.should_not contain("<style>")
    end

    it "applies extra CSS" do
      html = "<html><head></head><body><h1>Test</h1></body></html>"
      result = CssInline.inline(html, extra_css: "h1 { color: green; }")
      result.should contain("color: green")
    end

    it "removes inlined selectors" do
      html = "<html><head><style>h1 { color: blue; } h2 { color: red; }</style></head><body><h1>Test</h1></body></html>"
      result = CssInline.inline(html, remove_inlined_selectors: true)
      result.should eq("<html><head><style>h2 { color: red; }</style></head><body><h1 style=\"color: blue;\">Test</h1></body></html>")
    end

    it "raises error for invalid base URL" do
      expect_raises(CssInline::Error, /relative URL without a base: foo/) do
        CssInline.inline(SAMPLE_HTML, base_url: "foo")
      end
    end

    it "raises error for missing stylesheet" do
      html = "<html><head><link href=\"tests/missing.css\" rel=\"stylesheet\" type=\"text/css\"></head><body><h1>Big Text</h1></body>"
      expect_raises(CssInline::Error, /Missing stylesheet/) do
        CssInline.inline(html)
      end
    end
  end

  describe ".inline_fragment" do
    it "inlines CSS into an HTML fragment" do
      result = CssInline.inline_fragment(SAMPLE_FRAGMENT, SAMPLE_FRAGMENT_STYLE)
      result.should eq(SAMPLE_INLINED_FRAGMENT)
    end
  end

  describe CssInline::StylesheetCache do
    it "creates a cache with valid size" do
      cache = CssInline::StylesheetCache.new(8)
      result = CssInline.inline(SAMPLE_HTML, cache: cache)
      result.should eq(SAMPLE_INLINED)
    end

    it "raises error for cache size of 0" do
      expect_raises(CssInline::Error, /Cache size must be an integer greater than zero/) do
        CssInline::StylesheetCache.new(0)
      end
    end

    it "raises error for negative cache size" do
      expect_raises(CssInline::Error, /Cache size must be an integer greater than zero/) do
        CssInline::StylesheetCache.new(-1)
      end
    end
  end

  describe CssInline::CSSInliner do
    it "inlines CSS using instance API" do
      inliner = CssInline::CSSInliner.new
      result = inliner.inline(SAMPLE_HTML)
      result.should eq(SAMPLE_INLINED)
    end

    it "inlines CSS with options via instance API" do
      inliner = CssInline::CSSInliner.new(keep_style_tags: true)
      result = inliner.inline(SAMPLE_HTML)
      result.should contain("<style>")
    end

    it "inlines fragment using instance API" do
      inliner = CssInline::CSSInliner.new
      result = inliner.inline_fragment(SAMPLE_FRAGMENT, SAMPLE_FRAGMENT_STYLE)
      result.should eq(SAMPLE_INLINED_FRAGMENT)
    end
  end
end
