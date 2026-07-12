cmake_minimum_required(VERSION 3.22)

project(outback-splash VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick)

qt_standard_project_setup(REQUIRES 6.4)

qt_add_executable(outback-splash
    main.cpp
)

qt_add_qml_module(outback-splash
    URI Outback.Splash
    VERSION 1.0
    RESOURCE_PREFIX /
    QML_FILES
        Main.qml
)

target_link_libraries(outback-splash
    PRIVATE Qt6::Quick
)

install(
    TARGETS outback-splash
    RUNTIME DESTINATION bin
)
