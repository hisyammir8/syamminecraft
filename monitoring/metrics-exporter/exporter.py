#!/usr/bin/env python3

import json
import os
from http.server import BaseHTTPRequestHandler, HTTPServer


METRICS_DIR = os.environ.get(
    "METRICS_DIR",
    "/runtime/metrics"
)

HEALTH_STATE_FILE = os.environ.get(
    "HEALTH_STATE_FILE",
    "/var/lib/minecraft-health/state"
)

RESOURCE_STATE_FILE = os.environ.get(
    "RESOURCE_STATE_FILE",
    "/var/lib/minecraft-health/resource.state"
)

INSTANCE_NAME = os.environ.get(
    "INSTANCE_NAME",
    "minecraft-server"
)

def read_json(filename):
    path = os.path.join(METRICS_DIR, filename)

    try:
        with open(path, "r") as file:
            return json.load(file)
    except Exception:
        return {}


def read_text(filename):
    try:
        with open(filename, "r") as file:
            return file.read().strip()
    except Exception:
        return ""

METRIC_DEFINITIONS = {
    "minecraft_up": (
        "Whether Minecraft server is running",
        "gauge",
    ),
    "minecraft_online_players": (
        "Number of online Minecraft players",
        "gauge",
    ),
    "minecraft_max_players": (
        "Maximum number of Minecraft players",
        "gauge",
    ),
    "minecraft_cpu_usage_percent": (
        "Minecraft server CPU usage percentage",
        "gauge",
    ),
    "minecraft_memory_used_mb": (
        "Minecraft server memory used in megabytes",
        "gauge",
    ),
    "minecraft_memory_total_mb": (
        "Minecraft server total memory in megabytes",
        "gauge",
    ),
    "minecraft_disk_used_mb": (
        "Minecraft server disk used in megabytes",
        "gauge",
    ),
    "minecraft_disk_total_mb": (
        "Minecraft server total disk in megabytes",
        "gauge",
    ),
    "minecraft_process_running": (
        "Whether the Minecraft server process is running",
        "gauge",
    ),
    "minecraft_process_uptime_seconds": (
        "Minecraft server process uptime in seconds",
        "gauge",
    ),
    "minecraft_restart_count": (
        "Number of Minecraft server restarts",
        "gauge",
    ),
    "minecraft_exit_code": (
        "Last Minecraft server process exit code",
        "gauge",
    ),
    "minecraft_health": (
        "Whether Minecraft server health state is healthy",
        "gauge",
    ),
    "minecraft_resource_normal": (
        "Whether Minecraft server resource state is normal",
        "gauge",
    ),
    "minecraft_resource_warning": (
        "Whether Minecraft server resource state is warning",
        "gauge",
    ),
    "minecraft_resource_critical": (
        "Whether Minecraft server resource state is critical",
        "gauge",
    ),
}


def metric(name, value):
    help_text, metric_type = METRIC_DEFINITIONS[name]

    return (
        f"# HELP {name} {help_text}\n"
        f"# TYPE {name} {metric_type}\n"
        f'{name}{{instance="{escape_label(INSTANCE_NAME)}"}} {value}\n'
    )

def escape_label(value):
    return (
        str(value)
        .replace("\\", "\\\\")
        .replace('"', '\\"')
        .replace("\n", "\\n")
    )

def generate_metrics():

    server = read_json("server.json")
    system = read_json("system.json")
    process = read_json("process.json")

    health_state = read_text(HEALTH_STATE_FILE)
    resource_state = read_text(RESOURCE_STATE_FILE)

    instance = escape_label(INSTANCE_NAME)
    version = escape_label(
        server.get("version", "unknown")
    )

    output = ""

    # --------------------------------------------------
    # Server metadata
    # --------------------------------------------------

    output += (
        "# HELP minecraft_info Minecraft server metadata\n"
        "# TYPE minecraft_info gauge\n"
        f'minecraft_info{{instance="{instance}",'
        f'version="{version}"}} 1\n'
    )

    # --------------------------------------------------
    # Minecraft server
    # --------------------------------------------------

    output += metric(
        "minecraft_up",
        1 if server.get("status") == "running" else 0
    )

    output += metric(
        "minecraft_online_players",
        server.get("onlinePlayers", 0)
    )

    output += metric(
        "minecraft_max_players",
        server.get("maxPlayers", 0)
    )

    # --------------------------------------------------
    # System resources
    # --------------------------------------------------

    output += metric(
        "minecraft_cpu_usage_percent",
        system.get("cpuUsage", 0)
    )

    output += metric(
        "minecraft_memory_used_mb",
        system.get("memoryUsedMB", 0)
    )

    output += metric(
        "minecraft_memory_total_mb",
        system.get("memoryTotalMB", 0)
    )

    output += metric(
        "minecraft_disk_used_mb",
        system.get("diskUsedMB", 0)
    )

    output += metric(
        "minecraft_disk_total_mb",
        system.get("diskTotalMB", 0)
    )

    # --------------------------------------------------
    # Process
    # --------------------------------------------------

    output += metric(
        "minecraft_process_running",
        1 if process.get("running") else 0
    )

    output += metric(
        "minecraft_process_uptime_seconds",
        process.get("uptime", 0)
    )

    output += metric(
        "minecraft_restart_count",
        process.get("restartCount", 0)
    )

    output += metric(
        "minecraft_exit_code",
        process.get("exitCode", 0)
    )

    # --------------------------------------------------
    # Health state
    # --------------------------------------------------

    output += metric(
        "minecraft_health",
        1 if health_state == "HEALTHY" else 0
    )

    # --------------------------------------------------
    # Resource state
    # --------------------------------------------------

    output += metric(
        "minecraft_resource_normal",
        1 if resource_state == "NORMAL" else 0
    )

    output += metric(
        "minecraft_resource_warning",
        1 if resource_state == "WARNING" else 0
    )

    output += metric(
        "minecraft_resource_critical",
        1 if resource_state == "CRITICAL" else 0
    )

    return output


class MetricsHandler(BaseHTTPRequestHandler):

    def do_GET(self):

        if self.path != "/metrics":
            self.send_response(404)
            self.end_headers()
            return

        body = generate_metrics().encode("utf-8")

        self.send_response(200)

        self.send_header(
            "Content-Type",
            "text/plain; version=0.0.4"
        )

        self.send_header(
            "Content-Length",
            str(len(body))
        )

        self.end_headers()

        self.wfile.write(body)

    def log_message(self, format, *args):
        return


def main():

    host = "0.0.0.0"
    port = 9100

    server = HTTPServer(
        (host, port),
        MetricsHandler
    )

    print(
        f"Minecraft metrics exporter listening on "
        f"{host}:{port}",
        flush=True
    )

    server.serve_forever()


if __name__ == "__main__":
    main()
