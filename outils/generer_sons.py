"""Génère les effets sonores du jeu par synthèse — aucun asset externe, aucune licence.

Sortie : assets/sons/*.wav (mono 16 bits, 44,1 kHz). Tons doux et courts, accordés
à l'ambiance pastel : pas de bruit sec, pas d'attaque agressive.

    python outils/generer_sons.py
"""
import math
import os
import struct
import wave

SR = 44100
SORTIE = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets", "sons")


def _sin(f, t):
    return math.sin(2.0 * math.pi * f * t)


def _env(t, attaque=0.004, chute=0.18):
    if t < attaque:
        return t / attaque
    return math.exp(-(t - attaque) / chute)


def synthese(notes, duree, volume=0.30, chute=0.18):
    """notes : liste de (fréquence, début, durée, amplitude)."""
    n = int(SR * duree)
    donnees = []
    for i in range(n):
        t = i / SR
        v = 0.0
        for f, t0, dur, amp in notes:
            if t0 <= t < t0 + dur:
                tt = t - t0
                v += amp * _sin(f, tt) * _env(tt, 0.004, chute)
                # une octave au-dessus, très discrète : donne du corps sans dureté
                v += 0.18 * amp * _sin(f * 2.0, tt) * _env(tt, 0.004, chute * 0.6)
        v = math.tanh(v * 1.4)
        donnees.append(int(max(-1.0, min(1.0, v * volume)) * 32767))
    return donnees


def ecrire(nom, donnees):
    chemin = os.path.join(SORTIE, nom + ".wav")
    with wave.open(chemin, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", v) for v in donnees))
    print("  ok  %-12s %d Ko" % (nom, os.path.getsize(chemin) // 1024))


def main():
    os.makedirs(SORTIE, exist_ok=True)

    # fusion : deux notes qui montent, courte et ronde
    ecrire("fusion", synthese([(520, 0.00, 0.09, 0.9), (780, 0.06, 0.14, 0.8)], 0.24, 0.34, 0.13))

    # pièce : petite clochette de récompense
    ecrire("piece", synthese([(1318, 0.00, 0.06, 0.7), (1760, 0.05, 0.10, 0.6)], 0.22, 0.26, 0.10))

    # clic : confirmation discrète
    ecrire("clic", synthese([(392, 0.00, 0.05, 0.7)], 0.10, 0.22, 0.05))

    # erreur : grave, sans agressivité
    ecrire("erreur", synthese([(196, 0.00, 0.16, 0.8), (185, 0.02, 0.16, 0.6)], 0.22, 0.24, 0.14))

    # succès : arpège majeur
    ecrire("succes", synthese(
        [(523, 0.00, 0.12, 0.7), (659, 0.09, 0.12, 0.7), (784, 0.18, 0.20, 0.8)], 0.42, 0.28, 0.16))

    # construction : bois frappé
    ecrire("construire", synthese(
        [(110, 0.00, 0.10, 0.9), (220, 0.00, 0.06, 0.5), (330, 0.02, 0.05, 0.3)], 0.26, 0.30, 0.09))

    print("sons :", len([f for f in os.listdir(SORTIE) if f.endswith(".wav")]))


if __name__ == "__main__":
    main()
