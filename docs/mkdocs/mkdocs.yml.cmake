site_name: YAP Prolog Reference Manual

use_directory_urls: false
theme:
  name: 'readthedocs'
#  name: 'spacelab'
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
  - section-index
  - search:
  - autorefs:
      resolve_closest: true
  - literate-nav:
      nav_file: SUMMARY.md
  #  - awesome-nav
  - mkdoxy:
      # debug: true
      ignore-errors: true
      projects:
        YAP:
          src-dirs:       ${CMAKE_SOURCE_DIR}/CXX  
          full-doc: True
          doxy-cfg-file: ${CMAKE_BINARY_DIR}/Doxyfile.dox

markdown_extensions:
  - attr_list
  - def_list
  - toc:
      permalink: True
  - admonition
  - markdown.extensions.md_in_html

