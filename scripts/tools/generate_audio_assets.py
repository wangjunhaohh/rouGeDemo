from __future__ import annotations

import math
import os
import random
import wave
from pathlib import Path

SAMPLE_RATE = 22050
OUT_DIR = Path("audio/sfx")


def ensure_dir() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)


def synthesize(
    filename: str,
    duration: float,
    frequencies: list[float],
    waveform: str = "square",
    volume: float = 0.3,
    sweep: float = 0.0,
    noise: float = 0.0,
    decay: float = 5.0,
) -> None:
    total_samples = int(SAMPLE_RATE * duration)
    frames: list[int] = []

    for i in range(total_samples):
        t = i / SAMPLE_RATE
        envelope = math.exp(-decay * t)
        value = 0.0
        for base_freq in frequencies:
            freq = max(10.0, base_freq + sweep * t)
            phase = 2.0 * math.pi * freq * t
            if waveform == "square":
                sample = 1.0 if math.sin(phase) >= 0.0 else -1.0
            elif waveform == "saw":
                sample = 2.0 * ((freq * t) % 1.0) - 1.0
            else:
                sample = math.sin(phase)
            value += sample

        value /= max(1, len(frequencies))
        if noise > 0.0:
            value += random.uniform(-1.0, 1.0) * noise * envelope
        value *= envelope * volume
        value = max(-1.0, min(1.0, value))
        frames.append(int(value * 32767))

    path = OUT_DIR / filename
    with wave.open(str(path), "wb") as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(SAMPLE_RATE)
        wav_file.writeframes(b"".join(int(sample).to_bytes(2, "little", signed=True) for sample in frames))


def main() -> None:
    random.seed(42)
    ensure_dir()
    synthesize("shoot.wav", 0.10, [780.0, 1160.0], "square", 0.26, sweep=-1800.0, noise=0.02, decay=18.0)
    synthesize("hit.wav", 0.08, [280.0, 420.0], "square", 0.24, sweep=-900.0, noise=0.12, decay=20.0)
    synthesize("pickup.wav", 0.12, [660.0, 990.0], "sine", 0.22, sweep=600.0, noise=0.0, decay=10.0)
    synthesize("level_up.wav", 0.32, [392.0, 523.25, 783.99], "square", 0.22, sweep=220.0, noise=0.01, decay=6.0)
    synthesize("hurt.wav", 0.18, [190.0, 140.0], "saw", 0.22, sweep=-220.0, noise=0.08, decay=9.0)
    synthesize("enemy_die.wav", 0.16, [170.0, 220.0], "saw", 0.22, sweep=-620.0, noise=0.08, decay=10.0)
    synthesize("elite_spawn.wav", 0.42, [220.0, 293.66, 440.0], "square", 0.18, sweep=80.0, noise=0.01, decay=4.8)
    synthesize("boss_spawn.wav", 0.75, [98.0, 146.83, 196.0], "saw", 0.22, sweep=-20.0, noise=0.03, decay=2.8)
    synthesize("victory.wav", 0.58, [392.0, 523.25, 659.25], "square", 0.2, sweep=120.0, noise=0.0, decay=4.2)
    synthesize("defeat.wav", 0.62, [261.63, 196.0, 146.83], "saw", 0.2, sweep=-120.0, noise=0.03, decay=3.6)


if __name__ == "__main__":
    main()
