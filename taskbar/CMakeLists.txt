cmake_minimum_required(VERSION 3.22)

project(outback-taskbar VERSION 0.1 LANGUAGES CXX C)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick WaylandClient)
find_package(LayerShellQt REQUIRED)

qt_standard_project_setup(REQUIRES 6.5)

if(NOT DEFINED OUTBACK_COMMON_DIR)
    set(OUTBACK_COMMON_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../common)
endif()

add_subdirectory(${OUTBACK_COMMON_DIR} ${CMAKE_CURRENT_BINARY_DIR}/outback-common)

qt_add_executable(outback-taskbar
    main.cpp
    ForeignToplevel.cpp
    ForeignToplevel.h
    ToplevelManager.cpp
    ToplevelManager.h
    SignalBridge.cpp
    SignalBridge.h
)

qt6_generate_wayland_protocol_client_sources(outback-taskbar
    PRIVATE_CODE
    FILES
        ${CMAKE_CURRENT_SOURCE_DIR}/protocols/wlr-foreign-toplevel-management-unstable-v1.xml
)

qt_add_qml_module(outback-taskbar
    URI Outback.Taskbar
    VERSION 1.0
    RESOURCE_PREFIX /
    QML_FILES
        Main.qml
        StartMenu.qml
        Apps.qml
    SOURCES
        ForeignToplevel.cpp
        ForeignToplevel.h
        ToplevelManager.cpp
        ToplevelManager.h
        SignalBridge.cpp
        SignalBridge.h
)

target_link_libraries(outback-taskbar
    PRIVATE
        Qt6::Quick
        Qt6::WaylandClient
        LayerShellQt::Interface
        outback-common
)

install(
    TARGETS outback-taskbar
    RUNTIME DESTINATION bin
)
