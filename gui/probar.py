import socket

s = socket.create_connection(("127.0.0.1", 5000))
f = s.makefile("rw", encoding="utf-8", newline="\n")

for cmd in [
    "LOAD Sol,Lluvia | 0.9,0.1;0.5,0.5",
    "SIMULATE Sol 5",
    "DIST Sol 2",
    "STATIONARY",
    "SIMULATE Nieve 3",
]:
    f.write(cmd + "\n")
    f.flush()
    print(cmd, "->", f.readline().strip())