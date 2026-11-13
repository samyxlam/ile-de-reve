"""Serveur local du build web Godot : sert le projet et ouvre le navigateur.

Le build web a besoin d'HTTP (fetch du .wasm et du .pck) : ouvrir index.html
directement en file:// ne fonctionne pas. Ce script fait le minimum utile.
"""
import functools
import http.server
import os
import socketserver
import threading
import webbrowser

PORT = 8000
RACINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
URL = "http://localhost:%d/build/web/index.html" % PORT


class Handler(http.server.SimpleHTTPRequestHandler):
    extensions_map = dict(http.server.SimpleHTTPRequestHandler.extensions_map)
    extensions_map.update({
        ".wasm": "application/wasm",
        ".pck": "application/octet-stream",
        ".js": "text/javascript",
        ".json": "application/json",
    })

    def log_message(self, *args):
        pass


class Serveur(socketserver.TCPServer):
    allow_reuse_address = True


def main():
    os.chdir(RACINE)
    handler = functools.partial(Handler, directory=RACINE)
    try:
        srv = Serveur(("127.0.0.1", PORT), handler)
    except OSError:
        # Port déjà pris : probablement une session précédente, on ouvre juste le navigateur.
        print("Port %d deja utilise, ouverture du navigateur." % PORT)
        webbrowser.open(URL)
        return

    threading.Timer(1.2, lambda: webbrowser.open(URL)).start()
    print("Ile de Reve -- serveur local")
    print("Adresse : %s" % URL)
    print("Ferme cette fenetre (ou Ctrl+C) pour arreter le jeu.")
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        srv.server_close()


if __name__ == "__main__":
    main()
