import time
import random
import serial
from dataclasses import dataclass

# ---------------- CONFIG ----------------
@dataclass
class Config:
    port: str = "COM7"
    baud: int = 57600
    timeout: float = 1.0
    byte_gap_sec: float = 0.001
    msg_gap_sec: float = 0.00
    default_delay: float = 0.05
# ----------------------------------------


def clamp(val, lo=0, hi=255):
    return max(lo, min(hi, val))


class FpgaUart:
    def __init__(self, ser: serial.Serial, cfg: Config):
        self.ser = ser
        self.cfg = cfg

    # --- low-level send ---
    def send_msg_byte_by_byte(self, msg: str):
        print(f"Sending: {msg}")
        for ch in msg:
            self.ser.write(ch.encode("ascii"))
            self.ser.flush()
            if self.cfg.byte_gap_sec > 0:
                time.sleep(self.cfg.byte_gap_sec)
        if self.cfg.msg_gap_sec > 0:
            time.sleep(self.cfg.msg_gap_sec)

    # --- protocol helpers ---
    def send_rgb(self, r: int, g: int, b: int):
        r = clamp(int(r)); g = clamp(int(g)); b = clamp(int(b))
        msg = f"{{R{r:03d},G{g:03d},B{b:03d}}}"
        self.send_msg_byte_by_byte(msg)

    def send_led(self, l: int):
        # only allow 16/17 (optional but recommended)
        l = int(l)
        if l not in (16, 17):
            raise ValueError("LED must be 16 or 17")
        msg = f"{{L{l:03d}}}"   # {L016} / {L017}
        self.send_msg_byte_by_byte(msg)

    # --- transactions ---
    def rgb_transactions(self, num: int, delay: float = None):
        delay = self.cfg.default_delay if delay is None else delay
        for _ in range(int(num)):
            r = random.randint(0, 255)
            g = random.randint(0, 255)
            b = random.randint(0, 255)
            self.send_rgb(r, g, b)
            print(f"data sent: {r}, {g}, {b}")
            time.sleep(delay)

    def rgb_set_and_send(self, num: int, r_max: int, g_max: int, b_max: int, delay: float = None):
        delay = self.cfg.default_delay if delay is None else delay
        for _ in range(int(num)):
            r = random.randint(0, r_max)
            g = random.randint(0, g_max)
            b = random.randint(0, b_max)
            self.send_rgb(r, g, b)
            print(f"data sent: {r}, {g}, {b}")
            time.sleep(delay)

    def led_toggle_transactions(self, num: int, delay: float = None, start: int = 16):
        delay = self.cfg.default_delay if delay is None else delay
        led = start
        for _ in range(int(num)):
            self.send_led(led)
            led = 17 if led == 16 else 16
            time.sleep(delay)

    # --- modes ---
    def mode1(self, n: int):
        self.rgb_transactions(n)
        self.led_toggle_transactions(n // 2)
        self.rgb_transactions(n)

    def mode2(self, n: int):
        self.rgb_set_and_send(n, 255, 0,   0)   # red-ish
        self.rgb_set_and_send(n, 0,   0, 255)   # blue-ish
        self.led_toggle_transactions(n // 2)
        self.rgb_set_and_send(n, 255, 0, 255)   # magenta-ish
        self.rgb_set_and_send(1, 255, 0, 255)

    def mode3(self, n: int):
        delay: float = 0.01

        for i in range(int(255)):
            r = i
            g = 0
            b = 0
            self.send_rgb(r, g, b)
            print(f"data sent: {r}, {g}, {b}")
            time.sleep(delay)

        for i in range(int(255)):
            r = 0
            g = i
            b = 0
            self.send_rgb(r, g, b)
            print(f"data sent: {r}, {g}, {b}")
            time.sleep(delay)

        for i in range(int(255)):
            r = 0
            g = 0
            b = i
            self.send_rgb(r, g, b)
            print(f"data sent: {r}, {g}, {b}")
            time.sleep(delay)

        





        self.rgb_set_and_send(n, 255, 0,   0)   # red-ish
        self.rgb_set_and_send(n, 0,   0, 255)   # blue-ish
        self.led_toggle_transactions(n // 2)
        self.rgb_set_and_send(n, 255, 0, 255)   # magenta-ish
        self.rgb_set_and_send(1, 255, 0, 255)


def open_serial(cfg: Config) -> serial.Serial:
    return serial.Serial(
        cfg.port,
        cfg.baud,
        timeout=cfg.timeout,
        rtscts=False,
        dsrdtr=False,
        xonxoff=False
    )


def main():
    cfg = Config()
    try:
        with open_serial(cfg) as ser:
            time.sleep(0.2)
            print(f"Connected to {cfg.port}. Ctrl+C to stop.\n")

            fpga = FpgaUart(ser, cfg)

            # optional: reproducible tests
            # random.seed(123)

            fpga.mode2(20)
            
            while True:
                cmd = input("Choose mode [1/2], rgb, led, seed, q: ").strip().lower()

                if cmd in ("q", "quit", "exit"):
                    break

                elif cmd == "1":
                    fpga.mode1(20)

                elif cmd == "2":
                    fpga.mode2(20)
                    
                elif cmd == "3":
                    fpga.mode3(20)

                elif cmd == "rgb":
                    r = int(input("R (0-255): "))
                    g = int(input("G (0-255): "))
                    b = int(input("B (0-255): "))
                    fpga.send_rgb(r, g, b)

                elif cmd == "led":
                    l = int(input("LED (16/17): "))
                    fpga.send_led(l)

                elif cmd == "seed":
                    s = int(input("Seed number: "))
                    random.seed(s)
                    print(f"Seed set to {s}")

                else:
                    print("Unknown command. Try: 1, 2, rgb, led, seed, q")

    except serial.SerialException as e:
        print(f"Port Error: {e}")
    except KeyboardInterrupt:
        print("\nStopped by user.")


if __name__ == "__main__":
    main()
