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
    RESOURCES
        layers/background.png
        layers/sky.png
        layers/stars.png
        layers/kangaroo.png
        layers/windmill.png
        layers/ring.png
        layers/mark-space.png
        layers/letter-o-big.png
        layers/letter-s-big.png
        layers/outback-letter-1.png
        layers/outback-letter-2.png
        layers/outback-letter-3.png
        layers/outback-letter-4.png
        layers/outback-letter-5.png
        layers/outback-letter-6.png
        layers/outback-letter-7.png
        layers/os-letter-1.png
        layers/os-letter-2.png
        layers/tagline1-letter-1.png
        layers/tagline1-letter-2.png
        layers/tagline1-letter-3.png
        layers/tagline1-letter-4.png
        layers/tagline1-letter-5.png
        layers/tagline1-letter-6.png
        layers/tagline1-letter-7.png
        layers/tagline1-letter-8.png
        layers/tagline1-letter-9.png
        layers/tagline1-letter-10.png
        layers/tagline1-letter-11.png
        layers/tagline1-letter-12.png
        layers/tagline1-letter-13.png
        layers/tagline2-letter-1.png
        layers/tagline2-letter-2.png
        layers/tagline2-letter-3.png
        layers/tagline2-letter-4.png
        layers/tagline2-letter-5.png
        layers/tagline2-letter-6.png
        layers/tagline2-letter-7.png
        layers/tagline2-letter-8.png
        layers/tagline2-letter-9.png
        layers/tagline2-letter-10.png
        layers/tagline2-letter-11.png
        layers/tagline2-letter-12.png
        layers/tagline2-letter-13.png
)

target_link_libraries(outback-splash
    PRIVATE Qt6::Quick
)

install(
    TARGETS outback-splash
    RUNTIME DESTINATION bin
)
