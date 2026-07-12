cmake_minimum_required(VERSION 3.22)

project(outback-shell VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick)

qt_standard_project_setup(REQUIRES 6.4)

if(NOT DEFINED OUTBACK_COMMON_DIR)
    set(OUTBACK_COMMON_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../common)
endif()

add_subdirectory(${OUTBACK_COMMON_DIR} ${CMAKE_CURRENT_BINARY_DIR}/outback-common)

qt_add_executable(outback-shell
    main.cpp
)

qt_add_qml_module(outback-shell
    URI Outback.Shell
    VERSION 1.0
    QML_FILES
        Main.qml
    RESOURCES
        icons/outback-mark.svg
        icons/download.svg
)

target_link_libraries(outback-shell
    PRIVATE Qt6::Quick outback-common
)

install(
    TARGETS outback-shell
    RUNTIME DESTINATION bin
)
