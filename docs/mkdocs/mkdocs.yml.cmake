site_name: YAP Prolog Reference Manual
site_url: https://www.dcc.fc.up.pt/YAP
use_directory_urls: false
theme:
  name: 'readthedocs'
  highlightjs: true
  hljs_languages:
    - prolog
    - c
    - python
    - c++
    - java
    - javascript
    - R
  logo: 'img/favicon.ico'

plugins:
  - search
  - autorefs:
      resolve_closest: true
  - mkdoxy:
      # debug: true
      ignore-errors: true
      projects:
        YAP:
          src-dirs:       ${CMAKE_SOURCE_DIR}/
          full-doc: True
          doxy-cfg-file: ${CMAKE_BINARY_DIR}/Doxyfile.dox

markdown_extensions:
  - attr_list
  - def_list
  - toc:
      permalink: True
  - admonition
  - markdown.extensions.md_in_html

nav:
   - Home: index.md
   