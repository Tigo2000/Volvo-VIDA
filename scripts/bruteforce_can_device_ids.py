import can
import time

def send_can_message(bus, device_id):
    message = [0xCB, device_id, 0xAE, 0x1B, 0x00, 0x00, 0x00, 0x00]
    msg = can.Message(arbitration_id=0x000FFFFE,  
                      data=message, 
                      is_extended_id=True)
    bus.send(msg)

def listen_for_response(bus, device_id, listen_duration):
    start_time = time.time()
    
    try:
        while time.time() - start_time < listen_duration:
            message = bus.recv(timeout=0.1)
            if message is not None:
                data = message.data
                if len(data) >= 3 and data[1] == device_id and data[2] == 0xEE:
                    print(f"Device found! Device ID: {device_id:02X}, Response ID: {message.arbitration_id:08X}")
                    return message.arbitration_id
        return None
    except can.CanError as e:
        print(f"CAN Error: {e}")
        return None

def brute_force_device_ids():
    found_devices = []
    bus = None
    try:
        bus = can.interface.Bus(channel='can0', bustype='socketcan')
    
        for device_id in range(0x00, 0x100):  # 0x00 to 0xFF
            print(f"Trying Device ID: {device_id:02X}")
            
            send_can_message(bus, device_id)
            
            response_id = listen_for_response(bus, device_id, listen_duration=0.2)
            if response_id is not None:
                found_devices.append((device_id, response_id))
            
            time.sleep(0.01)

    finally:
        if bus is not None:
            bus.shutdown()
        
        if found_devices:
            print("\nDevices found:")
            for device_id, arbitration_id in found_devices:
                print(f"Device ID: {device_id:02X}, Response ID: {arbitration_id:08X}")
        else:
            print("No devices found")

if __name__ == "__main__":
    brute_force_device_ids()
