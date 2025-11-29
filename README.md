# MPD Choke Pressure Control Benchmark Suite

This repository contains the benchmark test platform associated with the CEP Journal Article: **"A Benchmark Suite for Choke Pressure Control in Managed Pressure Drilling"**.

The suite is designed to test Choke Pressure Control algorithms using high-fidelity FMU models, covering routine operations, disturbances, and stability verification.



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
**Contact:** Tarek El-Agroudi, tareke@stud.ntnu.no / tarek@kelda.no