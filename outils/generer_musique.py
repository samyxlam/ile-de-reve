# -*- coding: utf-8 -*-
"""Musique d'ambiance du jeu — synthèse pure, aucune licence.

Style : guzheng imaginaire — pentatonique de ré majeur, cordes pincées
synthétisées par Karplus-Strong (scipy.signal.lfilter), nappe de fond lente
et réverbération courte. Boucle de 72 s sans couture :

- la nappe est ré-accordée sur f' = round(f * T) / T (T = durée de boucle),
  donc exactement périodique sur la boucle ;
- aucun pincement ne chevauche la fin de boucle.

Sortie : assets/musique/ambiance.ogg (Vorbis, via soundfile/libsndfile).
Régénérer : python outils/generer_musique.py
"""
from pathlib import Path

import numpy as np
import soundfile as sf
from scipy.signal import lfilter

SR = 44100
BPM = 80.0
BEAT = 60.0 / BPM                     # 0,75 s
BARS = 12
BEATS_PAR_MESURE = 8
T = BARS * BEATS_PAR_MESURE * BEAT    # 72 s exactement
N = int(round(T * SR))

RACINE = Path(__file__).resolve().parent.parent

# Pentatonique de ré majeur sur 3 octaves (degrés graves → aigus).
DEGRES = [146.83, 220.00, 246.94, 293.66, 329.63, 369.99, 440.00, 493.88,
          587.33, 659.25, 739.99, 880.00]


def pince(freq: float, duree: float, vel: float) -> np.ndarray:
    """Corde pincée Karplus-Strong : bruit court dans un filtre en peigne."""
    periode = max(2, int(round(SR / freq)))
    rho = 0.9975 - freq * 4e-6            # les aigus meurent un peu plus vite
    a = np.zeros(periode + 2)
    a[0] = 1.0
    a[periode] = -0.5 * rho
    a[periode + 1] = -0.5 * rho
    rng = np.random.default_rng(int(freq * 1000) % 99991)
    excitation = rng.uniform(-1.0, 1.0, periode)
    cible = int(duree * SR)
    excitation = np.pad(excitation, (0, max(0, cible - len(excitation))))
    return vel * lfilter([1.0], a, excitation)


def nappe(freq: float, debut: float, fin: float, vel: float) -> np.ndarray:
    """Note tenue de la nappe, attaque et libération douces, aperiodicité annulée."""
    f_aj = round(freq * T) / T            # exactement périodique sur la boucle
    i0, i1 = int(debut * SR), int(fin * SR)
    t = np.arange(i0, i1) / SR
    onde = (np.sin(2 * np.pi * f_aj * t)
            + 0.35 * np.sin(2 * np.pi * 2 * f_aj * t)
            + 0.12 * np.sin(2 * np.pi * 3 * f_aj * t))
    attaque = min(1.8, (fin - debut) * 0.35)
    libere = min(2.2, (fin - debut) * 0.35)
    enveloppe = np.ones_like(t)
    n_att = int(attaque * SR)
    n_lib = int(libere * SR)
    if n_att > 0:
        enveloppe[:n_att] = np.linspace(0.0, 1.0, n_att)
    if n_lib > 0:
        enveloppe[-n_lib:] *= np.linspace(1.0, 0.0, n_lib)
    ligne = np.zeros(N)
    ligne[i0:i1] = vel * enveloppe * onde / 1.6
    return ligne


def compose() -> tuple:
    rng = np.random.default_rng(20261107)

    gauche = np.zeros(N)
    droite = np.zeros(N)

    # ------------------------------------------------- nappe d'accompagnement
    accords = [
        [146.83, 220.00, 293.66],           # ré
        [123.47, 185.00, 293.66],           # si mineur
        [110.00, 164.81, 246.94],           # sol
        [110.00, 220.00, 277.18],           # sol / fa# tenue
    ]
    for k in range(BARS // 2):
        accord = accords[k % len(accords)]
        debut = k * 4 * BEATS_PAR_MESURE * BEAT
        fin = min(T, debut + 4 * BEATS_PAR_MESURE * BEAT)
        for f in accord:
            ligne = nappe(f, debut, fin, 0.16)
            gauche += ligne
            droite += ligne * 0.92

    # ------------------------------------------------- mélodie pincée
    def phrase(variation: int) -> list:
        pos, deg = 0.0, rng.integers(4, 9)
        evts = []
        while pos < BEATS_PAR_MESURE:
            duree = 2.0 if rng.random() < 0.6 else 1.0
            if pos + duree > BEATS_PAR_MESURE:
                duree = BEATS_PAR_MESURE - pos
            if duree <= 0:
                break
            pas = int(rng.choice([-2, -1, 1, 1, 2, 3], p=[0.18, 0.22, 0.25, 0.15, 0.12, 0.08]))
            deg = int(np.clip(deg + pas, 3, len(DEGRES) - 1))
            if variation and rng.random() < 0.35:
                deg = int(np.clip(deg + rng.integers(-1, 2), 3, len(DEGRES) - 1))
            evts.append((pos, deg, duree))
            pos += duree
        return evts

    A = phrase(0)
    A1 = phrase(1)
    B = phrase(2)
    C = phrase(3)
    structure = [A, A1, B, A, C, A1, B, A, C, B, A1, A]

    # Glissandos d'ouverture des mesures 3 et 9 (descente pentatonique rapide).
    for mesure in (3, 9):
        base = mesure * BEATS_PAR_MESURE * BEAT
        for i, deg in enumerate([11, 10, 8, 7, 5, 4]):
            t0 = base + i * 0.095
            son = pince(DEGRES[deg], 0.9, 0.16)
            i0 = int(t0 * SR)
            gauche[i0:i0 + len(son)] += son * 0.55
            droite[i0:i0 + len(son)] += son * 0.85

    for k, evts in enumerate(structure):
        base_bar = k * BEATS_PAR_MESURE * BEAT
        for (pos, deg, duree) in evts:
            if k == len(structure) - 1 and pos + duree >= BEATS_PAR_MESURE - 0.5:
                deg = 3                        # la boucle retombe sur le ré grave
            vel = 0.34 + rng.random() * 0.10
            son = pince(DEGRES[deg], min(3.6, duree * BEAT + 1.8), vel)
            i0 = int((base_bar + pos * BEAT) * SR)
            if i0 + len(son) > N - int(0.05 * SR):
                son = son[:max(0, N - int(0.05 * SR) - i0)]   # rien ne traverse la couture
            if len(son) <= 0:
                continue
            pan = 0.5 + (deg - 7) * 0.045      # les aigus légèrement à droite
            gauche[i0:i0 + len(son)] += son * (1.0 - pan * 0.4)
            droite[i0:i0 + len(son)] += son * (0.6 + pan * 0.4)

    # ------------------------------------------------- écho court + normalisation
    delai = int(0.312 * SR)
    # écho doux appliqué au mélange (copie différée à 18 %)
    echo_g = np.zeros(N)
    echo_d = np.zeros(N)
    echo_g[delai:] = gauche[:N - delai] * 0.18
    echo_d[delai:] = droite[:N - delai] * 0.18
    gauche += echo_g
    droite += echo_d

    mix = np.stack([gauche, droite], axis=1)
    pic = np.abs(mix).max()
    mix = mix / pic * 0.45
    return mix.astype("float32"), SR


def main() -> None:
    mix, sr = compose()
    rep = RACINE / "assets" / "musique"
    rep.mkdir(parents=True, exist_ok=True)
    # L'encodeur Vorbis de libsndfile plante sous Windows : on passe par un WAV
    # intermédiaire puis le ffmpeg statique de imageio-ffmpeg (outil local,
    # jamais distribué avec le jeu).
    import subprocess
    import tempfile

    import imageio_ffmpeg

    wav_tmp = Path(tempfile.mkstemp(suffix=".wav")[1])
    sf.write(wav_tmp, mix, sr, subtype="PCM_16")
    sortie = rep / "ambiance.ogg"
    ffmpeg = imageio_ffmpeg.get_ffmpeg_exe()
    subprocess.run(
        [ffmpeg, "-y", "-loglevel", "error", "-i", str(wav_tmp),
         "-c:a", "libvorbis", "-q:a", "4", str(sortie)],
        check=True,
    )
    try:
        wav_tmp.unlink(missing_ok=True)
    except OSError:
        pass  # le handle ffmpeg peut survivre un instant sous Windows
    print("musique :", sortie, "%.1f Mo" % (sortie.stat().st_size / 1e6),
          "— boucle %.0f s" % (len(mix) / sr))


if __name__ == "__main__":
    main()
