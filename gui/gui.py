import tkinter as tk
from tkinter import messagebox, ttk

from client import Client


class App(tk.Tk):
    def __init__(self, client):
        super().__init__()
        self.title("Simulador de Cadenas de Markov")
        self.client = client
        self.states = []
        self.cells = []
        self._build()
        self.protocol("WM_DELETE_WINDOW", self._on_close)

    # ---------- Construcción de la ventana ----------

    def _build(self):
        top = ttk.Frame(self, padding=8)
        top.pack(fill="x")
        ttk.Label(top, text="Estados (separados por coma):").pack(side="left")
        self.states_var = tk.StringVar(value="Sol, Lluvia")
        ttk.Entry(top, textvariable=self.states_var, width=30).pack(side="left", padx=6)
        ttk.Button(top, text="Crear matriz", command=self._create_matrix).pack(side="left")

        self.matrix_frame = ttk.Frame(self, padding=8)
        self.matrix_frame.pack()

        controls = ttk.Frame(self, padding=8)
        controls.pack(fill="x")
        ttk.Label(controls, text="Estado inicial:").pack(side="left")
        self.start_box = ttk.Combobox(controls, state="readonly", width=12)
        self.start_box.pack(side="left", padx=6)
        ttk.Label(controls, text="Pasos n:").pack(side="left")
        self.steps_var = tk.StringVar(value="10")
        ttk.Entry(controls, textvariable=self.steps_var, width=6).pack(side="left", padx=6)

        buttons = ttk.Frame(self, padding=8)
        buttons.pack(fill="x")
        ttk.Button(buttons, text="Validar cadena", command=self._validate).pack(side="left", padx=2)
        ttk.Button(buttons, text="Simular", command=self._simulate).pack(side="left", padx=2)
        ttk.Button(buttons, text="Distribución tras n pasos", command=self._dist).pack(side="left", padx=2)
        ttk.Button(buttons, text="Estacionaria", command=self._stationary).pack(side="left", padx=2)

        self.output = tk.Text(self, height=10, width=60, wrap="word")
        self.output.pack(padx=8, pady=8, fill="both", expand=True)

        self._create_matrix()

    def _create_matrix(self):
        names = [s.strip() for s in self.states_var.get().split(",") if s.strip()]
        if not names or len(set(names)) != len(names) or any(" " in s for s in names):
            messagebox.showerror(
                "Estados inválidos",
                "Usa nombres únicos, sin espacios, separados por coma.",
            )
            return
        self.states = names
        for w in self.matrix_frame.winfo_children():
            w.destroy()
        self.cells = []
        for j, name in enumerate(names):
            ttk.Label(self.matrix_frame, text=name).grid(row=0, column=j + 1, padx=2)
        for i, name in enumerate(names):
            ttk.Label(self.matrix_frame, text=name).grid(row=i + 1, column=0, padx=2)
            row = []
            for j in range(len(names)):
                e = ttk.Entry(self.matrix_frame, width=7, justify="center")
                e.insert(0, "0")
                e.grid(row=i + 1, column=j + 1, padx=2, pady=2)
                row.append(e)
            self.cells.append(row)
        self.start_box["values"] = names
        self.start_box.current(0)

    # ---------- Lectura de entradas ----------

    def _read_matrix(self):
        try:
            return [[float(e.get().strip()) for e in row] for row in self.cells]
        except ValueError:
            messagebox.showerror(
                "Matriz inválida",
                "Todas las celdas deben ser números (usa punto decimal).",
            )
            return None

    def _read_steps(self):
        try:
            n = int(self.steps_var.get())
            if n < 0:
                raise ValueError
            return n
        except ValueError:
            messagebox.showerror("Pasos inválidos", "n debe ser un entero mayor o igual a 0.")
            return None

    # ---------- Acciones ----------

    def _run(self, action):
        """Carga la matriz actual en el servidor y luego ejecuta la acción."""
        matrix = self._read_matrix()
        if matrix is None:
            return
        try:
            reply = self.client.load(self.states, matrix)
            if reply["ok"]:
                reply = action()
        except (OSError, ValueError) as e:
            self._show("Error de conexión: " + str(e))
            return
        self._show(self._format(reply))

    def _validate(self):
        self._run(lambda: {"ok": True})

    def _simulate(self):
        n = self._read_steps()
        if n is not None:
            self._run(lambda: self.client.simulate(self.start_box.get(), n))

    def _dist(self):
        n = self._read_steps()
        if n is not None:
            self._run(lambda: self.client.dist(self.start_box.get(), n))

    def _stationary(self):
        self._run(self.client.stationary)

    # ---------- Salida ----------

    @staticmethod
    def _format(reply):
        if not reply["ok"]:
            return "Error: " + reply["error"]
        if "path" in reply:
            return " → ".join(reply["path"])
        if "dist" in reply:
            return "\n".join(
                "{}: {:.4f}".format(s, p) for s, p in reply["dist"].items()
            )
        return "Cadena válida"

    def _show(self, text):
        self.output.delete("1.0", "end")
        self.output.insert("1.0", text)

    def _on_close(self):
        self.client.close()
        self.destroy()


def main():
    try:
        client = Client()
    except OSError:
        print("No se pudo conectar. ¿Está corriendo el servidor (cabal run markov-server)?")
        return
    App(client).mainloop()


if __name__ == "__main__":
    main()