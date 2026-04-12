cmake_minimum_required(VERSION 3.20)
project(alfa-core VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

find_package(SQLite3)
if(SQLite3_FOUND)
    message(STATUS "Found SQLite3: ${SQLite3_LIBRARIES}")
else()
    find_library(SQLite3_LIBRARIES sqlite3)
    find_path(SQLite3_INCLUDE_DIR sqlite3.h)
    if(SQLite3_LIBRARIES AND SQLite3_INCLUDE_DIR)
        set(SQLite3_FOUND TRUE)
        set(SQLite3_INCLUDE_DIRS ${SQLite3_INCLUDE_DIR})
    endif()
endif()

if(NOT SQLite3_FOUND)
    message(FATAL_ERROR "SQLite3 library not found. Install sqlite3 development headers.")
endif()

add_executable(alfa-core
    src/main.cpp
    src/ProtectEngine.cpp
    src/Crypto.cpp
    src/Sha256.cpp
    src/Database.cpp
    src/PolicyStore.cpp
    src/CommandServer.cpp
)

target_include_directories(alfa-core PRIVATE src ${SQLite3_INCLUDE_DIRS})

target_link_libraries(alfa-core PRIVATE ${SQLite3_LIBRARIES})

if(WIN32)
    target_link_libraries(alfa-core PRIVATE ws2_32)
endif()

if(MSVC)
    target_compile_options(alfa-core PRIVATE /W4 /permissive-)
else()
    target_compile_options(alfa-core PRIVATE -Wall -Wextra -Wpedantic)
endif()
