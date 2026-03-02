# A Benchmark Suite for Choke Pressure Control in Managed Pressure Drilling

**Authors:** Tarek El-Agroudi, Ole-Magnus Brastein, Glenn-Ole Kaasa, Lars Imsland

This repository contains the benchmark test platform associated with the article: **"A Benchmark Suite for Choke Pressure Control in Managed Pressure Drilling"**.

The suite is designed to test Choke Pressure Control algorithms using high-fidelity FMU models, covering routine operations, disturbances, and stability verification.

## Abstract

Managed Pressure Drilling (MPD) represents a challenging class of industrial control problems characterized by distributed dynamics, operating point variations, and input nonlinearities. To facilitate standardized control development for such systems, this paper presents a benchmark suite for MPD choke pressure control. The suite includes a high-fidelity simulator comprising three test wells, representing Land/Shallow-water MPD, Deepwater MPD, and Controlled Mud Level (CML) operations, validated against field data. The suite features seven benchmark scenarios covering nominal operations, pipe connections, pump faults, and robust stability verification, alongside Key Performance Indicators (KPI) and acceptance criteria. A simple gain-scheduled controller is included to serve as a performance baseline. The simulator is provided both as a native MATLAB/Simulink package and as a standalone executable with a generic UDP interface, and supports simulation speeds up to 50-180 times real-time on standard hardware. The complete benchmark suite is available at https://github.com/TarekEl-Agroudi/KeldaBenchmarkTests.

## Repository Structure

This project is divided into two distinct frameworks depending on your development environment:

### 1. [SimulinkFramework](./SimulinkFramework)
**For MATLAB/Simulink Users.**
* **Best for:** Researchers developing controllers natively in Simulink.
* **Features:** Native Simulink harness, automated reporting, and pre-configured controller templates.
* **Requires:** MATLAB R2020b+.

### 2. [ExternalControllerFramework](./ExternalControllerFramework)
**For Matlab, Python, C++, C#, Java, or PLC Users.**
* **Best for:** Testing algorithms written in any language, or Hardware-in-the-Loop (HIL) testing.
* **Features:** Standalone Windows Executable that communicates via UDP. Includes a "Lock-step" protocol for deterministic simulation regardless of language speed.
* **Requires:** Windows 10/11 for the simulator; Any language for the controller.

---
**Contact:** Tarek El-Agroudi, tareke@stud.ntnu.no
