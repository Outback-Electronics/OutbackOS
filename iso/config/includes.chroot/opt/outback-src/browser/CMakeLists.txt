cmake_minimum_required(VERSION 3.22)

project(outback-browser VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick WebEngineQuick)

qt_standard_project_setup(REQUIRES 6.4)

qt_add_executable(outback-browser
    main.cpp
    BrowserBackend.cpp
    BrowserBackend.h
)

qt_add_qml_module(outback-browser
    URI Outback.Browser
    VERSION 1.0
    RESOURCE_PREFIX /
    QML_FILES
        Main.qml
    RESOURCES
        start.html
)

target_link_libraries(outback-browser
    PRIVATE Qt6::Quick Qt6::WebEngineQuick
)

install(
    TARGETS outback-browser
    RUNTIME DESTINATION bin
)
