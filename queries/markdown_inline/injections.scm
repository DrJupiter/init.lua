;; extends

((code_span) @injection.content
  (#cpp-docs? @injection.content)
  (#set! injection.language "cpp")
  (#offset! @injection.content 0 1 0 -1))
