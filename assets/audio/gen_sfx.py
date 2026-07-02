"""Synthesize gentle, kid-friendly game SFX as 16-bit mono WAVs (no downloads needed).

Design constraints (NORTH_STAR audience is Grade 2/5): soft attacks, no harsh noise,
short durations, everything peak-normalized well below full scale.
"""
import math
import os
import struct
import wave

SR = 22050
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "sfx")


def write_wav(name, samples, peak=0.55):
    m = max(max(samples), -min(samples), 1e-9)
    scaled = [s / m * peak for s in samples]
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, name)
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(s * 32767)) for s in scaled))
    print(path)


def env(i, n, attack=0.01, release=0.5):
    """Attack/release envelope; release is the fraction of the tail that fades."""
    t = i / n
    a = min(1.0, (i / SR) / attack) if attack > 0 else 1.0
    r = min(1.0, (1.0 - t) / release) if release > 0 else 1.0
    return a * r


def sine(freq, t):
    return math.sin(2 * math.pi * freq * t)


# 1. Sword swish: band-swept noise, very soft.
def swish():
    n = int(0.16 * SR)
    out, lp1, lp2 = [], 0.0, 0.0
    import random
    rng = random.Random(7)
    for i in range(n):
        t = i / n
        cutoff = 0.15 + 0.55 * t  # sweep the filter up
        white = rng.uniform(-1, 1)
        lp1 += cutoff * (white - lp1)
        lp2 += cutoff * (lp1 - lp2)
        band = lp1 - lp2
        out.append(band * env(i, n, 0.02, 0.45))
    return out


# 2. Slime boing: pitch-bent soft triangle-ish tone.
def boing():
    n = int(0.22 * SR)
    out, phase = [], 0.0
    for i in range(n):
        t = i / n
        freq = 330 - 190 * t + 60 * math.sin(t * math.pi * 3) * (1 - t)
        phase += freq / SR
        s = sine(1, phase) * 0.8 + sine(2, phase) * 0.15
        out.append(s * env(i, n, 0.005, 0.5))
    return out


# 3. Coin chime: two quick bell partials (E6 then B6).
def coin():
    n = int(0.30 * SR)
    out = []
    for i in range(n):
        t = i / SR
        s = 0.0
        if t < 0.10:
            s += (sine(1318.5, t) + 0.4 * sine(2637, t)) * env(i, int(0.10 * SR), 0.002, 0.6)
        if t >= 0.07:
            j = i - int(0.07 * SR)
            m = n - int(0.07 * SR)
            s += (sine(1975.5, t) + 0.4 * sine(3951, t)) * env(j, m, 0.002, 0.8)
        out.append(s)
    return out


# 4. Quest fanfare: gentle C-E-G-C arpeggio with soft square-ish tone.
def fanfare():
    notes = [523.25, 659.25, 783.99, 1046.5]
    dur = 0.16
    out = []
    for k, f in enumerate(notes):
        n = int(dur * SR * (1.9 if k == len(notes) - 1 else 1.0))
        for i in range(n):
            t = i / SR
            s = sine(f, t) * 0.7 + sine(2 * f, t) * 0.2 + sine(3 * f, t) * 0.08
            out.append(s * env(i, n, 0.01, 0.55))
    return out


# 5. UI click: tiny filtered tick.
def click():
    n = int(0.05 * SR)
    out = []
    for i in range(n):
        t = i / SR
        out.append(sine(900, t) * env(i, n, 0.001, 0.85))
    return out


# 6. Ambient meadow loop (~8s): two slowly-beating soft pad tones + airy noise.
def ambient():
    n = int(8.0 * SR)
    import random
    rng = random.Random(11)
    out, lp = [], 0.0
    for i in range(n):
        t = i / SR
        pad = 0.5 * sine(196.0, t) + 0.5 * sine(196.5, t)  # slow 0.5 Hz beat
        pad += 0.3 * sine(293.7, t) + 0.3 * sine(294.1, t)
        lp += 0.02 * (rng.uniform(-1, 1) - lp)  # very dark noise = wind
        # crossfade the loop seam: first/last 0.5 s
        fade = min(1.0, t / 0.5, (8.0 - t) / 0.5)
        out.append((pad * 0.5 + lp * 1.2) * fade)
    return out


# --- Region ambience pass: four more soft, seamlessly-loopable region beds. Each mirrors
# ambient()'s approach (a slow, near-silent pad bed at its core, with the seam faded so
# looping via AudioManager's finished->play reconnect never clicks or pops).

# 7. Village hearth: a very soft, warm low-tone bed (no melody) - the "safe hub" region.
def village_hearth():
    n = int(6.0 * SR)
    out = []
    for i in range(n):
        t = i / SR
        pad = 0.6 * sine(130.8, t) + 0.6 * sine(131.1, t)  # warm low pad, slow beat
        pad += 0.25 * sine(196.0, t)
        fade = min(1.0, t / 0.5, (6.0 - t) / 0.5)
        out.append(pad * 0.5 * fade)
    return out


# 8. Meadow birds: the existing meadow pad bed plus occasional soft, short chirps.
def meadow_birds():
    n = int(9.0 * SR)
    import random
    rng = random.Random(23)
    out, lp = [0.0] * n, 0.0
    for i in range(n):
        t = i / SR
        pad = 0.45 * sine(220.0, t) + 0.45 * sine(220.4, t)
        lp += 0.015 * (rng.uniform(-1, 1) - lp)
        fade = min(1.0, t / 0.5, (9.0 - t) / 0.5)
        out[i] = (pad * 0.4 + lp * 0.8) * fade

    # Sprinkle a handful of soft, short chirps (quick pitch blips) at fixed, seam-safe times
    # so the loop stays reproducible/deterministic.
    chirp_starts = [1.1, 2.6, 4.3, 5.9, 7.4]
    for start in chirp_starts:
        dur = 0.12
        cn = int(dur * SR)
        base = 2400 + rng.uniform(-200, 300)
        for j in range(cn):
            ct = j / SR
            freq = base + 900 * math.sin(ct / dur * math.pi)
            idx = int(start * SR) + j
            if 0 <= idx < n:
                out[idx] += sine(freq, ct) * env(j, cn, 0.005, 0.6) * 0.12
    return out


# 9. Forest wind: filtered-noise swells (a slow low-pass cutoff sweep), no tonal pad.
def forest_wind():
    n = int(10.0 * SR)
    import random
    rng = random.Random(41)
    out, lp1, lp2 = [], 0.0, 0.0
    for i in range(n):
        t = i / SR
        # Slow swelling cutoff (two overlapping sine LFOs) so gusts feel organic, not metronomic.
        cutoff = 0.03 + 0.02 * (0.5 + 0.5 * math.sin(t * 2 * math.pi / 4.0)) \
            + 0.015 * (0.5 + 0.5 * math.sin(t * 2 * math.pi / 2.6 + 1.3))
        white = rng.uniform(-1, 1)
        lp1 += cutoff * (white - lp1)
        lp2 += cutoff * (lp1 - lp2)
        fade = min(1.0, t / 0.5, (10.0 - t) / 0.5)
        out.append(lp2 * fade)
    return out


# 10. Lake water: soft, slow lapping - a gentle low-passed noise pulse on a ~2.3s period.
def lake_water():
    n = int(9.2 * SR)  # ~4 lap cycles at 2.3s each, so the loop seam lands mid-silence
    import random
    rng = random.Random(59)
    out, lp = [], 0.0
    period = 2.3
    for i in range(n):
        t = i / SR
        phase = (t % period) / period
        # Each lap: a short soft swell-and-fade envelope, silence between laps.
        lap_env = max(0.0, math.sin(phase * math.pi)) ** 3 if phase < 0.55 else 0.0
        lp += 0.09 * (rng.uniform(-1, 1) - lp)
        fade = min(1.0, t / 0.5, (9.2 - t) / 0.5)
        out.append(lp * lap_env * fade)
    return out


write_wav("swing.wav", swish(), 0.4)
write_wav("slime_boing.wav", boing(), 0.5)
write_wav("coin_chime.wav", coin(), 0.5)
write_wav("quest_fanfare.wav", fanfare(), 0.5)
write_wav("ui_click.wav", click(), 0.35)
write_wav("ambient_meadow.wav", ambient(), 0.30)
write_wav("village_hearth.wav", village_hearth(), 0.28)
write_wav("meadow_birds.wav", meadow_birds(), 0.30)
write_wav("forest_wind.wav", forest_wind(), 0.26)
write_wav("lake_water.wav", lake_water(), 0.26)
