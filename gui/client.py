import json
import socket


class Client:
    """Cliente del servidor Haskell: un comando por línea, respuesta JSON."""

    def __init__(self, host="127.0.0.1", port=5000):
        self._sock = socket.create_connection((host, port), timeout=5)
        self._file = self._sock.makefile("rw", encoding="utf-8", newline="\n")

    def _send(self, command):
        self._file.write(command + "\n")
        self._file.flush()
        line = self._file.readline()
        if not line:
            raise ConnectionError("El servidor cerró la conexión")
        return json.loads(line)

    def load(self, states, matrix):
        rows = ";".join(",".join(str(x) for x in row) for row in matrix)
        return self._send("LOAD " + ",".join(states) + " | " + rows)

    def simulate(self, start, n):
        return self._send("SIMULATE " + start + " " + str(n))

    def dist(self, start, n):
        return self._send("DIST " + start + " " + str(n))

    def stationary(self):
        return self._send("STATIONARY")

    def close(self):
        self._file.close()
        self._sock.close()