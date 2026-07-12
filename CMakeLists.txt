cmake_minimum_required(VERSION 3.16)
project(mpdlisten)

find_package(ECM 5.240.0 REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${ECM_MODULE_PATH})
include(KDEInstallDirs)

find_package(Qt6 REQUIRED COMPONENTS Core Qml Network)
find_package(Plasma REQUIRED)

set(CMAKE_AUTOMOC ON)

qt_add_qml_module(mpdlisten
    URI com.pioki.jukebox.backend
    VERSION 1.0
    SOURCES
        mpdListen.h
        mpdListen.cpp
)

target_link_libraries(mpdlisten PRIVATE
    Qt6::Core
    Qt6::Qml
    Qt6::Network
)

set_target_properties(mpdlisten mpdlistenplugin PROPERTIES
    INSTALL_RPATH "$ORIGIN"
    BUILD_WITH_INSTALL_RPATH TRUE
)

install(TARGETS mpdlisten mpdlistenplugin DESTINATION ${KDE_INSTALL_QMLDIR}/com/pioki/jukebox/backend)
install(FILES "${CMAKE_CURRENT_BINARY_DIR}/qmldir" DESTINATION ${KDE_INSTALL_QMLDIR}/com/pioki/jukebox/backend)

plasma_install_package(package com.pioki.jukebox)
