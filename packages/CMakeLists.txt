#TODO: change macro_log_feature to check both WITH_{$name} and ${name}_FOUND
#TODO: improve FindGecode.cmake to be similar to other Find*.cmake
#CHECK: GECODE

macro_optional_find_package (Gecode ON)

if (GECODE_FOUND)
  #DEFINES:
  #   GECODE_INCLUDE_DIR
  #   GECODE_VERSION
  #   GECODE_LIBRARIES

  #set (EXTRALIBS gecode)

  string(SUBSTRING ${GECODE_VERSION} 0 1 GECODE_MAJOR )

  set (GECODE_SOURCES gecode${GECODE_MAJOR}_yap.cc
    gecode${GECODE_MAJOR}-common.icc
    ${GECODE_VERSION}/gecode_yap_cc_impl_auto_generated.icc
    ${GECODE_VERSION}/gecode_yap_cc_init_auto_generated.icc
    ${GECODE_VERSION}/gecode_yap_cc_forward_auto_generated.icc
    disjunctor.icc
    disjunctor.hh )

  add_custom_target (gecodeyap ALL DEPENDS gecode${GECODE_MAJOR}_yap_hand_written.yap ${GECODE_VERSION}/gecode_yap_auto_generated.yap gecode_yap
    ) # WORKING_DIRECTORY ${CMAKE_BINARY_DIR} )

  # create a startup.yss on the top directory.
  add_custom_command (TARGET gecodeyap
    COMMAND cat ${CMAKE_CURRENT_SOURCE_DIR}/gecode${GECODE_MAJOR}_yap_hand_written.yap ${CMAKE_CURRENT_SOURCE_DIR}/${GECODE_VERSION}/gecode_yap_auto_generated.yap > gecode.yap
    VERBATIM
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    )

  add_lib(gecode_yap ${GECODE_SOURCES})

  target_link_libraries(gecode_yap libYap ${GECODE_LIBRARIES})

  set_target_properties (gecode_yap  PROPERTIES PREFIX "")

  include_directories (${GECODE_INCLUDE_DIR} ${CMAKE_CURRENT_SOURCE_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/${GECODE_VERSION})

  install(TARGETS  gecode_yap
          LIBRARY DESTINATION ${YAP_INSTALL_DLLDIR}
       RUNTIME DESTINATION ${YAP_INSTALL_DLLDIR}
    ARCHIVE DESTINATION ${YAP_INSTALL_DLLDIR}
    )

  install(FILES ${CMAKE_CURRENT_BINARY_DIR}/gecode.yap
    DESTINATION ${libpl}
    )

  install(FILES clpfd.yap
    DESTINATION ${libpl}/gecode
    )

endif (GECODE_FOUND)

