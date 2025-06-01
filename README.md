🚦 AI Railway Control System – Unix 3D-Real-Time Simulation in Pure Bash (on Windows! and Linux)

This project is a portable real-time simulation system with WebGL UI, fully automated and built using Bash on MSYS2 (or native Linux). It showcases how minimal dependencies can power modern, interactive, and intelligent control systems. ⚙️🧠

🎯 Why it matters :

✅ Zero setup – Everything auto-configures in seconds (PHP, SQLite, UI, WebGL)

✅ AI-driven simulation – Randomized traffic, signals, weather, events

✅ Web-based UI – No servers to install, just php -S and go

✅ SQLite-powered – Data persists locally, perfect for embedded use cases

✅ Security-conscious – Clean configuration, no loose ends

✅ 100% portable – Works out-of-the-box on any MSYS2-enabled Windows dev machine


🚀 How to try it:
bash railway-ai-control.sh

Then launch:
http://localhost:8080

👀 What you’ll see:

A smart simulation of a railway control system, complete with train movement, alerts, AI decisions, and UI built on-the-fly. Perfect to demonstrate real-time logic, embedded tech, and system monitoring.

🧩 Relevance for Aitek:

Whether gate automation, transport systems, or surveillance dashboards – this project shows how much can be done with minimal assumptions, high adaptability, and strong cross-platform tooling.

💬 Let’s talk about how this approach can enhance modularity, testing, and rapid prototyping in your stack.

🧰 Technical Description

This project was developed as a fully automated and portable simulation system for railway traffic control, aiming to showcase full-stack skills using minimal dependencies and rapid setup.

Main Components:

    Technologies used:
    
        Bash scripting (MSYS2/Windows/Linux)

        WebGL for dynamic browser-based visual feedback (no libraries required – pure HTML/JS)

        PHP 8.x with built-in server

        SQLite3 (embedded, no external database)

        HTML + dynamically generated UI

    Functionality:

        Real-time simulation of railway traffic events

        Dynamic web interface rendered on first run

        AI logic for randomized conditions (e.g., weather, delays, incidents)

        Local data persistence

    Design goals:

        Zero-config setup from a single .sh script

        Cross-platform compatibility using MSYS2

        Modularity and clean separation between logic, UI, and data

        Fully offline-capable once downloaded

This approach demonstrates practical skills in backend automation, frontend generation, and embedded system logic, all relevant to scenarios like transport monitoring, gate automation, or intelligent surveillance.

🐧 Addendum – How to Run It on Linux

Although originally designed for MSYS2 on Windows, this script runs smoothly on any modern Linux distribution with Bash and a few basic tools.

✅ Prerequisites:

    Bash shell (default)

    curl, unzip, sqlite3, php (≥ 8.x)

🔧 Quick setup (example on Ubuntu/Debian):

sudo apt install curl unzip php sqlite3
bash railway-ai-control.sh

Then open:
http://localhost:8080

Everything else is handled by the script – no web server or manual config needed. Just run and explore the simulation!

🔍 Platform Comparison: Windows (MSYS2) vs Linux

Feature        Windows (MSYS2)	                          Linux (Ubuntu/Debian/Fedora...)
Shell          Bash (via MSYS2)	                          Native Bash
PHP            Available via pacman -S php	              Preinstalled or available via apt/yum
SQLite3        Available via pacman -S sqlite	            Preinstalled or available via apt/yum
Start Command  bash railway-ai-control.sh                 bash railway-ai-control.sh
Web Server     php -S localhost:8080                      php -S localhost:8080
Compatibility	✅ Full with MSYS2	                        ✅ Full out of the box
Web UI         Opens in default browser (Edge, Chrome)    Opens in Firefox, Chrome, etc.
Editing Tools  Notepad / VSCode                           nano, vim, VSCode

📌 Key point: the script behaves identically across both platforms with minimal setup, ensuring full portability and quick deployment in Linux-dominant environments.

#Linux #Bash #MSYS2 #AI #Simulation #FullStackDev #TransportTech #SQLite #PHP #EmbeddedSystems #CrossPlatform #SmartControl #RealTimeData #RailwayTech #DevOps
