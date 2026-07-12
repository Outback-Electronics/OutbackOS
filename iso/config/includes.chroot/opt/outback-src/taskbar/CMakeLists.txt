cmake_minimum_required(VERSION 3.22)

project(outback-taskbar VERSION 0.1 LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick WaylandClient)
find_package(LayerShellQt REQUIRED)

qt_standard_project_setup(REQUIRES 6.5)

qt_add_executable(outback-taskbar
    main.cpp
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
    SOURCES
        ForeignToplevel.cpp
        ForeignToplevel.h
        ToplevelManager.cpp
        ToplevelManager.h
)

target_link_libraries(outback-taskbar
    PRIVATE
        Qt6::Quick
        Qt6::WaylandClient
        LayerShellQt::Interface
)

install(
    TARGETS outback-taskbar
    RUNTIME DESTINATION bin
)
