


get_target_property(YAP_SOURCES libYap SOURCES)


set(DOX_MD_FILES
 ${CMAKE_SOURCE_DIR}/docs/md/CALLING_YAP.md


)
file( COPY ${CMAKE_SOURCE_DIR}/docs/filter.yap DESTINATION .)

file( MAKE_DIRECTORY sphinx )
file( MAKE_DIRECTORY sphinx/source)
file( MAKE_DIRECTORY sphinx/source/images)
file( COPY ${CMAKE_SOURCE_DIR}/docs/sphinx/Makefile DESTINATION sphinx)
file( COPY ${DOX_MD_FILES} DESTINATION sphinx/source)

file( COPY ${CMAKE_SOURCE_DIR}/docs/sphinx/source/conf.py DESTINATION sphinx/source)
file( COPY ${CMAKE_SOURCE_DIR}/docs/sphinx/source/index.rst DESTINATION sphinx/source)
file( COPY ${CMAKE_SOURCE_DIR}/docs/images/yap_256x256x32.png DESTINATION  sphinx/source/images)
file( COPY_FILE ${CMAKE_SOURCE_DIR}/docs/images/favicon_32x32.ico sphinx/source/images/favicon.ico)

file( MAKE_DIRECTORY mkdocs )
file( MAKE_DIRECTORY mkdocs/docs)
file( COPY  ${CMAKE_SOURCE_DIR}/docs/mkdocs/mkdocs.yml DESTINATION  mkdocs)
file( MAKE_DIRECTORY mkdocs/docs/images)
file( COPY ${CMAKE_SOURCE_DIR}/docs/images/yap_256x256x32.png DESTINATION  mkdocs/docs/images)
file( COPY_FILE ${CMAKE_SOURCE_DIR}/docs/images/favicon_32x32.ico mkdocs/docs/images/favicon.ico)
file( MAKE_DIRECTORY mkdocs/docs/javascripts)
file( COPY ${CMAKE_SOURCE_DIR}/docs/assets/js/highlight.min.js DESTINATION  mkdocs/docs/javascripts)

configure_file(docs/md/yap.md.in ${CMAKE_BINARY_DIR}/mkdocs/docs/index.md)
configure_file(docs/md/INSTALL.md.in ${CMAKE_BINARY_DIR}/mkdocs/docs/INSTALL.md)
file( COPY ${DOX_MD_FILES} DESTINATION mkdocs/docs)


  find_host_package(Doxygen
    OPTIONAL_COMPONENTS dot dia)

if (DOXYGEN_FOUND)
  set(DOXYGEN_CMAKE_NUMBER  ${YAP_MAJOR_VERSION}.${YAP_MINOR_VERSION}.${YAP_PATCH_VERSION})
  set(DOXYGEN_BRIEF  "The YAP Prolog Compiler Manual")
  set( DOXYGEN_CMAKE_LOGO ${CMAKE_SOURCE_DIR}/docs/icons/yap_96x96x32.png)
  set( DOXYGEN_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})
  set( DOXYGEN_ALLOW_UNICODE_NAMES YES)
  set( DOXYGEN_OUTPUT_LANGUAGE English)
  set( DOXYGEN_ALWAYS_DETAILED_SEC NO)
  set( DOXYGEN_JAVADOC_AUTOBRIEF      YES)

#  set (Doxygen::doxygen doxygen-yap)
set( DOXYGEN_EXCLUDE
    CMakeLists.txt
    CMakeCache.txt
     ${CMAKE_SOURCE_DIR}/pl/boot2.yap
    ${CMAKE_SOURCE_DIR}/library/apply.yap
    ${CMAKE_SOURCE_DIR}/library/dialect/bprolog
    ${CMAKE_SOURCE_DIR}/library/clp
    ${CMAKE_SOURCE_DIR}/swi/library/clp
    ${CMAKE_SOURCE_DIR}/swi/console
    ${CMAKE_SOURCE_DIR}/include/cudd
    ${CMAKE_SOURCE_DIR}/docs/src
     ${CMAKE_SOURCE_DIR}/C/absmi.c
     ${CMAKE_SOURCE_DIR}/packages/jpl
     ${CMAKE_SOURCE_DIR}/packages/prism
     ${CMAKE_SOURCE_DIR}/packages/cuda
     ${CMAKE_SOURCE_DIR}/packages/meld
     ${CMAKE_SOURCE_DIR}/packages/cplint
     ${CMAKE_SOURCE_DIR}/include/SWI-Prolog.h
     ${CMAKE_SOURCE_DIR}/C/absmi_insts.i)

  set( DOXYGEN_EXCLUDE_PATTERNS
      */.git/*
    */.svn/*
    */.hg/*
    */CMakeFiles/*
     ${CMAKE_SOURCE_DIR}/H/Tags_24*
-     ${CMAKE_SOURCE_DIR}/C/Tags_32*
    */_CPack_Packages/*
    packages/sat/*-*/*
    )

  set( DOXYGEN_REPEAT_BRIEF NO)
  set( DOXYGEN_ENABLE_PREPROCESSING  YES)
  set( DOXYGEN_MACRO_EXPANSION YES)
  list (APPEND PREDEFINED "YAP_FLAG(A,B,C,D,E,F)=B"  )
  set(DOXYGEN_EXPAND_ONLY_PREDEF YES)
  set(DOXYGEN_PREDEFINED ${PREDEFINED} )
 set(DOXYGEN_HIDE_SCOPE_NAMES NO)
  set(DOXYGEN_HIDE_COMPOUND_REFERENCE NO)
set (DOXYGEN_REFERENCES_LINK_SOURCE NO)
set (DOXYGEN_HTML_EXTRA_STYLESHEET ${CMAKE_SOURCE_DIR}/docs/assets/css/solarized-light.css)
  set(DOXYGEN_HIDE_UNDOC_MEMBERS     YES)
  set(DOXYGEN_GENERATE_HTML NO)
  set(DOXYGEN_GENERATE_XML YES)
  set(DOXYGEN_XML_PROGRAMLISTING NO)
  set(DOXYGEN_GENERATE_MAN NO)
  set(DOXYGEN_SHOW_FILES NO)
   set(DOXYGEN_FILTER_SOURCE_FILES NO)
 set(DOXYGEN_OPTIMIZE_OUTPUT_FOR_C NO)
  set(DOXYGEN_OPTIMIZE_OUTPUT_FOR_PROLOG YES)
  set(DOXYGEN_SHOW_NAMESPACES YES)
  set(DOXYGEN_CREATE_SUBDIRS NO)
  set(DOXYGEN_INLINE_GROUPED_CLASSES YES)
  set(DOXYGEN_MARKDOWN_SUPPORT YES)
  set(DOXYGEN_TOC_INCLUDE_HEADINGS 5  )
  set(DOXYGEN_AUTOLINK_SUPPORT YES  )
  set(DOXYGEN_CASE_SENSE_NAMES YES)
    set(DOXYGEN_HAVE_DOT NO)
    set(DOXYGEN_GENERATE_TREEVIEW YES)
set(DOXYGEN_LAYOUT_FILE ${CMAKE_SOURCE_DIR}/docs/assets/DoxygenLayout.xml)
set(DOXYGEN_FILE_PATTERNS *.pl *.yap *.ypp *.c *.cc *.cxx *.cpp *.c++ *.java *.ii *.ixx *.ipp *.i++ *.inl *.idl *.ddl *.odl *.h *.hh *.hxx *.hpp *.h++ *.cs *.d *.php *.php4 *.php5 *.phtml *.inc *.m *.markdown *.md *.mm *.dox *.py *.pyw *.f90 *.f95 *.f03 *.f08 *.f *.for *.tcl *.vhd *.vhdl *.ucf *.qsf *.ice)
set(DOXYGEN_INPUT_FILTER ${CMAKE_BINARY_DIR}/filter)
set(DOXYGEN_EXTENSION_MAPPING yap=C++ pl=C++ ypp=C++)
#set(DOXYGEN_ALIASES "pred{2(}=@class P\\10  P\\1\\2" Bold{1}="<b>\\1</b>" )
set(DOXYGEN_INCLUDE_PATH ${INCLUDE_DIRECTORIES}  ${CMAKE_SOURCE_DIR}/H/generated  ${CMAKE_SOURCE_DIR}/H  ${CMAKE_SOURCE_DIR}/include   ${CMAKE_SOURCE_DIR}/os   ${CMAKE_SOURCE_DIR}/OPTYap   ${CMAKE_SOURCE_DIR}/CXX ${CMAKE_BINARY_DIR})
set(DOXYGEN_EXAMPLE_PATH  ${CMAKE_SOURCE_DIR}/docs/md)
set(DOXYGEN_SOURCE_BROWSER NO)
  #set(DOXYGEN_VERBATIM_HEADERS NO)


add_executable(filter-bin docs/filter.c)

  set_target_properties(filter-bin PROPERTIES OUTPUT_NAME filter )
  set_property( TARGET filter-bin APPEND PROPERTY COMPILE_DEFINITIONS YAPBIN="${CMAKE_BINARY_DIR}/yap")
  set_property( TARGET filter-bin APPEND PROPERTY COMPILE_DEFINITIONS PLFILTER="${CMAKE_CURRENT_SOURCE_DIR}/docs/filter.yap")



doxygen_add_docs(
  dox
  ${CMAKE_SOURCE_DIR}/docs/extra
  ${CMAKE_SOURCE_DIR}/C
      ${CMAKE_SOURCE_DIR}/H
      ${CMAKE_SOURCE_DIR}/include
      ${CMAKE_SOURCE_DIR}/CXX
     ${CMAKE_SOURCE_DIR}/pl
${CMAKE_SOURCE_DIR}/library
    ${CMAKE_SOURCE_DIR}/os
       ${CMAKE_SOURCE_DIR}/packages
       ${CMAKE_SOURCE_DIR}/OPTYap
COMMENT "Generating Xmls"
)



add_custom_target( docs2md
  COMMAND yap-bin -l ${CMAKE_SOURCE_DIR}/docs/dox2md -z main -- xml mkdocs/docs
DEPENDS filter-bin dox ${CMAKE_SOURCE_DIR}/docs/mkdocs/mkdocs.yml ${CMAKE_SOURCE_DIR}/docs/dox2md.yap ${MD_TARGETS}
   )

    add_custom_target(mkdocs
    COMMAND mkdocs build
      WORKING_DIRECTORY mkdocs
      DEPENDS docs2md
      ) 

    add_custom_target(sphinx
      COMMAND breathe-apidoc -f -o source/dox -p YAP -g class,group ../xml
      COMMAND make html
      WORKING_DIRECTORY sphinx
      DEPENDS dox
     )

endif()
