cmake_minimum_required(VERSION 3.22)

project(outback-terminal VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick)
find_package(PkgConfig REQUIRED)

pkg_check_modules(VTERM REQUIRED IMPORTED_TARGET vterm)

qt_standard_project_setup(REQUIRES 6.4)

qt_add_executable(outback-terminal
    main.cpp
    PtySession.cpp
    PtySession.h
    TerminalView.cpp
    TerminalView.h
)

qt_add_qml_module(outback-terminal
    URI Outback.Terminal
    VERSION 1.0
    RESOURCE_PREFIX /
    QML_FILES
        Main.qml
)

target_link_libraries(outback-terminal
    PRIVATE Qt6::Quick PkgConfig::VTERM
)

install(
    TARGETS outback-terminal
    RUNTIME DESTINATION bin
)
