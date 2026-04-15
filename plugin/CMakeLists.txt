cmake_minimum_required(VERSION 3.21)
project(dbussignallistener LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

include(GNUInstallDirs)

find_package(Qt6 6.5 REQUIRED COMPONENTS Core DBus Qml)

qt_standard_project_setup(REQUIRES 6.5)

# Build outputs directly under a path that matches the QML module URI so
# qml6 / plasmashell can find the module via QML2_IMPORT_PATH=$prefix/lib/qt6/qml.
set(QML_MODULE_OUTPUT_DIR
    "${CMAKE_BINARY_DIR}/qml/org/kde/plasma/dynamicisland/dbussignal")

qt_add_qml_module(dbussignallistener
    URI org.kde.plasma.dynamicisland.dbussignal
    VERSION 1.0
    PLUGIN_TARGET dbussignallistenerplugin
    OUTPUT_DIRECTORY ${QML_MODULE_OUTPUT_DIR}
    SOURCES
        DBusSignalListener.h
        DBusSignalListener.cpp
)

target_link_libraries(dbussignallistener
    PRIVATE
        Qt6::Core
        Qt6::DBus
        Qt6::Qml
)

target_compile_options(dbussignallistener PRIVATE
    -Wall -Wextra -Wpedantic
)

# Install the whole module directory as-is. Default prefix is /usr/local;
# install.sh sets CMAKE_INSTALL_PREFIX to $HOME/.local for user-local use.
install(DIRECTORY ${QML_MODULE_OUTPUT_DIR}/
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/qt6/qml/org/kde/plasma/dynamicisland/dbussignal
    FILES_MATCHING
        PATTERN "*.so"
        PATTERN "qmldir"
        PATTERN "*.qmltypes"
)
