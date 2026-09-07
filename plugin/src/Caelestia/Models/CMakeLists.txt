qml_module(caelestia-models
    URI Caelestia.Models
    SOURCES
        filesystemmodel.cpp
        appdb.cpp
    LIBRARIES
        Qt::Gui
        Qt::Concurrent
        Qt::Sql
)

if(BUILD_TESTING)
    find_package(Qt6 REQUIRED COMPONENTS Test)

    add_executable(caelestia-thumbnail-test tests/thumbnailtest.cpp)
    target_link_libraries(caelestia-thumbnail-test PRIVATE caelestia-models Qt::Gui Qt::Qml Qt::Test)
    add_test(NAME caelestia-thumbnail-cache COMMAND caelestia-thumbnail-test)
endif()
