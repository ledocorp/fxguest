// fxguest_lib — capability speech CLI (--cli).
module fxguest_lib;

using core;
import std/io;
import std/string;
import std/strutil;

extern "c" {
    fn fx_cli_argc() -> i32;
    fn fx_cli_arg(i: i32) -> string;
    effects { alloc } fn fx_guest_begin(root: string, arena_bytes: i64) -> i64;
    effects { alloc } fn fx_guest_end(ctx_handle: i64) -> i32;
    effects { alloc } fn fx_guest_mint_fscap(ctx_handle: i64, root: string) -> i64;
    effects { alloc } fn fx_guest_mint_fuelcap(ctx_handle: i64, units: i64) -> i64;
    effects { alloc } fn fx_fuelcap_burn(fuel_handle: i64, units: i64) -> i32;
    effects { io, alloc } fn fx_io_cap_read_file(fs_handle: i64, path: string) -> i32;
    effects { io, alloc } fn fx_io_cap_last_text() -> string;
}

fn eq(a: string, b: string) -> bool {
    return string.compare(a, b);
}

fn usage() -> i32 effects { io } {
    let _u = io.write_err("usage: fxguest --allow <dir> allow <rel-path>");
    let _u2 = io.write_err("       fxguest --allow <dir> deny <outside-rel-path>");
    let _u3 = io.write_err("       fxguest --allow <dir> budget [--fuel N]");
    return 1;
}

fn parse_i32(s: string) -> i32 {
    let nlen = str_len(s);
    let i: i32 = 0;
    let n: i32 = 0;
    while (i < nlen) {
        let c: i32 = str_byte_at(s, i);
        if (c < 48) {
            break;
        }
        if (c > 57) {
            break;
        }
        n = n * 10 + (c - 48);
        i = i + 1;
    }
    return n;
}

fn path_has_dotdot(s: string) -> bool {
    return strutil.contains(s, "..");
}

fn resolve_under(allow: string, rel: string) -> Result<string, core_Err> effects { alloc } {
    let al = string.len(allow);
    let dl = string.len(rel);
    if (dl > al) {
        if (strutil.starts_with(rel, allow) == true) {
            let c = string.byte_at(rel, al);
            if (c == 47) {
                return Ok(rel);
            }
            if (c == 92) {
                return Ok(rel);
            }
        }
    }
    let mid = string.concat(allow, "/")?;
    return string.concat(mid, rel);
}

fn map_read(st: i32) -> i32 effects { io } {
    if (st == 0) {
        return 0;
    }
    if (st == 5) {
        let _d = io.write_err("fxguest: path outside allow / denied");
        return 2;
    }
    if (st == 2) {
        let _m = io.write_err("fxguest: path missing or unreadable");
        return 3;
    }
    let _f = io.write_err("fxguest: read failed");
    return 3;
}

fn run_allow(allow: string, rel: string) -> Result<i32, core_Err> effects { alloc, io } {
    if (path_has_dotdot(rel) == true) {
        let _m = io.write_err("fxguest: path must not contain ..");
        return Ok(1);
    }
    let path = resolve_under(allow, rel)?;
    let g = fx_guest_begin(allow, 65536);
    if (g == 0) {
        let _g = io.write_err("fxguest: guest begin failed");
        return Ok(2);
    }
    let fs = fx_guest_mint_fscap(g, "");
    if (fs == 0) {
        let _e0 = fx_guest_end(g);
        let _f = io.write_err("fxguest: mint_fs failed");
        return Ok(2);
    }
    let st = fx_io_cap_read_file(fs, path);
    if (st != 0) {
        let _en = fx_guest_end(g);
        return Ok(map_read(st));
    }
    let body = fx_io_cap_last_text();
    let _w = io.write_line(body);
    let _en2 = fx_guest_end(g);
    return Ok(0);
}

fn run_deny(allow: string, outside: string) -> Result<i32, core_Err> effects { alloc, io } {
    if (path_has_dotdot(outside) == true) {
        let _m = io.write_err("fxguest: path must not contain ..");
        return Ok(1);
    }
    if (string.len(outside) == 0) {
        let _m = io.write_err("fxguest: deny requires a path");
        return Ok(1);
    }
    let g = fx_guest_begin(allow, 65536);
    if (g == 0) {
        let _g = io.write_err("fxguest: guest begin failed");
        return Ok(2);
    }
    let fs = fx_guest_mint_fscap(g, "");
    if (fs == 0) {
        let _e0 = fx_guest_end(g);
        let _f = io.write_err("fxguest: mint_fs failed");
        return Ok(2);
    }
    // Intentionally NOT resolve_under — path must fail FsCap prefix check.
    let st = fx_io_cap_read_file(fs, outside);
    let _en = fx_guest_end(g);
    if (st == 5) {
        let _d = io.write_err("fxguest: denied (expected)");
        return Ok(2);
    }
    if (st == 0) {
        let _b = io.write_err("fxguest: deny mode unexpectedly allowed path");
        return Ok(3);
    }
    return Ok(map_read(st));
}

/// Mint FuelCap, burn 1 until exhaust. Exit 3 when exhaust observed (speech Done-when).
fn run_budget(allow: string, fuel_n: i32) -> Result<i32, core_Err> effects { alloc, io } {
    if (fuel_n < 1) {
        let _m = io.write_err("fxguest: --fuel must be >= 1");
        return Ok(1);
    }
    let g = fx_guest_begin(allow, 65536);
    if (g == 0) {
        let _g = io.write_err("fxguest: guest begin failed");
        return Ok(2);
    }
    let fuel = fx_guest_mint_fuelcap(g, fuel_n as i64);
    if (fuel == 0) {
        let _e0 = fx_guest_end(g);
        let _f = io.write_err("fxguest: mint_fuel failed");
        return Ok(2);
    }
    let burns: i32 = 0;
    let limit: i32 = fuel_n + 2;
    while (burns < limit) {
        let burn_st = fx_fuelcap_burn(fuel, 1 as i64);
        if (burn_st == 0) {
            let _en = fx_guest_end(g);
            if (burns != fuel_n) {
                let _b = io.write_err("fxguest: fuel exhausted at unexpected count");
                return Ok(3);
            }
            let _d = io.write_err("fxguest: fuel exhausted (expected)");
            return Ok(3);
        }
        let _w = io.write_line("fuel-burn");
        burns = burns + 1;
    }
    let _en2 = fx_guest_end(g);
    let _x = io.write_err("fxguest: fuel never exhausted");
    return Ok(1);
}

fn cli_main() -> Result<i32, core_Err> effects { alloc, io, mut } {
    let allow = "";
    let mode = "";
    let path = "";
    let fuel_n: i32 = 2;
    let argc = fx_cli_argc();
    let i: i32 = 1;

    while (i < argc) {
        let a = fx_cli_arg(i);
        if (eq(a, "--help") == true) {
            return Ok(usage());
        }
        if (eq(a, "-h") == true) {
            return Ok(usage());
        }
        if (eq(a, "--allow") == true) {
            i = i + 1;
            if (i >= argc) {
                let _m = io.write_err("fxguest: --allow requires a directory");
                return Ok(1);
            }
            allow = fx_cli_arg(i);
            i = i + 1;
        } else {
            if (eq(a, "--fuel") == true) {
                i = i + 1;
                if (i >= argc) {
                    let _m = io.write_err("fxguest: --fuel requires N");
                    return Ok(1);
                }
                fuel_n = parse_i32(fx_cli_arg(i));
                i = i + 1;
            } else {
                if (string.len(mode) == 0) {
                    if (eq(a, "allow") == true) {
                        mode = "allow";
                        i = i + 1;
                    } else {
                        if (eq(a, "deny") == true) {
                            mode = "deny";
                            i = i + 1;
                        } else {
                            if (eq(a, "budget") == true) {
                                mode = "budget";
                                i = i + 1;
                            } else {
                                let _m = io.write_err("fxguest: expected allow, deny, or budget");
                                return Ok(1);
                            }
                        }
                    }
                } else {
                    if (string.len(path) == 0) {
                        path = a;
                        i = i + 1;
                    } else {
                        let _m = io.write_err("fxguest: unexpected extra argument");
                        return Ok(1);
                    }
                }
            }
        }
    }

    if (string.len(allow) == 0) {
        return Ok(usage());
    }
    if (string.len(mode) == 0) {
        return Ok(usage());
    }

    if (eq(mode, "budget") == true) {
        return run_budget(allow, fuel_n);
    }
    if (string.len(path) == 0) {
        let _m = io.write_err("fxguest: path required");
        return Ok(1);
    }
    if (eq(mode, "allow") == true) {
        return run_allow(allow, path);
    }
    return run_deny(allow, path);
}
