
option (HORUS "enable HORUS graphical model tookit" ON)

cmake_minimum_required(VERSION 3.1.0 FATAL_ERROR)



if (HORUS)
  set ( HORUS_SOURCES
	BayesBall.cpp
	BayesBallGraph.cpp
	BeliefProp.cpp
	ConstraintTree.cpp
	CountingBp.cpp
	ElimGraph.cpp
	Factor.cpp
	FactorGraph.cpp
	GenericFactor.cpp
	GroundSolver.cpp
	Histogram.cpp
	HorusYap.cpp
	Indexer.cpp
	LiftedBp.cpp
	LiftedKc.cpp
	LiftedOperations.cpp
	LiftedUtils.cpp
	LiftedVe.cpp
	LiftedWCNF.cpp
	Parfactor.cpp
	ParfactorList.cpp
	ProbFormula.cpp
	Util.cpp
	Var.cpp
	VarElim.cpp
	WeightedBp.cpp
	)

      set (UTESTS_SOURCES
	$(utestsdir)/BeliefPropTest.cpp
	$(utestsdir)/Common.cpp
	$(utestsdir)/CountingBpTest.cpp
	$(utestsdir)/FactorTest.cpp
	$(utestsdir)/VarElimTest.cpp
	$(utestsdir)/UnitTesting.cpp
	)


  INCLUDE_DIRECTORIES(
    ${CMAKE_CURRENT_SOURCE_DIR}
    )

    ADD_LIBRARY(horus SHARED ${HORUS_SOURCES} HorusYap.cpp )

   if(DEFINED YAP_MAJOR_VERSION)
    TARGET_LINK_LIBRARIES(horus
      libYap
      )
  else()
    ADD_LIBRARY(horus SHARED ${HORUS_SOURCES} )
  endif()

  #set_property(TARGET horus PROPERTY CXX_STANDARD 11)
  #set_property(TARGET horus PROPERTY CXX_STANDARD_REQUIRED ON)

  set_target_properties (horus PROPERTIES PREFIX "" CXX_STANDARD 11 CXX_STANDARD_REQUIRED ON)

  add_executable (HorusCli HorusCli.cpp)

  set_target_properties (HorusCli PROPERTIES OUTPUT_NAME hcli CXX_STANDARD 11 CXX_STANDARD_REQUIRED ON)

  target_link_libraries(HorusCli horus )


  install(TARGETS  horus HorusCli
    RUNTIME DESTINATION ${bindir}
    LIBRARY DESTINATION ${dlls}
    )

ENDIF(HORUS)