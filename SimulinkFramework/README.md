# MPD Choke Pressure Control Benchmark Suite (Simulink)

**Author:** Tarek El-Agroudi  
**Date:** 06-11-2025  
**Contact:** tareke@stud.ntnu.no / tarek@kelda.no

## 1. Overview
This benchmark suite provides a standardized simulation environment for testing Choke Pressure Control algorithms in Managed Pressure Drilling (MPD). It utilizes high-fidelity FMU (Functional Mock-up Unit) models to simulate realistic wellbore physics, including acoustic waves and nonlinear choke characteristics. The plant model runs at 100 Hz and the controller runs at 20 Hz.

The suite includes **7 standardized test scenarios** covering routine operations and stability verification.

## 2. System Requirements

### Software
* **MATLAB & Simulink:** Version R2020b or newer.
  *(Note: R2020b+ is required for native FMU Import support without add-ons).*
* **Operating System:** Windows.
  *(Future versions will support Linux and macOS).*

### Toolboxes
* **Simulink** (Required).
* **Control System Toolbox** (Recommended for controller tuning/design).

## 3. Directory Structure
Ensure your folder structure looks exactly like this. The script relies on relative paths to find models and controllers.

```text
[Root Folder]
 ├── RunBenchmarkTests.m            <-- Main execution script
 ├── BenchmarkTestHarness.slx       <-- Simulation environment
 ├── README.md
 │
 ├── controllers/                   <-- SAVE YOUR CONTROLLERS HERE
 │    ├── ExternalController.slx    (Use as template)
 │    └── MyChokePressureController.slx
 │
 ├── fmu/                           <-- DO NOT MODIFY
 │    ├── BM01_Land.fmu
 │    ├── BM02_DeepwaterMPD.fmu
 │    ├── BM03_DeepwaterCML.fmu
 │    └── SelectedFMU.fmu           (Auto-generated during runtime)
 │
 ├── Utils/                         <-- UTILITIES
 │    ├── linearChirp.m
 │    └── assignAllVariables.m
 │
 └── reports/                       <-- Output folder (Auto-generated)
```

## 4. How to Run

### Step 1: Prepare Your Controller
Create a Simulink model (`.slx`) containing your control logic and save it inside the `controllers` folder.

> **Important:** Your controller model must be configured to emulate realistic industrial hardware limits.

**System Requirements:**
* **Sample Time:** Your controller must run at **20 Hz (0.05s)**.
* **Solver Configuration:** Set your model settings to:
    * **Type:** `Fixed-step`
    * **Solver:** `discrete (no continuous states)`
    * **Fixed-step size:** `0.05`
* **Discrete Only:** Do not use continuous blocks. Use their discrete equivalents to avoid hybrid model errors.

> **Recommendation:** Use the provided `ExternalController.slx` as a starting point. It is pre-configured with the correct ports and solver settings.

### Step 2: Start the Script
Open MATLAB, navigate to the root folder, and type:
```matlab
>> RunBenchmarkTests
```

### Step 3: Select Scenarios
A dialog box will appear. Select one or multiple tests:

| ID | Test Name | Purpose |
| :--- | :--- | :--- |
| **T1** | Choke Pressure Steps | Tracking performance |
| **T2** | Downlinking | Setpoint changes |
| **T3** | Flow Ramps | Disturbance rejection |
| **T4** | Connection | Full connection procedure simulation |
| **T5** | Pump Shutdown and Recovery | Pressure trapping, recovery |
| **T6** | Stability Margins Nominal OP | High flow, low pressure|
| **T7** | Stability Margins Connection OP | Low flow, high Pressure |

### Step 4: Select Well & Controller
1. Select the specific well model (BM01 LandMPD, BM02 DeepwaterMPD, or BM03 DeepwaterCML).
2. Select your controller file from the list.

### Step 5: Reporting
Choose whether to generate a PDF report (Dark or Light theme). If selected, the report will automatically open upon completion.

## 5. Outputs
After execution, results are saved in the `reports` folder:
**Path:** `./reports/Benchmark_[WellName]_[ControllerName]/`

**Files generated:**
1. **Results.mat**: Contains raw data structs, simOutput objects, KPI struct.
2. **BenchmarkReport.pdf**: Visual summary of performance.
3. **[Plot Files]**: Individual plots for tests performed.

## 6. Troubleshooting

**ISSUE: "No controller models found..."**
* **Solution:** Ensure you have saved a `.slx` file inside the `controllers` directory. The script does not look in the root folder.

**ISSUE: "Failed to link controller model"**
* **Solution:** The script attempts to place your model into the harness using Model Reference. Ensure your model inputs/outputs match the harness requirements and that the file is not corrupted.

**ISSUE: FMU / Simulation Crash**
* **Solution:** Ensure you are using MATLAB R2020b or newer. If you are on an older version, FMU Import is not natively supported without the "Simulink Compiler" or "FMI Kit" add-ons.

**ISSUE: "Referencing a hybrid model with a different fixed step size is not supported"**
* **Cause:** Your controller model contains continuous states or has a block with `SampleTime = 0`. Simulink cannot solve continuous physics inside a discrete 20 Hz controller referenced by a 100 Hz harness.
* **Solution:**
    1. Open your controller model settings (`Ctrl+E`) and set the **Solver** to `discrete (no continuous states)`.
    2. Replace all continuous blocks with their discrete equivalents (e.g., `Discrete Time Integrator`).
    3. Ensure sources like **Step** or **Constant** blocks have a Sample Time of `0.05` or `-1` (Inherited).
