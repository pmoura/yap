
find_package(MySQL)

 if (MySQL_FOUND)
     add_feature_info(  YAPmysql "MySQL_FOUND	" " MySQL at PkgConfig::MySQL,  ${MySQL_INCLUDE_DIRS}" )

  set(MySQL_SOURCES
          myddas_mysql.c
          myddas_util.c
          myddas_util.c
          myddas_wkb2prolog.c
          )

  set(SO_MAJOR 1)
  set(SO_MINOR 0)
  set(SO_PATCH 0)

      #  MySQL_INCLUDE_DIRS - where to find mysql.h, etc.
      #  MySQL_LIBRARIES   - List of libraries when using MySQL.
      #  MySQL_FOUND       - True if MySQL found.

              include_directories(${MySQL_INCLUDE_DIRS}  ${CMAKE_CURRENT_SOURCE_DIR}/..)
    set_property(GLOBAL APPEND PROPERTY COMPILE_DEFINITIONS
      -DMYDDAS_MYSQL=1)
    set (MYDDAS_FLAGS ${MYDDAS_FLAGS} ON PARENT_SCOPE)
    list (APPEND MYDDAS_FLAGS -DMYDDAS_MYSQL=1)


	    if (WIN32)
	      	    add_library(YAPmysql OBJECT ${MySQL_SOURCES})
	      else()
	    add_library(YAPmysql  ${MySQL_SOURCES})
	    endif()
      set_target_properties(YAPmysql PROPERTIES
              POSITION_INDEPENDENT_CODE ON
               PREFIX "" 
              )
 	    target_link_libraries(YAPmysql PUBLIC ${MySQL_LIBRARIES}
	    libYap)
    install(TARGETS YAPmysql
              RUNTIME DESTINATION ${YAP_INSTALL_LIBDIR}
             ARCHIVE DESTINATION ${YAP_INSTALL_LIBDIR}
             LIBRARY DESTINATION ${YAP_INSTALL_LIBDIR}
              )

   
 
  else ()
   
  endif (MySQL_FOUND)

