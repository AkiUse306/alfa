#include <iostream>
#include <thread>
#include "ProtectEngine.h"

int main()
{
    Alfa::ProtectEngine engine;
    engine.initialize();

    std::cout << "Alfa core protection engine started." << std::endl;
    std::cout << "Press Ctrl+C to stop." << std::endl;

    while (engine.isRunning()) {
        engine.poll();
        std::this_thread::sleep_for(std::chrono::milliseconds(250));
    }

    return 0;
}
