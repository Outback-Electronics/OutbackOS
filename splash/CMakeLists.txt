cmake_minimum_required(VERSION 3.22)

project(outback-splash VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick Svg)

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
    RESOURCES
        layers/background.svg
        layers/sky.svg
        layers/stars.svg
        layers/kangaroo.svg
        layers/windmill.svg
        layers/ring.svg
        layers/mark-space.svg
        layers/letter-o-big.svg
        layers/letter-s-big.svg
        layers/outback-letter-1.svg
        layers/outback-letter-2.svg
        layers/outback-letter-3.svg
        layers/outback-letter-4.svg
        layers/outback-letter-5.svg
        layers/outback-letter-6.svg
        layers/outback-letter-7.svg
        layers/os-letter-1.svg
        layers/os-letter-2.svg
        layers/tagline1-letter-1.svg
        layers/tagline1-letter-2.svg
        layers/tagline1-letter-3.svg
        layers/tagline1-letter-4.svg
        layers/tagline1-letter-5.svg
        layers/tagline1-letter-6.svg
        layers/tagline1-letter-7.svg
        layers/tagline1-letter-8.svg
        layers/tagline1-letter-9.svg
        layers/tagline1-letter-10.svg
        layers/tagline1-letter-11.svg
        layers/tagline1-letter-12.svg
        layers/tagline1-letter-13.svg
        layers/tagline2-letter-1.svg
        layers/tagline2-letter-2.svg
        layers/tagline2-letter-3.svg
        layers/tagline2-letter-4.svg
        layers/tagline2-letter-5.svg
        layers/tagline2-letter-6.svg
        layers/tagline2-letter-7.svg
        layers/tagline2-letter-8.svg
        layers/tagline2-letter-9.svg
        layers/tagline2-letter-10.svg
        layers/tagline2-letter-11.svg
        layers/tagline2-letter-12.svg
        layers/tagline2-letter-13.svg
)

target_link_libraries(outback-splash
    PRIVATE Qt6::Quick Qt6::Svg
)

install(
    TARGETS outback-splash
    RUNTIME DESTINATION bin
)
