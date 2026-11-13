"""Importe sans écrasement un paquet PNG + manifeste issu de l'atelier Molab."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import struct
import sys
import unicodedata
import zipfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DESTINATIONS = {
    "sprite": (Path("assets/sprites"), "sprite"),
    "objet": (Path("assets/objets"), "objet"),
    "ui": (Path("assets/ui"), "ui"),
    "decor": (Path("assets/decors"), "decor"),
    "cinematique": (Path("assets/cine"), "cine"),
    "tuile": (Path("assets/tiles"), "tuile"),
}
PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"
MAX_PNG_BYTES = 40 * 1024 * 1024
MAX_SIDE = 8192


def slug(value: str) -> str:
    ascii_value = unicodedata.normalize("NFKD", value).encode("ascii", "ignore").decode()
    value = re.sub(r"[^a-zA-Z0-9]+", "-", ascii_value).strip("-").lower()
    return value[:80].rstrip("-") or "asset-ia"


def image_dimensions(png: bytes) -> tuple[int, int]:
    if len(png) < 24 or png[:8] != PNG_SIGNATURE or png[12:16] != b"IHDR":
        raise ValueError("Le fichier extrait n'est pas un PNG valide (signature/IHDR manquant).")
    width, height = struct.unpack(">II", png[16:24])
    if not (1 <= width <= MAX_SIDE and 1 <= height <= MAX_SIDE):
        raise ValueError(f"Dimensions PNG refusées : {width}×{height}.")
    return width, height


def load_package(path: Path) -> tuple[bytes, dict]:
    with zipfile.ZipFile(path) as archive:
        entries = [entry for entry in archive.infolist() if not entry.is_dir()]
        png_entries = [entry for entry in entries if entry.filename.lower().endswith(".png")]
        json_entries = [entry for entry in entries if entry.filename.lower().endswith(".json")]
        if len(png_entries) != 1 or len(json_entries) != 1 or len(entries) != 2:
            raise ValueError("Le ZIP doit contenir exactement un PNG et son manifeste JSON.")
        png_entry, json_entry = png_entries[0], json_entries[0]
        if png_entry.file_size > MAX_PNG_BYTES:
            raise ValueError("Image trop volumineuse (> 40 Mio).")
        png = archive.read(png_entry)
        manifest = json.loads(archive.read(json_entry).decode("utf-8"))

    if not isinstance(manifest, dict):
        raise ValueError("Le manifeste JSON doit contenir un objet.")
    if Path(str(manifest.get("file", ""))).name != png_entry.filename.split("/")[-1]:
        raise ValueError("Le nom du PNG ne correspond pas au manifeste.")
    expected_hash = manifest.get("sha256")
    actual_hash = hashlib.sha256(png).hexdigest()
    if not expected_hash or expected_hash != actual_hash:
        raise ValueError("L'empreinte SHA-256 ne correspond pas : paquet incomplet ou modifié.")
    dimensions = image_dimensions(png)
    if manifest.get("width") != dimensions[0] or manifest.get("height") != dimensions[1]:
        raise ValueError("Les dimensions du PNG ne correspondent pas au manifeste.")
    return png, manifest


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Valide et installe dans le projet un paquet d'image exporté par Molab."
    )
    parser.add_argument("paquet", type=Path, help="ZIP PNG + manifeste téléchargé depuis Molab")
    parser.add_argument("--type", choices=DESTINATIONS, default="sprite", help="dossier Godot cible")
    parser.add_argument("--nom", help="nom de base facultatif, sans extension")
    args = parser.parse_args()

    try:
        png, manifest = load_package(args.paquet)
        relative_dir, prefix = DESTINATIONS[args.type]
        directory = ROOT / relative_dir
        directory.mkdir(parents=True, exist_ok=True)
        base = slug(args.nom or Path(str(manifest["file"])).stem)
        filename = f"{prefix}-{base}.png"
        image_path = directory / filename
        provenance_path = directory / f"{prefix}-{base}.generation.json"
        if image_path.exists() or provenance_path.exists():
            raise FileExistsError(
                f"{image_path.relative_to(ROOT)} existe déjà; choisissez --nom ou gardez l'existant."
            )
        manifest["file"] = filename
        manifest["imported_as"] = str(image_path.relative_to(ROOT)).replace("\\", "/")
        image_path.write_bytes(png)
        provenance_path.write_text(
            json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
        )
    except (OSError, ValueError, KeyError, json.JSONDecodeError, zipfile.BadZipFile) as exc:
        print(f"Import annulé : {exc}", file=sys.stderr)
        return 2

    print(f"Image importée : {image_path.relative_to(ROOT)} ({manifest['width']}×{manifest['height']})")
    print(f"Manifeste : {provenance_path.relative_to(ROOT)}")
    print("Godot créera les métadonnées .import au prochain scan du projet.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
