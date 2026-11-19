#!/bin/bash
adb wait-for-device
adb root
adb remount
echo " 启动qnx ---> "
QNX_USER='root'
QNX_PASSWORD='mQx@r7PLv#Nf'
export QNX_USER QNX_PASSWORD
python3 - <<'PY'
import os
import select
import sys
import termios
import tty

user = os.environ["QNX_USER"]
password = (os.environ["QNX_PASSWORD"] + "\r").encode()
login = (user + "\r").encode()
cmd = ["adb", "shell", "-t", "busybox", "telnet", "192.168.118.2", "-l", user]

pid, fd = os.forkpty()
if pid == 0:
    os.execvp(cmd[0], cmd)

stdin = sys.stdin.fileno()
old = termios.tcgetattr(stdin)
sent_password = False
buf = b""
try:
    while True:
        watch = [fd]
        if sent_password:
            watch.append(stdin)
        readable, _, _ = select.select(watch, [], [])
        if fd in readable:
            try:
                data = os.read(fd, 4096)
            except OSError:
                break
            if not data:
                break
            os.write(sys.stdout.fileno(), data)
            if not sent_password:
                buf = (buf + data)[-256:]
                if b"Password:" in buf or b"password:" in buf:
                    os.write(fd, password)
                    sent_password = True
                    tty.setraw(stdin)
                    buf = b""
                elif buf.endswith(b"login:") or buf.endswith(b"login: "):
                    os.write(fd, login)
                    buf = b""
        if sent_password and stdin in readable:
            try:
                typed = os.read(stdin, 4096)
            except OSError:
                break
            if not typed:
                break
            os.write(fd, typed)
finally:
    termios.tcsetattr(stdin, termios.TCSADRAIN, old)
    try:
        os.waitpid(pid, 0)
    except ChildProcessError:
        pass
PY
