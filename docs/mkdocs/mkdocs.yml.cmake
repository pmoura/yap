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
      enabled: !ENV [ENABLE_MKDOXY, True]
      # debug: true
      ignore-errors: true
      projects:
        YAP:
          debug: True
          src-dirs: ${CMAKE_BINARY_DIR}/index.md ${CMAKE_SOURCE_DIR}/docs/md   ${CMAKE_SOURCE_DIR}/C     ${CMAKE_SOURCE_DIR}/H  ${CMAKE_SOURCE_DIR}/include    ${CMAKE_SOURCE_DIR}/pl   ${CMAKE_SOURCE_DIR}/library   ${CMAKE_SOURCE_DIR}/library/dialect/swi/fli   ${CMAKE_SOURCE_DIR}/os   ${CMAKE_SOURCE_DIR}/packages   ${CMAKE_BINARY_DIR}/packages/python/yap4py   ${CMAKE_BINARY_DIR}/packages/myddas   
          doxy-cfg-file: ${CMAKE_BINARY_DIR}/Doxyfile.dox
      save-api: .mkdoxy
      full-doc: True
      debug: True

markdown_extensions:
  - attr_list
  - def_list
  - toc:
      permalink: True
  - admonition
  - markdown.extensions.md_in_html
  - pymdownx.superfences



nav:
  - Home:
    - YAP/index.md
    - INSTALL: YAP/INSTALL.md
    - "Calling YAP": YAP/CALLING_YAP.md
  - Built-ins:
    -   Core: YAP/group__Builtins.md
    -   Input-Output: YAP/group__InputOutput.md
    -   Extensions: YAP/group__YapExtensions.md
    -   Programming: YAP/group__YAPProgramming.md
  - Libraries:
      - Library: YAP/group__YAPLibrary.md
      - Available Packages: YAP/group__YAPPackages.md
      - Foreign Language Interface : YAP/group__YAPAPI.md


