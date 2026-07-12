find_package(Qt6 REQUIRED COMPONENTS Core)

add_library(outback-common STATIC
    CommandRunner.cpp
    CommandRunner.h
)

target_include_directories(outback-common PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}
)

target_link_libraries(outback-common PUBLIC Qt6::Core)
