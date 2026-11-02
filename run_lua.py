#!/usr/bin/env python3
"""Run a Lua 5.4 file through the system liblua5.4 (no lua binary installed). Usage: run_lua.py file.lua"""
import ctypes, ctypes.util, sys
lib = ctypes.CDLL(ctypes.util.find_library("lua5.4") or "liblua5.4.so.0")
lib.luaL_newstate.restype = ctypes.c_void_p
lib.luaL_openlibs.argtypes = [ctypes.c_void_p]
lib.luaL_loadfilex.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_char_p]
lib.lua_pcallk.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_void_p, ctypes.c_void_p]
lib.lua_tolstring.restype = ctypes.c_char_p
lib.lua_tolstring.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_void_p]
def main(path):
    L = lib.luaL_newstate(); lib.luaL_openlibs(L)
    if lib.luaL_loadfilex(L, path.encode(), None) != 0:
        print("SYNTAX ERROR:", lib.lua_tolstring(L, -1, None).decode()); return 2
    if lib.lua_pcallk(L, 0, 0, 0, None, None) != 0:
        print("RUNTIME ERROR:", lib.lua_tolstring(L, -1, None).decode()); return 1
    return 0
sys.exit(main(sys.argv[1]))
