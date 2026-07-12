find_package(Qt6 REQUIRED COMPONENTS Core)

add_library(outback-common STATIC
    CommandRunner.cpp
    CommandRunner.h
    SystemLauncher.cpp
    SystemLauncher.h
)

# SystemLauncher is a Q_OBJECT; qt_add_executable/qt_add_qml_module enable
# AUTOMOC on the targets they create, but this is a plain add_library, so
# it needs to opt in explicitly or moc never runs for it.
set_target_properties(outback-common PROPERTIES AUTOMOC ON)

target_include_directories(outback-common PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}
)

target_link_libraries(outback-common PUBLIC Qt6::Core)
