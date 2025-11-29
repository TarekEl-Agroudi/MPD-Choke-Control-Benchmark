import socket
import struct
import time
import sys

LOCAL_IP = '127.0.0.1'
LOCAL_PORT = 65008
REMOTE_IP = '127.0.0.1'
REMOTE_PORT = 65000 
TIMEOUT_COUNT = 5000 

COMMAND_FORMAT = '<6d' 
MEASUREMENT_FORMAT = '<12d'
MEASUREMENT_BYTES = struct.calcsize(MEASUREMENT_FORMAT)

def select_well_and_get_op():
    well_names = {
        1: 'BM01 Land',
        2: 'BM02 Deepwater MPD',
        3: 'BM03 Deepwater CML'
    }
    
    print("\n--- Select Test Well ---")
    for key, name in well_names.items():
        print(f"[{key}] {name}")
    print("------------------------")
    
    while True:
        try:
            selection = int(input("Enter number for test well: "))
            if selection in well_names:
                break
            else:
                print("Invalid selection. Please enter 1, 2, or 3.")
        except ValueError:
            print("Invalid input. Please enter a number.")

    print(f"Selected well: {well_names[selection]}")
    
    if selection == 1:
        return 0.4356, 0.0
    elif selection == 2 or selection == 3:
        return 0.5871, 0.0
    
    return 0.4356, 0.0

def run_udp_controller():
    z_cA_init, z_cB_init = select_well_and_get_op()
    
    sim_idx = 0
    prev_sim_idx = 0

    w_uA = 0.0
    w_uB = 0.0
    z_cA = z_cA_init
    z_cB = z_cB_init
    E_ctrl = 0.0
    
    send_ctrl = True
    no_meas_count = 0

    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        sock.bind((LOCAL_IP, LOCAL_PORT))
        sock.setblocking(False) 
        
        print(f"\nController running... Ctrl+C to stop")
        print(f"Listening on port {LOCAL_PORT} and sending to {REMOTE_IP}:{REMOTE_PORT}")

    except Exception as e:
        print(f"Failed to initialize socket: {e}")
        sys.exit(1)

    while True:
        try:
            # 1) SEND CONTROL COMMAND
            if send_ctrl:
                control_cmd_values = [
                    float(sim_idx), 
                    z_cA, 
                    z_cB, 
                    w_uA,
                    w_uB,
                    E_ctrl
                ]
                
                bytes_out = struct.pack(COMMAND_FORMAT, *control_cmd_values)
                sock.sendto(bytes_out, (REMOTE_IP, REMOTE_PORT))
                send_ctrl = False
                no_meas_count = 0 
            
            # 2) RECEIVE MEASUREMENTS
            measurements = None
            try:
                data, sender = sock.recvfrom(MEASUREMENT_BYTES)
                if len(data) == MEASUREMENT_BYTES:
                    unpacked_measurements = struct.unpack(MEASUREMENT_FORMAT, data)
                    measurements = list(unpacked_measurements)
                    no_meas_count = 0
                else:
                    pass
                    
            except BlockingIOError:
                pass 
            except Exception as e:
                print(f"Socket error during receive: {e}")

            if measurements is None:
                no_meas_count += 1
                time.sleep(0.001)
                
                if no_meas_count >= TIMEOUT_COUNT:
                    print(f"Timeout (>{TIMEOUT_COUNT * 0.001}s) reached. Resetting control variables.")
                    sim_idx = 0
                    prev_sim_idx = 0
                    w_uA = 0.0
                    w_uB = 0.0
                    E_ctrl = 0.0
                    z_cA = z_cA_init
                    z_cB = z_cB_init
                    send_ctrl = True
                    no_meas_count = 0
                continue
            
            # Measurements:
            # 1:t_sim, 2:sim_idx, 3:p_c_r, 4:p_c, 5:p_stp, 6:q_p, 7:q_bl, 8:q_c, 9:z_cA, 10:z_cB, 11:w_cA, 12:w_cB
            t_sim    = measurements[0]
            sim_idx   = int(measurements[1])
            p_c_r     = measurements[2]
            p_c       = measurements[3]
            p_stp     = measurements[4]
            q_p       = measurements[5]
            q_bl      = measurements[6]
            q_c       = measurements[7]
            z_cA      = measurements[8]
            z_cB      = measurements[9]
            w_cA      = measurements[10] # Measurement A
            w_cB      = measurements[11] # Measurement B
            
            # 3) CONTROL LAW
            if sim_idx > prev_sim_idx:
                K_p = -0.001
                w_uA = K_p * (p_c_r - p_c)

                print(
                    f"\n[MEASUREMENT] t={t_sim:.4f}, count={sim_idx}, "
                    f"p_c={p_c:.4f}, p_c_r={p_c_r:.4f}, p_stp={p_stp:.4f}, "
                    f"q_p={q_p:.4f}, q_bl={q_bl:.4f}, q_c={q_c:.4f}, "
                    f"z_cA={z_cA:.4f}, z_cB={z_cB:.4f}, "
                    f"w_cA={w_cA:.4f}, w_cB={w_cB:.4f}"
                )

                prev_sim_idx = sim_idx
                send_ctrl = True
            
        except KeyboardInterrupt:
            print("\nShutting down controller.")
            sock.close()
            break
        except Exception as e:
            print(f"An unhandled error occurred in the main loop: {e}")
            sock.close()
            break

if __name__ == "__main__":
    run_udp_controller()